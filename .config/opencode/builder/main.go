package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
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

func main() {
	cwd, _ := os.Getwd()
	fmt.Printf("🚀 Starting Generic OpenCode Builder in: %s\n", cwd)

	// 0. Load Model Profile
	if err := loadModelProfile(); err != nil {
		fmt.Printf("❌ Error loading model profile: %v\n", err)
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
		return fmt.Errorf("profile '%s' not found. Available: %s", profileName, strings.Join(available, ", "))
	}

	// Type-assert the profile to map[string]string
	profileMap := make(map[string]string)
	for k, v := range profile.(map[string]interface{}) {
		profileMap[k] = v.(string)
	}

	ModelProfile = profileMap
	fmt.Printf("📋 Model Profile: '%s' (%d entries)\n", profileName, len(profileMap))
	return nil
}

// resolveModelPlaceholders replaces {{MODEL:key}} with the value from the active profile
func resolveModelPlaceholders(content string) string {
	reModel := regexp.MustCompile(`\{\{MODEL:([a-zA-Z0-9_]+)\}\}`)
	return reModel.ReplaceAllStringFunc(content, func(match string) string {
		key := strings.TrimSuffix(strings.TrimPrefix(match, "{{MODEL:"), "}}")
		val, exists := ModelProfile[key]
		if !exists {
			fmt.Printf("   ⚠️  Warning: Unknown model key '%s' in profile — leaving as-is\n", key)
			return match
		}
		return val
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

	// Regex for {file:path} include directive
	reInclude := regexp.MustCompile(`\{file:([^}]+)\}`)

	for _, file := range files {
		if file.IsDir() {
			continue
		}
		fmt.Printf("🔨 Building Agent: %s\n", file.Name())

		content, err := os.ReadFile(filepath.Join(agentTemplatesDir, file.Name()))
		if err != nil {
			return err
		}

		newContent := reInclude.ReplaceAllStringFunc(string(content), func(match string) string {
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

		// Resolve {{MODEL:xxx}} placeholders
		newContent = resolveModelPlaceholders(newContent)

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

	// Resolve {{MODEL:xxx}} placeholders (for model and small_model)
	contentStr = resolveModelPlaceholders(contentStr)

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
