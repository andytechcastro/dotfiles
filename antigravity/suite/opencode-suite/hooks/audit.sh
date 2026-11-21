#!/bin/sh
# audit.sh — F4 PostToolUse audit trail (append-only JSONL). NEVER blocks.
# PostToolUse expects {} on stdout (hooks.md §2); we always print {} and exit 0.
# Fail-OPEN here is deliberate: the security surface is gate.sh (fail-CLOSED); the
# audit trail is observability, and a broken observability path must not brick the
# agent loop (P6 fail-open/closed for multi-hook chains is unproven — never let the
# audit hook become a load-bearing failure point).
set -u

# --- log root: configurable at the top (env override for tests) --------------------
AUDIT_DIR="${AGY_AUDIT_DIR:-$HOME/.agy-audit}"
AUDIT_FILE="$AUDIT_DIR/agy-audit.jsonl"

mkdir -p "$AUDIT_DIR" 2>/dev/null || true
input=$(cat 2>/dev/null) || true
ts=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)

line=""
if command -v python3 >/dev/null 2>&1 && [ -n "$input" ]; then
  line=$(printf '%s' "$input" | python3 -c '
import json, sys
raw = sys.stdin.read()
try:
    d = json.loads(raw)
    tc = d.get("toolCall") if isinstance(d, dict) else None
    rec = {"audit_ts": sys.argv[1],
           "event": d.get("hookEventName") if isinstance(d, dict) else None,
           "tool": (tc or {}).get("name") if isinstance(tc, dict) else None,
           "payload": d}
except Exception:
    rec = {"audit_ts": sys.argv[1], "parse_error": True, "raw": raw[:2000]}
print(json.dumps(rec, ensure_ascii=False, separators=(",", ":")))
' "$ts" 2>/dev/null) || line=""
fi
if [ -z "$line" ]; then
  # degraded single-line record: never lose the event, never block the loop
  safe=$(printf '%s' "$input" | tr '\n\r\t' '   ' | cut -c1-500 | tr '"' "'")
  line="{\"audit_ts\":\"$ts\",\"parse_error\":true,\"note\":\"audit degraded: no python3 or empty stdin\",\"raw_truncated\":\"$safe\"}"
fi
printf '%s\n' "$line" >> "$AUDIT_FILE" 2>/dev/null || true
printf '{}\n'
exit 0
