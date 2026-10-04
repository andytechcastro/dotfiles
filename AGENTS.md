# OpenCode Agent Engineering Guide

> **WARNING:** DO NOT EDIT FILES IN `.config/opencode/agent/` DIRECTLY.
> They are generated artifacts. Your changes will be overwritten.
> Edit templates in `.config/opencode/builder/templates/` instead.

## 🏗 Architecture

This repository uses a **GitOps-style Builder Pattern** to generate AI Agent configurations. It also contains platform tools and dotfiles.

```text
.config/opencode/
├── bin/                      # CLI Tools
│   └── oc                    # OpenCode builder + launcher wrapper (symlinked to ~/.local/bin/oc)
├── builder/                  # The Build System (Go)
│   ├── main.go               # The Compiler — compiles templates → agents + config
│   ├── current_profile       # Persistent profile choice (user-managed)
│   ├── README.md             # Builder documentation
│   └── templates/            # SOURCE OF TRUTH
│       ├── agent/            # Agent templates (YAML frontmatter + {file:} includes)
│       │   ├── commander.md
│       │   ├── PE.md
│       │   ├── go_architect.md
│       │   ├── python_architect.md
│       │   ├── frontend_architect.md
│       │   ├── qa_architect.md
│       │   └── security_architect.md
│       ├── config/
│       │   └── config.json   # Config template (${VAR} substitution + _requires_env)
│       └── model_profiles.json # Model profiles (opencodego, gemini, etc.)
├── prompts/                 # Reusable Behavior Libraries (included via {file:})
│   ├── behavior.md           # Shared behavioral rules (never be a yes-man, wait for user)
│   ├── commander_behavior.md # Commander-specific orchestration protocol
│   ├── commander_identity.md # Commander persona
│   ├── pe_behavior.md        # PE operating protocol
│   ├── pe_identity.md        # PE persona
│   ├── specialist_identity.md # Shared identity for all sub-agents
│   ├── frontend_behavior.md  # Frontend architect protocol
│   ├── go_architect_behavior.md # Go architect specific behavior
│   ├── python_architect_behavior.md # Python architect specific behavior
│   ├── qa_behavior.md        # QA SDET protocol
│   ├── security_behavior.md # Security architect protocol
│   ├── caveman_behavior.md   # Token-saving protocol for sub-agents
│   ├── engram_memory.md      # Engram Ask-First memory protocol
│   ├── glossary.md           # Architecture glossary (Clean Arch, Hexagonal, etc.)
│   ├── _installed_capabilities.md # List of installed plugins/MCPs/skills
│   ├── _subagent_permissions.md   # Centralized subagent permission rules
│   ├── language.md           # Language detection (Spanish ↔ English)
│   ├── language_subagent.md  # Language rules for sub-agents
│   ├── lean_technical_behavior.md # Concise communication rules
│   ├── subagent_behavior.md  # Sub-agent integrity rules
│   └── tools_rules.md        # Preferred CLI tools (bat, rg, fd, etc.)
├── agent/                    # ⚠️ GENERATED OUTPUT (Do not edit — run builder)
├── tool/                     # Platform Tools (TS/Bun & Go)
│   ├── hex_check.go         # Hexagonal architecture validator (Go)
│   ├── hexagonal-validator.ts # OpenCode tool wrapper for hex_check.go
│   ├── k8s-pod-doctor.ts    # Kubernetes pod diagnostic tool
│   ├── mgrep.ts              # Semantic search tool (MxBai API)
│   ├── tofu-scan.ts          # Trivy-based IaC security scanner
│   └── graphify.sh           # Graphify wrapper (ensures PATH)
├── skill/                   # OpenCode Skills (loaded on-demand)
│   ├── hexagonal-architect/  # Go hexagonal architecture enforcement
│   ├── infra-security-check/ # Trivy security scanning skill
│   └── production-log-analyzer/ # Datadog log analysis skill
├── command/                  # Custom slash commands
│   ├── infra-scan.md         # Security & infra scan (uses PE agent)
│   └── k8s-doctor.md         # K8s pod diagnostics (uses PE agent)
├── plugins/                  # Local V2 plugins — AUTO-DISCOVERED, never listed in config array
│   ├── engram.ts              # Engram session tracking + compaction hooks
│   ├── squeez.js              # Output compression (95% token reduction)
│   ├── graphify.js            # Knowledge graph reminders (shell tool hook)
│   ├── run-watch.ts           # Tool `run_watch` — bg script + session wake (detached survives restarts)
│   ├── yt-transcript.ts       # Tool `yt_transcript` — YouTube transcripts via yt-dlp (no paid API)
│   └── echo.ts.v1-retired     # Retired V1 clone (non-.ts extension = ignored by auto-discovery)
├── squeez/                   # Squeez configuration
│   └── config.ini             # Compression settings (persona: ultra)
├── opencode.json             # ⚠️ GENERATED (secrets injected — gitignored)
├── cli.json                  # V2 terminal config (theme, terminal plugins — currently plugins: [])
└── tui.json                  # ⚠️ V1 relic — auto-migrated to cli.json; candidate for deletion
```

## 🛠 Build System

### How It Works

1. **Agent Templates** (`.md` files) contain YAML frontmatter + `{file:prompts/...}` include directives.
2. **Model Profiles** (`model_profiles.json`) define which model each agent uses. Templates reference models via `{{MODEL:key}}` placeholders.
3. The **Go Builder** (`main.go`) reads all agent templates, resolves `{file:}` includes and `{{MODEL:xxx}}` placeholders, and writes the compiled output to `agent/`.
4. The **Config Template** (`config.json`) uses `${ENV_VAR}` substitution, `{{MODEL:xxx}}` resolution, and `_requires_env` arrays. If a required env var is missing, the entire MCP entry is removed from the output.

### Building

**Recommended: Use the `oc` wrapper** (symlinked to `~/.local/bin/oc`):

```bash
# Launch opencode (auto-rebuilds if config is stale)
oc

# Rebuild with specific profile, then launch
oc --profile gemini

# Set persistent default profile (no launch)
oc --set-current gemini

# Force rebuild without launching
oc --rebuild

# List available profiles
oc --list-profiles
```

**Manual build** (if you need fine-grained control):

```bash
# 1. Export secrets (only the ones you have)
export BRAVE_API_KEY='...'

# 2. Run the builder (uses current_profile or default: opencodego)
cd .config/opencode/builder && go run main.go

# Or override with env var
MODEL_PROFILE=gemini go run main.go
```

**Profile Resolution Priority:**
1. `MODEL_PROFILE` env var (temporary override)
2. `builder/current_profile` file (persistent choice)
3. `default_profile` in `model_profiles.json`
4. Hardcoded fallback: `opencodego`

The builder will:
- Load the active model profile from `model_profiles.json`
- Compile all agent templates → `agent/*.md`
- Resolve `{{MODEL:xxx}}` placeholders with profile values
- Generate `opencode.json` with env vars substituted
- Remove MCP entries with missing required env vars
- Log ✅/🚫 for each MCP entry's status

### Model Profiles

Models are **not hardcoded** in agent templates. Instead, each profile in `model_profiles.json` defines the full roster:

| Profile | Commander | Workers | Personal agents | small_model |
|---------|-----------|---------|-----------------|-------------|
| `opencodego` | opencode-go/qwen3.8-flash | opencode-go/qwen3.8-flash | antigravity/gemini-3.8-flash-high (`finanzas`, `organiza`, `habitos`, `life`, `coach`) | opencode-go/qwen3.8-flash |
| `gemini` | ⚠️ **DEAD** — stale V1 `google/*` IDs, unusable since antigravity-auth archive (2026-08-27). Do not select. | | | |

To add a new profile, add an entry to `model_profiles.json` with keys matching all `{{MODEL:key}}` placeholders used in templates.

### Adding a New Agent

1. Create `.config/opencode/builder/templates/agent/my_agent.md` with YAML frontmatter.
2. Use `{file:prompts/...}` to include shared behavior libraries.
3. Add `permissions:` list rules (`{action, resource, effect}`, catch-all first).
4. Run `oc --rebuild` to regenerate (or `cd .config/opencode/builder && go run main.go`).

### Adding a New MCP

1. Add the MCP entry to `.config/opencode/builder/templates/config/config.json`.
2. Use `${ENV_VAR}` for secrets and add `"_requires_env": ["ENV_VAR"]` to conditionally include it.
3. Re-export secrets and rebuild.

> **Warning:** `https://opencode.ai/config.json` (the `$schema` URL) serves a **V1 schema** — never infer V2 config shapes from it (editor autocomplete will lie to you). The V2 docs are the source of truth.

### Installed MCPs

| MCP | Purpose |
|-----|---------|
| `context7` | Current library docs (Next.js, React, Prisma, etc.) |
| `engram` | Persistent memory (SQLite) |
| `gh_grep` | Real GitHub code examples |
| `gcp` | Google Cloud Platform (OAuth) |
| `google_drive` | Drive files (`_requires_env: GOOGLE_CLIENT_ID/SECRET`) |
| `codebase-memory-mcp` | Knowledge graph of codebase (tree-sitter + SQLite) |
| `playwright` | Browser automation |

> **Note:** `_requires_env` pruning is implemented in `main.go` ONLY for the `mcp` map and the legacy singular `provider` map. The V2 `providers` block (plural) is NOT pruned — but the `oc` wrapper preflight builds its required-vars set as the **union of every `_requires_env` entry AND a generic `${VAR}` placeholder scan** of the template (uppercase `UPPER_SNAKE` names), and **aborts the build** if any env is missing (`Aborted. Set the missing env vars and retry.`), so a key can never be silently baked empty.

### Adding a New Plugin (V2 contract)

**Local plugin (preferred for personal tooling):**
1. Drop the file in `.config/opencode/plugins/` (`.ts` or `.js`). Contract:
   `export default Plugin.define({ id, async setup(ctx) { ... } })` from `@opencode/plugin` (^2.x).
2. It is **auto-discovered** — NEVER add it to the config `plugins` array (that array accepts npm packages/dirs only; file entries emit a `configured plugin path must be a directory` WARN).
3. Deploy: `opencode service restart`. A rebuild or hot reload does NOT re-register hooks/tools on live sessions.
4. Static-verify first: `tsc --noEmit` against installed `@opencode/plugin` typings (missing ambient `process`/`Bun` type errors are benign — injected by opencode's embedded runtime).

**Registry plugin (npm package):**
1. Add to the `plugins` array in `builder/templates/config/config.json` — plain `"pkg@X.Y.Z"` string (**pin exact versions — never `@latest`**; supply-chain integrity: `@latest` re-resolves silently on every fresh install, and `update: "notify"` means we choose when to bump), or `{ "package": "...", "options": {...} }` when it needs options (V1 tuple form is invalid). Resolve the pinned version from opencode's on-disk npm cache (`~/.cache/opencode/npm/<pkg>@latest/*/package.json`) or `npm view <pkg> version`. Same rule applies to `npx -y` MCP servers in `mcp.servers` (e.g. `@playwright/mcp@X.Y.Z`, resolved from the `~/.npm/_npx` cache).
2. `oc --rebuild` then `opencode service restart`.

**Terminal/TUI plugin:** add to the `plugins` array in `cli.json` (currently empty — V1 TUI contracts are rejected by the V2 loader).

### Installed Plugins

**Live — registry packages (`plugins` array):**

| Plugin | Purpose |
|--------|---------|
| `opencode-snippets` | Snippet expansion with `#hashtag` syntax |
| `@tarquinen/opencode-dcp` | Dynamic context pruning |
| `@plannotator/opencode` | Browser UI for plan/code review — `options: { workflow: "plan-agent", planningAgents: ["commander"] }` |

**Live — local auto-discovered (`.config/opencode/plugins/`):** `engram.ts`, `squeez.js`, `graphify.js`, `run-watch.ts` (tool `run_watch`), `yt-transcript.ts` (tool `yt_transcript`).

**Replaced by native V2 (removed 2026-09-26):**

| V1 plugin | Native replacement |
|-----------|--------------------|
| `opencode-autotitle` | `agent.title.model` = `{{MODEL:small_model}}` in config template |
| `opencode-notify` | `cli.json` `attention.notifications` / `attention.sounds` |
| `@ykaratkou/opencode-worktree` | V2 native `ctx.worktree` + `worktree.directory` |
| `envsitter-guard` | `permissions` deny rules on `*.env` / `*.env.*` (read+edit, 4 rules live in template) |
| `opencode-antigravity-auth` | Upstream ARCHIVED 2026-08-27 → Google models now via CLIProxyAPI provider (see below) |

**Dropped — waiting on upstream V2 ports:** `opencode-vibeguard`, `@nick-vi/opencode-type-inject`, `opencode-claude-auth`, `opencode-sdd-engram-manage` (upstream issue #52), `opencode-subagent-statusline` (issue #97).

## 🔌 Model Providers — Antigravity via CLIProxyAPI

Native V2 has NO consumer Google OAuth (Google killed it 2026-06-18; native `google` = paid API-key, `vertex` = ADC). Google models are served through **CLIProxyAPI** (`router-for-me/CLIProxyAPI`, v8.0.13, MIT):

- **Binary:** `~/.local/bin/cli-proxy-api` — official GitHub release tarball, sha256-verified (AUR route needs interactive sudo).
- **Proxy:** binds `127.0.0.1:8317` ONLY. Client auth = self-generated 64-hex LOCAL token in `access.api-keys` — free, not a paid key.
- **Upstream auth:** Antigravity Google OAuth → uses the user's Google AI Pro subscription quotas. Tokens live in `~/.cli-proxy-api/` — NEVER in git.
- **Service:** systemd USER unit `.config/systemd/user/cliproxyapi.service` (versioned in repo, symlinked to `~/.config/systemd/user/`). Manage with `systemctl --user {status,restart} cliproxyapi`.
- **GOTCHA:** manual one-shot commands MUST pass `--config ~/.config/cli-proxy-api/config.yaml` — the default is `./config.yaml` relative to CWD (`failed to read config file` error otherwise). Login: `cli-proxy-api --antigravity-login --config ~/.config/cli-proxy-api/config.yaml`.
- **OpenCode side:** `providers.antigravity` in the config template — `package: "@opencode/ai/providers/openai-compatible"`, `settings.baseURL: http://127.0.0.1:8317/v1`, `settings.apiKey: ${CLIPROXY_API_KEY}` **baked at build** (runtime is env-free). `models` = the 14 real IDs served by `GET /v1/models` — NEVER guess them; re-probe the proxy to refresh the catalog.
- **Secrets:** `CLIPROXY_API_KEY` (+ everything else) lives in `~/.secret_envs` (chmod 600, sourced by `~/.zshrc`).

## 🤖 Agent Roster & Permissions

### Agent Roles

| Agent | Model (opencodego) | Model (gemini) | Role | Mode |
|-------|-------------------|----------------|------|------|
| `commander` | opencode-go/qwen3.8-flash | ⚠️ dead | Orchestrator. Plans, delegates, verifies. No code. | primary |
| `PE` | opencode-go/qwen3.8-flash | ⚠️ dead | Platform Engineer. Infra, CI/CD, platform glue. | subagent |
| `go_architect` | opencode-go/qwen3.8-flash | ⚠️ dead | Go specialist. Clean Architecture, SOLID. | subagent |
| `python_architect` | opencode-go/qwen3.8-flash | ⚠️ dead | Python specialist. Type-safe, modern Python. | subagent |
| `frontend_architect` | opencode-go/qwen3.8-flash | ⚠️ dead | UX/UI + Frontend. Next.js 15, React 19. | subagent |
| `qa_architect` | opencode-go/qwen3.8-flash | ⚠️ dead | QA SDET. Regression, resilience, performance. | subagent |
| `security_architect` | opencode-go/qwen3.8-flash | ⚠️ dead | Security auditor. IaC, secrets, least-privilege. | subagent |

> Personal agents (`finanzas`, `organiza`, `habitos`, `life`, `coach`) run on `antigravity/gemini-3.8-flash-high` — Google AI Pro quotas via CLIProxyAPI (see **Model Providers**). The built-in `title` agent uses `small_model`. The `gemini` profile column is legacy — that profile is dead.

### Permissions Model (V2 Native)

V2 agent frontmatter uses a `permissions:` **ordered LIST** of `{action, resource, effect}` entries — NOT the legacy singular `permission:` map. The legacy top-level fields (`permission`, `tools`, `temperature`, `top_p`, `prompt`, `disable`, `maxSteps`) are **IGNORED at runtime** (empirically proved 2026-10-04: a PE subagent executed `git stash list` / `git add` / `git commit` despite deny entries in its legacy `permission:` map). Action names in V2: `shell`, `edit` (covers write/patch), `read`, `glob`, `grep`, `webfetch`, `websearch`, `subagent` (resource = child agent ID), `external_directory` — **but see the dual-vocabulary rule below: `shell` alone is NOT enforced at runtime.**

All agents keep a **catch-all-first, denies-last** layout — the semantics are unchanged (**last-match-wins**, `*` = zero-or-more chars), only the format changed. `- {action: shell, resource: "*", effect: allow}` appears FIRST in every list and every explicit deny is written AFTER it, so the later deny overrides the catch-all. This eliminates nuisance permission prompts for command variants (flags, pipes, paths) while keeping the denies effective. The previous "denies first, catch-all last" layout was a defect: the trailing `"*": allow` silently voided every deny (proved in audit — a denied `curl` executed). Shell resources match RAW command text (no `~`/`$HOME` expansion). The scalar `write: ask` / `edit: ask` entries were **deliberately dropped** in the 2026-10-04 migration: they were inert under the legacy map and activating them now would prompt-block subagent file editing (behavior change). The guaranteed enforcement layer for `.env` / `.ssh` / secrets remains config-level `experimental.policies`. Global config `permissions` array applies BEFORE agent rules; agent rules refine on top.

**Dual vocabulary (mandatory, do not "clean up").** The V2 docs name the actions `shell` and `subagent`, but the runtime daemon evaluates shell checks under `bash` and subagent-spawn under `task`. Proven 2026-10-04: a `--attach` private-server probe returned `Supported actions: read, edit, glob, grep, list, bash, task, todowrite, todoread, question`, and `opencode api get /api/agent` showed our `shell` rules loaded yet never matching. Catalog-layer tool filtering *does* honor the documented names, which is why `webfetch: deny` already works without a twin; `read`/`edit` are identical in both worlds. Every template therefore carries an **identical adjacent twin** for each `shell` entry (`action: bash`, same resource/effect) and for each `subagent` entry (`action: task`) — commander 8+8, each work agent 23+23, each personal agent 21+21 plus a `subagent`/`task` pair. The duplication is intentional: add new shell or subagent rules as **pairs**, and delete the twins only when upstream aligns the action names with the docs.

#### Commander (Full Access)
```yaml
permissions:
  - {action: shell, resource: "*", effect: allow}          # catch-all FIRST
  - {action: shell, resource: "rm -rf /", effect: deny}    # denies AFTER
  - {action: shell, resource: "mkfs*", effect: deny}
  - {action: shell, resource: "sudo rm*", effect: deny}
```
Full deny set: `rm -rf /`, `rm -rf *`, `rm -rf /*`, `mkfs*`, `dd *`, `sudo rm*`, `chmod -R 777 /`. The Commander is the orchestrator — it needs unrestricted bash access to coordinate, commit, and deploy.

#### Sub-Agents (Read + Build — No Git Write, No Network)
```yaml
permissions:
  - {action: shell, resource: "*", effect: allow}          # catch-all FIRST
  - {action: shell, resource: "git push*", effect: deny}   # denies AFTER
  - {action: shell, resource: "curl*", effect: deny}
  - {action: webfetch, resource: "*", effect: deny}
```
Full deny set: destructive ops (same 7 as Commander) + `git add/commit/push/pull/merge/rebase/reset/checkout/stash/cherry-pick` + `curl`/`wget`/`nc` + `security`/`sysctl` + `webfetch`. Sub-agents can read files, search, build, test, and edit — but cannot write to git, make network calls, or access macOS security APIs.

### Sub-Agent Communication Protocol (Caveman Mode)

All sub-agents use the **Token Hunter** protocol to save tokens when reporting back to the Commander:

1. **No social cues**: No "Hello", "Sure", "I'd be happy to".
2. **No grammar fluff**: Drop articles, pronouns, auxiliary verbs.
3. **Technical only**: Use technical terms, paths, and results.
4. **Format**: Problem? State it. Fix? Code block. Result? Done.

**Example:** `User model updated. Field added.` instead of `I have updated the user model and added the new field.`

## 🧠 Persistent Memory (Engram)

All agents have access to **Engram** persistent memory via MCP tools + the OpenCode plugin. Memory survives sessions and compactions.

### How It Works

| Component | Role |
|-----------|------|
| **Plugin (`engram.ts`)** | Session tracking, prompt capture, auto-compaction recovery, system prompt injection |
| **MCP Server (`engram mcp --tools=agent`)** | 15 memory tools available to agents (save, search, context, sessions) |
| **SQLite (`~/.engram/engram.db`)** | Local storage — no cloud, no sync unless explicitly configured |

### Ask-First Protocol

Agents **NEVER save automatically**. The protocol is:

1. **Propose:** Agent says `"💡 I noticed something worth remembering: <brief>. Save it?"`
2. **Approve:** User says "yes" → agent calls `mem_save`
3. **Reject:** User says "no" → nothing saved

**Immediate saves:** If the user says "remember this", "save this", "guarda esto" — agent saves immediately without asking.

### Session End Protocol

Before ending a session, agents MUST:
1. Present a numbered list of potential memories with `[type]` tags
2. Ask the user which ones to save
3. Call `mem_save` only for approved items
4. Call `mem_session_summary` with a concise recap

### After Compaction

If context is reset, agents call `mem_session_summary` first, then `mem_context` to recover state. The plugin also injects context automatically during compaction.

### CLI Commands

```bash
engram tui                    # Visual memory browser
engram search "auth bug"      # Search from terminal
engram projects list          # List all projects with memory counts
engram sync                   # Export memories to .engram/ for git sharing
engram sync --import          # Import memories on another machine
```

### TUI Plugins

None active. The two V1 TUI plugins (`opencode-subagent-statusline`, `opencode-sdd-engram-manage`) were removed 2026-09-26 — the V2 loader rejects their contract (upstream issues #97 / #52). Terminal plugins now go in the `plugins` array of `cli.json` (currently empty). Partial native coverage meanwhile: `session.sidebar`, `tabs.indicators: status`, `subagent_done` sound.

## 🔐 Secrets & Security

### What's Gitignored

- `opencode.json` — Contains API tokens (generated from template)
- `agent/` directory — Generated output (rebuilt from templates)
- `*.bak` files — Never commit backups
- `node_modules`, `bun.lock` — NPM artifacts
- `~/.engram/` — Local SQLite memory database (never committed)
- `squeez/sessions/` — Session logs (regenerated per session)
- `.config/opencode/service.json` — V2 background-service registration
- `.config/opencode/AGENTS.md` — squeez-managed session-context block (nested gitignore rule)
- `~/.cli-proxy-api/` — CLIProxyAPI OAuth tokens (outside repo, never commit)
- `~/.secret_envs` — single source of secrets, sourced by `~/.zshrc` (chmod 600, outside repo)

> **Note (2026-09-26):** `.config/opencode/package.json` IS tracked now —
> it carries security `overrides` (toml/uuid Dependabot bumps). Ignoring it
> would let fresh clones silently re-resolve vulnerable versions.

### The `.bak` Lesson

A `opencode.json.tui-migration.bak` file was found containing plaintext API tokens. **Never store secrets in backup files.** The builder handles secret injection via `${ENV_VAR}` substitution — always use the builder, never hand-edit `opencode.json`.

## 📜 Code Style & Tooling Guidelines

### Preferred Tooling (Updated May 2026)
We do not use legacy commands. Use these modern alternatives:

| Legacy | Modern | Purpose | Install | Notes |
|--------|--------|---------|---------|-------|
| `cat` | `bat` | Syntax-highlighted file viewing | `yay -S bat` | Use `bat -p` for plain output |
| `grep` | `rg` (ripgrep) | Fast content search | `yay -S ripgrep` | Use `rg -t ts` to filter by file type |
| `find` | `fd` | Fast file search | `yay -S fd` | Use `fd -e ts` for extensions |
| `sed` | `sd` | In-place find/replace | `yay -S sd` | Supports regex groups: `sd '(\w+)' '$1_suffix'` |
| `ls` | `eza` | Beautiful file listing | `yay -S eza` | Use `eza --tree` for directory trees |
| `grep -A` | `grep-ast` | Context-aware search with scope | `pip install grep-ast` | Shows function/class context around matches |
| `sed` (structural) | `sg` (ast-grep) | AST-based code search/replace | `yay -S ast-grep` | For complex refactoring where regex breaks syntax |
| — | `mgrep` | Semantic search (cost-sensitive) | Custom tool | Use for concepts, NOT exact strings |
| — | `graphify` | Knowledge graph (source of truth) | `yay -S graphify` | Always check before architecture work |
| — | `repomix` | Pack directories for LLM consumption | `npm install -g repomix` | Use `repomix src/ -o context.xml` |
| `pip` | `uv` | Ultra-fast Python package manager | `yay -S uv` | Drop-in replacement, much faster |
| `make` | `just` | Modern command runner | `yay -S just` | Better syntax than Makefiles |
| — | `squeez` | Output compression (95% token reduction) | `~/.local/bin/squeez` | Wraps bash commands automatically |
| — | `codebase-memory-mcp` | Codebase knowledge graph | `pip install --user codebase-memory-mcp` | Tree-sitter + SQLite based |

### General Principles
*   **Platform over Apps:** Build tools that other developers can use.
*   **Reliability & DX:** If a tool is hard to run or fails silently, it's trash.
*   **Hexagonal Architecture:** Dependencies flow inwards. Domain must NOT import infrastructure.

### Go Style
*   **Imports:** Group standard library first, then third-party. Use `goimports`.
*   **Formatting:** Strict `gofmt`.
*   **Error Handling:**
    *   Always check `if err != nil`.
    *   In CLI tools: Print error to stderr and `os.Exit(1)`.
    *   In libraries: Wrap errors with context: `fmt.Errorf("failed to process X: %w", err)`.
*   **Naming:**
    *   Structs/Interfaces: `CamelCase`.
    *   Receivers: Short (e.g., `p` for `Processor`).
    *   Variables: Concise but descriptive.
*   **Modern Go:** Use `os.ReadFile`/`os.WriteFile` (NOT `ioutil` — deprecated since Go 1.16). Use `os.ReadDir` (NOT `ioutil.ReadDir`).

### TypeScript Style
*   **Plugins (V2):** use `@opencode/plugin` — `Plugin.define` contract, JSON Schema tool inputs (no `zod` in the `editor.add` path). Code runs in opencode's embedded runtime; ambient `process`/`Bun` globals are injected at load (tsc errors on them are benign).
*   **Legacy custom tools (`tool/*.ts`):** still on the V1 `@opencode-ai/plugin` SDK (1.4.7, kept for compat — it pulls `toml`/`uuid` via `effect` beta.48; security overrides pinned in the tracked `package.json`).
*   **No `bun` binary on the system** — don't assume `Bun.*` outside plugin runtime code.
*   **Types:** Strict typing with TypeScript.
*   **Formatting:** 2 spaces, no semicolons (unless required).

### Lua (Neovim/Wezterm) Style
*   **Modularity:** Keep `config/set.lua`, `config/remap.lua`, etc., separate.
*   **Lazy Loading:** Use `lazy.nvim` for all plugin configurations.
*   **Convention:** Use `local` variables to avoid polluting the global namespace.

## 🤖 Rules for Agents (Cursor/Copilot/OpenCode)

1.  **Context First:** Before touching code, ALWAYS check if there is an `AGENTS.md` or `graphify-out/` in the current project root.
2.  **Graphify is MANDATORY:** `graphify` (aka `graphifyy`) is a global tool available at `~/.local/bin/graphify`. It is the source of truth for architecture and god nodes.
    - **Bootstrap new projects:** If `graphify-out/` is missing, run `graphify opencode install && graphify update .`.
    - **Handling Dot-Folders:** `graphify` ignores folders starting with `.`. If the code is in `.config/` or similar, use a temporary symlink: `ln -s .config/foo src_foo && graphify update src_foo && rm src_foo`.
    - **NO Platform Skills:** DO NOT run `graphify gemini install`, `graphify cursor install`, etc. We use the **OpenCode integration** (`graphify opencode install`) which uses `.opencode/plugins/graphify.js`.
3.  **Persona:** All agents are "Spaniard Platform Engineers". Use Spain-Spanish (Castellano) slang if the user writes in Spanish.
4.  **Zero Patience for Mediocrity:** If code violates architectural rules (like Hexagonal), fail the build and explain WHY.
5.  **Shebang Convention:** Use `#!/usr/bin/env bash` (portable) instead of `#!/bin/bash` (macOS-specific).

## 🚫 Troubleshooting

| Problem | Solution |
|---------|----------|
| Generated files missing | Run `oc --rebuild` or `cd .config/opencode/builder && go run main.go` |
| Missing Tools | Builder needs `go` only. `bun` is NOT installed — plugins run inside opencode's embedded runtime |
| Architecture Violation | Run `go run .config/opencode/tool/hex_check.go` in the project root |
| MCP server fails to connect | Check that the required env vars are set for that MCP entry |
| Agent can't execute commands | Check the `permissions:` list entries in the agent template — last deny may override the catch-all (V2: legacy `permission:` map and `tools:` are ignored) |
| Custom command uses disabled agent | Check `command/*.md` — ensure `agent:` field points to an enabled agent |
| Builder uses deprecated Go APIs | Use `os.ReadFile`/`os.WriteFile`/`os.ReadDir` instead of `ioutil` |
| Model profile not found | Check `model_profiles.json` — profile name must match exactly. Use `oc --set-current <name>` or `MODEL_PROFILE=<name>` |
| Unknown model key warning | Template uses `{{MODEL:xxx}}` but key is missing from active profile in `model_profiles.json` |
| Engram plugin not working | Ensure `engram` binary is installed (`yay -S engram-bin`) |
| `failed to load plugin` at boot | Plugin not on V2 contract (must `export default Plugin.define`) or stale config entry — single-file plugins must NEVER be listed in the config `plugins` array |
| Plugin/tool changes have no effect | `opencode service restart` — hot reload/rebuild does not re-register hooks on live sessions |
| `Model unavailable: antigravity/*` | Rebuild with `CLIPROXY_API_KEY` sourced (`source ~/.secret_envs`), then `opencode service restart`; check `systemctl --user is-active cliproxyapi` |
| `oc` build aborted: missing env vars | `source ~/.secret_envs` and retry — the `${VAR}` preflight abort is a feature (prevents baking empty keys) |
| `cli-proxy-api: failed to read config file` | Pass `--config ~/.config/cli-proxy-api/config.yaml` in manual one-shot commands (default is `./config.yaml` relative to CWD) |
| `yt_transcript` 429 / throttle | Retry later — YouTube rate-limits aggressive polling |
| Agent saves memories without asking | Verify `engram_memory.md` prompt includes Ask-First rules. Rebuild if needed. |
| `oc` command not found | Symlink missing. Run: `ln -sf $(pwd)/.config/opencode/bin/oc ~/.local/bin/oc` |
| Squeez not compressing output | Ensure `squeez` binary is installed (`~/.local/bin/squeez`). Check `squeez/config.ini` exists. |
| codebase-memory-mcp not indexing | Run `codebase-memory-mcp` manually first. Check binary at `~/.local/bin/codebase-memory-mcp`. |

## graphify

This project has a graphify knowledge graph at graphify-out/.

Rules:
- Before answering architecture or codebase questions, read graphify-out/GRAPH_REPORT.md for god nodes and community structure
- If graphify-out/wiki/index.md exists, navigate it instead of reading raw files
- After modifying code files in this session, run `graphify update .` to keep the graph current (AST-only, no API cost)
- If "No code files found", try specific directories: `graphify update src/` or adapt to project structure
