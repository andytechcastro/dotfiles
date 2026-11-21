#!/bin/sh
# session-start.sh — F4 SessionStart contract injection (agy opencode-suite).
# Schema decision per hooks.md §3: SessionStart output is
#   {"injectSteps":[{"systemMessage":{"systemMessage":"<text>"}}]}
# (nested object, NOT a plain string; persists in the conversation trajectory).
# "additionalContext" is an OpenCode/Claude-Code field that DOES NOT EXIST in agy's
# schema — rejected. systemMessage it is.
# Failure mode: fail-OPEN on purpose (missing injection = DX degradation, not a
# security hole; the security surface is gate.sh).
set -u

d=$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd) || d=.
CONTRACT="${AGY_CONTRACT_FILE:-$d/contracto.md}"

[ -f "$CONTRACT" ] || { printf '{}\n'; exit 0; }
command -v python3 >/dev/null 2>&1 || { printf '{}\n'; exit 0; }
python3 -c '
import json, sys
text = open(sys.argv[1], encoding="utf-8").read()
print(json.dumps({"injectSteps": [{"systemMessage": {"systemMessage": text}}]}, ensure_ascii=False))
' "$CONTRACT" 2>/dev/null || printf '{}\n'
exit 0
