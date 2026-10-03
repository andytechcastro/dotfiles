# OpenCode Builder

Generic builder for OpenCode agents and configuration. Compiles agent templates with file includes and model profile resolution.

## Model Profile System

The builder supports multiple model profiles with a priority-based resolution system.

### Priority Order

1. **`MODEL_PROFILE` environment variable** (temporary override for testing)
2. **`current_profile` file** (persistent default for repeated builds)
3. **`default_profile` in model_profiles.json** (fallback)
4. **Hardcoded fallback**: `opencodego`

### Available Profiles

| Profile | Commander | Workers | small_model | Use Case |
|---------|-----------|---------|-------------|----------|
| `opencodego` | opencode-go/qwen3.8-flash | opencode-go/qwen3.8-flash | opencode-go/qwen3.8-flash | Default — Go gateway; personal agents (`finanzas`/`organiza`/`habitos`/`life`/`coach`) on `antigravity/gemini-3.8-flash-high` via CLIProxyAPI |
| `gemini` | ⚠️ DEAD (stale V1 `google/*` IDs) | | | Do not select — legacy since antigravity-auth archive 2026-08-27 |

### Switching Profiles

#### Method 1: Persistent (Recommended)

```bash
# Set your preferred profile
echo "gemini" > current_profile

# Rebuild
go run main.go
```

#### Method 2: Temporary Override

```bash
# One-time override (doesn't change current_profile)
MODEL_PROFILE=gemini go run main.go

# Back to persistent choice
go run main.go
```

#### Method 3: Change Default

Edit `templates/model_profiles.json` and change `default_profile` (not recommended — use `current_profile` instead).

### Using the `oc` Wrapper

The `oc` script at `.config/opencode/bin/oc` provides a convenient CLI:

```bash
oc                              # Launch opencode (skips rebuild if config is fresh)
oc --profile gemini             # Rebuild with gemini profile, then launch
oc --set-current gemini         # Make gemini the persistent default
oc --rebuild                    # Force rebuild with last-used profile
oc --list-profiles              # See all profiles with model details
```

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
# Set up your environment
export ATLASSIAN_DOMAIN='...'
export ATLASSIAN_EMAIL='...'
export ATLASSIAN_API_TOKEN='...'
export MXBAI_API_KEY='...'

# Choose your profile (one-time setup)
echo "opencodego" > current_profile

# Build
go run main.go

# Or use the oc wrapper
oc --profile gemini
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
    "model": "provider/model-name",
    "small_model": "provider/model-name"
  }
}
```

Then: `echo "my_custom_profile" > current_profile && go run main.go`
