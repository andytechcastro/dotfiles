# OpenCode Agent Engineering Guide

> **WARNING:** DO NOT EDIT FILES IN `.config/opencode/agent/` DIRECTLY.
> They are generated artifacts. Your changes will be overwritten.
> Edit templates in `.config/opencode/builder/templates/` instead.

## 🏗 Architecture

This repository uses a **GitOps-style Builder Pattern** to generate AI Agent configurations. It also contains platform tools and dotfiles.

```text
.config/opencode/
├── builder/                  # The Build System (Go)
│   ├── main.go               # The Compiler — compiles templates → agents + config
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
│   ├── qa_behavior.md        # QA SDET protocol
│   ├── security_behavior.md # Security architect protocol
│   ├── caveman_behavior.md   # Token-saving protocol for sub-agents
│   ├── engram_memory.md      # Engram Ask-First memory protocol
│   ├── lean_technical_behavior.md # Concise communication rules
│   ├── language.md           # Language detection (Spanish ↔ English)
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
├── plugins/                  # OpenCode TUI + Runtime Plugins
│   ├── graphify.js            # Knowledge graph reminders
│   └── engram.ts              # Engram session tracking + compaction hooks
├── opencode.json             # ⚠️ GENERATED (secrets injected — gitignored)
└── tui.json                  # TUI theme + plugins config
```

## 🛠 Build System

### How It Works

1. **Agent Templates** (`.md` files) contain YAML frontmatter + `{file:prompts/...}` include directives.
2. **Model Profiles** (`model_profiles.json`) define which model each agent uses. Templates reference models via `{{MODEL:key}}` placeholders.
3. The **Go Builder** (`main.go`) reads all agent templates, resolves `{file:}` includes and `{{MODEL:xxx}}` placeholders, and writes the compiled output to `agent/`.
4. The **Config Template** (`config.json`) uses `${ENV_VAR}` substitution, `{{MODEL:xxx}}` resolution, and `_requires_env` arrays. If a required env var is missing, the entire MCP entry is removed from the output.

### Building

```bash
# 1. Export secrets
export ATLASSIAN_DOMAIN='...'
export ATLASSIAN_EMAIL='...'
export ATLASSIAN_API_TOKEN='...'
export TAVILY_API_KEY='...'
export MXBAI_API_KEY='...'

# 2. Run the builder (default profile: opencodego)
cd .config/opencode/builder && go run main.go

# Or use a specific model profile
MODEL_PROFILE=gemini go run main.go
```

The builder will:
- Load the active model profile from `model_profiles.json`
- Compile all agent templates → `agent/*.md`
- Resolve `{{MODEL:xxx}}` placeholders with profile values
- Generate `opencode.json` with env vars substituted
- Remove MCP entries with missing required env vars
- Log ✅/🚫 for each MCP entry's status

### Model Profiles

Models are **not hardcoded** in agent templates. Instead, each profile in `model_profiles.json` defines the full roster:

```bash
# Default profile (current setup)
go run main.go

# Switch to Gemini
MODEL_PROFILE=gemini go run main.go
```

| Profile | Commander | Workers | small_model |
|---------|-----------|---------|-------------|
| `opencodego` | qwen3.6-plus | deepseek-v4-pro / kimi-k2.6 | deepseek-v4-flash |
| `gemini` | gemini-3.1-pro | gemini-3.1-pro / gemini-3.5-flash | gemini-3.5-flash |

To add a new profile, add an entry to `model_profiles.json` with keys matching all `{{MODEL:key}}` placeholders used in templates.

### Adding a New Agent

1. Create `.config/opencode/builder/templates/agent/my_agent.md` with YAML frontmatter.
2. Use `{file:prompts/...}` to include shared behavior libraries.
3. Add `permission.bash` allow/deny rules.
4. Run `cd .config/opencode/builder && go run main.go` to regenerate.

### Adding a New MCP

1. Add the MCP entry to `.config/opencode/builder/templates/config/config.json`.
2. Use `${ENV_VAR}` for secrets and add `"_requires_env": ["ENV_VAR"]` to conditionally include it.
3. Re-export secrets and rebuild.

### Adding a New Plugin

1. Place the plugin file in `.config/opencode/builder/templates/plugins/` (e.g., `engram.ts`).
2. Add the relative path to the `plugin` array in `config.json` (e.g., `"./plugins/engram.ts"`).
3. For TUI plugins, also install via npm: `npm install <plugin-name>` in `.config/opencode/`.
4. Add the plugin name to `tui.json` `plugin` array.
5. Re-export secrets and rebuild.

## 🤖 Agent Roster & Permissions

### Agent Roles

| Agent | Model (opencodego) | Model (gemini) | Role | Mode |
|-------|-------------------|----------------|------|------|
| `commander` | qwen3.6-plus | gemini-3.1-pro | Orchestrator. Plans, delegates, verifies. No code. | primary |
| `PE` | deepseek-v4-pro | gemini-3.1-pro | Platform Engineer. Infra, CI/CD, platform glue. | subagent |
| `go_architect` | deepseek-v4-pro | gemini-3.1-pro | Go specialist. Clean Architecture, SOLID. | subagent |
| `python_architect` | deepseek-v4-pro | gemini-3.1-pro | Python specialist. Type-safe, modern Python. | subagent |
| `frontend_architect` | qwen3.6-plus | gemini-3.1-pro | UX/UI + Frontend. Next.js 15, React 19. | subagent |
| `qa_architect` | kimi-k2.6 | gemini-3.5-flash | QA SDET. Regression, resilience, performance. Long context for logs. | subagent |
| `security_architect` | kimi-k2.6 | gemini-3.5-flash | Security auditor. IaC, secrets, least-privilege. Long context for scans. | subagent |

### Bash Permission Model

All agents use a **deny-first** model: explicit deny rules are evaluated first, then `"*": allow` as catch-all. This eliminates nuisance permission prompts for command variants (flags, pipes, paths) while maintaining security guardrails.

#### Commander (Full Access)
```
🚫 ALWAYS DENY: rm -rf /, rm -rf *, rm -rf /*, mkfs, dd, sudo rm, chmod -R 777 /
✅ Everything else: ALLOW (no prompts)
```
The Commander is the orchestrator — it needs unrestricted bash access to coordinate, commit, and deploy.

#### Sub-Agents (Read + Build — No Git Write, No Network)
```
🚫 ALWAYS DENY: rm -rf /, rm -rf *, rm -rf /*, mkfs, dd, sudo rm, chmod -R 777 /
🚫 GIT WRITE: git add, commit, push, pull, merge, rebase, reset, checkout, stash, cherry-pick
🚫 NETWORK: curl, wget, nc
🚫 macOS SECURITY: security, sysctl
✅ Everything else: ALLOW (no prompts)
```
Sub-agents can read files, search, build, test, and edit — but cannot write to git, make network calls, or access macOS security APIs.

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

| Plugin | Purpose |
|--------|---------|
| `opencode-subagent-statusline` | Shows sub-agent activity in sidebar (time, tokens, status) |
| `opencode-sdd-engram-manage` | SDD profile management + Engram memory browser from TUI |

> **Note:** TUI plugins require OpenCode >= 1.14.48. They are installed via npm but won't activate until OpenCode is updated.

## 🔐 Secrets & Security

### What's Gitignored

- `opencode.json` — Contains API tokens (generated from template)
- `agent/` directory — Generated output (rebuilt from templates)
- `*.bak` files — Never commit backups
- `node_modules`, `package.json`, `bun.lock` — NPM artifacts
- `~/.engram/` — Local SQLite memory database (never committed)

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

### TypeScript (Bun) Style
*   **Environment:** Use `Bun` APIs (e.g., `Bun.$`, `Bun.file`) over Node.js equivalents.
*   **Tools:** Define tools using the `@opencode-ai/plugin` SDK.
*   **Types:** Strict typing with TypeScript. Use `zod` for argument validation.
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
| Generated files missing | Run `cd .config/opencode/builder && go run main.go` |
| Missing Tools | Ensure `bun`, `go`, and `envsubst` are installed |
| Architecture Violation | Run `go run .config/opencode/tool/hex_check.go` in the project root |
| MCP server fails to connect | Check that the required env vars are set for that MCP entry |
| `tavily` MCP not appearing | Export `TAVILY_API_KEY` and rebuild: `cd .config/opencode/builder && go run main.go` |
| Agent can't execute commands | Check `permission.bash` in the agent template — may need to add `bash: true` to `tools` |
| Custom command uses disabled agent | Check `command/*.md` — ensure `agent:` field points to an enabled agent |
| Builder uses deprecated Go APIs | Use `os.ReadFile`/`os.WriteFile`/`os.ReadDir` instead of `ioutil` |
| Model profile not found | Check `model_profiles.json` — profile name must match exactly. Set `MODEL_PROFILE=opencodego` or `MODEL_PROFILE=gemini` |
| Unknown model key warning | Template uses `{{MODEL:xxx}}` but key is missing from active profile in `model_profiles.json` |
| Engram plugin not working | Ensure `engram` binary is installed (`yay -S engram-bin`) |
| TUI plugins not visible | Requires OpenCode >= 1.14.48. Check with `opencode --version` |
| Agent saves memories without asking | Verify `engram_memory.md` prompt includes Ask-First rules. Rebuild if needed. |

## graphify

This project has a graphify knowledge graph at graphify-out/.

Rules:
- Before answering architecture or codebase questions, read graphify-out/GRAPH_REPORT.md for god nodes and community structure
- If graphify-out/wiki/index.md exists, navigate it instead of reading raw files
- After modifying code files in this session, run `graphify update .` to keep the graph current (AST-only, no API cost)
- If "No code files found", try specific directories: `graphify update src/` or adapt to project structure
