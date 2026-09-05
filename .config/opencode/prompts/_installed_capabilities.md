# Installed Capabilities

This platform has these plugins/MCPs/skills active. Use them — they exist for a reason.

## Runtime Plugins

| Plugin | Purpose | When to use |
|---|---|---|
| `opencode-vibeguard` | HMAC-SHA256 secret redaction (email, IP, UUID, etc.) | ALWAYS ON. Credentials pasted in prompts get redacted automatically. Complement to `envsitter-guard`. |
| `opencode-wakatime` | Time tracking heartbeats (1/min) | For retrospectives: "how long did this task take?" |
| `@plannotator/opencode` | Local browser UI for plan/code review | **Commander**: instead of printing plans in terminal, plannotator opens a browser for visual review with structured input. Set `PLANNOTATOR_SHARE=disabled` to keep plans local. **Workflow: `plan-agent`** with `planningAgents: ["commander"]` — only Commander can call `submit_plan`. No dependency on built-in `build`/`plan` agents (both disabled). **🚦 GOLDEN RULE — use only for COMPLEX multi-step plans (5+ steps, multiple files, or architectural changes). Small changes (typo fix, single-file tweak, <3 steps) → just proceed, do NOT trigger plannotator. Plannotator is for the big stuff.** |
| `@nick-vi/opencode-type-inject` | Auto-injects TS/Svelte types into file reads | `frontend_architect`, `go_architect` working with TS files. |
| `@tarquinen/opencode-dcp` | Dynamic Context Pruning (mid-session) | Auto-fires when context gets large. Different from compaction — trims duplicates, prunes errors, deduplicates file reads. Author migrating to "Sleev" (local proxy successor) but DCP still maintained. |
| `envsitter-guard` | .env file redaction (no values printed) | ALWAYS ON. Use `envsitter_*` tools, never `cat` on .env files. |
| `opencode-autotitle` | Auto-generates session titles | For long sessions. |

## Built-in Subagents (opencode ≥1.14.48)

| Subagent | Purpose | When to delegate |
|---|---|---|
| `scout` | External docs/deps research. Clones to cache, NO edits. | When you need current docs for a library, framework version, or API. **FREE** (built-in, no token cost to call). Prefer over `mgrep` for external research. |

## MCP Servers

| MCP | Purpose | When to use |
|---|---|---|
| `context7` | Current library docs (Next.js, React, Prisma, etc.) | When implementing against a library — your training data may be stale. |
| `atlassian` | Jira + Confluence | Project management, docs. |
| `tavily` | Web search + extract | Real-time info, news, post-cutoff events. |
| `mgrep` | Semantic local code search | Conceptual discovery in unknown repos. **COSTS TOKENS** — use sparingly. |
| `engram` | Persistent memory | Decisions, bugs, conventions, session summaries. |
| `gh_grep` | Real GitHub code examples | When you need to see how others use a specific API. |
| `cw-ai-gateway` | Coverwallet platform (k8s, datadog, jira, psql, mongo) | For Coverwallet work only. |
| `gcp` | Official Google Cloud MCP (Compute, GKE, BigQuery, Storage, etc.) | GCP infra queries, resource management. OAuth flow on first use. |
| `wiz` | Cloud security posture (vulnerabilities, threats, findings) | Wiz security insights. OAuth flow on first use. Requires Wiz account w/ MCP enabled. |

## Skills (`.opencode/skills/<name>/SKILL.md`)

| Skill | Trigger |
|---|---|
| `hexagonal-architect` | Enforces Hexagonal rules in Go projects. Auto-loads on Go file work. |
| `infra-security-check` | Trivy scan of Terraform/OpenTofu. Run before committing IaC. |
| `production-log-analyzer` | Pulls Datadog logs for service debugging. |
| `snippets` | Code snippet management. |
| `customize-opencode` | OpenCode config (agents, plugins, MCPs). ONLY when editing this repo's `.config/opencode/`. |

## Commands (slash)

| Command | Purpose |
|---|---|
| `/infra-scan` | Full IaC + secrets audit (uses PE). |
| `/k8s-doctor <pod>` | K8s pod diagnostics (uses PE). |
