# antigravity/ — agy port of the OpenCode roster (source of truth)

opencode → Antigravity CLI (`/usr/bin/agy`) port. Ships two agy **plugins**; sources live here,
installs land in `~/.gemini/config/plugins/` (discovery root per `plugins.md` — F0 doc-confirmed,
live-verified at F4+). GitOps direction: edit here, never in `~/.gemini`.

| Plugin | Source tree | Content |
|---|---|---|
| `opencode-suite` | `suite/opencode-suite/` | technical roster (commander, PE, architects) |
| `opencode-personal` | `personal/opencode-personal/` | personal agents (finanzas, life, coach, chef, barista, habitos, organiza) |

## Workflow

```bash
./build.sh            # sources -> dist/ (+ flatten + size guards + dist/manifest.sha256). Fail-closed.
DRY_RUN=1 ./sync.sh   # rsync -n: shows the plan, writes NOTHING. Always dry-run first.
./sync.sh             # live install into ~/.gemini/config/plugins/ (F6+; nothing under ~/.gemini until then)
./verify.sh           # read-only: manifest drift (dist + installed), plugin.json parse, layout. Warnings OK pre-F4/F5.
```

Enable/disable is **agy-side** and never automated by `sync.sh`: state lives in
`~/.gemini/config/config.json` → `plugins.<dirname>.enabled`, written by `agy plugin install`
or the customizations UI (deep-links:
`customization://opencode-suite` · `customization://opencode-personal` — formato
SKILL.md §Step 4; verificación viva del toggle queda para el F0 re-run). `config.json`/global `mcp_config.json` are hard-refused in dist (see GUARD in `sync.sh`).

## Drift model

`dist/` is disposable (gitignored; rebuild via `./build.sh`). `dist/manifest.sha256` hashes every
synced file; `./verify.sh` checks dist against the manifest and the installed trees against the
same manifest. The installed plugin dirs must only ever be a copy — hand-edits there = drift = FAIL.

## Re-test gate after `yay` upgrades

F0 hypothesis: the v1.5.12 update wiped agy auth; same class of update can break hooks/discovery.
After any OS/`yay` upgrade touching agy:
1. `agy --version` vs the last verified row below;
2. `./verify.sh`;
3. `./probe.sh` (needs the owner's interactive login; F0 K3).
Frozen sync until 1–3 pass.

| agy version | verified | evidence |
|---|---|---|
| 1.5.12 | doc/static only (F0) | `../docs/evidence/agy-probes.md` |
| — | live | `../docs/evidence/agy-probes-live.md` (from F4 onward) |

## Uninstall

`agy plugin uninstall/remove <name>` (exact verb confirmed at F6), or manual floor:

```bash
rm -rf ~/.gemini/config/plugins/opencode-suite ~/.gemini/config/plugins/opencode-personal
```

Then clear the two `plugins.<dirname>.enabled` entries from `~/.gemini/config/config.json` (or via
the customizations UI). Repo sources stay; `dist/` is disposable.

## Contract notes (F1 findings — flagged to Commander)

- `plugins.md` documents manifest fields `name/author/homepage/repository` + `disabled`. The plan's
  `description`/`version` are **undocumented extras** — RESOLVED at F2a: `migrate-agent-settings/SKILL.md` lists
  name/displayName/version/description as known manifest fields and states unknown fields are
  silently dropped. Files are kept valid pure JSON (JSONC-superset safe; no doc evidence comments
  are accepted).
- `agents/` is **not** a documented plugin surface (contract has `rules/`, `skills/`, root
  `hooks.json`, `mcp_config.json`). RESOLVED at F2a — plugin `agents/<name>.md` (flat; YAML
  frontmatter `name`/`description`/`subagent: true`/`mainAgent: false`/`tools:`) IS a documented
  surface per `migrate-agent-settings/SKILL.md` §Step 3; 7 technical agents staged in
  `suite/opencode-suite/agents/`.
- Budgets + `{{INCLUDE:key}}` convention: see `includes/README.md`. Enforced by `build.sh`.

## Layout

```text
antigravity/
├── suite/opencode-suite/{plugin.json,agents/,rules/,skills/}    # F2 agents · F3 rules+skills · F4 hooks.json · F5 mcp_config.json
├── personal/opencode-personal/{plugin.json,agents/,rules/,skills/}
├── includes/            # {{INCLUDE:key}} fragments + convention README
├── build.sh sync.sh verify.sh probe.sh
└── dist/                # gitignored build output + manifest.sha256
```

## Extension points

- **Remote sync (homesrv Pi)**: `AGY_SYNC_TARGET=host:path ./sync.sh` → refuses with exit 2 today.
  Design: rsync-over-ssh to the Pi's `~/.gemini/config/plugins/`, same DRY_RUN + manifest contract.
- `probe.sh` — F0 checklist re-run once agy is authenticated; appends to `docs/evidence/agy-probes-live.md`.

## Agents staging (F2a) — TODO-LIVE

- **Global agents discovery dir UNCONFIRMED**: `~/.gemini/config/agents/` vs workspace
  `.agents/agents/` vs plugin `agents/` (SKILL.md confirms only `~/.gemini/config/plugins/<p>/agents/<name>.md`
  as a write target). Settles with the F0 re-run (probe) once agy is authenticated.
- `invoke_subagent` appears in the F-plan tool list but is **absent from every builtin doc**
  (SKILL.md tools: read_file, edit_file, write_file, run_command, manage_task, search_web).
  Deny-subagents is implemented as **omission** from `tools:`; native deny flag (if any) TODO-LIVE.
- Capability consequences encoded in bodies: security-architect has NO `write_file` (reports via
  final message / edits only); doc-architect has NO `run_command` (git/graphify/test execution is
  caller-supplied — bodies instruct emitting exact commands).

## Personal agents staging (F2b)

7 agentes personales en `personal/opencode-personal/agents/` (misma convención F2a; bodies en
castellano, fuente `prompts/<agent>_behavior.md` + `personal_identity.md`). Compartido vía
`includes/personal-shared.md` + token `{{INCLUDE:personal-shared}}` (identidad Socio Estratégico,
Veto 4 pasos, ISO/notas, sello). Agrupación web = **roster vivo** (dotfiles AGENTS.md / ADR-0004). El flip coach↔habitos de la
tabla del ticket F2b fue error del ticket; revertido 2026-11-20 por orden directa:
SELLADOS `finanzas, life, habitos, organiza` = `[read_file, edit_file, write_file]`;
WEB-OPEN `coach, chef, barista` = `+ search_web`. Ninguno con `run_command`/`manage_task`.
`plugin.json` intacto — el contrato de SKILL.md no tiene campo de surfaces; los 7 ya figuraban
en `description`.

- **Desviaciones/port notes**: `mode: primary` (opencode) → `subagent: true` en agy (convención
  F2a); Engram MCP eliminado — los ficheros `~/notas/<agent>/` son la única memoria; el routing
  por modelo (ADR 0008 argon/luna/mimo) no existe en el frontmatter de agentes agy (SKILL ordena
  dropping `model`) → TODO-LIVE: confirmar superficie de model-selection en agy; ADR-0004
  cross-isolation de notas queda como **doctrina en body** (agy tools allow-list no expresan
  paths) — coach/chef/barista (los web-open) con finanzas+life vetados en body.

## Rules + Skills (F3)

- `suite/rules/AGENTS.md`: hechos máquina-wide únicamente — binarios verificados
  (`command -v`+versión, 2026-11-20), tool paths horneados, presupuestos de prompt
  (bytes→tokens ~4 B/tok, nota agregada 20k), cero secretos, **cero persona** (vive en `agents/`).
- `personal/rules/AGENTS.md`: 26 B = solo `{{INCLUDE:rule-language}}` — idéntico mínimo,
  duplicación cero real vía `includes/rule-language.md`.
- Skills del suite (formato `skills.md`: frontmatter `name`==folder + `description` what/when):
  `hexagonal-architect` (REWRITE real → `go run <abs>/tool/hex_check.go` desde raíz del proyecto,
  condicional para repos con validator propio) · `infra-security-check` **FUSIONADO** con el
  antiguo command `/infra-scan` (misma semántica; un solo skill; sintaxis opencode `!cmd`/$1
  eliminada) · `k8s-doctor` (wrapper `node --experimental-strip-types` sobre
  `tool/k8s-pod-doctor.ts`; node v26 — sin bun/deno).
- **DROP**: `production-log-analyzer` no se porta — dependía del MCP Datadog de opencode, que no
  existe en el roster agy (F5 no lo contempla). Si algún día hace falta, primero mcp_config.
- Cero mcp_config hasta F5; **hooks añadidos después en F4** (ver sección Safety gate F4).
  `sync.sh` no ejecutado (F6); `build.sh` sí como validación
  de flatten+guards (dist/ regenerable, gitignored).

## MCP servers (F5) — `suite/opencode-suite/mcp_config.json`

Fuente de verdad: `builder/templates/config/config.json` → `mcp.servers.*` (leída 2026-11-20; el
`opencode.json` generado no se toca). Formato agy: un solo mapa `mcpServers`, claves permitidas
`command,args,env,cwd,url,headers,disabled,variables`; campos opencode (`type`, `timeout`,
`oauth`, `_requires_env`) descartados por el contrato (SKILL.md §Step 3).

| MCP | Transporte | Estado en plugin | Nota |
|---|---|---|---|
| context7 | remote Streamable-HTTP `https://mcp.context7.com/mcp` | ✅ | url exacta plantilla |
| gh_grep | remote `https://mcp.grep.app` | ✅ | url exacta plantilla |
| gcp | remote `https://run.googleapis.com/mcp` | ✅ sin env | **TODO-LIVE (F0 re-run):** auth OAuth/ADC del CLI agy hacia el endpoint — sin surface documentada en config; probar con sesión autenticada |
| engram | local `/home/andres/.local/bin/engram mcp --tools=agent` | ✅ | binario verificado `which`; SQLite local `~/.engram`, cero env requeridos |
| codebase-memory-mcp | local `/home/andres/.local/bin/codebase-memory-mcp` | ✅ | binario verificado `which`; sin args |
| google_drive | remote + `oauth ${GOOGLE_CLIENT_ID}/${GOOGLE_CLIENT_SECRET}` | ⛔ OMITIDO | decisión del dueño; además intraducible limpia: placeholders `${ENV}` no los expande agy (SO env no aplica) y declarar `variables` **deshabilita el plugin** hasta rellenar el formulario — trampa evitada |
| playwright | local `npx -y @playwright/mcp@0.0.83` | ⛔ OMITIDO | decisión del dueño (npx sin pin en runtime remoto; reintroducir solo con decisión explícita) |

Modos: staged `chmod 600` y propagación verificada — `build.sh` usa `cp -a` (conserva modo →
`dist/.../mcp_config.json` 600) y `sync.sh` usa `rsync -a` (conserva). Guard de `sync.sh`:
`mcp_config.json` en raíz de plugin es legítimo (plugins.md) y pasa; solo se rechaza
`config.json` o `mcp_config.json` en raíz de dist.

**Delta conocido del port — scope de MCPs:** en opencode la visibilidad de tools MCP se afinaba
por agente (policies/injection en prompts); en agy los servers del `mcp_config.json` de un plugin
habilitado son **globales para todos los agentes** (no scopeables por agente). Consecuencia de
diseño: el plugin técnico `opencode-suite` es el único que declara MCPs; los agentes personales
(sin shell, sellados) comparten ese plano global — el aislamiento personal queda relegado a la
doctrina de bodies hasta que exista surface de scoping (TODO-LIVE: verificar en F0 re-run si agy
ofrece algo más que `disabled` por server).

## Safety gate + auditoría (F4) — `suite/opencode-suite/hooks.json`

**⚠ Nota honesta: el schema de hooks de agy sigue SIN VERIFICAR EN VIVO.** La "verificación"
de una sesión anterior fue **fabulada** y quedó retractada (ADR 0012 §6d; evidencia real:
`docs/evidence/agy-probes.md` — fichero en sitio, cero fires, `num_turns: 0`). Todo lo de
abajo está diseñado contra la DOC (`hooks.md`) y **fail-closed para sobrevivir a la
incertidumbre**; la verificación real es la captura del live-kit (§F4.1).

- **3 hooks** (no 4): `SessionStart` → `./hooks/session-start.sh` (inyecta `includes/contracto.md`,
  ~2 KB, vía `injectSteps[].systemMessage.systemMessage` — formato docs §3; `additionalContext`
  NO existe en el schema agy, es relic de opencode); `PreToolUse` matcher `*` → `./hooks/gate.sh`;
  `PostToolUse` matcher `*` → `./hooks/audit.sh`. **El 4º hook (PreToolUse separado run_command
  vs file-ops) NO hace falta**: `hooks.md` dice que `"matcher": "*"` matchea TODAS las tools, y
  como los tokens de tool-name y el casing de las keys de args están sin confirmar en vivo (P1),
  el gate no enruta por nombre de tool sino por **presencia de valores**: compara cada string
  bajo `toolCall.args` contra todos los floors (command y path indistintamente). Over-match =
  deny = lado seguro.
- **gate.sh**: POSIX sh, `set -u`, **fail-closed total** (floors missing/empty, stdin vacío,
  JSON ilegible, evaluator caído → deny). Evaluador: python3+fnmatch; fallback sin python3 =
  grep -F sustrato sobre el stdin crudo (heurístico, solo puede over-deny, documentado en el
  script). Path de floors: env override → absoluta horneada por `build.sh` (`$HOME/.gemini/config/
  plugins/opencode-suite/hooks/floors.txt`) → `$0`-dir. Salida deny: `{"decision":"deny","reason":...}`.
- **audit.sh**: JSONL append-only a `~/.agy-audit/agy-audit.jsonl` (root configurable arriba del
  script / `AGY_AUDIT_DIR`). **Fail-open deliberado** — es observabilidad; la superficie de
  seguridad es gate.sh.
- **floors**: `includes/floors.txt` (16 patrones: rutas sensibles espejo de los floors
  `tool.use` de opencode + destructivos). Los literales viven SOLO ahí — nunca inline en
  comandos shell (los floors del daemon matchean texto crudo). Copiado a `dist/.../hooks/`
  por `build.sh`; `sync.sh` instala `hooks/*.sh` a 755 (resto 600).
- **timeout 5 s** en los tres handlers (hooks son síncronos y bloquean el loop — hooks.md limitations).
- **verify.sh** ya no WARN-ea hooks: asserts reales (hooks.json presente+parsea+3 eventos,
  scripts `-x`, floors ≥14, contracto ≤4 KB) + **dry-test local** de gate.sh con 4 JSONs
  sintéticos (canary path fake, comando destructivo, comando inocuo, stdin roto) → deny/deny/allow/deny.
- No hay evidencia de que un error de agy al parsear la salida del hook bloquee o deje pasar
  (P6 NOT-DONE) — por eso cada script empite SIEMPRE una línea JSON válida y sale 0.

## F4.1 — live-kit (captura del schema en vivo, 1 comando)

En el **terminal autenticado de Tony** (el daemon opencode NO puede autenticar agy — F0 K3):

```bash
bash ~/Proyectos/dotfiles/antigravity/live-kit.sh
```

Auto-instala en `/tmp/opencode/agy-livekit/`, monta un workspace probe con
`.agents/hooks.json` de 5 eventos (dump crudo del stdin de cada evento a `dumps/NNN.json`,
Pre/PostToolUse con matcher `*`), lanza `agy` interactivo con 3 turnos inocuos guiados
(leer canary.txt, `echo hola`, escribir probe.txt), y al salir imprime la tabla resumen:
eventos capturados, tool names observados, keys de args por tool, y si el matcher `*` disparó.
Los dumps quedan en `/tmp` para análisis del Commander (`ANALISIS.md` junto a ellos).
Idempotente: dumps previos rotados, nunca borrados.

## Runbook (F6) — instalar / actualizar / deshacer

**Instalar o actualizar** (mismos cuatro pasos siempre; `dist/` es derivado, gitignored):

```bash
cd ~/Proyectos/dotfiles/antigravity
./build.sh            # sources → dist/ + manifest (flatten + guards, fail-closed)
DRY_RUN=1 ./sync.sh   # plan visible — escribe CERO
./sync.sh             # LIVE: rsync -a --delete --no-perms + chmod dirs 700 / files 600
./verify.sh           # dist↔manifest e INSTALADOS↔manifest (--strict); hand-edits = FAIL
```

- La instalación vive en `~/.gemini/config/plugins/opencode-{suite,personal}/` (34 entradas,
  modos 700/600 forzosos — los modos los manda `sync.sh`, no el staging).
- Idempotencia probada: segunda pasada con `--no-perms -c --itemize` = vacío;
  `sha256sum --strict -c manifest` contra instalados = 0 diffs.
- Activación/visibility agy: `agy plugin list` + `customization://opencode-suite` ·
  `customization://opencode-personal` — requiere sesión autenticada (F0 K3): los 14
  agents/skills/mcp quedan EN STAGING-VIVO hasta que los probes confirman discovery.
- **Undo**: `rm -rf ~/.gemini/config/plugins/opencode-suite ~/.gemini/config/plugins/opencode-personal`
  (o toggle off en la UI). `config.json`/`mcp_config.json` globales nunca los toca `sync.sh`
  (guard + `--no-perms` no altera ese contrato); limpiar el mapa `plugins.<dir>.enabled` si
  agy llegó a escribirlo.
- **Re-test gate tras `yay`**: `agy --version` vs tabla ↑ → `./verify.sh` → `./probe.sh`
  (con auth). Cualquier FAIL: congelar `./sync.sh` hasta re-certificar.

## Trust & modos globales (F7)

| Store | Entry | Antes | Después |
|---|---|---|---|
| `~/.gemini/antigravity-cli/settings.json` (`trustedWorkspaces`) | `/home/andres` (HOME entero — genérico NO declarado en el ticket, descubierto midiendo) | TRUST | **RETIRADO** |
| idem | `Proyectos/dotfiles` · `Projects/server` · `Projects/server/health-sync` | TRUST | TRUST (per-repo, EXISTS verificado) |
| `~/.gemini/trustedFolders.json` | `/home/andres/Proyectos` (todos los repos del padre) | TRUST_FOLDER | **RETIRADO** |
| idem | `/home/andres/Proyectos/dotfiles` | TRUST_FOLDER | TRUST_FOLDER |

Backups previos: `/tmp/opencode/settings.json.bak-agyport` · `/tmp/opencode/trustedFolders.json.bak-agyport`
(no junto al original, por diseño). JSON re-parseado post-edit ✓. `~/.gemini/config/config.json` no
se tocó (jamás). `~/.gemini/config/mcp_config.json`: **solo chmod 644→600** — sha256 idéntico
pre/post (`e57d5875…c20aa2`), contenido inmutable. **Recordatorio: los instaladores de agy pueden
regenerar ese fichero con 644 — re-aplicar `chmod 600` tras cada upgrade** (dentro del re-test gate).

**Gate F4 en STAGING (post-F4):** `hooks.json` + gate/audit/contracto existen y pasan
`verify.sh` (dry-test local deny/deny/allow/deny), pero la propiedad de seguridad sigue
**sin certificar en vivo** hasta `live-kit.sh` en terminal autenticado (K1: ¿disparan los
hooks? P6: ¿fail-open o fail-closed de agy ante hook roto?). Mientras tanto, el diseño
fail-closed del gate es la hipótesis defensiva, y la enforcement REAL sigue siendo:
trust por-repo ↑ + allow-list `tools:` + exebox default-deny. ADR 0012 documenta los deltas.

## Distribución `.agents/` (F8-pre)

Los agents de plugin NO se registran en el catálogo (plugins.md no tiene campo `agents`; F8 midió:
`agy plugin list` los cuenta pero `agy agent` no los ve). Distribution real = **workspace root**:
`build.sh` genera `dotagents/` (14 agents flattenados de ambos plugins + 3 skills del suite +
`skills.json` + marker `.opencode-suite-managed` + `manifest.sha256` propio) y `sync.sh` lo
instala vía rsync `--delete` en `<repo>/.agents/` SOLO para `DOTAGENTS_TARGETS` (arriba en
sync.sh; v1 = dotfiles). Añadir un repo a esa lista ES el permiso; sync **refusa** targets con
`.agents/` ajeno (sin marker). Modos 700/600 como los plugins. Idempotencia probada (itemize -c
vacío). `agy agent` lista solo main-capables — los 14 son `subagent:true` → se ven en el picker
`/agents` de la sesión interactiva (verificación viva Tony). Las skills del mismo árbol SÍ se
registran (evidencia: `k8s-doctor` expuesta por el runtime post-sync).

**Uninstall distribución**: borrar el directorio `<repo>/.agents` completo — no está contenido en
`~/.gemini/config/plugins/` (el uninstall de plugins de arriba no lo toca). Los dos sitios pueden
coexistir (agents duplicados inofensivos; decisión post-probe de cuál se queda).

## Global agents (F8b) — `~/.gemini/config/agents/`

Tercer target de `sync.sh` (medido en vivo, dos sondas diferenciales): agy descubre agentes SOLO
en el directorio GLOBAL (visible desde cualquier cwd); plugin `agents/` se cuenta pero no se
registra; `~/.agents` bajo HOME NO participa. Pasada aditiva **sin `--delete`**: los `.md` ajenos
del target se REPORTAN y no se tocan (pre F8b no había ninguno). Modos: dir 700, nuestros 14 600.

**Filtro medido y RESUELTO (F8c):** el catálogo (`agy agent`, `--agent`, picker `/agents`) expone
SOLO main-capables. Decisión de owner registrada: los 14 van **main-capable por diseño de
selección directa** — las líneas `subagent: true` / `mainAgent: false` se ELIMINARON del
frontmatter de las 14 fuentes (keys restantes: `name`/`description`/`tools` exactas; `tools:`
intocable — es el sello de permisos). Evidencia post-volteo: `agy agent` desde cwd ajeno lista
los 14 exactos; sha256 del dir global == `dotagents/agents`. **Delegación-from-default (que el
agente main invoque subagentes) = NO PROBADO — TODO-LIVE para la certificación: un turno real
«usa go-architect para …», anotar resultado en docs/evidence.**

Sondas del experimento de descubrimiento (`probe-flat.md`, `probe-nested/`) eliminadas del
directorio global tras confirmar el mecanismo — `ls ~/.gemini/config/agents` = exactamente los
14 portados. Uninstall invariante: los mismos 14 nombres (+ `.agents/` del repo si se distribuyó).
