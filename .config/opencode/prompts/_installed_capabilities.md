# Installed Capabilities (ground truth — verified 2026-11-16)

<!-- Single source: builder/templates/config/config.json + this directory. Update ONLY when config/roster changes. If a tool is missing here, it does not exist. -->

## MCP servers (config template `mcp`)
| Server | Purpose | Requires env |
|--------|---------|--------------|
| `context7` | Live library/framework docs | — |
| `engram` | Persistent memory (local SQLite `~/.engram`) | — |
| `gh_grep` | Real-world GitHub code examples | — |
| `gcp` | Google Cloud Platform (OAuth) | — |
| `google_drive` | Drive files | `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET` |
| `codebase-memory-mcp` | Code knowledge graph (tree-sitter + SQLite) | — |
| `playwright` | Browser automation | — |

NOT installed (do not hallucinate): wiz, cw-ai-gateway, atlassian/Jira, tavily, mgrep-as-MCP (it is a local tool).

## Plugins — registry (`plugins` array, pinned policy: exact versions; plannotator sanctioned float)
| Plugin | Version | Purpose |
|--------|---------|---------|
| `opencode-snippets` | 3.4.0 | `#hashtag` snippet expansion |
| `@tarquinen/opencode-dcp` | 3.2.0 | Dynamic context pruning |
| `@plannotator/opencode` | `@latest` (float) | Plan/code review UI + Inbox; options `workflow:"plan-agent"`, `planningAgents:["commander"]`. Binary + inbox docs: `docs/plannotator.md` |

## Plugins — local auto-discovered (`plugins/*.ts|js`, NEVER listed in config)
`engram.ts` (memory hooks) · `squeez.js` (output compression) · `graphify.js` (graph reminders) · `run-watch.ts` (tool `run_watch`: bg script + session wake) · `yt-transcript.ts` (tool `yt_transcript`). `echo.ts.v1-retired` is inert by extension.

## Skills (on-demand)
`hexagonal-architect` (Go import-boundary enforcement) · `infra-security-check` (Trivy IaC) · `production-log-analyzer` (Datadog logs).

## Custom commands
`/infra-scan` (PE + tofu-scan) · `/k8s-doctor` (PE + k8s-pod-doctor). Plannotator installer may add `commands/` (gitignored, untracked by design).

## Platform CLI tools (`bin/`, `tool/`)
`oc` (builder+launcher wrapper; guardrail `check_plugin_pins` pending) · `hex_check.go` + `hexagonal-validator.ts` (hexagonal import validator) · `k8s-pod-doctor.ts` · `mgrep.ts` (semantic search, cost-sensitive) · `tofu-scan.ts` (Trivy) · `graphify.sh`. Planned: `.local/bin/up` (opencode-stack updater; NO OS packages — Tony runs yay daily).

## Agent roster (profile `opencodego` — the only one)
- **Technical (opencode-go gateway):** `commander` (primary), subagents `PE`, `go_architect`, `python_architect`, `frontend_architect`, `qa_architect`, `security_architect`, `doc_architect`, native `explore`.
- **Personal (native `google` provider, remote, shell-denied):** `finanzas`/`life`/`coach` → `gemini-4-hydrogen`; `barista`/`chef`/`organiza`/`habitos` → `gemini-3.8-flash`; notes in `~/notas/<agent>/`.
- `general`/`build`/`plan` disabled.

## Providers & env
- `opencode-go` gateway = technical agents. `google` native = personal agents, keyed by `GEMINI_API_KEY` (in `~/.secret_envs`; NOT visible to builder preflight — blind spot by design).
- `experimental.policies` keeps `provider.use google allow` — load-bearing.
- Local machine: no systemd opencode unit (service = user session); systemd exists ONLY on homesrv (Pi). NEVER `oc --rebuild`/`oc --sync`/`opencode service restart`/`opencode api` from inside a live session — kills it.
