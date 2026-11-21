#!/bin/sh
# gate.sh — F4 PreToolUse safety gate (agy opencode-suite plugin).
#
# DESIGN AGAINST UNPROVEN SCHEMA (docs/evidence/agy-probes.md P1: the hook schema is
# DOC-SOURCED ONLY, never fired live; the earlier "verified" claim was a false-green —
# ADR 0012 §6d). Consequences baked into this script:
#   * hooks.json uses matcher "*" (hooks.md: `"*"` matches ALL tools) — one gate per
#     call, no dependency on unproven tool-name tokens (run_command vs view_file).
#   * No dependency on arg-KEY casing: the docs example shows "CommandLine" (PascalCase)
#     but file-op keys are unconfirmed live. We therefore match VALUES: every string
#     anywhere under toolCall.args is tried against every floor glob (command AND path
#     patterns alike). Over-matching = deny = safe side.
#   * FAIL-CLOSED everywhere: floors file missing/empty, empty stdin, unparseable JSON,
#     python crash with no usable fallback -> {"decision":"deny"}. Never allow on error.
# Protected-path literals live in floors.txt (data file), never in shell commands.
set -u

# --- config at the top -------------------------------------------------------------
# Precedence: env override (tests) > absolute path baked by build.sh > script dir.
FLOORS="${AGY_FLOORS_FILE:-__AGY_FLOORS_ABS__}"
if [ ! -f "$FLOORS" ]; then
  d=$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd) || d=.
  FLOORS="$d/floors.txt"
fi

deny()  { printf '{"decision":"deny","reason":"%s"}\n' "$1"; exit 0; }
allow() { printf '{"decision":"allow"}\n'; exit 0; }

[ -f "$FLOORS" ] || deny "F4 safety gate: floors file not found - fail closed"
[ -s "$FLOORS" ] || deny "F4 safety gate: floors file empty - fail closed"

input=$(cat 2>/dev/null) || true
[ -n "$input" ] || deny "F4 safety gate: empty stdin - fail closed"

if command -v python3 >/dev/null 2>&1; then
  py='
import fnmatch, json, sys
floors = []
for line in open(sys.argv[1], encoding="utf-8"):
    line = line.strip()
    if line and not line.startswith("#"):
        floors.append(line)
if not floors:
    print(json.dumps({"decision": "deny", "reason": "F4 gate: no patterns in floors file - fail closed"}))
    raise SystemExit
try:
    payload = json.loads(sys.stdin.read())
except Exception:
    print(json.dumps({"decision": "deny", "reason": "F4 gate: unparseable hook stdin - fail closed"}))
    raise SystemExit
if not isinstance(payload, dict):
    print(json.dumps({"decision": "deny", "reason": "F4 gate: hook stdin not an object - fail closed"}))
    raise SystemExit
tc = payload.get("toolCall")
if not isinstance(tc, dict):
    # tolerate opencode-shaped payloads if the live schema ever differs from the docs
    tc = payload.get("tool_input")
if not isinstance(tc, dict):
    tc = {}
args = tc.get("args")
if args is None:
    args = tc
def strings(x):
    if isinstance(x, str):
        yield x
    elif isinstance(x, dict):
        for v in x.values():
            yield from strings(v)
    elif isinstance(x, list):
        for v in x:
            yield from strings(v)
name = str(tc.get("name", "?"))
hits = []
for s in strings(args):
    for f in floors:
        if fnmatch.fnmatchcase(s, f):
            hits.append(f)
            break
    if len(hits) >= 3:
        break
if hits:
    print(json.dumps({"decision": "deny",
                      "reason": "F4 safety gate: floors match [" + ", ".join(hits) + "] on tool " + name},
                     ensure_ascii=False))
else:
    print(json.dumps({"decision": "allow"}))
'
  out=$(printf '%s' "$input" | python3 -c "$py" "$FLOORS" 2>/dev/null) || out=""
  case "$out" in
    '{"decision"'*) printf '%s\n' "$out"; exit 0 ;;
    *) deny "F4 safety gate: python evaluation failed - fail closed" ;;
  esac
fi

# --- fallback, documented: no python3 on PATH --------------------------------------
# Heuristic substring grep of each pattern (surrounding * stripped) against the RAW
# stdin. Coarser than the python path: payload metadata (workspacePaths etc.) can
# over-match -> over-deny. It can never UNDER-deny relative to truth, which keeps the
# fail-closed property. Missing floors or no match -> handled below.
if command -v grep >/dev/null 2>&1; then
  hits=""
  while IFS= read -r pat; do
    case "$pat" in ''|'#'*) continue ;; esac
    sub=${pat#\*}
    sub=${sub%\*}
    [ -n "$sub" ] || continue
    if printf '%s' "$input" | grep -qF -- "$sub" 2>/dev/null; then
      hits="$hits $pat"
    fi
  done < "$FLOORS"
  if [ -n "$hits" ]; then
    deny "F4 safety gate (grep fallback): floors match$hits"
  fi
  allow
fi

deny "F4 safety gate: no evaluator (python3/grep absent) - fail closed"
