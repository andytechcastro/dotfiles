# OpenCode Agent Engineering Guide

> **WARNING:** DO NOT EDIT FILES IN `.config/opencode/agent/` DIRECTLY.
> They are generated artifacts. Your changes will be overwritten.
> Edit templates in `.config/opencode/builder/templates/` instead.

> **DOC LAYOUT / CONTEXT BUDGET (ADR 0009):** this file is **operative-only**, target ≤25 KB — it is
> re-sent to every step of every session in this repo, so dated chronicles are expensive. Superseded
> dated history lives in `docs/history/`; decisions in `docs/adr/`; both are **gitignored (local
> only — never `git add -f`)**. Rule: a fact with a date that no longer governs behavior goes to
> `docs/history/`, with a one-line pointer here. Duplicates of platform prompts (`prompts/*.md`) are
> not copied here — they are already paid for in every agent prefix.

## 🏗 Architecture

GitOps-style **Builder Pattern**: templates → compiled agent configs + platform tools + dotfiles.

```text
.config/opencode/
├── bin/oc                     # builder + launcher CLI
├── builder/                   # the build system (Go)
│   ├── main.go                # templates → agent/*.md + config
│   ├── current_profile        # profile choice
│   └── templates/             # ⚠ SOURCE OF TRUTH
│       ├── agent/*.md         # frontmatter + {file:} includes
│       ├── config/config.json # ${ENV} + _requires_env
│       └── model_profiles.json# the only profile: opencodego
├── prompts/                   # behavior libraries ({file:} includes)
│   ├── commander_behavior.md  # orchestration protocol (~18 KB)
│   ├── behavior.md            # shared rules
│   ├── subagent_behavior.md   # Goldfish contract + integrity
│   ├── <domain>_behavior.md   # go/python/frontend/qa/security/doc/pe
│   ├── tools_rules.md         # canonical tool table
│   ├── _installed_capabilities.md # MCP/plugin/skill roster
│   └── _subagent_permissions.md   # subagent permission rules
├── agent/                     # ⚠ GENERATED — never edit
├── tool/                      # hex_check.go, *-validator.ts, k8s-pod-doctor.ts,
│                              # mgrep.ts, tofu-scan.ts, graphify.sh, output-anomaly-scan.sh
├── skill/                     # hexagonal-architect, infra-security-check, production-log-analyzer
├── command/                   # tracked slash commands (singular)
├── plugins/                   # local V2 plugins — NEVER in config array
├── squeez/config.ini          # compression persona + caps
├── opencode.json              # ⚠ GENERATED, secrets injected (gitignored)
├── cli.json                   # terminal config (plugins: [])
└── tui.json                   # V1 relic, deletion candidate
```

## 🛠 Build System

Templates hold YAML frontmatter + `{file:prompts/...}` includes. `model_profiles.json` supplies the
roster; templates reference models via `{{MODEL:key}}`. `main.go` resolves includes + placeholders,
writes `agent/`, generates `opencode.json` (env substitution, `_requires_env` pruning).

**`oc` wrapper** (`~/.local/bin/oc`; if missing: Troubleshooting `oc: command not found`):

```bash
oc                          # launch (auto-rebuild if config stale)
oc --profile opencodego     # rebuild with profile, then launch
oc --set-current opencodego # persistent default, no launch
oc --rebuild                # force rebuild, no launch
oc --sync [--dry-run|--agents-only|--notes-only]  # push agents+~/notas to homesrv,
                                                # restarts its SYSTEMD SYSTEM unit opencode.service
oc --list-profiles
```

**Guardrails (oc v0.6.0):** hard-die on unpinned non-float entries, hard-die on missing `${ENV}`; `GEMINI_API_KEY` advisory never aborts. Internals + call sites: `bin/oc`, `docs/history/oc-guardrails-internals-2026-11-16.md`.

**⚠ LETHAL from inside a live session:** `oc --rebuild`, `oc --sync`, `opencode service restart`,
`opencode api` (auto-spawns managed service :49374) — they kill/collide with your own daemon.
From a session, build with: `cd .config/opencode/builder && MODEL_PROFILE=opencodego go run main.go`.
Laptop has no systemd unit (daemon IS the user session); homesrv (Pi) is a SYSTEM unit restarted by
`oc --sync` via `ssh homesrv "sudo systemctl restart opencode"`.

**`up`** (`.local/bin/up`, tracked via 4-line gitignore exception): updates only the opencode stack
(uv tools, pipx skip-guarded, `opencode upgrade`, `opencode plugin update` for floats, pin-drift
report). **No OS-package step by owner decision** (Tony runs `yay` daily; `up` must never race/sudo).

**Profile resolution priority:** `MODEL_PROFILE` env → `builder/current_profile` →
`default_profile` (`opencodego`) → hardcoded `opencodego`. A removed profile (`google`, `gemini`)
aborts in the wrapper: `Profile '<name>' not found. Available: opencodego`.

Manual build: `export <needed secrets>` then `cd .config/opencode/builder && go run main.go`.

### Model Profiles — live state (`opencodego`, the only profile)

| Key | Model |
|---|---|
| `commander`, `pe`, `go_architect`, `python_architect`, `frontend_architect`, `qa_architect`, `security_architect`, `doc_architect`, `model`, `small_model`, `explore` | `opencode-go/qwen3.8-flash` |
| `finanzas`, `life`, `coach` (sensitive/reflective) | `opencode-go/gemini-4-argon#medium` |
| `chef` `#medium`, `barista` `#none`, `habitos` `#low` (factual) | `opencode-go/gpt-6-luna#…` |
| `organiza` | `opencode-go/mimo-v2.6-flash` **(BARE — model exposes no variants)** |

**Invariants (verified 2026-11-17, ADR 0008):**
- All 17 keys resolve through `opencode-go`. Google API spend for agents = **$0** (one-invoice rule).
  Measured personal workload ≈ 1,002 in / 27,394 out per turn ≈ **$0.75/month** equivalent.
- Budget control = gateway **per-model ceilings**, published as **($/month, requests/5h)**, counted
  over 5 h + weekly + monthly windows: qwen3.8-flash 90/16200 · gemini-4-argon 120/**2260** ·
  gpt-6-luna **60**/16900 · claude-haiku-5-5 60/15400 · minimax-m3.1-flash 80/15500 ·
  mimo-v2.6-flash 120/60200 · deepseek-v4.1-flash 200/86700 · qwen4-max 60/1850.
  The luna trio shares **$60/month**; the argon trio shares **2,260 req/5h** (tightest window live).
- **Overflow:** FAQ says at a Go limit you may keep using the free models; `*-free` ids are
  limited-time. "Extra Usage" credit is **OFF by default** — the hard stop is the guardrail.
- **`#none` is a latency selector, NOT a cost lever.** Price does not vary by variant.
- **Variant syntax contract:** `builder/main.go:125` regex constrains the placeholder KEY only;
  `:133` returns the value verbatim; `:188` writes raw bytes; `builder/go.mod` has zero `require`
  entries (no YAML lib in the emission path). js-yaml 3.x (opencode 2.3.0) round-trips
  `model: opencode-go/gemini-4-argon#medium`; parser splits on FIRST `/` and FIRST `#`.
  **Traps:** `model: x #medium` (space) → YAML comment, id truncated. `model: #medium` → null →
  silent account-default substitution. **The builder does NOT validate variants:** a bad variant
  compiles fine and kills every session of that agent at first turn (`provider.no-route`).
  `opencode models` prints ids WITHOUT variants — never validate a variant against it.
- **Observability (contract, details in Troubleshooting rows):** variant is NOT console-auditable
  (export drops `#variant`) → read `session_message.data.model.variant` locally, tolerating the
  `session_id` (2.2.5) / `sessionID` (2.3.0) skew; `session_v2.model` is EMPTY and the `cost` field
  reads 0 client-side, so $/month is console-only and `opencode stats` proves counts, not spend.
- **Residency/training gates are ACCOUNT/WORKSPACE privacy settings**, invisible to the CLI and the
  builder: the HTTP 400s ("hosted outside Europe and the United States…", `#training`) are the control
  **WORKING**, not bugs. Policy = EU/US residency (Global tested then revoked; deepseek excluded) plus
  *"By default, Go blocks paid endpoints that train on your requests"*. Counterparty for personal data
  = the gateway.
- **No automatic model fallback** (see below): 429/400 kills the turn; moving to a free model is MANUAL.
- **Homesrv (Pi):** aarch64, opencode **2.2.5**, no builder, artifact sink fed by `oc --sync`
  (`rsync -avz --delete --backup` + tar.gz pre-backup in `~/backups/oc-sync/`). `#variant` resolves
  identically on 2.2.5 and 2.3.0; synced 2026-11-17. Remaining hole: silent frontmatter drop (below).
- **`GEMINI_API_KEY` stays configured but UNUSED** — rollback safety net; do NOT document it as removed.

To add a profile: add an entry to `model_profiles.json` with keys matching all `{{MODEL:key}}`
placeholders — **live set = 17 keys** (8 technical + 7 personal + `model` + `small_model`). A missing
key prints `⚠️ Warning: Unknown model key '<x>'` and leaves the literal `{{MODEL:x}}` in the compiled
agent (silent broken model at runtime).

### Adding a New Agent

1. `builder/templates/agent/my_agent.md` with YAML frontmatter.
2. `{file:prompts/...}` includes for shared behavior.
3. `permissions:` list rules — **deny-only inline, no catch-all allow** (base allows, proved v2.3.0).
   Personal/primary agents that only read/write their notes dir MUST carry
   `- { action: shell, resource: "*", effect: deny }` as their **FIRST** rule (exfil seal).
4. Rebuild: `cd .config/opencode/builder && MODEL_PROFILE=opencodego go run main.go`.

### Adding a New MCP

1. Entry in `builder/templates/config/config.json`; secrets as `${ENV_VAR}`.
2. `"_requires_env": ["ENV_VAR"]` → entry pruned when the env is missing.
3. Rebuild.

> `https://opencode.ai/config.json` (the `$schema` URL) serves a **V1 schema** — never infer V2
> shapes from it. `npx -y` MCP servers stay pinned to exact versions (registry policy).

### Installed Capabilities

Canonical roster (MCPs, registry plugins with exact pins, local plugins, skills, commands, CLI tools)
lives in **`prompts/_installed_capabilities.md`** — injected into every agent, so per ADR 0009 it is not
copied here. The two load-bearing exceptions: the ONLY sanctioned float is `@plannotator/opencode@latest`
(machine parity — the vendor installer rewrites it; every other package stays exactly pinned), and local
plugins in `plugins/` are auto-discovered so they must NEVER appear in the config `plugins` array.
Dated plugin-removal chronicle: `docs/history/plugins-removals-superseded.md`.

Plannotator facts that can bite a config: a stray `opencode.jsonc` in the config dir is a LIVE doc
merged AFTER the generated `opencode.json` (per-key map wins → hence its gitignore rule; the global
`config.json` name is DEAD in V2), `PLANNOTATOR_SHARE` overrides the template's load-bearing
`share:"disabled"`, and the installer writes `commands/` (plural, gitignored) while tracked commands stay
in `command/` (singular — acceptance test: `git status --porcelain` empty after install). Dated
2026-11-16 measurements (`planningAgents` inert below 0.28, frozen-cache resurrection, CLI path) and the
upgrade runbook: `docs/history/plannotator-platform-facts-2026-11-16.md`, `docs/plannotator.md` (§9
Inbox), `.config/opencode/docs/vendor/plannotator-upgrade.sh`. Inbox-vs-`question` precedence = Commander
doctrine (`prompts/commander_behavior.md` PHASE 2.5): interactive decisions NEVER park in the Inbox.

## 🔌 Model Providers — Google

The **third-party** path to the Antigravity edge (`[daily-]cloudcode-pa.googleapis.com`) is RETIRED and
must **NEVER** be re-enabled without a new explicit user decision; first-party `/usr/bin/agy` traffic is a
different, legitimate surface and is **not** precedent, and no `google_search` MCP is permitted.
`experimental.policies` keeps `{action: provider.use, resource: "google", effect: allow}` as the documented
**rollback path** — **Retention ≠ authorization:** no agent may revert `model_profiles.json`, edit a
generated `agent/*.md`, or pass `--model google/...`/`-m` on its own (that route needs no file edit, no
rebuild and leaves no git trace). Native `google` is built into the binary, keyed by `GEMINI_API_KEY` in
the daemon **process** env (a rebuild never delivers env vars). Everything else dated — ToS suspension,
native-key eras, tier/quota chronicle, superseded cost projections, rollback mechanics + sanity check,
`vendor/antigravity-port/` kit, upstream PR #623 / issues #621-622 — is in
`docs/history/provider-eras-native-google.md`; the `google/*` troubleshooting rows that re-apply only
after a rollback are in `docs/history/rollback-era-troubleshooting.md`. **Live agy port (2026-11-20):** the opencode→Antigravity CLI roster port is operative →
`antigravity/README.md` + ADR 0012 (`docs/adr/0012-antigravity-port.md`); there is NO `docs/history/antigravity-port/`
chronicle — this line is the only agy pointer in this file (operative-only budget, ADR 0009).

### No error-based model fallback in V2 (platform limitation)

**Decision: document only** — owner declined a fallback mechanism; nothing is implemented, and nothing may
be invented without a new plan. V2 (statically checked against `v2.3.0`) has no `fallbacks:` config for
chat. What exists:

| Mechanism | Trigger | Semantics |
|-----------|---------|-----------|
| **Availability degradation chain** | model **not available** (not an error) | `variant` → `agent-model` → **account default**, silently — why wrong-model bugs "just work" |
| **"Newest available supported model"** | root model of a catalog entry missing | substitutes newest supported model |
| **Internal transient retry** | 429 / 5xx | same model, same request (`retry 1/5`) — not a model switch |
| **`experimental.image_generate`** | image generation | the ONLY documented per-model failover; not chat |

Consequence for the live roster: any personal agent that hits 429/400 **dies in place**; the three
gateway pools (argon trio, luna trio, mimo/`organiza`) are independent — a pool block does not touch
the others, and that is **not** failover. Real automatic failover would need a **router in front**
(self-hosted LiteLLM or OpenRouter `models: [primary, fallback]`) wired through
`providers.*.settings.baseURL`.

## 🤖 Agent Roster & Permissions

### Agent Roles

| Agent | Model (compiled) | Role | Mode |
|-------|-------|------|------|
| `commander` | opencode-go/qwen3.8-flash | **Pure Orchestrator**, 0 lines edited: plans, specs, delegates, gates, verifies | primary |
| `PE` | opencode-go/qwen3.8-flash | Infra (IaC), CI/CD, containers, tooling, platform glue | subagent |
| `go_architect` | opencode-go/qwen3.8-flash | Go: Clean Arch, SOLID, concurrency | subagent |
| `python_architect` | opencode-go/qwen3.8-flash | Python 3.12+, uv, ruff, Pydantic v2 | subagent |
| `frontend_architect` | opencode-go/qwen3.8-flash | Next.js 15/React 19, nuqs, TanStack Query, WCAG 2.2 | subagent |
| `qa_architect` | opencode-go/qwen3.8-flash | Testability, property-based, contract tests, regression | subagent |
| `security_architect` | opencode-go/qwen3.8-flash | STRIDE, AST taint, secrets, IaC hardening | subagent |
| `doc_architect` | opencode-go/qwen3.8-flash | Goldfish spec audit, ADRs, contracts, graphify | subagent |
| `finanzas`/`life`/`coach` | opencode-go/gemini-4-argon#medium | Personal notes agents (`~/notas/<agent>/`), no shell | primary |
| `chef`/`barista`/`habitos` | opencode-go/gpt-6-luna#medium/#none/#low | Personal notes agents, no shell | primary |
| `organiza` | opencode-go/mimo-v2.6-flash (bare) | Task/organizing lookups, no shell | primary |
| `explore` | {{MODEL:small_model}} | Fast recon (pinned for cheap mass searches) | native subagent |

**Native agents policy:** `explore` active and pinned; `general`/`build`/`plan` **disabled** —
all planning belongs to `commander`, all code modification to domain architects (prevents
unspecialized fallback hallucinations). `title` pinned to `small_model`.

### 🔄 Shift-Left Lifecycle (Phases 1.5 and 4) — summary

Full protocol (EGM model, adversarial 3-section contract, anti-sycophancy gate, bounded 2-round
negotiation, mandatory domain invocation matrix, Plannotator plan invariants) lives in
`prompts/commander_behavior.md` — it is injected into the Commander, so it is not duplicated here.
Repo-side essentials:

- **P1.5** hostile spec audit before any write; subagents answer (A) assumptions (B) failure modes
  (C.1) invariants (C.2) owner decisions + VERDICT. Static analysis only, zero disk writes,
  ADR drafted in memory/RFC as `Proposed`.
- **P2** plan approval gates Phase 3 (Plannotator, Spanish plan text).
- **P3** atomic delegation + ADR written to `docs/adr/NNNN-*.md` (`Proposed`).
- **P4** Spec Drift Check (`git diff` vs approved spec), ADR → `Accepted`, CHANGELOG, `graphify update .`.
- Commander never edits files; 100% of writes are subagent-owned. Cost rules (kill-gate first, atomic
  tickets with budgets, one writer per directory, verify once at phase end): **ADR 0011**.

### Permissions Model (V2 Native)

Frontmatter uses an **ordered `permissions:` LIST** of `{action, resource, effect}` — never the legacy
singular `permission:` map (V2 auto-migrates it; the LIST is the contract). Actions V2 actually
evaluates (proved dynamically 2026-11-16): `shell`, `edit` (write/patch), `read`, `glob`, `grep`,
`webfetch`, `websearch`, `subagent` (resource = child agent id), `external_directory`. The old
`bash:`/`task:` twin vocabulary is **dead code — do not reintroduce**.

**Deny-only layout:** no matching rule → **ALLOW** (measured v2.3.0, 17/17; the documented `?? ask`
default never fires, headless agents cannot deadlock). Every matched deny is hard and silent:
`Permission denied: <action>`. Last-match-wins among denies. Shell resources match **RAW command
text** (no `~`/`$HOME` expansion). `write`/`edit: ask` scalars stay dropped.
`experimental.policies` supports multiple actions; `tool.use "<action>:<glob>"` floors evaluate BEFORE
any agent rule and emit `Blocked by configuration policy`. **27 live floors** cover
read/edit/shell × `*.ssh*`, `*.env*`, `*.secret_envs*`, `*.netrc*`, `*.config/gh/hosts.yml*`,
`*auth.json*`, `*opencode.db*`, `*cli-proxy-api*`, `*.config/opencode/opencode.json*`. Accepted cost:
floors cannot lift with allows, so `.env.example` reads are blocked and `source ~/.secret_envs` is
unavailable to agents (secrets must already be in the daemon env, loaded by `~/.zshrc` first).

- **Commander:** destructive-op denies only (`rm -rf /`, `rm -rf *`, `rm -rf /*`, `mkfs*`, `dd *`,
  `sudo rm*`, `chmod -R 777 /`). Orchestrator needs unrestricted bash to coordinate/commit/deploy.
- **Sub-agents:** same 7 + `git add/commit/push/pull/merge/rebase/reset/checkout/stash/cherry-pick` +
  `curl`/`wget`/`nc` + macOS relics (`security`, `sysctl`) + `subagent "*"`, `webfetch "*"`,
  `websearch "*"` (denying also filters them from the model's tool catalog). Leaf execution: no git
  write, no network egress, no grandchild spawns.
- **Personal agents:** `shell "*"` **deny as the FIRST rule** (the load-bearing exfil seal) + read/edit
  on `~/notas/<agent>/`. **No allow may follow the catch-all** (last-match-wins would re-open the hole).
  Web egress is per-agent: `finanzas`/`organiza`/`habitos`/`life` SEALED (identical blocks, md5
  `139ddbd38e7213faf3c186b2224b69e0`); `barista`/`coach`/`chef` intentionally web-open (owner decision
  — new personal agents default to SEALED). The rule is provider- and tier-independent because every
  current model is remote.
- **⚠ OPEN THREAT (ADR 0010):** squeez-wrapped shell commands **evade subagent frontmatter git
  denies** — the deny matcher sees the wrapped raw text, not `git add*`. Until the daemon is restarted,
  the `--no-squeez` escape hatch is not live either. Owner decision pending; Phase-4 security gate weighs in.

### Sub-Agent Communication Protocol

Caveman/Token-Hunter reporting to Commander: no social cues, no grammar fluff, technical only,
`[thing] → [action]. [next].`. Contract in `prompts/caveman_behavior.md`.

## 🧠 Persistent Memory (Engram)

Plugin `engram.ts` (session tracking, prompt capture, compaction recovery, prompt injection) + MCP
`engram mcp --tools=agent` (23 tools) + SQLite store in `~/.engram/` (local, no cloud). Ask-First
protocol, session-end batch review, post-compaction recovery, topic hygiene and `mem_judge_many`
conflict flow are canonical in **`prompts/engram_memory.md`** (injected into every agent) — CLI:
`engram tui | search | projects list | sync [--import] | save "<title>" "<content>" --type discovery
--topic <key>`.

## 🔐 Secrets & Security

Gitignored (never commit): `opencode.json` (injected tokens), `agent/` (generated), `*.bak`,
`node_modules`/`bun.lock`, `~/.engram/`, `squeez/sessions/`, `.config/opencode/service.json`,
`.config/opencode/AGENTS.md` (squeez-managed), `.config/opencode/antigravity-accounts.json` (dead
legacy OAuth state — never synced), `.config/opencode/commands/`, `.config/opencode/opencode.jsonc`,
`docs/` (**deliberate**: local ADRs/history/specs out of git; a platform doc that must ship is
force-added per-file, e.g. `docs/plannotator.md` — never flip the global rule to `docs/*`),
`.local/*` except the `!.local/bin/up` exception, `~/.secret_envs` (chmod 600, outside repo, sourced
by `~/.zshrc`).

**`.bak` lesson:** a `opencode.json.tui-migration.bak` once held plaintext tokens. Never store secrets
in backups; the builder injects secrets — never hand-edit `opencode.json`.
Tracked `package.json` carries security `overrides` (toml/uuid) — do not ignore it.

## 📜 Code Style

Tooling: canonical table in `prompts/tools_rules.md` (bat/rg/fd/sd/eza/mgrep/graphify/sg/repomix/uv/
just/gh/lazygit/fzf/zoxide/delta). Prefer modern tools; `graphify` is architecture truth.

General: platform over apps; reliability & DX; Hexagonal — dependencies point inward, domain never
imports infrastructure.

**Go:** stdlib-first imports, `goimports`, strict `gofmt`; always `if err != nil`; CLI → stderr +
`os.Exit(1)`; libraries wrap with `%w`; `CamelCase` types, short receivers, concise vars; `os.ReadFile`/
`os.WriteFile`/`os.ReadDir` (never `ioutil`).
**TypeScript:** plugins on V2 `@opencode/plugin` (`Plugin.define`, JSON Schema inputs, no zod in the
`editor.add` path; ambient `process`/`Bun` type errors benign); legacy `tool/*.ts` stay on V1 SDK
(1.4.7); **no `bun` binary on the system**; strict types; 2 spaces, no semicolons.
**Lua:** separate `config/set.lua` + `config/remap.lua`; `lazy.nvim` for all plugin config; `local`
vars only.
**Shebang:** `#!/usr/bin/env bash` (portable).

## 🤖 Rules for Agents

1. **Context first:** check for `AGENTS.md` / `graphify-out/` before touching code.
2. **graphify is MANDATORY** (`~/.local/bin/graphify`): new project → `graphify opencode install &&
   graphify update .`. Dot-folders are ignored → symlink trick:
   `ln -s .config/foo src_foo && graphify update src_foo && rm src_foo`.
   **NO platform skills** (`graphify gemini/cursor install`) — OpenCode integration only.
3. **Persona:** Spaniard Platform Engineer; Castellano slang when the user writes Spanish.
4. **Zero patience for mediocrity:** hexagonal violation → fail the build and say why.

## 🚫 Troubleshooting (live rows; rollback-era rows → `docs/history/rollback-era-troubleshooting.md`)

| Problem | Solution |
|---------|----------|
| Generated files missing | `cd .config/opencode/builder && MODEL_PROFILE=opencodego go run main.go` (never `oc --rebuild` from a live session) |
| Missing tools | Builder needs `go` only; `bun` is not installed |
| Architecture violation | `go run .config/opencode/tool/hex_check.go` in the project root |
| MCP server fails to connect | Check that its `_requires_env` vars are set |
| Command unexpectedly blocked | `Permission denied: <action>` = frontmatter deny matched (last-match-wins, raw-text globs, `*` crosses `/`). `Blocked by configuration policy` = `tool.use` floor. No missing-catch-all failure mode since 2026-11-16 |
| Custom command uses disabled agent | `command/*.md` — `agent:` must point to an enabled agent |
| Builder deprecated Go APIs | `os.ReadFile`/`os.WriteFile`/`os.ReadDir` |
| Model profile not found | Only `opencodego` exists since 2026-11-15; `oc --set-current opencodego` or `MODEL_PROFILE=opencodego` |
| Unknown model key warning | `{{MODEL:xxx}}` in a template but key missing in the active profile |
| Engram plugin dead | `engram` binary present (`yay -S engram-bin`) |
| `failed to load plugin` at boot | Not on V2 contract (`export default Plugin.define`) or stale config entry — single-file plugins are NEVER listed in the config `plugins` array |
| Plugin/tool change has no effect | `opencode service restart` (kills local sessions — own window) — rebuild/hot-reload do not re-register hooks |
| Auth state wrong / `opencode auth logout` hangs | Credential truth = `credential` table in `~/.local/share/opencode/opencode.db` (`auth.json` is a mirror); logout needs the credential **ID** or hangs in non-TTY |
| Env-var diagnostic flag ignored | systemd service carries no ad-hoc env — reproduce on isolated `opencode serve --port` with the var exported |
| Personal agent hits a gateway ceiling (429) | Check **console** allowance counters; locally count requests per model from `session_message` (`cost` reads 0). No automatic fallback — the turn dies; moving to a `*-free` model is MANUAL |
| Session dies at FIRST turn with `provider.no-route` | Bad/unsupported `#variant` (builder does not validate). `mimo-v2.6-flash` must stay bare for `organiza`. Fix, rebuild, verify via `session_message.data.model` |
| HTTP 400 "hosted outside Europe and the United States…" / `#training` 400 | Workspace privacy control **WORKING**. Do not switch to Global (tested + revoked). Pick an EU/US non-training model |
| Agent silently uses the account default | `model:` came back null/empty — missing profile key (literal left in agent) or `model: #medium` (YAML comment). Check compiled frontmatter + `session_message.data.model` |
| `model:` truncated at `#` | Space before `#` → YAML comment. Attach with NO space: `model: x#medium` |
| Agent vanished from `--agent` list, NO error | **2.2.5 (homesrv) silent frontmatter drop** — comment-trap null value; `agent file skipped` log string does not exist in that binary, `--print-logs` is empty, no `--archived` flag. Detect by counting agents / running a turn / inspecting compiled bytes before sync |
| Script reads `session_message`, blind on one node | Schema skew: `session_id` (2.2.5) vs `sessionID` (2.3.0). Accept both; never `session_v2.model` (EMPTY) or the zombie `message` table |
| Burn detector reports zero spend | Gateway `cost` reads 0 client-side. Count requests locally; read $/month in the console. First-turn `cache.read = 0` is normal |
| Variant not auditable in console export | Known limitation: export drops `#variant`. Audit locally via `session_message.data.model.variant` |
| Stale model after a profile edit | Config watcher picked up `agent/*.md` on 2.3.0 without restart (verified 2026-11-17). If a daemon still holds stale defs: `opencode service restart` or verify on isolated `opencode serve --port` |
| `Location plugins did not finish activating` | Slow node (Pi) still downloading a registry plugin — wait 1-3 min, retry |
| `oc` build aborted: missing env vars | `source ~/.secret_envs` (in a terminal, not inside an agent) and retry — the abort is a feature |
| `yt_transcript` 429 | Retry later — YouTube rate-limits aggressive polling |
| Agent saves memories without asking | `engram_memory.md` Ask-First rules; rebuild |
| `oc: command not found` | `ln -sf $(pwd)/.config/opencode/bin/oc ~/.local/bin/oc` |
| Squeez not compressing | `squeez` binary at `~/.local/bin/squeez`; `squeez/config.ini` exists |
| codebase-memory-mcp not indexing | Run `codebase-memory-mcp` manually first (`~/.local/bin/codebase-memory-mcp`) |

## graphify

Graph lives in `graphify-out/`: read `GRAPH_REPORT.md` (god nodes, communities) before answering
architecture questions, and `wiki/index.md` instead of raw files when it exists. Bootstrap, the
dot-folder symlink trick and `update .` cadence are in **Rules for Agents §2** (not repeated here).
