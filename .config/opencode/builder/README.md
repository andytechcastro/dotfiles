# OpenCode Builder

Generic builder for OpenCode agents and configuration. Compiles agent templates with file includes and model profile resolution.

## Model Profile System

The builder supports profile-based model resolution. Today exactly one profile is defined — `opencodego` — the mechanism accepts more.

### Priority Order

1. **`MODEL_PROFILE` environment variable** (temporary override for testing)
2. **`current_profile` file** (persistent default for repeated builds)
3. **`default_profile` in model_profiles.json** (fallback)
4. **Hardcoded fallback**: `opencodego`

### Available Profiles

| Profile | Commander | Workers | Personal agents | small_model | Use Case |
|---------|-----------|---------|-----------------|-------------|----------|
| `opencodego` | opencode-go/qwen3.8-flash | opencode-go/qwen3.8-flash | **opencode-go/gemini-4-argon#medium ×3** · **opencode-go/gpt-6-luna ×3** (`#medium`/`#none`/`#low`) · **opencode-go/mimo-v2.6-flash** (bare) | opencode-go/qwen3.8-flash | **Sole profile — ALL 15 agents on the gateway since 2026-11-17** (ADR 0008): Go gateway for every technical agent (`commander`, `PE`, the six architects) plus `model`/`small_model`, and `provider/model#variant` personal entries — gateway flagship `gemini-4-argon#medium` for the 3 sensitive ones (`finanzas`/`life`/`coach`), `gpt-6-luna` variants for `chef`/`barista`/`habitos`, bare `mimo-v2.6-flash` for `organiza` (that model exposes no effort variants — any suffix → `provider.no-route`) |

> **2026-11-15:** the `google` and `gemini` profiles were deleted (`opencode-antigravity-auth`
> retired after the Google account ToS suspension). Selecting a removed profile aborts in `oc`:
> `Profile '<name>' not found. Available: opencodego`. `default_profile` is `opencodego`.
>
> **2026-11-17 (ADR 0008 — CURRENT):** the 7 personal keys moved back onto the gateway via the V2
> `provider/model#variant` syntax (sole data change: `model_profiles.json` lines 12-18; templates
> untouched; no daemon restart needed — the config watcher reloaded `agent/*.md` live, verified).
> Motivation: the one-invoice rule (subscription already paid; Tony refuses subscription +
> pay-per-use simultaneously) — measured personal workload ≈ $0.75/month equivalent, economically
> irrelevant. `GEMINI_API_KEY` stays configured as the rollback path. Budget control: per-model
> gateway ceilings + a burn detector — request/token counts locally (`session_message`, tolerating
> the `session_id`/`sessionID` schema skew) and the **$/month** figure in the console / request-log
> export, because the local `cost` field reads 0 on both nodes.
>
> **Historical — 2026-11-15 (same day, mixed roster + tier rebalance), superseded 2026-11-17:** the
> 7 personal keys inside `opencodego` were repointed from `opencode-go/qwen3.8-flash` to the native
> `google` provider, then split across two tiers on measured cost: **3 → `google/gemini-4-hydrogen`**
> (`finanzas`, `life`, `coach`) and **4 → `google/gemini-3.8-flash`** (`barista`, `chef`, `organiza`,
> `habitos`) — flash measured 2–3× cheaper on the same prompt ($0.0115185 vs $0.0216–$0.0393). The two
> models did keep **separate per-model quota pools**, but that was architecture, not the operating
> constraint: the key was topped up with **€5 prepaid and promoted to Gemini API tier 2** (100K RPD
> per model, ~2K RPM, ~3M TPM), so for that workload the binding limit was the **prepaid balance**,
> not the quota (HTTP 402 at zero balance). That was **not** the deleted `google` profile — that one
> used Antigravity OAuth; this used opencode's **native** `google` provider with a plain
> `GEMINI_API_KEY` (AI Studio, `generativelanguage.googleapis.com/v1beta`). The change was **7 values
> in `model_profiles.json` + a rebuild**. Full narrative: `AGENTS.md` → **Model Providers** and
> `docs/adr/0008-personal-agents-runtime-relocation-to-opencode-go.md`.
>
> **Build after profile edits:** run the builder directly
> (`MODEL_PROFILE=opencodego go run main.go`). `oc --rebuild` / `oc --sync` restart the local daemon
> and kill any live session; for homesrv use `oc --sync --agents-only --no-rebuild`. **Version
> contract — measured and satisfied 2026-11-17:** PE verified that opencode 2.2.5 (homesrv Pi) and
> 2.3.0 (laptop) resolve `model: opencode-go/gemini-4-argon#medium` identically (`Variant
> unavailable`, `provider.no-route`, `activeVariant` present in both), so the ADR 0008 artifacts are
> **SAFE_TO_SYNC — and they ARE synced** (Pi `~/.config/opencode/agent/` mtime 19:52, 15 files, zero
> `google/` refs; backup `~/backups/oc-sync/overwrites-agent-20261117-195248/`; remote
> `opencode run --agent finanzas` rc=0 with `session_message.data.model` =
> `gemini-4-argon` / `opencode-go` / `variant=medium`). Keep the rule for FUTURE suffixes: verify
> parity on both binaries before assuming a node can parse a new variant. Note the Pi's residual
> weakness is observability, not resolution: on 2.2.5 an agent with `model: null` frontmatter
> disappears from the listing with **no log line at all** (`agent file skipped` does not exist in
> that binary).

The generated `opencode.json` (`templates/config/config.json`) reflects the current platform state:

- `plugins`: `opencode-snippets@3.4.0`, `@tarquinen/opencode-dcp@3.2.0`, `@plannotator/opencode@latest` (float, options `workflow:"plan-agent"`, `planningAgents:["commander"]` — sanctioned exception to the pin policy, see `AGENTS.md` → Adding a New Plugin)
  (local plugins in `.config/opencode/plugins/` are auto-discovered and never listed here).
- `experimental.policies`: catch-all `provider.use * deny`, then `allow opencode-go` and
  `allow google`. The `google` allow was load-bearing 2026-11-15 → 2026-11-16 (the 7 personal
  agents then resolved to `google/gemini-4-hydrogen` ×3 / `google/gemini-3.8-flash` ×4). **Since
  2026-11-17 (ADR 0008) nothing running consumes it** — retained as the documented rollback path.
  Do not "clean it up". Still **no** Antigravity OAuth.
- `providers`: `{}` — the CLIProxyAPI sidecar it superseded was torn down 2026-10-30. The native
  `google` provider (rollback path; no agent uses it since 2026-11-17) is **built into the opencode
  binary** and keyed by the `GEMINI_API_KEY` environment variable, so it needs **no entry here and
  no `${VAR}` placeholder**. Consequence: neither `_requires_env` pruning nor the `oc` preflight
  `${VAR}` scan can detect a missing `GEMINI_API_KEY` — and since ADR 0008 a missing key is not
  even a runtime failure: the `oc` check is an advisory. Keep the key in `~/.secret_envs` (and in
  the homesrv systemd environment) so the rollback stays one file edit.

### Switching Profiles

#### Method 1: Persistent (Recommended)

```bash
# Set your preferred profile
echo "opencodego" > current_profile

# Rebuild
go run main.go
```

#### Method 2: Temporary Override

```bash
# One-time override (doesn't change current_profile)
MODEL_PROFILE=opencodego go run main.go

# Back to persistent choice
go run main.go
```

#### Method 3: Change Default

Edit `templates/model_profiles.json` and change `default_profile` (not recommended — use `current_profile` instead).

### Using the `oc` Wrapper

The `oc` script at `.config/opencode/bin/oc` provides a convenient CLI:

```bash
oc                              # Launch opencode (skips rebuild if config is fresh)
oc --profile opencodego         # Rebuild with that profile, then launch opencode
oc --set-current opencodego     # Make it the persistent current_profile
oc --rebuild                    # Force rebuild with last-used profile
oc --sync                       # Rebuild & sync agents + notes to homesrv (restarts daemon)
oc --sync --dry-run             # Preview sync without touching server
oc --sync --agents-only         # Sync only agent definitions (~/.config/opencode/agent/)
oc --sync --notes-only          # Sync only personal context (~/notas/)
oc --sync --no-rebuild          # Sync WITHOUT rebuilding (skips the local service restart)
oc --list-profiles              # See all profiles with model details
```

> ⚠️ **`oc --sync` calls `do_rebuild`, which restarts the LOCAL background service** and kills any
> live session attached to it. To sync from inside a running session, pass `--no-rebuild`.

See `oc --help` for full usage.

## Build Process

1. **Load Model Profile**: Resolves active profile and model assignments
2. **Process Agents**: Compiles agent templates from `templates/agent/*.md`
   - Resolves `{file:prompts/...}` includes
   - Replaces `{{MODEL:xxx}}` placeholders with profile values
   - Outputs to `../agent/*.md`
3. **Process Config**: Compiles `templates/config/config.json`
   - Substitutes `${ENV_VAR}` placeholders
   - Resolves `{{MODEL:xxx}}` placeholders
   - Removes MCP entries with missing required env vars
   - Outputs to `../opencode.json`

## Example Workflow

```bash
# Set up your environment. Template ${VAR} placeholders (caught by the oc preflight) are only
# google_drive's OAuth pair; GEMINI_API_KEY has NO placeholder (native provider reads the process
# env at runtime). Since ADR 0008 (2026-11-17) it is OPTIONAL — no agent consumes it; it is kept
# only as the rollback path to the native google provider. The oc preflight prints an advisory
# when unset and never aborts:
source ~/.secret_envs          # exports GOOGLE_CLIENT_ID / GOOGLE_CLIENT_SECRET / GEMINI_API_KEY

# Choose your profile (one-time setup — opencodego is the only one that exists; since 2026-11-17
# ALL agents are on opencode-go: technical agents + model/small_model on qwen3.8-flash, the 7
# personal ones via provider/model#variant — gemini-4-argon#medium ×3, gpt-6-luna#* ×3,
# mimo-v2.6-flash bare ×1)
echo "opencodego" > current_profile

# Build
go run main.go

# Or use the oc wrapper
oc --profile opencodego
```

## Adding a New Profile

Edit `templates/model_profiles.json`:

```json
{
  "default_profile": "opencodego",
  "my_custom_profile": {
    "commander": "provider/model-name",
    "pe": "provider/model-name",
    "go_architect": "provider/model-name",
    "python_architect": "provider/model-name",
    "frontend_architect": "provider/model-name",
    "qa_architect": "provider/model-name",
    "security_architect": "provider/model-name",
    "doc_architect": "provider/model-name",
    "finanzas": "provider/model-name",
    "organiza": "provider/model-name",
    "habitos": "provider/model-name",
    "life": "provider/model-name",
    "coach": "provider/model-name",
    "barista": "provider/model-name",
    "chef": "provider/model-name",
    "model": "provider/model-name",
    "small_model": "provider/model-name"
  }
}
```

**All 17 keys are mandatory** — one per template placeholder. A key left out prints
`⚠️ Warning: Unknown model key '<x>' in profile — leaving as-is` and bakes the **literal**
`{{MODEL:x}}` into `../agent/<x>.md`, which fails at runtime with no build error. The 7 personal keys
are placeholdered in `templates/agent/*.md` exactly like the technical ones, so a profile that "only"
covers the 8 technical agents is broken.

Then: `echo "my_custom_profile" > current_profile && go run main.go`
