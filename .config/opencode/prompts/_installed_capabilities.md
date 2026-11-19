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
`oc` (builder+launcher wrapper; guardrails since v0.6.0 live in `bin/oc` itself — dated internals archived in dotfiles `docs/history/oc-guardrails-internals-2026-11-16.md`) · `hex_check.go` + `hexagonal-validator.ts` (hexagonal import validator) · `k8s-pod-doctor.ts` · `mgrep.ts` (semantic search, cost-sensitive) · `tofu-scan.ts` (Trivy) · `graphify.sh` · `.local/bin/up` (opencode-stack updater, tracked by gitignore exception; NO OS packages — Tony runs yay daily).

## Agent roster (profile `opencodego` — the only one)
- **Technical (opencode-go gateway):** `commander` (primary), subagents `PE`, `go_architect`, `python_architect`, `frontend_architect`, `qa_architect`, `security_architect`, `doc_architect`, native `explore`.
- **Personal (opencode-go gateway, remote, shell-denied — ADR 0008, 2026-11-17):** `finanzas`/`life`/`coach` → `gemini-4-argon#medium`; `chef`/`barista`/`habitos` → `gpt-6-luna#medium|#none|#low`; `organiza` → `mimo-v2.6-flash` (bare — model exposes no variants); notes in `~/notas/<agent>/`.
- `general`/`build`/`plan` disabled.

## Providers & env
- `opencode-go` gateway = ALL agents since 2026-11-17 (ADR 0008). `google` native = **rollback path only**, keyed by `GEMINI_API_KEY` (in `~/.secret_envs`; no template placeholder — preflight shows an advisory, never aborts).
- `experimental.policies` keeps `provider.use google allow` — retained as the rollback path, no longer load-bearing for any running agent. **Retention ≠ authorization:** switching any agent back to `google/*` is a data-counterparty change requiring an explicit user decision. No agent may revert `model_profiles.json`, edit a generated `agent/*.md`, or pass `--model google/...` on its own — the `--model` route needs no file edit, no rebuild and leaves no git trace.
- homesrv (Pi) runs opencode as a systemd **SYSTEM** unit — `opencode.service`, active, restarted by `oc --sync` via `ssh homesrv "sudo systemctl restart opencode"` (measured 2026-11-17 19:52:52 CET). The **local** machine has no systemd opencode unit: its daemon is the user session (and `opencode api` auto-spawns a managed service on :49374). NEVER `oc --rebuild`/`oc --sync`/`opencode service restart`/`opencode api` from inside a live session — kills it.
