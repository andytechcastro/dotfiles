# Plannotator on Linux — Platform Guide (measured 2026-11-16, opencode v2.3.0)

Companion to ADRs 0005 (float + vendor route) and 0006 (surface precedence). Everything here is measured on THIS box or in the delivered commits; Mac-origin claims without local evidence are marked as such.

## 1. What is installed

Registry plugin entry in `builder/templates/config/config.json` (object form):

```json
{
  "package": "@plannotator/opencode@latest",
  "options": { "workflow": "plan-agent", "planningAgents": ["commander"] }
}
```

- **`@latest` is a sanctioned float exception** (user decision 2026-11-16) to the exact-pin law — machine parity with dotfilesMac, where the vendor installer itself rewrites this entry on every update. Every other package keeps exact pins. Do not generalize.
- `planningAgents:["commander"]` was **provably inert below 0.28** (agent-switch dead-end bug). The float exists so the fix ships without a template edit; acceptance of any upgrade is version-checked (§3), not assumed.
- Config template also carries `"share": "disabled"` — **load-bearing for isolation**. See §6 override warnings.

## 2. Guardrail behavior (`oc` v0.6.0, `bin/oc :: check_plugin_pins`)

- Hard-dies on a non-`@`-prefixed, non-semver plugin entry; **floats pass** and get registry-freshness reporting cached 24 h in `~/.cache/opencode/pin-check.json`.
- TTL uses GNU `stat -c %Y`. The Mac fork's BSD `stat -f %m` printed the whole filesystem here and silently defeated the cache (up to ~24 s latency per launch) — fixed, regression test: `grep -c 'stat -f %m' bin/oc` must be 0.
- Network failures degrade to silence — never blocks a launch.
- Known latent debt: semver regex `@[0-9]+\.[0-9]+\.[0-9]+$` skips prerelease tags.
- Call sites: `do_rebuild()` (after `check_env_vars` hard-die preflight) and the fresh-config branch.
- Drift reporting also lives in `up` step 7 (`.local/bin/up`), sharing the same cache file and `OC_PIN_CHECK*` knobs.

## 3. Upgrade / first-install procedure — the runbook

**Script:** `.config/opencode/docs/vendor/plannotator-upgrade.sh` (tracked via `git add -f`).
**Executor: the user, from a terminal. NEVER a subagent, NEVER from inside a live session.**

Order is mandatory (each step exists because of a measured failure mode):

1. **Purge scope-level cache BEFORE any daemon start:** `rm -rf ~/.cache/opencode/npm/@plannotator ~/.cache/opencode/packages/@plannotator && rm -f ~/.cache/opencode/pin-check.json`. Also destroys the legacy `packages/` fossil (0.23.1).
2. `opencode service restart` — **kills all live sessions** (§7).
3. **Verify by version, not directory name:** read `version` from the resolved `package.json` under `~/.cache/opencode/npm/@plannotator@latest/*/`; acceptance is **≥ 0.28**.
   - **Frozen-cache resurrection (measured 2026-11-16):** after a purge, the OLD resolved tree (0.27.20) can REAPPEAR before any restart — stale metadata re-resolves the old version. The `@latest` directory name means nothing; only the `package.json` `version` field is evidence. The runbook purges immediately before restart and asserts this.
4. **Vendor binary route:** download `install.sh` → inspect it → record `sha256sum` in the docs commit → execute. Review-before-execute is the policy; the sha256 registered at review time must match the file executed.
5. `plannotator --version`.
6. **Git-clean test:** `git status --porcelain` must be EMPTY after install (the installer writes into the repo through the `~/.config/opencode` symlink — §5).
7. **Loopback check:** `ss -ltnp` — the Inbox server must listen on loopback only.

## 4. Measured runtime facts (Linux)

- **Reload vs restart (A5):** a builder rebuild or config hot-reload does **NOT** re-register plugin hooks/tools on live sessions. Plugin code changes deploy only via `opencode service restart`. Measured on this box, not inherited from Mac.
- **`plannotator` CLI** (0.28.66): instalado el 2026-11-16 vía `install.sh` (sha256 `659c5b46545f5f386946ccb98d967e96f8fd9f3e036a217ec56d99b8a8afc0c7`, descargado a `/tmp/opencode/plannotator-install.sh` e inspeccionado ANTES de ejecutar — la política review-before-execute se mantiene; el pipe directo `curl | bash` del guide del vendor se sustituyó por `curl -o` + `sha256sum` + `bash local`). El binario vive en `~/.local/bin/plannotator` (en PATH).
- **`--attach` flag is retired** in V2. Attaching to a protected daemon uses the server password: export `OPENCODE_SERVER_PASSWORD` for both daemon and client; there is no `--attach` equivalent to reach for.

## 5. Directory contract: `command/` vs `commands/`

- `command/` (singular) = OUR tracked custom slash commands (`infra-scan.md`, `k8s-doctor.md`).
- `commands/` (plural) = written INSIDE the worktree by the vendor installer. `~/.config/opencode` is a symlink into this repo, so without ignore rules every install dirties git. `.gitignore` carries `.config/opencode/commands/` — hence the step-6 clean test. Never "clean up" by deleting the tracked singular dir or un-ignoring the plural one.

## 6. Config-shadow and egress warnings

- **`opencode.jsonc` (V2-merged, live):** a stray `opencode.jsonc` in the config dir is loaded as a LIVE config document merged AFTER the generated `opencode.json`; per-key, the jsonc value WINS. The global `config.json` name is DEAD in V2 (never loaded). `.gitignore` carries `.config/opencode/opencode.jsonc` because the installer may write it — installer state must never shadow the generated secrets-bearing config.
- **`PLANNOTATOR_SHARE` env overrides the config `share` setting at runtime** (the vendor install.sh writes it into `opencode.jsonc`). `share:"disabled"` in the template is the isolation baseline; exporting the env var silently defeats it. Know before you export.
- `.config/opencode/AGENTS.md` is a **multi-writer file** (squeez binary + vendor installer inject blocks; it is gitignored for that reason). The tracked mirror convention for injected vendor blocks lives in `.config/opencode/docs/vendor/`. **El bloque Inbox `v9` quedó inyectado el 2026-11-16** y su espejo tracked es `docs/vendor/plannotator-inbox-v9.md` (obligación FASE 1.5 cumplida; reespejar en cada upgrade comparando el marker `vN`).

## 7. Service restart policy

`opencode service restart` terminates every live session attached to the daemon. It is a **TERMINAL-ONLY, user-executed action**. From inside a session: forbidden — same class as `oc --rebuild` / `oc --sync` (lethal). `up` deliberately never auto-restarts; it prints the instruction instead.

## 8. Human surface (Inbox / plans)

Per ADR-0006 precedence, codified in `prompts/commander_behavior.md` PHASE 2.5:

- **Everything Plannotator renders for the user (plans, Inbox message bodies, `:::question` blocks, guides) is ESPAÑOL.** Internal artifacts (RFCs, code, logs, commits) stay English.
- **Interactive decisions NEVER park in the Inbox:** in-session approvals and C.2 escalations go through the `question` tool in chat. Inbox is for async traffic only: long-background-work results, `run_watch` wake-ups, cross-session handoffs.
- Conflict rule: if a session is live and interactive, the current turn's blocking decision must never be delegated to the Inbox. The Inbox must not block the Commander.

## 9. Inbox — hechos medidos (2026-11-16, setup del vendor completado en esta máquina)

- Servidor: `plannotator inbox` → escucha **solo** `127.0.0.1:34365` (proceso `plannotator`, verificado con `ss -ltnp`). Datos en `~/.plannotator/inbox/` (`inbox.json`, hilos por proyecto). El guide del vendor exige este listener loopback — sustituye al «Loopback check» del runbook §3.7.
- Conexión automática (paso 2.2 del guide): `Connected Gemini CLI, OpenCode and Antigravity`. Para OpenCode escribió `{"inboxTool":{"opencode":true}}` en `~/.plannotator/config.json`. La entrada de **Antigravity es solo config local del Inbox**: cero tráfico a `*-cloudcode-pa.googleapis.com`; el path ToS-retirado sigue muerto.
- **El tool `plannotator_inbox` solo aparece en sesiones NUEVAS** (misma ley que §4: nada de hot-reload). Sesiones vivas: enviar por stdio — `plannotator inbox mcp < payload.json` (JSON-RPC `tools/call`). El resultado de `send_message` dice si la respuesta despierta la sesión; por stdio **no despierta**: `read_thread` manual.
- Envío de prueba: thread `msg_01M7K17H1KHV9NKQTAHJ1R90CJ` (proyecto `dotfiles`, idempotencia `plannotator-inbox-first-v1-opencode`). Reenvío seguro con la misma clave: devuelve el primer mensaje, no duplica.
- Notas en instrucciones de agentes (guide §3b): OpenCode auto (bloque `v9`, espejado en `docs/vendor/plannotator-inbox-v9.md`). **Qwen Code y Cursor no existen en esta máquina** (`command -v qwen cursor cursor-agent` vacío) → `plannotator inbox --notes` no se ejecutó; si algún día se instalan, la decisión es del usuario.
- Git-clean test (§3.6) tras install: los artefactos del instalador (`commands/`, AGENTS.md inyectado) están gitignored por diseño. Los sucios preexistentes `natpw.txt` (15-nov) y `.config/hypr/dms/layout.lua` (19:08) NO son del instalador (mtime verificado).
- Reglas de operación del Inbox (para TODOS los agentes): nunca `plannotator uninstall`, nunca `inbox stop/restart` sin pedido del usuario, nunca `--tailscale` por iniciativa propia, nunca borrar hilos. Decisiones interactivas de la sesión actual siguen yendo por `question` en el chat (ADR-0006 sigue en pie); el Inbox es para tráfico asíncrono.
