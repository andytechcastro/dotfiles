# personal-recipe/ — opencode personal vía ACP (receta P1, standalone)

Roster **personal** (7 agentes) corriendo sobre los **modelos de la suscripción Antigravity**
dentro de **opencode**, enrutados por el plugin npm `opencode-antigravity-acp@0.1.0`, que
habla con el `agy acp` OFICIAL (`--stdio --process-per-session`). Nada de OAuth-proxy ni
extracción de tokens: el spawn local de agy firmado.

**STANDALONE por diseño — jamás producción.** Pared keyring: solo los procesos nacidos de la
terminal autenticada de Tony resuelven OAuth; el daemon de fondo (y cualquier sesión de
agente) muere en el auth gate (F0 K3). La producción del equipo técnico es el gateway
`opencode-go` y sigue intocada; esta receta vive fuera de ella (XDG aislado bajo este árbol).

> ⚠ **Esquema de hooks/agents de agy NO aplica aquí** — esto es superficie opencode, vida
> aparte del manifiesto de plugins de `~/.gemini`. `build.sh` solo VALIDA la receta
> (bash -n, JSON parseable + pin, 7 agentes, sha del shim); NO la mete en `dist/`.

## Adaptaciones medidas vs. plano del ticket
- El plano pedía `config/opencode.json`; **XDG exige `$XDG_CONFIG_HOME/opencode/opencode.json`**
  (forma exacta que funcionó en el sandbox `/tmp/opencode/acp-sandbox/`). La config está en
  `config/opencode/opencode.json` y los lanzadores apuntan `XDG_CONFIG_HOME=<recipe>/config`.
- Provider real según README del vendor: **`antigravity-acp/*`** (no `agy/*`); modelos y
  reasoning-efforts se descubren EN VIVO vía `agy acp` (cache 6 h). Por eso los 7 `.md`
  llevan `model: antigravity-acp/REPLACE-AFTER-FIRST-START` — TODO-LIVE, ver §1er arranque.
- `opencode serve --hostname --port` y `--standalone` verificados en v2.3.2 (help real);
  `OPENCODE_SERVER_PASSWORD` verificado en las strings del binario.

## Qué corre aquí y qué no
| Sí | No |
|---|---|
| `finanzas, life, coach, chef, barista, habitos, organiza` (copias aisladas en `config/opencode/agent/`, con SUS denies de producción preservados: shell-deny first rule, etc.) | Agentes técnicos (commander/PE/architects) — viven en opencode-go y en el port agy (`../suite`, `../dotagents`) |
| Modelos de la suscripción Antigravity vía `agy acp` | Cualquier cosa que dependa del daemon en background (auth imposible) |

## Uso
```bash
# TUI (default cwd ~/notas):
~/Proyectos/dotfiles/antigravity/personal-recipe/bin/oc-personal
# o con directorio explícito (nunca dotfiles ni dirs de secretos):
.../bin/oc-personal ~/notas

# Server para el móvil (loopback + password obligatoria, nunca hardcodeada):
.../bin/oc-personal-serve            # pide password por prompt
OPENCODE_SERVER_PASSWORD=... PORT=19999 .../bin/oc-personal-serve
# Acceso remoto SOLO por tailscale; la quota se ve SOLO en la consola de Google.
```

## Condiciones del auditor (obligatorias, permanentes)
1. **B.1 — modo DEFAULT, NUNCA `auto`:** los approval-modes del pill ACP se dejan en default
   (`Ask`/`Accept edits`); `Auto` aprueba shell/edits sin humano y está PROHIBIDO en esta
   receta. No se añade el flag `--auto` de opencode jamás.
2. **B.2 — spawn con env frotado:** `AGY_BIN` apunta SIEMPRE a `bin/agy-shim` (copia
   versionada del shim del sandbox, sha256
   `5f579f819ac5accf01d6c379d8112e3cfdff5b2ccdd23c4c6a451e4de489a338`): PATH fijo,
   strip de `KEY|SECRET|TOKEN|PASS`, exec `/usr/bin/agy`. Nunca señalar AGY_BIN a otra cosa.
3. **Pin exacto:** `opencode-antigravity-acp@0.1.0`, sha256 del tarball npm
   `715f4bdcd1b760b68f29f843151e8730aa00053379a22bc4f49bbf29dc3b207d`. Sin floats.
4. **B.4 — nunca cwd=dotfiles ni repos con secretos:** lo aplican los dos lanzadores
   (abort si cwd bajo dotfiles, `~/.gemini`, `~/.config/opencode`, ssh/gnupg/gh).
5. **Re-diff dist↔src en cada upgrade** (ver política abajo).

## Checklist 1er arranque (TODO-LIVE — nadie lo ha ejecutado aún)
- [ ] `bin/oc-personal` arranca TUI sin `provider.no-route` tras fijar modelos.
- [ ] Modelos visibles: con la receta, `opencode models` lista `antigravity-acp/*` →
      fijar el modelo de cada agente reemplazando `REPLACE-AFTER-FIRST-START` en
      `config/opencode/agent/<agente>.md` (finanzas/life/coach ↔ tier fuerte; chef/barista/
      habitos/organiza ↔ tier factual — ver tabla ADR-0008 en el AGENTS.md del repo).
- [ ] Turno de prueba en `~/notas` (p.ej. organiza: «resume mis notas de esta semana») —
      debe ESCRIBIR SOLO bajo `~/notas/<agente>/`.
- [ ] `pgrep -af "agy acp"` muestra el hijo del plugin. El plano esperaba ver
      `--cloud_code_endpoint` en la línea; el README del vendor documenta
      `agy acp --stdio --process-per-session` — **anotar los flags REALES que salgan**
      y reportar la discrepancia al Commander, no "arreglarla" a priori.
- [ ] `tr '\0' '\n' < /proc/$(pgrep -f "agy acp" | head -1)/environ | grep -cE 'KEY|SECRET|TOKEN|PASS'`
      → 0 (env del hijo frotado por el shim; si hay algún hit, ABORT de la receta y reportar).
- [ ] La prod (`oc` normal) sigue usando opencode-go: esta receta no escribe fuera de su árbol.

## Política de upgrades
1. `npm view opencode-antigravity-acp versions` + `npm view opencode-antigravity-acp@X dist.integrity`.
2. Descargar el tarball y `sha256sum` — SIEMPRE contra el registro de esta receta; cualquier
   float/`latest` queda prohibido (política de pins del repo).
3. Re-audit: diff `dist/` vs `src/` del paquete (el bundle publicado incluye `src/`), y diff
   del comportamiento contra las 4 condiciones del auditor (¿sigue sin tocar token stores?
   ¿el circuit breaker 429 sigue? ¿el allowlist de contextos sigue?).
4. Solo tras re-audit: actualizar pin en `config/opencode/opencode.json`, bump del sha aquí,
   `cd ../ && ./build.sh` (validadores P1), y anotar la versión en el CHANGELOG del port.

## Árbol
```text
personal-recipe/
├── README.md                      # este fichero
├── bin/{oc-personal,oc-personal-serve,agy-shim}   # 755
└── config/opencode/
    ├── opencode.json              # pin 0.1.0 — raíz XDG aislada (= XDG_CONFIG_HOME=config/)
    └── agent/*.md                 # 7 personales, modelo=placeholder, denies de prod intactos
```
