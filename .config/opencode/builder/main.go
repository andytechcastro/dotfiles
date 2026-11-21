package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
)

// Config holds the paths relative to the builder directory
const (
	TemplatesDir = "templates"
	PromptsDir   = "../prompts" // Relative to builder/
	OutputDir    = "../"        // Relative to builder/ (.config/opencode/)
)

// ModelProfile holds the resolved model assignments for the active profile
var ModelProfile map[string]string

// ---------------------------------------------------------------------------
// Model-id emission guard (silent-failure gate)
// ---------------------------------------------------------------------------
// Why this exists — every entry below is a MEASURED failure mode of the raw
// textual {{MODEL:key}} substitution:
//   - `model: x #medium` (space before '#') → js-yaml reads a comment, the
//     value becomes null → opencode 2.3.0 silently substitutes the account
//     default; opencode 2.2.5 (homesrv/Pi) drops the agent from the listing
//     with NO log line at all.
//   - `model: #medium` (value starts with '#') → same null outcome.
//   - profile key missing → the literal {{MODEL:x}} survives into the
//     compiled agent → broken model at runtime.
//   - empty value → YAML/JSON null → silent substitution.
//   - structured/numeric profile value → the old `v.(string)` type assertion
//     PANICKED mid-run, potentially leaving a partially written tree. Now a
//     pre-flight error before any os.WriteFile.
//
// What this guard CANNOT catch: variant-name validity. There is no local
// catalog of variants — `opencode models` prints ids WITHOUT the '#variant'
// suffix — so `opencode-go/gemini-4-argon#ultra` passes SHAPE validation and
// still kills every session of that agent at first turn with
// provider.no-route. Only the gateway knows whether a variant exists; this
// validator checks form, never existence.
//
// Coverage: both emission paths (agent templates and
// templates/config/config.json → model, agents.title.model,
// agents.explore.model) flow through ModelProfile +
// resolveModelPlaceholders, so the guard covers JSON too ('#' is legal in
// JSON strings). Model ids must NEVER be routed through ${VAR} env
// substitution in the config template: dotenv-style consumers truncate at
// '#' (e.g. an `[^#\r\n]+` capture), silently eating the variant suffix.
// Keep ids in model_profiles.json.
var allowedModelProviders = map[string]bool{
	"opencode-go": true,
	// ACP Antigravity channel — deliberate, owner-approved (ADR 0012,
	// 2026-11-21): personal agents run through opencode-antigravity-acp.
	"antigravity-acp": true,
}

// Adding a provider here is a deliberate, reviewed change. Rolling back to
// the native `google` provider (documented ADR 0008 safety net) requires
// adding `"google"` to this map — do NOT do it automatically: the
// `provider.use google allow` policy floor permits the route, it does not
// authorize the build to take it.

// modelShapeRe is the generic legal form for a model id:
// provider/model[#variant], every segment non-empty, charset
// [A-Za-z0-9._-]. It deliberately accepts no whitespace and at most one '#'.
var modelShapeRe = regexp.MustCompile(`^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+(#[A-Za-z0-9._-]+)?$`)

// reModelPlaceholder matches {{MODEL:key}} references in templates. The KEY
// charset is historical; the VALUE rules live in validateModelValue.
var reModelPlaceholder = regexp.MustCompile(`\{\{MODEL:([a-zA-Z0-9_]+)\}\}`)

// validateModelValue checks one profile value against the shape rules and the
// provider allowlist. It returns a deterministic, actionable error naming the
// profile key, the offending value, and the violated rule. It never mutates
// the value: bare ids (e.g. opencode-go/mimo-v2.6-flash, which exposes no
// variants) stay bare — appending or stripping a suffix here would itself be
// a silent failure mode.
func validateModelValue(key, value string) error {
	fail := func(rule, detail string) error {
		return fmt.Errorf("model key %q: value %q violates %s — %s", key, value, rule, detail)
	}

	if value == "" {
		return fail("EMPTY_VALUE", "an empty id becomes YAML/JSON null; opencode then silently substitutes the account default")
	}
	// Covers `x #medium` (the js-yaml comment trap), ` x`, trailing newlines,
	// tabs — any whitespace anywhere is illegal in a model id.
	if strings.ContainsAny(value, " \t\n\v\f\r") {
		return fail("WHITESPACE", "a space before '#' turns the value into a YAML comment (→ null on js-yaml); whitespace is never legal in a model id")
	}
	if strings.HasPrefix(value, "#") {
		return fail("HASH_FIRST", "value starts with '#': there is no provider/model prefix ('model: #medium' parses as null)")
	}
	if strings.Count(value, "#") > 1 {
		return fail("MULTI_HASH", "more than one '#': only one variant suffix is legal (the id parser splits on the FIRST '#')")
	}
	provider, rest, hasSlash := strings.Cut(value, "/")
	if !hasSlash || provider == "" || rest == "" {
		return fail("MISSING_SEGMENT", "expected 'provider/model' or 'provider/model#variant'")
	}
	model, variant, hasHash := strings.Cut(rest, "#")
	if model == "" || (hasHash && variant == "") {
		return fail("EMPTY_SEGMENT", "empty model or variant segment")
	}
	if !modelShapeRe.MatchString(value) {
		return fail("ILLEGAL_CHARACTERS", "segments must match [A-Za-z0-9._-]")
	}
	if !allowedModelProviders[provider] {
		return fail("PROVIDER_NOT_ALLOWLISTED", fmt.Sprintf("provider %q is not in allowedModelProviders; adding a provider is a deliberate, reviewed change", provider))
	}
	return nil
}

// validateProfile flattens a decoded JSON profile to map[string]string,
// hard-failing on non-string values (the old panic path) and on any shape or
// allowlist violation. Violations are collected for every key, in sorted
// order, so one run reports all problems deterministically.
func validateProfile(raw map[string]interface{}) (map[string]string, error) {
	keys := make([]string, 0, len(raw))
	for k := range raw {
		keys = append(keys, k)
	}
	sort.Strings(keys)

	flat := make(map[string]string, len(raw))
	var problems []string
	for _, k := range keys {
		v, ok := raw[k].(string)
		if !ok {
			problems = append(problems, fmt.Sprintf(
				"model key %q: value must be a string model id like \"opencode-go/provider-model#variant\", got %T (a structured or numeric value used to panic the emitter mid-write)", k, raw[k]))
			continue
		}
		if err := validateModelValue(k, v); err != nil {
			problems = append(problems, err.Error())
			continue
		}
		flat[k] = v
	}
	if len(problems) > 0 {
		return nil, fmt.Errorf("invalid model profile:\n  - %s", strings.Join(problems, "\n  - "))
	}
	return flat, nil
}

// preflightModelKeys scans every template the builder emits — agent templates
// after {file:} include expansion (exactly as processAgents sees them) plus
// the config template — and hard-fails if any {{MODEL:key}} reference is
// missing from the active profile. It runs BEFORE any os.WriteFile: a missing
// key discovered at substitution time (mid-loop over agent files) would leave
// a partially written tree with a mix of old and new artifacts.
func preflightModelKeys() error {
	refs := make(map[string]map[string]bool) // missing key → referencing files

	addRefs := func(source, content string) {
		for _, m := range reModelPlaceholder.FindAllStringSubmatch(content, -1) {
			key := m[1]
			if _, ok := ModelProfile[key]; ok {
				continue
			}
			if refs[key] == nil {
				refs[key] = make(map[string]bool)
			}
			refs[key][source] = true
		}
	}

	agentTemplatesDir := filepath.Join(TemplatesDir, "agent")
	files, err := os.ReadDir(agentTemplatesDir)
	if err != nil {
		return fmt.Errorf("could not read agent templates dir: %w", err)
	}
	for _, file := range files {
		if file.IsDir() {
			continue
		}
		path := filepath.Join(agentTemplatesDir, file.Name())
		content, err := os.ReadFile(path)
		if err != nil {
			return fmt.Errorf("could not read template %s: %w", path, err)
		}
		addRefs(path, resolveIncludes(string(content)))
	}

	// A missing config template fails later in processConfig; here it only
	// means "no extra references to scan".
	if content, err := os.ReadFile(filepath.Join(TemplatesDir, "config", "config.json")); err == nil {
		addRefs("templates/config/config.json", string(content))
	}

	if len(refs) == 0 {
		return nil
	}

	keys := make([]string, 0, len(refs))
	for k := range refs {
		keys = append(keys, k)
	}
	sort.Strings(keys)

	var b strings.Builder
	b.WriteString("template(s) reference model key(s) missing from the active profile — leaving the literal {{MODEL:key}} in a compiled agent means a broken model at runtime:")
	for _, k := range keys {
		sources := make([]string, 0, len(refs[k]))
		for s := range refs[k] {
			sources = append(sources, s)
		}
		sort.Strings(sources)
		fmt.Fprintf(&b, "\n  - '{{MODEL:%s}}' referenced by: %s", k, strings.Join(sources, ", "))
	}
	fmt.Fprintf(&b, "\n  fix: add the key to the active profile in %s, or correct the template reference", filepath.Join(TemplatesDir, "model_profiles.json"))
	return fmt.Errorf("%s", b.String())
}

func main() {
	cwd, _ := os.Getwd()
	fmt.Printf("🚀 Starting Generic OpenCode Builder in: %s\n", cwd)

	// 0. Load Model Profile
	if err := loadModelProfile(); err != nil {
		fmt.Printf("❌ Error loading model profile: %v\n", err)
		os.Exit(1)
	}

	// 0.5. Pre-flight: every {{MODEL:key}} referenced by any template must
	// exist in the validated profile BEFORE the first os.WriteFile. Hard
	// abort, not a warning — see preflightModelKeys.
	if err := preflightModelKeys(); err != nil {
		fmt.Printf("❌ Model key pre-flight failed: %v\n", err)
		os.Exit(1)
	}

	// 1. Process Agents
	if err := processAgents(); err != nil {
		fmt.Printf("❌ Error processing agents: %v\n", err)
		os.Exit(1)
	}

	// 2. Process Config
	if err := processConfig(); err != nil {
		fmt.Printf("❌ Error processing config: %v\n", err)
		os.Exit(1)
	}

	fmt.Println("✅ Build completed successfully!")
}

// loadModelProfile reads model_profiles.json and resolves the active profile.
// Priority order:
//  1. MODEL_PROFILE env var (explicit override, highest priority)
//  2. current_profile file (persistent default for repeated builds)
//  3. default_profile from model_profiles.json
//  4. Hardcoded fallback "opencodego"
func loadModelProfile() error {
	var profileName string

	// Priority 2 (read first to know whether env overrides it): current_profile file
	currentProfilePath := "current_profile"
	var fileProfile string
	if data, err := os.ReadFile(currentProfilePath); err == nil {
		fileProfile = strings.TrimSpace(string(data))
	}

	// Priority 1: MODEL_PROFILE env var (explicit override)
	if env := strings.TrimSpace(os.Getenv("MODEL_PROFILE")); env != "" {
		profileName = env
		if fileProfile != "" && fileProfile != env {
			fmt.Printf("🔧 Using profile from MODEL_PROFILE env: '%s' (overrides current_profile)\n", profileName)
		} else {
			fmt.Printf("🔧 Using profile from MODEL_PROFILE env: '%s'\n", profileName)
		}
	} else if fileProfile != "" {
		// Priority 2: fall back to current_profile file
		profileName = fileProfile
		fmt.Printf("📌 Using profile from current_profile file: '%s'\n", profileName)
	}

	profilesPath := filepath.Join(TemplatesDir, "model_profiles.json")
	data, err := os.ReadFile(profilesPath)
	if err != nil {
		return fmt.Errorf("could not read model_profiles.json: %w", err)
	}

	var profiles map[string]interface{}
	if err := json.Unmarshal(data, &profiles); err != nil {
		return fmt.Errorf("could not parse model_profiles.json: %w", err)
	}

	// Priority 3: default_profile from JSON
	if profileName == "" {
		if def, ok := profiles["default_profile"].(string); ok {
			profileName = def
			fmt.Printf("📋 Using default_profile from JSON: '%s'\n", profileName)
		} else {
			// Priority 4: hardcoded fallback
			profileName = "opencodego"
			fmt.Printf("⚠️ No profile specified, falling back to hardcoded: '%s'\n", profileName)
		}
	}

	// Strip the default_profile key so it doesn't interfere with profile lookup
	delete(profiles, "default_profile")

	profile, exists := profiles[profileName]
	if !exists {
		available := make([]string, 0, len(profiles))
		for k := range profiles {
			available = append(available, k)
		}
		sort.Strings(available)
		return fmt.Errorf("profile '%s' not found. Available: %s", profileName, strings.Join(available, ", "))
	}

	// The profile must be a JSON object; anything else (string, array,
	// number) is a hard error, not the old panic on type assertion.
	rawProfile, ok := profile.(map[string]interface{})
	if !ok {
		return fmt.Errorf("profile '%s' must be a JSON object of key/model-id pairs, got %T", profileName, profile)
	}

	// Validate every model id (shape + provider allowlist) and flatten to
	// map[string]string. Any violation aborts the build here — before a
	// single file is written.
	profileMap, err := validateProfile(rawProfile)
	if err != nil {
		return fmt.Errorf("profile '%s': %w", profileName, err)
	}

	ModelProfile = profileMap
	fmt.Printf("📋 Model Profile: '%s' (%d entries, all model ids validated)\n", profileName, len(profileMap))
	return nil
}

// resolveModelPlaceholders replaces {{MODEL:key}} with the value from the
// active profile. A missing key is a hard build error (the old warn-and-
// leave-literal path produced a compiled agent with a broken model and zero
// runtime signal); preflightModelKeys normally catches it before any write,
// this is the belt-and-braces path. Values are returned verbatim — no
// suffix is ever appended or stripped.
func resolveModelPlaceholders(content string) (string, error) {
	var missing string
	out := reModelPlaceholder.ReplaceAllStringFunc(content, func(match string) string {
		key := strings.TrimSuffix(strings.TrimPrefix(match, "{{MODEL:"), "}}")
		val, exists := ModelProfile[key]
		if !exists {
			if missing == "" {
				missing = key
			}
			return match
		}
		return val
	})
	if missing != "" {
		return "", fmt.Errorf("unknown model key %q in active profile — a literal {{MODEL:%s}} left in a compiled agent is a broken model at runtime", missing, missing)
	}
	return out, nil
}

// reInclude matches the {file:path} include directive.
var reInclude = regexp.MustCompile(`\{file:([^}]+)\}`)

// resolveIncludes expands {file:path} directives. Unreadable includes are
// left as-is with a warning (historical behavior, preserved).
func resolveIncludes(content string) string {
	return reInclude.ReplaceAllStringFunc(content, func(match string) string {
		refPath := strings.TrimSuffix(strings.TrimPrefix(match, "{file:"), "}")
		var absPath string
		if filepath.IsAbs(refPath) {
			absPath = refPath
		} else {
			if strings.Contains(refPath, "prompts/") {
				_, fname := filepath.Split(refPath)
				absPath = filepath.Join(PromptsDir, fname)
			} else {
				absPath = refPath
			}
		}
		refContent, err := os.ReadFile(absPath)
		if err != nil {
			fmt.Printf("   ⚠️  Warning: Could not read included file '%s': %v\n", refPath, err)
			return match
		}
		return string(refContent)
	})
}

func processAgents() error {
	agentTemplatesDir := filepath.Join(TemplatesDir, "agent")
	outputAgentDir := filepath.Join(OutputDir, "agent")

	if err := os.MkdirAll(outputAgentDir, 0755); err != nil {
		return err
	}

	files, err := os.ReadDir(agentTemplatesDir)
	if err != nil {
		return err
	}

	for _, file := range files {
		if file.IsDir() {
			continue
		}
		fmt.Printf("🔨 Building Agent: %s\n", file.Name())

		content, err := os.ReadFile(filepath.Join(agentTemplatesDir, file.Name()))
		if err != nil {
			return err
		}

		newContent := resolveIncludes(string(content))

		// Resolve {{MODEL:xxx}} placeholders
		newContent, err = resolveModelPlaceholders(newContent)
		if err != nil {
			return fmt.Errorf("agent template %s: %w", file.Name(), err)
		}

		if err := os.WriteFile(filepath.Join(outputAgentDir, file.Name()), []byte(newContent), 0644); err != nil {
			return err
		}
	}
	return nil
}

func processConfig() error {
	configTemplate := filepath.Join(TemplatesDir, "config", "config.json")
	outputConfig := filepath.Join(OutputDir, "opencode.json")

	fmt.Printf("🔧 Building Config from Template\n")

	content, err := os.ReadFile(configTemplate)
	if err != nil {
		return err
	}
	contentStr := string(content)

	// ---------------------------------------------------------
	// 1. GENERIC VARIABLE REPLACEMENT (Regex)
	// ---------------------------------------------------------
	// Finds patterns like ${MY_VAR} or $MY_VAR
	// We handle ${VAR} specifically to be safe
	reVars := regexp.MustCompile(`\$\{([A-Z0-9_]+)\}`)

	// Track what we found for logging
	foundVars := make(map[string]bool)

	contentStr = reVars.ReplaceAllStringFunc(contentStr, func(match string) string {
		varName := strings.TrimSuffix(strings.TrimPrefix(match, "${"), "}")
		val := os.Getenv(varName)
		foundVars[varName] = true

		if val == "" {
			// If empty, we replace with empty string, but logic below handles removal
			return ""
		}
		return val
	})

	// Resolve {{MODEL:xxx}} placeholders (model, small_model, agents.title,
	// agents.explore). Same guard as the agent path: profile values are
	// shape-validated up front, a missing key aborts here. Ids stay literal
	// in model_profiles.json — never route them through the ${VAR} env pass
	// above ('#' truncation hazard, see the guard block).
	contentStr, err = resolveModelPlaceholders(contentStr)
	if err != nil {
		return fmt.Errorf("config template: %w", err)
	}

	// ---------------------------------------------------------
	// 2. INTELLIGENT MCP & FEATURE TOGGLING
	// ---------------------------------------------------------
	var configMap map[string]interface{}
	if err := json.Unmarshal([]byte(contentStr), &configMap); err != nil {
		return fmt.Errorf("failed to parse config JSON after substitution: %v", err)
	}

	// Helper function to process any map that might contain "_requires_env"
	processMap := func(data map[string]interface{}) {
		for key, val := range data {
			// Check if value is a map (like an MCP definition)
			if itemMap, ok := val.(map[string]interface{}); ok {
				// Check for magic field "_requires_env"
				if reqs, hasReqs := itemMap["_requires_env"]; hasReqs {
					// It should be a list of strings
					shouldKeep := true
					if reqList, validList := reqs.([]interface{}); validList {
						for _, reqVar := range reqList {
							if envName, isString := reqVar.(string); isString {
								if os.Getenv(envName) == "" {
									fmt.Printf("   🚫 Missing env '%s': Removing entry '%s'\n", envName, key)
									shouldKeep = false
									break
								}
							}
						}
					}

					// Clean up the magic field regardless (it's not valid for Opencode schema)
					delete(itemMap, "_requires_env")

					if !shouldKeep {
						delete(data, key)
					} else {
						fmt.Printf("   ✅ Requirements met for '%s'\n", key)
					}
				}
			}
		}
	}

	// Process MCP servers — V2 nests definitions under mcp.servers
	// (mcp.timeout and non-mcp blocks are intentionally NOT pruned; the `oc`
	// wrapper's ${VAR} preflight guards those)
	if mcp, ok := configMap["mcp"].(map[string]interface{}); ok {
		if servers, ok := mcp["servers"].(map[string]interface{}); ok {
			processMap(servers)
		} else {
			fmt.Println("   ⚠️  'mcp' has no 'servers' map (V1 flat shape?) — _requires_env pruning skipped")
		}
	}

	// 3. Write Output
	finalJSON, err := json.MarshalIndent(configMap, "", "    ")
	if err != nil {
		return err
	}

	// Generated config embeds secrets — owner-only. os.WriteFile's perm arg is
	// ignored when the file already exists, so force the mode with Chmod too.
	if err := os.WriteFile(outputConfig, finalJSON, 0600); err != nil {
		return err
	}
	return os.Chmod(outputConfig, 0600)
}
