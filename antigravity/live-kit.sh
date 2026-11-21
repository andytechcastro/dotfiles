#!/usr/bin/env bash
# live-kit.sh — F4 live hook-schema capture kit for agy (Antigravity CLI).
#
# WHY: the hooks schema is DOC-SOURCED ONLY (docs/evidence/agy-probes.md P1); the earlier
# "live-verified" claim was a false-green, retracted in ADR 0012 §6d. This kit captures
# REAL hook payloads so the schema table can finally be filled with evidence.
#
# WHO RUNS IT: the owner (Tony), in his AUTHENTICATED interactive terminal. The opencode
# daemon CANNOT authenticate agy on this machine (F0 K3: no token in keyring/file store)
# — never run this kit from an agent session.
#
# Usage:  bash antigravity/live-kit.sh
# Idempotent: self-installs to /tmp/opencode/agy-livekit/ and relaunches from there;
# previous dumps are rotated to .agents/dumps.prev.<epoch>, never deleted.
set -euo pipefail
export LC_ALL=C

ROOT="/tmp/opencode/agy-livekit"
WS="$ROOT/workspace"
AG="$WS/.agents"
DUMPS="$AG/dumps"
SELF="$(readlink -f "${BASH_SOURCE[0]}")"

# --- idempotent self-install --------------------------------------------------------
if [ "$SELF" != "$ROOT/live-kit.sh" ]; then
  mkdir -p "$ROOT"
  cp -f "$SELF" "$ROOT/live-kit.sh"
  echo "[livekit] instalado en $ROOT/live-kit.sh — relanzando desde allí"
  exec bash "$ROOT/live-kit.sh" "$@"
fi

command -v agy >/dev/null 2>&1 || { echo "[livekit] FATAL: agy no está en PATH" >&2; exit 1; }

mkdir -p "$AG"
if [ -d "$DUMPS" ] && [ -n "$(ls -A "$DUMPS" 2>/dev/null)" ]; then
  mv "$DUMPS" "$AG/dumps.prev.$(date +%s)"
  echo "[livekit] dumps previos rotados a $AG/dumps.prev.*"
fi
mkdir -p "$DUMPS"

printf 'AGY-LIVEKIT-CANARY — si puedes leer este fichero, una herramienta de lectura disparó los hooks y el volcado existe.\n' > "$WS/canary.txt"

# --- dump hook: writes the FULL stdin of every event to dumps/NNN.json --------------
cat > "$AG/dump.sh" <<'DUMP'
#!/bin/sh
# dump.sh — captura cruda del payload de cada evento hook (kit F4).
# El cwd de un hook es el directorio que contiene hooks.json (= .agents) — hooks.md.
# Responde {"decision":"allow"}: en PreToolUse evita prompts; en el resto de eventos
# la clave es ignorada. NO niega nada: este kit observa, no gatea.
set -u
cd "$(dirname "$0")" || exit 0
n=0
[ -f dumps/.count ] && n=$(cat dumps/.count 2>/dev/null || echo 0)
n=$((n + 1))
printf '%s' "$n" > dumps/.count
f=$(printf 'dumps/%03d.json' "$n")
cat > "$f"
printf '{"decision":"allow"}\n'
DUMP
chmod 755 "$AG/dump.sh"

# --- hooks.json: 5 eventos, Pre/PostToolUse con matcher "*" --------------------------
cat > "$AG/hooks.json" <<'HOOKS'
{
  "livekit-dump": {
    "enabled": true,
    "SessionStart": [
      { "type": "command", "command": "./dump.sh", "timeout": 10 }
    ],
    "PreInvocation": [
      { "type": "command", "command": "./dump.sh", "timeout": 10 }
    ],
    "PreToolUse": [
      { "matcher": "*", "hooks": [ { "type": "command", "command": "./dump.sh", "timeout": 10 } ] }
    ],
    "PostToolUse": [
      { "matcher": "*", "hooks": [ { "type": "command", "command": "./dump.sh", "timeout": 10 } ] }
    ],
    "Stop": [
      { "type": "command", "command": "./dump.sh", "timeout": 10 }
    ]
  }
}
HOOKS

# --- summary analyzer ----------------------------------------------------------------
cat > "$ROOT/summary.py" <<'PY'
import collections, glob, json, os, sys
d = sys.argv[1]
files = sorted(glob.glob(os.path.join(d, "[0-9][0-9][0-9].json")))
events = collections.Counter()
tools = collections.Counter()
keys = collections.defaultdict(set)
pre_fired = False
errs = 0
for f in files:
    try:
        p = json.load(open(f, encoding="utf-8"))
    except Exception:
        errs += 1
        continue
    if not isinstance(p, dict):
        errs += 1
        continue
    ev = p.get("hookEventName") or "SIN_HOOK_EVENT_NAME"
    events[ev] += 1
    tc = p.get("toolCall")
    if isinstance(tc, dict):
        nm = str(tc.get("name", "?"))
        tools[nm] += 1
        a = tc.get("args")
        if isinstance(a, dict):
            keys[nm].update(a.keys())
        elif a is not None:
            keys[nm].add("<args-no-dict:" + type(a).__name__ + ">")
    if ev == "PreToolUse":
        pre_fired = True
print("=== resumen captura livekit F4 ===")
print("dumps totales: %d  (parse-errors: %d)" % (len(files), errs))
print("eventos capturados:")
for k in sorted(events):
    print("  %-16s %d" % (k, events[k]))
print("tool names observados (toolCall.name):")
for k in sorted(tools):
    print("  %-24s %d" % (k, tools[k]))
print("claves de toolCall.args por tool:")
for k in sorted(keys):
    print("  %-24s %s" % (k, sorted(keys[k])))
print("matcher '*' PreToolUse disparó: %s" % ("SI" if pre_fired else "NO"))
print("dumps en:", d)
PY

cat > "$ROOT/ANALISIS.md" <<'DOC'
# Qué hacer con los dumps (para el Commander tras la sesión de Tony)
- docs/evidence/agy-probes.md P1 tiene la tabla DOC-SOURCED a confirmar: claves raíz
  (toolCall.id/name/args, stepIdx + campos comunes), token de matcher real, casing de
  args ("CommandLine" PascalCase vs path keys), orden multi-hook y fail-open/closed (P6).
- dumps/NNN.json = stdin CRUDO de cada evento, en orden de ejecución.
- Si PreToolUse no disparó con "*": revisar salida de agy y probar matcher vacío "".
- La carpeta de dumps NO se borra: es la evidencia. Rotar repitiendo live-kit.sh.
DOC

echo
echo "=============================================================================="
echo " LIVE-KIT F4 listo en $WS"
echo "=============================================================================="
echo "INSTRUCCIONES PARA TONY (terminal autenticado — aquí NO se puede loguear agy):"
echo
echo "  1) Se lanzará 'agy' interactivo con cwd $WS (si pide trust, acepta ESTE repo de probe)."
echo "  2) Pídele al agente main 3 turnos INOCUOS, uno por turno:"
echo "       turno 1: «lee canary.txt y dime su contenido»"
echo "       turno 2: «ejecuta el comando: echo hola»"
echo "       turno 3: «crea un fichero probe.txt con el texto ping»"
echo "  3) Sal de agy (Ctrl-D o /exit). NO pidas nada peligroso a propósito: el gate real"
echo "     del plugin se prueba aparte; aquí solo capturamos el SHAPE de los payloads."
echo "  4) Al volver, este script imprime la tabla resumen y los dumps quedan en $DUMPS"
echo "     para análisis del Commander (ver $ROOT/ANALISIS.md)."
echo
echo "  Si agy muere por auth: logueate antes ('agy' a secas y completa OAuth) y repite."
echo "=============================================================================="
echo

rc=0
( cd "$WS" && agy ) || rc=$?
echo "[livekit] agy terminó (exit $rc)"
echo
if command -v python3 >/dev/null 2>&1; then
  python3 "$ROOT/summary.py" "$DUMPS"
else
  echo "=== resumen (fallback sin python3) ==="
  echo "dumps: $(find "$DUMPS" -maxdepth 1 -name '[0-9][0-9][0-9].json' | wc -l)"
  grep -ho '"hookEventName":"[^"]*"' "$DUMPS"/*.json 2>/dev/null | sort | uniq -c || echo "sin eventos capturados"
fi
echo
echo "[livekit] dumps crudos en $DUMPS — NO borrar; son la evidencia para el Commander."
