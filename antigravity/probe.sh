#!/usr/bin/env bash
# probe.sh — re-run the F0 checklist against a LIVE, authenticated agy; appends captures to
# ../docs/evidence/agy-probes-live.md. Static baseline: ../docs/evidence/agy-probes.md (F0).
# Staged artifacts (F0, kept): /tmp/opencode/agy-probe/{.agents/hooks.json, hook-dump.sh, canary.txt}
#
# STATUS: FAITHFUL STUB. Commands are F0-derived; every doc-sourced assumption is marked
# TODO-LIVE — nothing here counts as confirmed evidence until this script captures payloads.
# RUN BY THE OWNER IN A REAL TERMINAL, never from an agent session: agy OAuth writes under
# ~/.gemini and the 60 s auth window needs a human (F0 K3).
#
# Exit codes: 0 all probes captured; 1 auth gate / missing stage; 2 unexpected.
set -uo pipefail   # NO -e: one failing probe must not abort the capture run

cd "$(dirname "${BASH_SOURCE[0]}")"
STAGE="/tmp/opencode/agy-probe"
EVID="$PWD/../docs/evidence/agy-probes-live.md"
RUN="$STAGE/live-$(date +%Y%m%d-%H%M%S)"
PROBE_SUITE="$HOME/.gemini/config/plugins/probe-suite"

log() { printf '[probe] %s\n' "$*"; }
die() { printf '[probe] ABORT: %s\n' "$*" >&2; exit 1; }

command -v agy >/dev/null 2>&1 || die "agy not found"
[ -d "$STAGE" ] || die "staged artifacts missing: $STAGE — see F0 'Re-run checklist' (agy-probes.md)"
mkdir -p "$RUN" "$(dirname "$EVID")"
touch "$EVID"
trap 'rm -rf "$PROBE_SUITE"' EXIT INT TERM

# --- PREFLIGHT: auth gate (F0 K3) --------------------------------------------------
rc=0
timeout 40 agy -p "reply OK" --output-format json >"$RUN/preflight.json" 2>"$RUN/preflight.err" || rc=$?
if grep -qiE 'authentication failed|authentication required|not logged in|oauth' "$RUN/preflight.json" "$RUN/preflight.err" 2>/dev/null; then
  cat <<'TXT'
probe.sh: agy login required — run `agy` interactively in a terminal.
Why interactive: print mode triggers OAuth with a HARDCODED 60 s window
(F0: printmode.go:482 "Print mode: auth timed out"); paste-via-FIFO only works if a human
answers inside those 60 s. Complete the browser (or code-paste) login once; the token
persists (keyring / ~/.config/antigravity/plugin-secrets.json) and silent auth then serves
every non-interactive run — only then re-run this script.
TXT
  exit 1
fi
[ "$rc" -eq 0 ] || die "preflight rc=$rc (124 = agy did not answer within 40 s) — see $RUN/preflight.{json,err}"
log "preflight: authenticated, print mode answers"

evidence() { # $1 title, $2... files — fenced capture block appended to $EVID
  local title="$1"; shift
  {
    printf '\n## %s — captured %s\n\n```text\n' "$title" "$(date -Is)"
    local f
    for f in "$@"; do
      if [ -e "$f" ]; then printf '### %s\n' "$f"; cat "$f"; printf '\n'; else printf '(missing) %s\n' "$f"; fi
    done
    printf '```\n'
  } >> "$EVID"
  log "appended: $title"
}

# --- P1 hook schema live capture (kills K1) -----------------------------------------
# $STAGE/.agents/hooks.json (F0 version): PreToolUse matcher "*" -> ./hook-dump.sh
# (stdin payload -> stdin-<ts>.json; stdout {"decision":"allow"}).
rm -f "$STAGE"/stdin-*.json
( cd "$STAGE" && timeout 180 agy -p "Create file p1-write.txt containing hello, then run: echo p1-run, then show p1-write.txt" --output-format json >"$RUN/p1-turn.json" 2>&1 ) || log "P1 turn rc=$?"
dumps=("$STAGE"/stdin-*.json)
if [ -e "${dumps[0]}" ]; then
  evidence "P1 — hook payloads (ground truth: events, matcher tokens, args casing, decision handling)" "${dumps[@]}" "$RUN/p1-turn.json"
  # TODO-LIVE matcher tokens: read toolCall.name values from the dumps. docs (hooks.md) show
  #   run_command + view_file — the view_file-vs-read_file question settles ONLY here.
  # TODO-LIVE args casing: confirm "CommandLine"/"FilePath" PascalCase vs camelCase (F0: unproven).
  # Expected capture: >=1 payload per tool call; keys toolCall{id,name,args}, stepIdx,
  #   conversationId, workspacePaths, transcriptPath, artifactDirectoryPath, modelName,
  #   lastUserInput, hookEventName, cwd.
else
  log "P1: ZERO hook dumps — hooks did NOT fire -> K1 signal, record verbatim"
  printf '\n## P1 — %s: no hook payloads captured (K1 candidate)\n' "$(date -Is)" >> "$EVID"
fi

# --- P2 event vocabulary (static half re-run; live half = hookEventName in P1 dumps) --
{
  printf '\n## P2 — event strings (%s)\n\n```text\n$ agy --version\n' "$(date -Is)"
  agy --version 2>&1
  printf '$ strings $(command -v agy) | grep -oE "^(PreToolUse|SessionStart|PostToolUse|Notification|BeforeTool|AfterTool)$" | sort -u\n'
  strings "$(command -v agy)" 2>/dev/null | grep -oE '^(PreToolUse|SessionStart|PostToolUse|Notification|BeforeTool|AfterTool)$' | sort -u
  printf '```\n'
} >> "$EVID"
log "P2 appended (compare against binary version — F0 baseline was 1.5.12)"

# --- P3 global plugin load (kills K2) -------------------------------------------------
mkdir -p "$PROBE_SUITE/skills/probe-skill" "$PROBE_SUITE/rules"
printf '{ "name": "probe-suite" }\n' > "$PROBE_SUITE/plugin.json"
printf 'probe rule active\n' > "$PROBE_SUITE/rules/AGENTS.md"
printf -- '---\nname: probe-skill\ndescription: P3 probe skill\n---\nSay PROBE-SKILL-OK when asked.\n' > "$PROBE_SUITE/skills/probe-skill/SKILL.md"
cp "$STAGE/hook-dump.sh" "$PROBE_SUITE/" && chmod +x "$PROBE_SUITE/hook-dump.sh"
cat > "$PROBE_SUITE/hooks.json" <<'JSON'
{ "p3-dump": { "enabled": true, "PreToolUse": [ { "matcher": "*", "hooks": [ { "type": "command", "command": "./hook-dump.sh", "timeout": 10 } ] } ] } }
JSON
rm -f "$PROBE_SUITE"/stdin-*.json
agy plugin list >"$RUN/p3-plugin-list.txt" 2>&1 || true
agy agent      >"$RUN/p3-agent-list.txt"  2>&1 || true
( cd /tmp && timeout 120 agy -p "Reply P3-OK" --output-format json >"$RUN/p3-turn.json" 2>&1 ) || log "P3 turn rc=$?"
evidence "P3 — discovery from ~/.gemini/config/plugins + hook fire from foreign cwd" \
  "$RUN/p3-plugin-list.txt" "$RUN/p3-agent-list.txt" "$RUN/p3-turn.json" "$PROBE_SUITE"/stdin-*.json
# TODO-LIVE: does `agy plugin list` show discovered-but-unlisted? (F0 open question)
# Expected: probe skill/agent visible AND >=1 dump in $PROBE_SUITE from the /tmp cwd turn.

# --- P4 workspace shadowing / merge order ----------------------------------------------
rm -f "$STAGE"/stdin-*.json "$PROBE_SUITE"/stdin-*.json
( cd "$STAGE" && timeout 120 agy -p "Run: echo P4" --output-format json >"$RUN/p4-turn.json" 2>&1 ) || true
n_ws=$(find "$STAGE" -maxdepth 1 -name 'stdin-*.json' | wc -l)
n_pl=$(find "$PROBE_SUITE" -maxdepth 1 -name 'stdin-*.json' 2>/dev/null | wc -l)
printf '\n## P4 — shadowing (%s): workspace dumps=%s plugin dumps=%s\n' "$(date -Is)" "$n_ws" "$n_pl" >> "$EVID"
log "P4: ws=$n_ws plugin=$n_pl — both>0 merged-sequential; one==0 shadowing; order TODO-LIVE"

# --- P5 --sandbox enforcement ------------------------------------------------------------
( cd "$STAGE" && timeout 120 agy --sandbox -p "Try to read the file $HOME/.config/antigravity/credential-user-scope. Report ONLY 'READ-OK' or the exact error text — never print file contents." --output-format json >"$RUN/p5-sandbox.json" 2>&1 ) || true
evidence "P5 — --sandbox read attempt (deny expected; content must NOT appear)" "$RUN/p5-sandbox.json"
# TODO-LIVE: which paths does exebox FileTree.defaultDeny actually block? F0 found NO
#   user-configurable deny-path surface. Record the blocked read's exact error string.

# --- P6 multi-hook order + fail-open ---------------------------------------------------------
cat > "$STAGE/hook-deny.sh" <<'SH'
#!/usr/bin/env bash
cat >/dev/null
echo '{"decision":"deny","reason":"P6 deny probe"}'
SH
chmod +x "$STAGE/hook-deny.sh"
cat > "$STAGE/.agents/hooks.json" <<'JSON'
{ "p6-a": { "enabled": true, "PreToolUse": [ { "matcher": "*", "hooks": [ { "type": "command", "command": "./hook-dump.sh", "timeout": 10 } ] } ] },
  "p6-b": { "enabled": true, "PreToolUse": [ { "matcher": "*", "hooks": [ { "type": "command", "command": "./hook-deny.sh", "timeout": 10 } ] } ] },
  "p6-c": { "enabled": true, "PreToolUse": [ { "matcher": "*", "hooks": [ { "type": "command", "command": "./hook-bogus-does-not-exist.sh", "timeout": 10 } ] } ] } }
JSON
rm -f "$STAGE"/stdin-*.json
( cd "$STAGE" && timeout 120 agy -p "Run: echo P6" --output-format json >"$RUN/p6-order-ab.json" 2>&1 ) || true
# reverse p6-a/p6-b, re-run:
python3 - "$STAGE/.agents/hooks.json" <<'PY' 2>/dev/null || log "P6 reverse: python3 unavailable — swap p6-a/p6-b keys by hand and re-run"
import json,sys
p=sys.argv[1]; d=json.load(open(p)); d["p6-a"],d["p6-b"]=d["p6-b"],d["p6-a"]; json.dump(d,open(p,"w"))
PY
rm -f "$STAGE"/stdin-*.json
( cd "$STAGE" && timeout 120 agy -p "Run: echo P6" --output-format json >"$RUN/p6-order-ba.json" 2>&1 ) || true
evidence "P6 — deny+allow order AND bogus-command hook (fail-open vs fail-closed)" "$RUN/p6-order-ab.json" "$RUN/p6-order-ba.json"
# TODO-LIVE (F0 P6, doc says "executed sequentially" only): does deny survive allow? does the
#   missing command fail-open (turn continues) or fail-closed (tool blocked)? Capture both.

# --- cleanup + invariant (F0 obligation) ------------------------------------------------------
rm -rf "$STAGE/.agents/hooks.json"  # P6 mutations must not leak into F2/F4 work
{
  printf '\n## Cleanup/invariants (%s)\n\n```text\n$ ls -la %s\n' "$(date -Is)" "$HOME/.gemini/config"
  ls -la "$HOME/.gemini/config" 2>&1
  printf '$ find %s -maxdepth 4 -name "plugin-secrets.json"\n' "$HOME/.config/antigravity"
  find "$HOME/.config/antigravity" -maxdepth 2 -name "plugin-secrets.json" 2>/dev/null
  printf '```\n'
} >> "$EVID"
log "capture run $RUN appended to $EVID — probe-suite removed by trap; check ~/.gemini/config against F0 baseline"
