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
│       │   ├── security_architect.md
│       │   └── doc_architect.md
│       ├── config/
│       │   └── config.json   # Config template (${VAR} substitution + _requires_env)
│       └── model_profiles.json # Model profiles (opencodego — sole profile since 2026-11-15; ALL 15 agents on opencode-go since 2026-11-17: 8 technical + model + small_model on qwen3.8-flash, 7 personal via `provider/model#variant`: 3× gemini-4-argon#medium + 3× gpt-6-luna + 1× mimo-v2.6-flash bare — ADR 0008)
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
│   ├── doc_behavior.md       # Documentation architect protocol
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

# Rebuild with specific profile, then launch (opencodego is the only profile today)
oc --profile opencodego

# Set persistent default profile (no launch)
oc --set-current opencodego

# Force rebuild without launching
oc --rebuild

# Sync agents + notes to homesrv (Raspberry Pi 4) & restart opencode.service
#   (homesrv runs opencode as a systemd SYSTEM unit, `opencode.service` — active,
#    restarted by the sync leg via `ssh homesrv "sudo systemctl restart opencode"`;
#    the laptop has no systemd unit — its daemon IS the user session. Verified 2026-11-17.)
oc --sync
oc --sync --dry-run      # Preview without touching the server
oc --sync --agents-only  # Sync only compiled agent definitions
oc --sync --notes-only   # Sync only context notes (~/notas/)

# List available profiles
oc --list-profiles
```

**`oc` v0.6.0 guardrails (ported from dotfilesMac 2026-11-16, hand-adapted — the two `oc` forks diverged, never `git apply` between them):**
- `check_plugin_pins`: hard-die on a non-`@`-prefixed, non-semver plugin entry; floats (`@latest`) pass and get a registry-freshness report cached 24 h (`pin-check.json`, GNU `stat -c %Y` — the Mac `stat -f %m` BSD idiom printed the whole filesystem here and silently defeated the TTL cache); network failures degrade to silence, never block a launch. Known latent debt: the semver regex `@[0-9]+\.[0-9]+\.[0-9]+$` skips prerelease tags.
- `check_env_vars` is now **hard-die** (`Aborted. Set the missing env vars and retry.`) — before, a missing `${VAR}` baked an empty key into `opencode.json` silently. It also carries an explicit **`GEMINI_API_KEY` advisory**: that key has no template placeholder (the native `google` provider is built into the binary), so neither `_requires_env` pruning nor the `${VAR}` scan can see it. **Since 2026-11-17 the key is OPTIONAL — no running agent consumes it** (ADR 0008 moved the 7 personal agents to the gateway); the warning survives as the rollback-path reminder and never aborts the build. Hard-die behavior for the vars that DO matter is unchanged.
- Call sites: `do_rebuild` (after `check_env_vars`) and the fresh-config branch.
- **LETHAL from inside a live session:** `oc --rebuild`, `oc --sync`, `opencode service restart` and `opencode api` (auto-spawns a managed service on :49374) kill or collide with the daemon running your own session. Builds from a session use `cd .config/opencode/builder && MODEL_PROFILE=opencodego go run main.go`.

**`up` (`.local/bin/up`, tracked via a 4-line `.gitignore` exception — `.local/*`, `!.local/bin/`, `.local/bin/*`, `!.local/bin/up`):** Arch port of the Mac updater, updated **only the opencode stack**: `uv tool upgrade --all`, pipx (self-guarded skip), `opencode upgrade`, `opencode plugin update` (floats; never auto-restarts the service — prints the instruction), and a plugin pin-drift report (snippets/dcp/plannotator vs registry). **No OS-package step at all, by user decision: Tony runs `yay` daily and `up` must never race it or need sudo** (Mac steps 1 `/private/tmp` perms and `brew upgrade` deleted — neither exists here).

**Manual build** (if you need fine-grained control):

```bash
# 1. Export secrets (only the ones you have)
export BRAVE_API_KEY='...'

# 2. Run the builder (uses builder/current_profile, else default_profile in model_profiles.json = opencodego)
cd .config/opencode/builder && go run main.go

# Or override with env var
MODEL_PROFILE=opencodego go run main.go
```

**Profile Resolution Priority:**
1. `MODEL_PROFILE` env var (temporary override)
2. `builder/current_profile` file (persistent choice — currently `opencodego`)
3. `default_profile` in `model_profiles.json` — now `opencodego` (was `google` until 2026-11-15)
4. Hardcoded fallback: `opencodego`

Selecting a removed profile (`google`, `gemini`) aborts in the `oc` wrapper: `Profile '<name>' not found.
Available: opencodego`. Only `opencodego` exists.

The builder will:
- Load the active model profile from `model_profiles.json`
- Compile all agent templates → `agent/*.md`
- Resolve `{{MODEL:xxx}}` placeholders with profile values
- Generate `opencode.json` with env vars substituted
- Remove MCP entries with missing required env vars
- Log ✅/🚫 for each MCP entry's status

### Model Profiles

Models are **not hardcoded** in agent templates. Instead, each profile in `model_profiles.json` defines the full roster. Since 2026-11-15 there is **one profile only** — `google` and `gemini` were deleted (see **Model Providers**). Since **2026-11-17** the profile is **no longer mixed**: all 15 agents resolve through the `opencode-go` gateway (ADR 0008), the 7 personal ones via the V2 `provider/model#variant` frontmatter syntax. The former native-`google` state (2026-11-15 → 2026-11-16) is preserved below as a dated historical record.

| Profile | Commander | Workers | Personal agents | small_model |
|---------|-----------|---------|-----------------|-------------|
| `opencodego` ★ **DEFAULT** | opencode-go/qwen3.8-flash | opencode-go/qwen3.8-flash | **opencode-go/gemini-4-argon#medium** ×3 — `finanzas`, `life`, `coach` (sensitive/reflective) · **opencode-go/gpt-6-luna** ×3 — `chef#medium`, `barista#none`, `habitos#low` (factual/lookup) · **opencode-go/mimo-v2.6-flash** (BARE — no variants exposed) — `organiza` | opencode-go/qwen3.8-flash |

> **Current cost / quota state (verified 2026-11-17 — ADR 0008):** all 17 keys resolve through
> `opencode-go`. Google API spend for agents = **$0**: the one-invoice rule (OpenCode Go Plus
> subscription already paid; Tony refuses subscription + pay-per-use simultaneously). Measured
> personal workload — ~1,002 input / 27,394 output tokens per turn — prices at **≈$0.75/month**
> equivalent on the gateway: economically irrelevant. Budget control is now the gateway's
> **per-model ceilings** (published, $/month + requests/5h; counted over 5-hour, weekly AND monthly
> windows), **plus a burn detector** — requests per model counted locally from `session_message`,
> dollar consumption read from the console / request-log export (see **Cost visibility is
> console-only** below; local `cost` fields read 0 and are NOT a usable signal):
> qwen3.8-flash 90/16200 · gemini-4-argon 120/2260 · gpt-6-luna **60/16900** · claude-haiku-5-5
> 60/15400 · minimax-m3.1-flash 80/15500 · mimo-v2.6-flash 120/60200 · deepseek-v4.1-flash 200/86700
> · qwen4-max 60/1850. Ceilings are pairs of **($/month, requests/5h)**: the luna trio (`chef#medium`,
> `barista#none`, `habitos#low`) shares one **$60/month** allowance (its 16,900 req/5h window is
> generous); the argon trio (`finanzas`/`life`/`coach`) shares **2,260 requests/5h** — the tightest
> request window in the live roster.
> - **Overflow path:** official FAQ — *"When you reach a Go limit, you can keep using the free
>   models."* `*-free` models (`beam-free`, `hy4-flash-free`, `longcat-2.5-free`) are unlimited but
>   **LIMITED-TIME**; "Extra Usage" (console-side credit) is **OFF by default** — the hard stop is
>   the intended guardrail, same posture as the retired 402.
> - **`#none` is a latency selector, NOT a cost lever.** Gateway pricing does not vary by variant;
>   disabling thinking buys speed only.
> - **Variant syntax contract (builder emission proved):** `builder/main.go:125` regex constrains
>   only the placeholder KEY, `:133` returns the value verbatim, `:188` writes raw bytes;
>   `builder/go.mod` has ZERO `require` entries — no YAML library in the emission path. js-yaml 3.x
>   (embedded in opencode 2.3.0) round-trips `model: opencode-go/gemini-4-argon#medium` intact; the
>   model-id parser splits on the FIRST `/` and FIRST `#`. **Traps:** `model: x #medium` (space) →
>   YAML COMMENT, id truncated; `model: #medium` → null → silent account-default substitution.
>   **The builder does NOT validate variants:** a non-existent variant name compiles fine and kills
>   every session of that agent at first turn (`provider.no-route`). `opencode models` prints ids
>   WITHOUT variants — variant validity cannot be checked statically.
> - **Variant observability:** the gateway request-log export shows `requestedModel`/`model` WITHOUT
>   the `#variant` → variant consumption is **NOT auditable from the console export**. Locally it IS,
>   but only from one place: `session_message.data.model.variant` (`opencode stats --models` shows
>   per-model request/token counts — useful for burn, NOT proof of a variant; `--cost` reads 0, see
>   the cost bullet). `reasoningTokens` is
>   NOT valid variant evidence for argon (0 at both low and medium); luna showed medium=41 vs
>   low/none=0 (weak signal only). The `session_v2.model` column comes back EMPTY — do not script
>   against it. Read the LIVE `session_message.data.model` table, never the zombie `message` table.
>   **Schema skew across versions — any consumer script must tolerate BOTH names:** the
>   `session_message` session column is **`session_id` on 2.2.5 (Pi)** and **`sessionID` on 2.3.0
>   (laptop)**; `session_v2`/`session_message` exist on both but keyed differently (the Pi also lists
>   `session_inbox`, `session_part`). Pick one name and you are blind on the other node.
> - **Cost visibility is console-only:** the gateway `cost` field reads **0 client-side on both nodes**
>   (`opencode stats` included) — Go consumption is not exposed locally, only request counts. A local
>   detector can count **requests per model** from `session_message`, but the ceiling that actually
>   binds is the **$/month** figure, which lives only in the console / request-log export. Do not build
>   the burn detector on local `cost` numbers. (Measured: a trivial first-turn `finanzas` run on the Pi
>   logged 58,700 input tokens with `cache.read = 0` — normal for the FIRST turn of a new session,
>   where prompt caching has no prior identical prefix yet; it is not a caching failure.)
> - **Residency/training gates are ACCOUNT/WORKSPACE privacy settings — invisible to the CLI and to
>   the builder.** Evidence the gate exists and works: `opencode-go/deepseek-v4.1-flash` → HTTP 400
>   *"This OpenCode Go model is hosted outside Europe and the United States. Select Global at
>   .../settings/privacy#regions"*; `iceman-contributor-free` → HTTP 400 gated by the `#training`
>   setting. That 400 is the privacy control **WORKING**, not a bug. Tony toggled Global, tested it,
>   then **REVOKED it and returned to EU/US** → deepseek excluded; `habitos` went to luna#low.
>   Per-workspace residency also governs the sensitive agents (`finanzas`/`coach`/`life`). The
>   accepted privacy guarantee is *"By default, Go blocks paid endpoints that train on your
>   requests"*; the counterparty for personal data changed from Google to the gateway.
> - **No automatic model fallback in V2** (unchanged): a 429/400 kills the agent turn; switching to
>   a free model is **MANUAL**.
> - **Homesrv (Pi): `#variant` VERIFIED AND SYNCED — 2026-11-17.** The Pi is aarch64 on opencode
>   **v2.2.5** (laptop 2.3.0), has NO builder, and is a pure artifact sink fed by `oc --sync` (agents
>   leg: `rsync -avz --delete --backup`, pre-backup tar.gz in `~/backups/oc-sync/` — the shipped run is
>   `overwrites-agent-20261117-195248/`, 15 `.md`). PE measured both binaries: `model:
>   opencode-go/gemini-4-argon#medium` resolves **identically** on 2.2.5 and 2.3.0 (`Variant
>   unavailable`, `provider.no-route`, `activeVariant` present in both) ⇒ **SAFE_TO_SYNC**. Sync
>   executed (user, 19:52): Pi `agent/` carries the 15 relocated files, **zero `google/` refs**;
>   systemd **SYSTEM** unit `opencode` restarted 19:52:52 CET. Remote runtime turn verified:
>   `ssh homesrv opencode run --agent finanzas --format json` → rc=0, Spanish, `reason: stop`,
>   and the Pi's own DB shows `session_message.data.model` = `id=gemini-4-argon`,
>   `providerID=opencode-go`, `variant=medium`. The version axis of `#` was never the blocker; what
>   remains on the Pi is an **observability hole** (see the silent-drop troubleshooting row) and the
>   `session_id`/`sessionID` schema skew recorded under **Variant observability** above.
> - **`GEMINI_API_KEY` stays configured but unused** — documented rollback safety net to the native
>   `google` provider. Do NOT document it as removed. **Authorization (security gate 2026-11-17): the
>   rollback is a counterparty change, not a mechanical one.** Reverting `model_profiles.json` lines
>   12-18 (~2 min + rebuild) is only ONE of its shapes — `opencode run --model google/...` performs the
>   SAME switch with **zero file edits, zero rebuild, `git status` clean and no policy floor matching it**
>   (the floors match neither `agent/*.md` nor `model_profiles.json`). No agent may revert the profile,
>   edit a generated `agent/*.md`, or pass a non-`opencode-go` `--model`/`-m` on its own initiative:
>   retaining `provider.use google allow` permits the route, it does NOT authorize using it.
>
> **Historical record — the native-`google` era, 2026-11-15 → 2026-11-16 (verbatim, superseded by
> ADR 0008 on 2026-11-17; facts stated below were true and verified on 2026-11-15, NOT current):**
> a **€5 prepaid top-up** promoted the key to **Gemini API tier 2**; live panel limits: **RPD
> 100,000 per model** (`gemini-3.8-flash` 5/100K, `gemini-4-hydrogen` 5/100K, `gemini-3-flash`
> 2/100K), **RPM ~2,000**, **TPM ~3M**; at zero balance the API answers **HTTP 402** and every
> `google/*` agent stops at once; **auto-recharge deliberately OFF** so the stop is hard; measured
> price gap **2–3×** (flash $0.75/1M in · $3.75/1M out, `barista` = **$0.0115185** vs hydrogen
> **$0.0216–$0.0393**); projected mixed cost **≈ $25/month**; the two-model split gave **two
> independent per-model request pools** (an architectural property of the API, true regardless of
> tier — traffic never aggregates into one counter); the free tier licensed submitted content for
> training, paid tiers (1/2/3) do not, and tier advanced on **accumulated spend history**, not
> consumer subscriptions; a zero balance was documented as an **availability event (402), not a
> documented tier demotion**; the retired `google` profile had depended on AI Pro
> (2026-11-01 → 2026-11-15); free-tier RPD reset at **midnight Pacific**. E2E verifications of that
> era (isolated `opencode serve`: hydrogen via `chef`/`barista`, flash via `barista`, `finish: stop`,
> resolved model = `gemini-3.8-flash`) remain true as dated observations of 2026-11-15.
>
> **Google models today:** reachable through the gateway as `opencode-go/gemini-4-argon` (verified
> responding 2026-11-15), and — **available but no longer consumed by any agent since 2026-11-17** —
> via the native API key (`GEMINI_API_KEY`, see **Model Providers**). The catalog sanity check of the
> previous era (`opencode models | rg '^google/gemini-(4-hydrogen|3\.8-flash)$'`) is **obsolete for
> profile debugging — nothing personal runs there now**; it only checks the rollback path. Vertex ADC
> remains a possible future path.
> **Catalog trap:** `opencode models` (2026-11-15) prints 42 `google/*` ids — **24 live
> native models** on the AI Studio endpoint plus **18 `google/antigravity-*` ids that are only upstream
> static catalog entries** (they are not in the binary, and the plugin that authenticated them is
> retired). **Listed ≠ available**: there is no auth path for any `antigravity-*` id, and probing one
> would send traffic to the suspended Antigravity edge — forbidden from third-party clients. Never
> hand-infer a catalog. `opencode models` ALSO prints ids without `#variant` suffixes — never
> validate a variant against it.
>
> **Build procedure for profile-only changes:** compile with the builder directly
> (`cd .config/opencode/builder && MODEL_PROFILE=opencodego go run main.go`). **Do NOT use
> `oc --rebuild` / `oc --sync` from inside a live session** — both restart the local daemon and kill
> the session attached to it (use `oc --sync --agents-only --no-rebuild` to propagate to homesrv).

To add a new profile, add an entry to `model_profiles.json` with keys matching all `{{MODEL:key}}` placeholders used in templates — **the live set is 17 keys**: 8 technical agents (`commander`, `pe`, `go_architect`, `python_architect`, `frontend_architect`, `qa_architect`, `security_architect`, `doc_architect`), 7 personal agents (`finanzas`, `organiza`, `habitos`, `life`, `coach`, `barista`, `chef`), plus `model` and `small_model`. A missing key makes the builder print `⚠️ Warning: Unknown model key '<x>' in profile — leaving as-is` and **leaves the literal `{{MODEL:x}}` in the compiled agent** (silent broken model at runtime).

### Adding a New Agent

1. Create `.config/opencode/builder/templates/agent/my_agent.md` with YAML frontmatter.
2. Use `{file:prompts/...}` to include shared behavior libraries.
3. Add `permissions:` list rules (`{action, resource, effect}`, **deny-only inline — no catch-all allow needed**; base allows, proved v2.3.0). **Personal/primary agents that only read/write their notes dir MUST carry `- { action: shell, resource: "*", effect: deny }` as their FIRST rule** (the load-bearing exfil seal, see Personal Agents) — never an allow.
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
>
> **Preflight blind spot — `GEMINI_API_KEY` (advisory only since 2026-11-17):** the native `google` provider needs **no config entry**, so `GEMINI_API_KEY` appears in **no template placeholder** and is therefore **invisible to both the `_requires_env` pruning and the `oc` `${VAR}` preflight scan**. A missing key does not abort the build. **Since the ADR 0008 relocation NO running agent consumes this key at all** — it is retained, configured, as the rollback safety net to the native `google` provider (the homesrv sync is done and verified, 2026-11-17, so the net now covers both nodes only in principle: **whether the Pi's service actually carries the key is NOT verified** — `systemctl show opencode -p Environment` on the Pi returns only `PATH`, and that query does not display `EnvironmentFile=` variables, so it proves nothing either way). The `oc` preflight warning fires for an OPTIONAL key: informational, never a build blocker, never a runtime blocker for any current agent. Rollback-era sanity check (only meaningful after reverting `model_profiles.json` lines 12-18): `source ~/.secret_envs && opencode models | rg '^google/gemini-(4-hydrogen|3\.8-flash)$'`. Current-state sanity check for the live roster: verify resolved `id`+`variant` per agent in `session_message.data.model` (see **Model Profiles** — variant observability).

### Adding a New Plugin (V2 contract)

**Local plugin (preferred for personal tooling):**
1. Drop the file in `.config/opencode/plugins/` (`.ts` or `.js`). Contract:
   `export default Plugin.define({ id, async setup(ctx) { ... } })` from `@opencode/plugin` (^2.x).
2. It is **auto-discovered** — NEVER add it to the config `plugins` array (that array accepts npm packages/dirs only; file entries emit a `configured plugin path must be a directory` WARN).
3. Deploy: `opencode service restart`. A rebuild or hot reload does NOT re-register hooks/tools on live sessions.
4. Static-verify first: `tsc --noEmit` against installed `@opencode/plugin` typings (missing ambient `process`/`Bun` type errors are benign — injected by opencode's embedded runtime).

**Registry plugin (npm package):**
1. Add to the `plugins` array in `builder/templates/config/config.json` — plain `"pkg@X.Y.Z"` string (**pin exact versions — never `@latest`**; supply-chain integrity: `@latest` re-resolves silently on every fresh install, and `update: "notify"` means we choose when to bump), or `{ "package": "...", "options": {...} }` when it needs options (V1 tuple form is invalid). Resolve the pinned version from opencode's on-disk npm cache (`~/.cache/opencode/npm/<pkg>@latest/*/package.json`) or `npm view <pkg> version`. Same rule applies to `npx -y` MCP servers in `mcp.servers` (e.g. `@playwright/mcp@X.Y.Z`, resolved from the `~/.npm/_npx` cache).
   > **Sanctioned exception (user decision 2026-11-16):** `@plannotator/opencode` floats at `@latest` — machine parity with dotfilesMac, where the vendor installer itself rewrites the entry on every update. The `oc` guardrail `check_plugin_pins` (v0.6.0) knows this: floats pass the pin check, get TTL-cached registry freshness reporting (24 h, `stat -c %Y`, offline-silent), and are checked for drift by `up` step 7. **Every other package keeps exact pins.** Do not generalize this exception.
2. `oc --rebuild` then `opencode service restart`.

**Terminal/TUI plugin:** add to the `plugins` array in `cli.json` (currently empty — V1 TUI contracts are rejected by the V2 loader).

### Installed Plugins

**Live — registry packages (`plugins` array):**

| Plugin | Version | Purpose |
|--------|---------|---------|
| `opencode-snippets` | 3.4.0 | `#hashtag` snippet expansion |
| `@tarquinen/opencode-dcp` | 3.2.0 | Dynamic context pruning |
| `@plannotator/opencode` | `@latest` (float) | Plan/code review UI + Inbox; options `workflow:"plan-agent"`, `planningAgents:["commander"]` |

**Live — local auto-discovered (`.config/opencode/plugins/`):** `engram.ts`, `squeez.js`, `graphify.js`, `run-watch.ts` (tool `run_watch`), `yt-transcript.ts` (tool `yt_transcript`).

#### Plannotator — platform facts (2026-11-16, measured on Linux v2.3.0)

- **Float policy:** see the sanctioned exception in *Adding a New Plugin*. `planningAgents:["commander"]` was **provably inert below 0.28** (agent-switch dead-end bug); the float exists so the upgrade ships without a template edit.
- **`plannotator` CLI en PATH desde 2026-11-16** (`~/.local/bin/plannotator`, 0.28.66; `install.sh` revisado con sha256 antes de ejecutar — política review-before-execute cumplida, no `curl | bash` a ciegas). El **Inbox está operativo**: server loopback-only `127.0.0.1:34365`, datos en `~/.plannotator/inbox/`, OpenCode/Gemini CLI/Antigravity conectados, `inboxTool.opencode:true`, bloque vendor `v9` inyectado en AGENTS.md y espejado (force-added) en `docs/vendor/plannotator-inbox-v9.md`. Runbook upgrade: `.config/opencode/docs/vendor/plannotator-upgrade.sh`. Docs medidos: `docs/plannotator.md` (§9 Inbox).
- **The installer writes `commands/` (plural) inside the worktree** — `~/.config/opencode` is a symlink into this repo. `.gitignore` now carries `.config/opencode/commands/` so the acceptance test is `git status --porcelain` == empty after install. Tracked custom commands stay in `command/` (singular).
- **Frozen-cache resurrection (measured 2026-11-16):** after purging the stale `@plannotator` cache, the old resolved tree (`0.27.20`) can REAPPEAR before any restart — stale metadata re-resolves the old version. Never trust the directory name `@latest`: read `version` from the resolved `package.json` (must be ≥ 0.28 after upgrade). The runbook purges immediately before restart and asserts this.
- **`PLANNOTATOR_SHARE` env overrides the config `share` setting** at runtime (vendor install.sh writes it into `opencode.jsonc`). `share:"disabled"` in the config template is load-bearing for isolation; the env var can defeat it — know before exporting.
- **`opencode.jsonc` precedence (probe 2026-11-16):** a stray `opencode.jsonc` in the config dir is a LIVE config doc merged AFTER the generated `opencode.json` (per-key map merge — same scalar key in the jsonc wins). The global `config.json` name is DEAD in V2 (never loaded). Hence the `.config/opencode/opencode.jsonc` gitignore rule: installer state must not shadow the generated secrets-bearing config.
- **Inbox vs `question` precedence** lives in Commander doctrine (PHASE 2.5 of `prompts/commander_behavior.md`): interactive decisions NEVER park in the Inbox.

**Removed — account suspension (2026-11-15):**

| Plugin | Reason / disposition |
|--------|----------------------|
| `opencode-antigravity-auth@2.1.2` | Pulled from the `plugins` array: Google account `andy.tech.castro@gmail.com` suspended for ToS violation (third-party use of the Antigravity login), and the plugin's request path was broken by an upstream `systemInstruction` signature issue (PR #623 still unmerged). Port kit + revert evidence archived in `vendor/antigravity-port/` (`REVERT-2026-11-15.md`, `RESTORE.md`). See **Model Providers**. |

**Replaced by native V2 (removed 2026-09-26):**

| V1 plugin | Native replacement |
|-----------|--------------------|
| `opencode-autotitle` | `agent.title.model` = `{{MODEL:small_model}}` in config template |
| `opencode-notify` | `cli.json` `attention.notifications` / `attention.sounds` |
| `@ykaratkou/opencode-worktree` | V2 native `ctx.worktree` + `worktree.directory` |
| `envsitter-guard` | `permissions` deny rules on `*.env` / `*.env.*` (read+edit, 4 rules live in template) |

**Dropped — waiting on upstream V2 ports:** `opencode-vibeguard`, `@nick-vi/opencode-type-inject`, `opencode-claude-auth`, `opencode-sdd-engram-manage` (upstream issue #52), `opencode-subagent-statusline` (issue #97).

## 🔌 Model Providers — Google (Antigravity plugin RETIRED 2026-11-15 · native API key LIVE 2026-11-15, UNUSED by agents since 2026-11-17)

**Status: RETIRED (plugin) / NATIVE API KEY = rollback path only.** The registry plugin `opencode-antigravity-auth@2.1.2` was pulled from the `plugins` array, the `google` and `gemini` profiles were deleted from `model_profiles.json`, and `default_profile` became `opencodego`. **Since 2026-11-17 (ADR 0008) no agent uses the native `google` provider**: the 7 personal agents moved to the `opencode-go` gateway (`gemini-4-argon#medium` ×3, `gpt-6-luna` ×3, `mimo-v2.6-flash` ×1). `GEMINI_API_KEY` stays configured — documented rollback safety net, NOT removed — so everything below remains the verified record of how that path was built. Google models are reachable two legitimate ways: through the gateway as `opencode-go/gemini-4-argon`, and via opencode V2's **native `google` provider with `GEMINI_API_KEY`**.

- **Native `GEMINI_API_KEY` path: OPERATIVE 2026-11-15 → UNUSED 2026-11-17** (this was "the future path" in earlier revisions of this document — it was the shipped state 2026-11-15/16, and since ADR 0008 is the **rollback path only**). An AI Studio key exported as `GEMINI_API_KEY` activates opencode V2's **built-in** `google` provider: endpoint `generativelanguage.googleapis.com/v1beta`, `opencode models` lists **24 `google/*` models** (verified 2026-11-15). No plugin, no OAuth, no sidecar. E2E verified twice the same day: first with all 7 personal agents on `google/gemini-4-hydrogen` (`chef`, `barista` returned real hydrogen completions), then after the cost rebalance on `google/gemini-3.8-flash` (`barista` → model resolved = `gemini-3.8-flash`, `finish: stop`, cost **$0.0115185**). The full Commander prompt (17,936 tokens, containing the literal `session_move` string) finished `stop` with zero errors against the official API. The ADR 0008 relocation was **not** a failure of this path — it was the one-invoice decision; nothing here is retracted, only re-dated.
- **Why this is ToS-legitimate while Antigravity was not:** the account suspension and the **false-429 filter** (`tools.opencode.session_move` in every `systemInstruction`) live exclusively in the Antigravity product edge — `cloudcode-pa.googleapis.com` / `daily-cloudcode-pa.googleapis.com`. The official `generativelanguage` endpoint digests the same prompt without complaint. **No traffic to `*-cloudcode-pa.googleapis.com` from THIRD-PARTY CLIENTS remains permitted** — the rule scoped here is the retired `opencode-antigravity-auth` plugin path and anything shaped like it: the `google_search` MCP must stay out, and **the Antigravity OAuth login must never be used from a third-party client**. The appeal is unaffected by API-key traffic (separate product, separate billing). **Re-scoped 2026-11-17:** an earlier blanket reading of this sentence ("zero traffic to those endpoints, full stop") is FALSE BY BEHAVIOR — first-party `/usr/bin/agy` authenticates via keyring and legitimately emits `daily-cloudcode-pa.googleapis.com/v1internal:loadCodeAssist` + `:fetchAvailableModels` (verified in `~/.gemini/antigravity-cli/log/cli-20261117_171211.log`). First-party Antigravity CLI usage is a different, legitimate product surface; the ban covers third-party use of the Antigravity login, nothing more. **This ban is self-contained: the retired third-party path (the `opencode-antigravity-auth` plugin, any `google_search` MCP, or any client shaped like them) must NEVER be re-enabled without a new explicit user decision — "first-party traffic is legitimate" is not a precedent that authorizes third-party use of these endpoints, and no agent may read this paragraph as such.**
- **Cost model (historical — 2026-11-15 → 2026-11-16, verbatim record; superseded 2026-11-17 by ADR 0008):** API-key usage was billed against the **prepaid balance on the GCP account**, not a subscription — and **AI Pro would not change these limits**: Gemini API tiers advance on **accumulated spend history** (free → 1 → 2 → 3), per the official [billing](https://ai.google.dev/gemini-api/docs/billing) / [rate-limits](https://ai.google.dev/gemini-api/docs/rate-limits) docs. **State verified 2026-11-15: tier 2**, reached with a **€5 top-up**; live limits **100K RPD per model** (`gemini-3.8-flash` 5/100K, `gemini-4-hydrogen` 5/100K, `gemini-3-flash` 2/100K), ~2,000 RPM, ~3M TPM. `gemini-4-hydrogen` is not cheap per token, which is why the roster was **rebalanced the same day (2026-11-15)**: the 4 factual/lookup agents moved to `gemini-3.8-flash` (measured 2–3× cheaper, paid standard $0.75/1M input · $3.75/1M output) while the 3 sensitive/reflective agents stay on hydrogen. The two models still give **two independent per-model quota pools** (an architectural property), but at tier 2 that is not what protects the workload — **the balance is**: ~$0.003–$0.023 per personal turn means €5 ≈ hundreds of turns, and at **zero balance every `google/*` agent halts with HTTP 402**. **Auto-recharge was intentionally OFF** so the stop is hard. Projected mixed cost was **≈ $25/month** under the observation window that started 2026-11-15 — **that projection is obsolete**: since 2026-11-17 the personal agents run on the gateway (measured workload ≈ $0.75/month equivalent; Google API spend $0) and budget control moved to per-model ceilings + a burn detector (see **Model Profiles**). Rollback = revert the affected values in `model_profiles.json` (lines 12-18) and rebuild (~2 min) — still valid, now the documented rollback path. **Privacy rider (historical):** **paid tiers (1/2/3) did not use submitted content for training; the free tier did**. That regime came from the tier (accumulated spend), so the top-up is what put the personal agents in it. Depleting the balance is a documented **availability** event (`HTTP 402`), **not** a documented tier demotion — do not claim the latter. The privacy counterparty is now the gateway, under *"By default, Go blocks paid endpoints that train on your requests"* (account-level setting; see ADR 0008). Historical detail: free-tier RPD reset at **midnight Pacific**.
- **Provider gotchas (proved 2026-11-15; relevant only on the rollback path since 2026-11-17):** (1) `gemini-4-hydrogen` needs a **generous `maxOutputTokens`** — reasoning tokens are consumed from the output budget, so small budgets return empty/truncated answers (probes needed ≥800 output tokens). (2) `gemini-3.8-flash` hit a **transient 503 `high demand`**; retry resolves it, and a lower tier is the workaround if it persists. (3) Quotas are counted **per model**, so a flash-pool 429 does not touch the hydrogen agents and vice versa — but at **tier 2 (100K RPD/model)** a genuine 429 is an anomaly, not normal wear: suspect another app sharing the key, or an RPM (~2K) burst, before blaming personal usage. (4) **HTTP 402 ≠ key failure**: it means the prepaid balance is exhausted, and because auto-recharge is off, it takes **all** `google/*` agents down together.
- **Trigger (why the plugin died):** the Google account `andy.tech.castro@gmail.com` was **suspended for a Terms of Service violation** — third-party clients using the Antigravity login are not permitted. Appeal filed 2026-11-15 with an explicit non-repetition commitment. Until reinstatement, nothing from **our third-party tooling (opencode, the retired plugin, any sidecar)** is sent to `daily-cloudcode-pa.googleapis.com` / `cloudcode-pa.googleapis.com` (first-party `agy` CLI traffic is the legitimate exception — see the ToS bullet above).
- **Root cause of the failures (upstream, still open):** the OpenCode V2 binary injects the literal string `tools.opencode.session_move` into every `systemInstruction` (Code Mode catalog). The Google edge answered that with a **false 429 `RESOURCE_EXHAUSTED`** — not a quota event — the plugin dropped to its gemini-cli fallback, which returned **403 `SUBSCRIPTION_REQUIRED` (#3501)**, and it surfaced as `Error: Forbidden`. Tracked upstream: **PR #623 (OPEN, unmerged)** in `NoeFabris/opencode-antigravity-auth`; our evidence is published in **issues #621 / #622** (2026-11-15). **This defect does not apply to the native API-key path** — it was an artifact of the cloudcode edge, and the official endpoint accepts the identical prompt.
- **Backport proven, then reverted:** a hand-applied PR #623 sanitizer in the npm cache flipped 429→200 end-to-end, and was reverted to pristine 2.1.2 the same day. Kit: `vendor/antigravity-port/` — `REVERT-2026-11-15.md` (sha256 + `cmp` verification of the reverted files), `RESTORE.md` (re-apply **only after** account reinstatement), `backup/request.js.registry-original`. Prefer an upstream npm release over re-patching: the patched cache path is ephemeral (lost on version bump / npm cache GC).
- **Decision retained (do NOT "clean up"):** `experimental.policies` still carries `{action: provider.use, resource: "google", effect: allow}` after the catch-all deny. Since 2026-11-15 this rule was **load-bearing**: it is what let the personal agents (then pinned to `google/gemini-4-hydrogen` ×3 and `google/gemini-3.8-flash` ×4) talk to the native provider with `GEMINI_API_KEY`. **Since 2026-11-17 (ADR 0008) nothing running consumes `google/*`, so the rule is NO LONGER load-bearing — it is retained solely as the documented rollback/safety-net path.** Do not delete it: removing it would close the rollback door the ADR deliberately leaves open, and would also break any `google/*` model if the profile is ever reverted. It also still covers a possible future Vertex ADC path. The other 27 `tool.use` policy floors are unchanged. **Never** confuse it with Antigravity OAuth — that path stays dead.
- **History (facts that stay true):** native V2 has no consumer Google OAuth — Google killed it 2026-06-18; native `google` = paid API key (in production for the personal agents 2026-11-15 → 2026-11-16, **rollback path only since 2026-11-17**), `vertex` = ADC. The plugin (NoeFabris, MIT) registered under the native `google` provider with `antigravity-*` model ids and an account-discovered catalog (1 h cache); V2-native support landed 2026-10-27; the CLIProxyAPI sidecar it superseded was torn down 2026-10-30 and the config template `providers` block has been `{}` since (the native `google` provider needs no `providers` entry — it is built into the binary and keyed by `GEMINI_API_KEY`). The `/antigravity` (`/ag`) in-app command is gone with the plugin.
- **Credential gotchas (still valid, provider-agnostic):** the V2 source of truth for credentials is the `credential` table in `~/.local/share/opencode/opencode.db` (`auth.json` is a mirror only); `opencode auth logout <provider>` needs the credential ID or it hangs in non-TTY; env-var diagnostics require an isolated `opencode serve --port`, because the systemd service does not carry them (historically `OPENCODE_ANTIGRAVITY_DEBUG=1`). **For the API-key rollback path (not active since 2026-11-17):** `GEMINI_API_KEY` must exist in the *process* environment of the daemon — live in `~/.secret_envs` (chmod 600), and on homesrv in the **systemd SYSTEM unit** (`opencode.service`) environment. A rebuild alone does not deliver env vars. Whether the Pi's unit currently carries the key is **NOT verified**: `systemctl show opencode -p Environment` returns only `PATH`, and that query does not display `EnvironmentFile=` variables — do not conclude either way from it.
- **Discontinued practice:** copying `~/.config/opencode/antigravity-accounts.json` between nodes over ssh (the old refresh-token migration trick) — stopped with the account. The file is dead state; it stays gitignored, never synced.

### No error-based model fallback in V2 (platform limitation — documented 2026-11-15)

**Decision: document only.** The user explicitly declined to build a fallback mechanism; nothing below is implemented, and nothing must be invented later without a new plan.

OpenCode V2 (checked statically against `v2.3.0`) has **no `fallbacks: [modelA, modelB]` config for chat**. There is no key that says "if this model errors, retry on that model". What actually exists:

| Mechanism | Trigger | Semantics |
|-----------|---------|-----------|
| **Availability degradation chain** | configured model **not available** (not an error) | `variant` → `agent-model` → **account default**, resolved silently — the reason a wrong-model bug looks like "it just works". |
| **"Newest available supported model"** | the *root* model of a catalog entry is unavailable | opencode substitutes the newest supported model instead of failing. |
| **Internal transient retry** | 429 / 5xx | Same model, same request — surfaces as `retry 1/5`. Not a model switch. |
| **`experimental.image_generate`** | image generation | The **only** documented per-model failover in the platform: it picks a different image model. Not applicable to chat. |

**Consequences for the current roster (ADR 0008, 2026-11-17):** all 15 agents now resolve through `opencode-go`, so the cross-provider rollover question is moot for the running system — a personal agent on `gemini-4-argon#medium`, `gpt-6-luna#*`, or `mimo-v2.6-flash` that hits a **429/400 kills the turn in place**; there is **no rollover** to another gateway model, and moving traffic to a `*-free` model is **MANUAL** (or a deliberate `model_profiles.json` edit + rebuild). The `gpt-6-luna` trio (`chef#medium`, `barista#none`, `habitos#low`) shares one **$60/month** allowance, and the `gemini-4-argon` trio (`finanzas`/`life`/`coach`) shares the roster's tightest request window (**2,260 req/5h**), so burst saturation of either shared pool is the realistic new failure mode; the third pool (`mimo-v2.6-flash`, `organiza`) keeps working while the other two are blocked — independent pools, still **not** a failover pair. Historical (2026-11-15/16, mixed profile): a `google/*` personal agent hitting 429/503 or a truncated-budget response failed in place — it did not roll over to `opencode-go`, and **not even to the other Google tier**; and an exhausted prepaid balance (`HTTP 402`) took all 7 personal agents down together while the gateway agents kept working — the only sense in which the two providers were "redundant", and it was **manual** (edit the affected keys back to `opencode-go`, rebuild). If a real automatic failover is ever needed, the only supported shape is a **router in front of the providers** — self-hosted LiteLLM, or OpenRouter with `models: [primary, fallback]` — wired through `providers.*.settings.baseURL`; the platform itself will not do it.

## 🤖 Agent Roster & Permissions

### Agent Roles

All agents resolve through the `opencodego` profile (the only one). Since 2026-11-17 (ADR 0008) **all 15 agents are on `opencode-go`**: the 8 technical agents + `model` + `small_model` on `opencode-go/qwen3.8-flash`, and the 7 personal agents via `provider/model#variant` — **3 on `gemini-4-argon#medium`, 3 on `gpt-6-luna` (variants `#medium`/`#none`/`#low`), 1 on `mimo-v2.6-flash` bare**. (The former state — 2026-11-15/16 — had the personal agents on the native `google` provider; that is now the rollback path.) Model column = compiled value:

| Agent | Model | Role | Mode |
|-------|-------|------|------|
| `commander` | opencode-go/qwen3.8-flash | **Pure Orchestrator**. 0 lines edited. Plans, specs, delegates, gates, verifies. | primary |
| `PE` | opencode-go/qwen3.8-flash | Platform Engineer. Infra (IaC), CI/CD, containers, dev tooling, platform glue. | subagent |
| `go_architect` | opencode-go/qwen3.8-flash | Go specialist. Clean Architecture, SOLID, high-performance concurrency. | subagent |
| `python_architect` | opencode-go/qwen3.8-flash | Python specialist. Type-safe (3.12+), uv, ruff, Pydantic v2, clean architecture. | subagent |
| `frontend_architect` | opencode-go/qwen3.8-flash | UX/UI + Frontend. Next.js 15, React 19, nuqs, TanStack Query, WCAG 2.2. | subagent |
| `qa_architect` | opencode-go/qwen3.8-flash | QA SDET. Testability audit, property-based, contract tests, regression. | subagent |
| `security_architect` | opencode-go/qwen3.8-flash | Security auditor. STRIDE threat model, AST taint, secrets, IaC hardening. | subagent |
| `doc_architect` | opencode-go/qwen3.8-flash | Documentation architect. Goldfish spec audit, ADRs, contracts, graphify. | subagent |
| `finanzas`, `life`, `coach` *(personal — sensitive/reflective, 3)* | opencode-go/gemini-4-argon#medium | Personal context agents (notes in `~/notas/<agent>/`). Gateway flagship at `#medium` for money/wellbeing/training reasoning; unified id+variant so all three share one pool and one rollback line (ADR 0008). No shell. | primary |
| `chef`, `barista`, `habitos` *(personal — factual/lookup, 3)* | opencode-go/gpt-6-luna (`#medium` chef · `#none` barista · `#low` habitos) | Personal context agents (notes in `~/notas/<agent>/`). Variants are **latency/depth selectors, not cost levers**. Shared luna allowance: **$60/month** (16,900 req/5h). No shell. | primary |
| `organiza` *(personal — factual/lookup, 1)* | opencode-go/mimo-v2.6-flash **(bare — NO suffix)** | Task/organizing lookups. That model exposes no effort variants — any suffix yields `provider.no-route` at session start. Resolved variant is ABSENT. No shell. | primary |
| `explore` *(native)* | `{{MODEL:small_model}}` | Fast recon subagent. Broad codebase searches and pattern discovery. | native subagent |

> **Native OpenCode Agents Policy:**
> - `explore`: Active and pinned to `{{MODEL:small_model}}` (in `opencodego`: `opencode-go/qwen3.8-flash`) for cost-efficient mass workspace searches.
> - `general`, `build`, `plan`: **Explicitly disabled** (`"disabled": true` in `config.json`). All planning belongs exclusively to `commander`, and all build/code modifications must route to domain-specialized architects, preventing unspecialized fallback hallucinations.
> - `title`: Built-in agent pinned to `{{MODEL:small_model}}`.
> - Personal agents (`finanzas`, `organiza`, `habitos`, `life`, `coach`, `barista`, `chef`) run on the **`opencode-go` gateway** under the `opencodego` profile since 2026-11-17 (ADR 0008; 2026-11-15/16 they were on the native `google` provider), via `provider/model#variant`: `gemini-4-argon#medium` for the 3 sensitive/reflective ones (`finanzas`, `life`, `coach`), `gpt-6-luna#medium|#none|#low` for 3 of the factual ones (`chef`, `barista`, `habitos`), `mimo-v2.6-flash` bare for `organiza`. All are **remote** models — the vendor changed twice, the rule did not — which is why their shell catch-all stays `deny` (see Personal Agents). Before 2026-11-15 all 7 were on `opencode-go/qwen3.8-flash`; a Vertex ADC path would also be remote. **The hardening rule is provider- and tier-independent: a local model would be the only case that weakens it, and there is none.**

### 🔄 Shift-Left Architecture & Verification Lifecycle (Phase 1.5 & Phase 4)

To prevent structural debt and hallucinated implementations, the platform enforces an end-to-end Shift-Left engineering lifecycle:

```mermaid
flowchart TD
    User([User Request]) --> P1[Phase 1: Strategic Reconnaissance\nCommander + explore]
    P1 --> P15[Phase 1.5: Shift-Left RFC & Spec Audit\nGoldfish Review]
    
    subgraph GoldfishReview [Multi-Pillar Goldfish Audit]
        direction TB
        DA[doc_architect\nContract Lock & ADR Proposed]
        QA[qa_architect\nTestability & Failure Matrix]
        SA[security_architect\nSTRIDE Threat Model]
        Domain[Domain Architects\nGo / Python / Frontend / PE Specs]
    end
    
    P15 --> GoldfishReview
    GoldfishReview --> P2[Phase 2: Master Plan Approval\ntodowrite + Plannotator submit_plan]
    P2 --> P3[Phase 3: Specialized Orchestration\nAtomic delegation to domain sub-agents]
    P3 --> P4[Phase 4: Synthesis & Certification]
    
    subgraph CertificationGates [Phase 4 Quality Gates]
        direction TB
        SDC[doc_architect: Spec Drift Check\ngit diff vs RFC + ADR Accepted + graphify]
        QAC[qa_architect: Regression Suite\nProperty-based & contract tests]
        SEC[security_architect: Security Audit\nTaint analysis & secret scan]
    end
    
    P4 --> CertificationGates
    CertificationGates --> Release[Commander: Final Review & Git Release]
```

1. **Commander Pure Orchestrator Boundary (0 Code Lines):** Commander NEVER edits code, configuration, markdown, or scripts directly. 100% of file modifications belong to sub-agents. Commander reads files, scopes requirements, authors English RFCs/specs, manages `todowrite`, delegates via `subagent`, reviews diffs, runs quality gates, and handles release commits.
2. **Phase 1.5 Shift-Left RFC & Turn-1 Pre-Plan Consultation Protocol:**
   - **Elephant-Goldfish Model (EGM) & Devil's Advocate Mandate:** Commander is the Elephant (long-term context, strategic memory via Engram, user rapport). Phase 1.5 subagents are Goldfish (stateless, clean context, zero unstated assumptions). All Phase 1.5 subagent delegations MUST be prefixed with `[MODE: DEVILS_ADVOCATE_PHASE_1_5]`. Subagents act as hostile reviewers ("Abogados del Diablo") to pressure-test specs before any code is modified. Passive approvals ("LGTM", "looks good", rubber-stamping) are strictly banned.
   - **Mandatory 3-Section Output Contract:** Every Phase 1.5 subagent response must strictly adhere to:
     * **(A) Challenged Assumptions & Unstated Invariants:** Minimum 1 implicit assumption, unverified prerequisite, or missing architectural invariant actively attacked.
     * **(B) Concrete Failure Modes (Min 2-3 scenarios):** Grounded failure cascades using concrete spec symbols, file paths, and interfaces (`Trigger -> Failure Cascade -> Blast Radius` + Root Cause).
     * **(C) Probing Architectural Questions & Trade-offs:** Explicitly split into:
       - **C.1 Technical Invariants:** Internal architecture contracts, consistency models, and boundaries for Commander to resolve directly in the RFC.
       - **C.2 Product / Risk Decisions:** Business trade-offs, UX alterations, or operational risks that Commander CANNOT decide autonomously and MUST escalate to the user via `question`.
     * **Verdict:** Explicitly conclude with `BLOCKED`, `CHALLENGED`, or `CERTIFIED_WITH_MITIGATIONS`. Unconditional certification without mitigations is prohibited.
   - **Anti-Sycophancy Rejection Gate:** Commander is strictly forbidden from accepting passive agreements. If a subagent response lacks sections (A), (B), (C) or a valid VERDICT, Commander MUST reject the response and enforce an adversarial audit.
   - **Bounded Negotiation & Static Audit Invariants:** Maximum 2 review rounds per specialist to avoid deadlock and token exhaustion. Phase 1.5 is strictly static analysis (AST inspection, `rg`, `fd`, `bat`). No dynamic test runs, untrusted scripts, or file/code edits on disk before Phase 3.
   - **Lone Wolf Prevention:** Plans created in isolation without specialist intelligence are prohibited. Commander NEVER authors a master plan blindly.
   - **Prerequisite Boundaries (Zero Disk Writes):** Read-only reconnaissance (Phase 1) and Shift-Left specialist consultation (Phase 1.5) via `subagent` do NOT modify files on disk and do NOT require prior plan approval; they are mandatory inputs to create the plan. What is strictly forbidden without user approval is Phase 3 implementation (file/code edits on disk).
   - **Turn-1 Consultation Obligations (Pre-`submit_plan`):**
     * **Ambiguities & Trade-offs:** Commander MUST call `question` to clarify user requirements and trade-offs before locking architecture.
     * **Multi-Pillar Audits via `subagent`:**
       - `doc_architect` (Goldfish Spec Auditor): Reads spec with zero assumptions, eliminates ambiguities, locks OpenAPI/JSON Schema contracts, updates `graphify`, and drafts ADR specification in memory/RFC context with status `Proposed` (strictly NO file writes to disk before plan approval).
       - `qa_architect`: Audits testability, models failure matrices (network, DB, concurrency), defines acceptance test contracts.
       - `security_architect`: Executes STRIDE/PASTA threat modeling, identifies privilege escalation, auth gaps, and data leakage channels.
     * **Mandatory Domain Invocation Matrix (Zero Exceptions):**
       Eliminates all optional/selective review. Calling the corresponding specialist in Phase 1.5 BEFORE drafting the plan is mandatory whenever a task touches their domain:
       - **Touches Go:** MUST invoke `go_architect` (package layout, interfaces, iterators, goroutines, mutexes, memory overhead, `hex_check.go` invariants).
       - **Touches Frontend / UI / Web (React, Next.js, Tailwind, DOM):** MUST invoke `frontend_architect` (Server vs Client components, App Router, state management, TanStack Query, accessibility WCAG 2.2, layout ergonomics).
       - **Touches Python:** MUST invoke `python_architect` (Pydantic v2 schemas, strict type hints, async TaskGroups, exceptions, uv/ruff conventions).
       - **Touches Infra / Docker / CI/CD / Tooling:** MUST invoke `PE` (deployment topology, container specs, resource limits, CI pipeline jobs).
     * **Strict Domain Architecture Prohibition:** Commander is STRICTLY FORBIDDEN from architecting Go packages, frontend component hierarchies, or Python models in isolation without the domain architect's Phase 1.5 Goldfish design.
     * **Specialist Evidence in Plan:** The Master Plan (`submit_plan`) must explicitly cite the domain architect's design decisions alongside QA failure matrices, Security threat boundaries, and locked schema contracts.
3. **Phase 2 Master Plan Approval & Plannotator Invariants:**
   - **Mandatory Spanish Invariant:** Every plan submitted to Plannotator (`submit_plan`) MUST be written **EXCLUSIVELY IN SPANISH** (Castellano claro y técnico). While backend RFCs or technical specs in the repo are in English, user-facing plans presented in the browser review UI must always be in Spanish.
   - **Final Plan Only (Zero Preliminary Plans):** `submit_plan` MUST ONLY be called when the plan is **100% FINAL AND DEFINITIVE**. All Phase 1.5 subagent consultations (to investigate, refine, or shape architecture) and all user inquiries (`question`) MUST be completed BEFORE calling `submit_plan`. Submitting preliminary or placeholder plans stating that subagents will be consulted later is strictly forbidden. Plannotator receives only the finalized battle plan ready for Phase 3 execution.
   - **Approval Gating:** Plannotator approval (`Plan approved!`) constitutes explicit user authorization to transition into Phase 3. Commander is strictly forbidden from proceeding to Phase 3 without explicit approval (via Plannotator or chat fallback).
4. **Phase 3 Specialized Orchestration & ADR Materialization:**
   - Commander delegates implementation atomically to leaf sub-agents via `subagent`.
   - `doc_architect` writes the formal ADR file to `docs/adr/NNNN-<title>.md` with status `Proposed` alongside implementation artifacts.
5. **Phase 4 Spec Drift Check & Multi-Pillar Certification:**
   - `doc_architect`: Compares full `git diff` against the approved RFC (Spec Drift Check). Zero undocumented drift permitted. Promotes ADR from `Proposed` to `Accepted`, updates `CHANGELOG.md`, and synchronizes AST knowledge graph (`graphify update .`).
   - `qa_architect`: Executes regression suites, property-based tests, and verifies zero regressions.
   - `security_architect`: Verifies secrets, AST taint analysis, and validates IaC security posture.

### Permissions Model (V2 Native)

V2 agent frontmatter uses a `permissions:` **ordered LIST** of `{action, resource, effect}` entries — NOT the legacy singular `permission:` map. Legacy top-level fields (`permission`, `tools`, `temperature`, `top_p`, `prompt`, `disable`, `maxSteps`): the singular `permission:` map was IGNORED in the 2026-10-04 audit (a PE subagent executed `git stash list` / `git add` / `git commit` despite its denies) and by v2.3.0 it is AUTO-MIGRATED to the list form — but the LIST is the contract; never hand-write legacy fields. Action names in V2: `shell`, `edit` (covers write/patch), `read`, `glob`, `grep`, `webfetch`, `websearch`, `subagent` (resource = child agent ID), `external_directory` — **these documented names ARE what the v2.3.0 runtime evaluates (proved dynamically 2026-11-16; the old `bash`/`task` twin doctrine is RETIRED, see below).**

**Deny-only inline layout (since 2026-11-16).** NO catch-all `allow` rule is needed: measured on v2.3.0 (isolated Basic-auth probes, 17/17), no matching rule → **ALLOW** — the documented `?? ask` default never materializes and headless agents cannot deadlock on approval prompts. Every explicit deny is hard and silent: `Permission denied: <action>`, tool never executes, zero prompts. Entries are inline-flow (`- { action: shell, resource: "curl*", effect: deny }`); among denies, last-match-wins. Shell resources match RAW command text (no `~`/`$HOME` expansion). The `write: ask` / `edit: ask` scalars stay dropped — under the now-proven engine they would prompt-block subagent editing. `experimental.policies` supports MULTIPLE actions (proved: `provider.use`, `tool.use`, and more — the old "only provider.use" claim is retired); `tool.use "<action>:<glob>"` floors evaluate BEFORE any agent rule and emit `Blocked by configuration policy`. File/secret enforcement now lives in **27 floors** in the config template (read/edit/shell × `*.ssh*`, `*.env*`, `*.secret_envs*`, `*.netrc*`, `*.config/gh/hosts.yml*`, `*auth.json*`, `*opencode.db*`, `*cli-proxy-api*`, `*.config/opencode/opencode.json*`) — the global top-level `permissions` array was REMOVED: redundant under floors, and the floor set is strictly stronger (adds shell coverage — closing the measured HIGH bypass `cat ~/.ssh/id_rsa` — plus `opencode.json`/`cli-proxy-api`/`netrc` paths the array missed; Mac's typo `*.secrets_env*` corrected to `*.secret_envs*`). Accepted cost: floors cannot express allow-lifts, so `*.env*` also blocks `.env.example` reads — and the `shell` floor on `*.secret_envs*` blocks `source ~/.secret_envs` from inside any agent (intentional: secrets must already be in the daemon's process env, loaded by the terminal's `~/.zshrc` before opencode starts; agents never touch the file).

**Dual vocabulary — RETIRED 2026-11-16 (do NOT reintroduce).** The old doctrine claimed the daemon evaluated shell under `bash` and spawns under `task`, forcing adjacent twins in every template (commander 8+8, work agents 23+23, personal 21+21). The 2026-11-16 dynamic campaign proved the opposite on v2.3.0: **docs-names (`shell`, `subagent`, `webfetch`) fire; `bash:`/`task:` entries are dead code.** Twins stripped from all 15 templates, from config floors, and from `_subagent_permissions.md`. The 2026-10-04 "shell rules loaded yet never matching" evidence belonged to the legacy-map era, not the list era. If a future version flips enforcement again, re-run the probe BEFORE duplicating anything.

#### Commander (Full Access)
```yaml
permissions:  # deny-only inline — base allows, no catch-all needed (proved v2.3.0)
  - { action: shell, resource: "rm -rf /", effect: deny }
  - { action: shell, resource: "rm -rf *", effect: deny }
  - { action: shell, resource: "rm -rf /*", effect: deny }
  - { action: shell, resource: "mkfs*", effect: deny }
  - { action: shell, resource: "dd *", effect: deny }
  - { action: shell, resource: "sudo rm*", effect: deny }
  - { action: shell, resource: "chmod -R 777 /", effect: deny }
```
Full deny set: `rm -rf /`, `rm -rf *`, `rm -rf /*`, `mkfs*`, `dd *`, `sudo rm*`, `chmod -R 777 /`. The Commander is the orchestrator — it needs unrestricted bash access to coordinate, commit, and deploy.

#### Sub-Agents (Read + Build — No Git Write, No Network, No Subagent Spawning)
```yaml
permissions:  # deny-only inline, single docs-named entries (no twins since 2026-11-16)
  - { action: shell, resource: "git push*", effect: deny }
  - { action: shell, resource: "curl*", effect: deny }
  # Leaf hardening: no grandchild spawns, no web egress — deny ALSO filters the model's tool catalog
  - { action: subagent, resource: "*", effect: deny }
  - { action: webfetch, resource: "*", effect: deny }
  - { action: websearch, resource: "*", effect: deny }
```
Full deny set: destructive ops (same 7 as Commander) + `git add/commit/push/pull/merge/rebase/reset/checkout/stash/cherry-pick` + `curl`/`wget`/`nc` + `security`/`sysctl` (macOS relics kept as zero-cost documentation) + `subagent` (`*`) + `webfetch`/`websearch` (`*`) — single docs-named entries, no twins since 2026-11-16. Denying `subagent`/`webfetch`/`websearch` ALSO filters them from the model tool catalog. Sub-agents can read files, search, build, test, and edit — but cannot write to git, make network calls, access macOS security APIs, or recursively spawn child subagents. This enforces pure leaf execution: all task decomposition remains strictly in the hands of the Commander.

#### Personal Agents (No Shell — hardened 2026-10-27 · models switched 2026-11-15, then relocated to the gateway 2026-11-17, ADR 0008)

The 7 personal agents (`finanzas`, `organiza`, `habitos`, `life`, `coach`, `barista`, `chef`) have **`shell`/`bash` `"*"` set to `deny` as the FIRST rule** — not `allow`. They only need `read`/`edit` on their own `~/notas/<agent>/` directory plus Engram.

**Why:** personal agents run on a **remote** model — since 2026-11-17 the `opencode-go` gateway (`gemini-4-argon#medium` for `finanzas`/`life`/`coach`, `gpt-6-luna#*` for `chef`/`barista`/`habitos`, `mimo-v2.6-flash` bare for `organiza`; ADR 0008), from 2026-11-15 to 2026-11-16 the native `google` provider, before that `opencode-go/qwen3.8-flash`; any provider reachable over HTTPS is remote, so the rule does not depend on which vendor **or which tier** is active. Under the old layout the `shell "*": allow` catch-all let `cat ~/.secret_envs` execute as plain bash, bypassing the global `read`/`edit` secret denies and streaming secrets into a remote model's context. That was a **HIGH** finding in the `barista` security audit — structural debt inherited from `coach`, not specific to any one agent. With a catch-all `deny` first, the secret-exfil-by-shell channel is closed at the source.

> **Data-path note (ADR 0008, 2026-11-17):** the 7 personal agents' prompt/response traffic flows through the **`opencode-go` gateway** again — same counterparty as the technical agents. From 2026-11-15 to 2026-11-16 that traffic went to **Google AI Studio under `GEMINI_API_KEY`**; that window is closed and the key is retained only as the rollback path. The shell hardening is unaffected (the exfil channel was the local shell, not the vendor), but the privacy control changed shape: what leaves the machine is personal notes + conversation sent to the gateway, and the governing guarantee is the account-level setting *"By default, Go blocks paid endpoints that train on your requests"* — **not** a Google billing tier. The old tier reasoning (paid tiers 1/2/3 do not train; free tier does) is **HISTORICAL** and must not be reused as current justification; per-workspace residency/training settings are invisible to the CLI and the builder (see **Model Profiles** and ADR 0008). Do **not** infer "cheaper model = safer data" — the model/variant choice was cost/latency/depth, never a data-sensitivity control; residency policy did veto one candidate (`deepseek-v4.1-flash` for `habitos`, excluded outside EU/US). Their `webfetch` posture is still per-agent: `barista`/`coach`/`chef` are web-open, the other four are sealed (see below) — note that the web-open/sealed groups **cut across** the model groups (`coach` is web-open on `gemini-4-argon#medium`; `organiza`/`habitos` are sealed on `mimo-v2.6-flash`/`gpt-6-luna#low`), so never use one grouping to reason about the other.

The per-command denies below the catch-all are retained as **documentation of intent** (and as defense-in-depth if a future refactor reintroduces a scoped allow). **No `allow` rule may follow the catch-all deny** — last-match-wins would silently re-open the hole (the exact defect proved in the 2026-10-04 audit). Since 2026-11-16 personal templates carry NO twins and the redundant per-command shell denies were consolidated into the blanket `"*"` deny + intent comments (docs-names fire; see retired dual-vocabulary note).

**Network egress (web tools) is per-agent, not blanket:** `finanzas`, `organiza`, `habitos` and `life` carry explicit `webfetch`/`websearch` `"*"` denies (sealed group — their `permissions:` blocks are byte-identical, md5 `139ddbd38e7213faf3c186b2224b69e0`). `barista`, `coach`, and `chef` are **intentionally web-open** (user decision 2026-10-27: they research machine manuals/specs, food and training recipes) — their templates simply omit the two web deny rules and carry a comment marking the exception. Any new personal agent defaults to SEALED; opening web requires an explicit user decision recorded in the template comment.

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
- `.config/opencode/antigravity-accounts.json` — legacy OAuth tokens (access/refresh) of the **retired** `opencode-antigravity-auth` plugin (2026-11-15). NEVER in git; the node-to-node ssh copy was discontinued with the account
- `~/.secret_envs` — single source of secrets, sourced by `~/.zshrc` (chmod 600, outside repo)
- `.config/opencode/commands/` — Plannotator vendor installer output (plural; the tracked custom commands live in `command/` singular). Added 2026-11-16 after the installer polluted the worktree on the Mac twin
- `.config/opencode/opencode.jsonc` — installer-written config (V2 merges it as a LIVE doc after `opencode.json`; see Plannotator platform facts)
- `.local/*` except `!.local/bin/` + `!.local/bin/up` — 4-line exception block so ONLY the `up` updater is tracked from `~/.local`
- `docs/` — Tony's deliberate convention: local ADRs/specs kept out of git (ADRs 0001-0007 exist on disk untracked by design). Platform docs that MUST ship (`docs/plannotator.md`, `docs/vendor/plannotator-upgrade.sh`) are force-added per-file with `git add -f`; never flip the global `docs/` rule to `docs/*` (would unignore every nested docs dir)

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
| Command unexpectedly blocked | `Permission denied: <action>` = frontmatter deny matched (last-match-wins among denies; raw-text globs, `*` crosses `/`). `Blocked by configuration policy` = `tool.use` floor. There is NO missing-catch-all failure mode since 2026-11-16: no-match → ALLOW |
| Custom command uses disabled agent | Check `command/*.md` — ensure `agent:` field points to an enabled agent |
| Builder uses deprecated Go APIs | Use `os.ReadFile`/`os.WriteFile`/`os.ReadDir` instead of `ioutil` |
| Model profile not found | Check `model_profiles.json` — profile name must match exactly. Only `opencodego` exists since 2026-11-15 (`google`/`gemini` deleted). Use `oc --set-current opencodego` or `MODEL_PROFILE=opencodego` |
| Unknown model key warning | Template uses `{{MODEL:xxx}}` but key is missing from active profile in `model_profiles.json` |
| Engram plugin not working | Ensure `engram` binary is installed (`yay -S engram-bin`) |
| `failed to load plugin` at boot | Plugin not on V2 contract (must `export default Plugin.define`) or stale config entry — single-file plugins must NEVER be listed in the config `plugins` array |
| Plugin/tool changes have no effect | `opencode service restart` — hot reload/rebuild does not re-register hooks on live sessions |
| `Error: Forbidden` / 403 `SUBSCRIPTION_REQUIRED` on a `google/antigravity-*` model | **Historical** — that path was retired 2026-11-15 (account ToS suspension; false 429 caused by the `tools.opencode.session_move` string in every `systemInstruction`; upstream PR #623 unmerged, issues #621/#622). Use `opencode-go/gemini-4-argon` (the gateway, where the personal agents actually run since ADR 0008) or, as rollback only, the native key path (`google/gemini-4-hydrogen`, `google/gemini-3.8-flash`). The ids still appearing in `opencode models` does **not** make them usable — no auth path exists. Re-apply kit + evidence: `vendor/antigravity-port/REVERT-2026-11-15.md`. See **Model Providers** |
| Auth state looks wrong / `opencode auth logout` hangs | V2 credentials truth = the `credential` table in `~/.local/share/opencode/opencode.db` (`auth.json` is a mirror only). `opencode auth logout <provider>` needs the credential ID or it hangs in non-TTY |
| Env-var diagnostic flag has no effect | The systemd service does not carry ad-hoc env vars — reproduce on an isolated `opencode serve --port` with the var exported (e.g. the historical `OPENCODE_ANTIGRAVITY_DEBUG=1`) |
| `google` provider refused | **HISTORICAL (2026-11-15/16) — rollback path only.** `experimental.policies` keeps `{action: provider.use, resource: "google", effect: allow}` after the catch-all deny; since 2026-11-17 no running agent needs it (ADR 0008 moved the personal roster to `opencode-go`). The rule is retained as the rollback path — if it were removed, reverting the profile would make every `google/*` agent die silently |
| 503 `high demand` / overloaded on a `google/*` model | **HISTORICAL (2026-11-15/16)** — transient AI Studio capacity event (observed on `gemini-3.8-flash`). Retry — V2's internal `retry 1/5` usually clears it; a lower tier is the workaround. Relevant again only on the rollback path. There is **no automatic model fallback** in any era (see **No error-based model fallback in V2**) |
| `google/gemini-4-hydrogen` answers empty or truncated | **HISTORICAL (rollback path)** — `maxOutputTokens` too small: reasoning tokens are charged to the output budget (proved 2026-11-15: probes needed ≥800 output tokens). Raise the budget before concluding the model is broken |
| Personal agent hits a gateway ceiling (429) | Gateway ceilings are **per model**, published as **($/month, requests/5h)** and counted over 5-hour, weekly AND monthly windows: `gemini-4-argon` 120/**2260** (request-side — shared by `finanzas`/`life`/`coach`) · `gpt-6-luna` **60**/16900 (spend-side — shared by `chef`/`barista`/`habitos`) · `mimo-v2.6-flash` 120/60200 (`organiza`). Check the **console** allowance counters; locally, count requests per model from `session_message` — the `cost` field reads 0 and proves nothing. **No automatic fallback**: the turn dies; moving to a `*-free` model is MANUAL. Official FAQ: "When you reach a Go limit, you can keep using the free models" |
| Agent session dies at the FIRST turn with `provider.no-route` | Bad or unsupported `#variant` suffix in `model_profiles.json`. **The builder does not validate variants** — the build succeeds and every session of that agent dies at first turn. Either the model exposes no variants (`mimo-v2.6-flash` → `organiza` MUST stay bare) or the suffix name is wrong. `opencode models` cannot help: it prints ids WITHOUT variants. Fix the suffix or drop it, rebuild, verify via `session_message.data.model` |
| HTTP 400 "...hosted outside Europe and the United States. Select Global at .../settings/privacy#regions" | The workspace **residency privacy control WORKING — not a bug**. Do not "fix" by switching the account to Global: EU/US residency is the accepted policy (Global was tested 2026-11-17 and revoked). Pick an EU/US-hosted model instead (this vetoed `deepseek-v4.1-flash` for `habitos`) |
| HTTP 400 gated by "Allow paid endpoints that train on request data" (e.g. `iceman-contributor-free`) | The workspace **`#training` privacy control WORKING — not a bug**. It blocks endpoints that train on request data while the setting is off. Keep it off; choose a non-training model. Note: paid models are already blocked from training by default ("Go blocks paid endpoints that train on your requests") |
| Agent silently uses the wrong model (the account default) | `model:` key came back **empty/null** — typically a `{{MODEL:key}}` placeholder whose profile key is missing (builder warns but leaves the literal) or a YAML null value (e.g. `model: #medium` — the value starts with `#` → YAML comment → null). Availability degradation chain substitutes the account default silently. Check the compiled `agent/*.md` frontmatter and `session_message.data.model` |
| `model:` value truncated at `#` in the compiled agent | You wrote `model: x #medium` with a SPACE before `#` → js-yaml read it as a COMMENT. The suffix must be attached with NO space: `model: x#medium` |
| Agent vanished from `opencode run --agent` / the agent list, with NO error | **Measured 2.2.5 (homesrv) — silent frontmatter drop.** A `model:` value eaten by the comment trap becomes `null`, and on 2.2.5 the agent simply **disappears from the listing with zero warnings**: the `agent file skipped` log string does not exist in that binary (0 matches), `--print-logs` filtered on skip/frontmatter/invalid/error returns **empty**, and 2.2.5 has no `opencode run --archived` flag. There is nothing to read on the Pi — detect by counting agents and running a turn, or inspect the compiled `agent/*.md` bytes before sync. Treat "agent missing, no message" as frontmatter corruption, not as a config-cache issue |
| Script reads `session_message` and sees nothing on one node | **Schema skew, measured:** the session column is `session_id` on 2.2.5 (Pi) and `sessionID` on 2.3.0 (laptop); `session_v2`/`session_message` exist on both but keyed differently (Pi also lists `session_inbox`, `session_part`). Accept both names (`COALESCE(json_extract(...,'$.sessionID'), json_extract(...,'$.session_id'))`-style) or the script is blind on the other node. Still never use `session_v2.model` (EMPTY) or the zombie `message` table |
| Burn detector on `opencode stats --models --cost` reports zero spend | Not a bug and not free usage: the gateway `cost` field reads **0 client-side on both nodes**; Go consumption is metered in the console, only request/token counts are local. Count requests per model from `session_message` locally, read the **$/month** ceiling in the console / request-log export. `cache.read = 0` on a first turn of a new session is likewise normal (no identical prefix yet to cache against) |
| Variant not auditable from the console export | Known limitation, not a bug: the gateway request-log export shows `requestedModel`/`model` WITHOUT the `#variant`. Audit locally: `session_message.data.model.variant` (tolerating the `session_id`/`sessionID` skew above). `reasoningTokens` is NOT valid variant evidence for argon (0 at low and medium alike); luna medium=41 vs low/none=0 is a weak signal only. Never script against `session_v2.model` (comes back EMPTY); the live table is `session_message.data.model` |
| Every `google/*` agent stops at once with **HTTP 402 Payment Required** | **HISTORICAL (2026-11-15/16; rollback path only)** — the prepaid balance was exhausted; not a broken key and not a quota problem. Since 2026-11-17 nothing spends Google API credit, so this cannot fire on the live roster. If seen after a rollback: top up (auto-recharge is intentionally off — the stop is the guardrail) or move agents back to `opencode-go`, and re-check tier/data-use terms in the billing panel rather than assuming |
| Personal agent fails with an auth / missing-key error on `google/*` | **HISTORICAL — rollback path only** (no agent should hit this since 2026-11-17): `GEMINI_API_KEY` missing from the **process** environment — `source ~/.secret_envs` locally; on homesrv it must be in the systemd service environment (`Environment=` / `SourcePath` drop-in). A rebuild does not deliver env vars. Check with `opencode models \| rg '^google/'` |
| Personal agents still on the old model after a profile edit | First check the config watcher picked up the reload — on 2.3.0 `agent/*.md` changes were applied WITHOUT a daemon restart (verified 2026-11-17). If a live daemon still holds stale definitions: `opencode service restart` (kills local sessions — do it in a window you control) or verify on an isolated `opencode serve --port`. The `agent/*.md` on disk are already correct |
| `Location plugins did not finish activating` | Slow node (Pi) still downloading/activating a registry plugin at boot — wait ~1-3 min and retry; not a config error |
| `oc` build aborted: missing env vars | `source ~/.secret_envs` and retry — the `${VAR}` preflight abort is a feature (prevents baking empty keys) |
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
