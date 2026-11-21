#!/usr/bin/env bash
# verify.sh — read-only integrity checks after build/sync. NO network, NO writes, NO agy calls.
# Exit 0 while only warnings; FAIL sets exit 1. F4: hooks asserts are REAL (no more WARN stubs).
set -uo pipefail
export LC_ALL=C

cd "$(dirname "${BASH_SOURCE[0]}")"

DIST="dist"
LOCAL_BASE="${HOME}/.gemini/config/plugins"
NAMES=(opencode-suite opencode-personal)
FAILED=0

ok()   { printf '[verify] OK:   %s\n' "$*"; }
warn() { printf '[verify] WARN: %s\n' "$*"; }
fail() { printf '[verify] FAIL: %s\n' "$*"; FAILED=1; }

json_parses() { # $1=file -> 0 ok, 1 invalid, 2 no parser (python3 preferred, node fallback; jq unverified)
  local f="$1"
  if command -v python3 >/dev/null 2>&1; then
    python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$f" >/dev/null 2>&1
    return $?
  fi
  if command -v node >/dev/null 2>&1; then
    node -e 'JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"))' "$f" >/dev/null 2>&1
    return $?
  fi
  return 2
}

# 1) manifest vs dist (dist must always be build.sh-clean) -------------------------
if [ ! -f "$DIST/manifest.sha256" ]; then
  fail "$DIST/manifest.sha256 missing — run ./build.sh"
else
  if (cd "$DIST" && sha256sum --status -c manifest.sha256); then
    ok "dist/ matches manifest.sha256 ($(wc -l < "$DIST/manifest.sha256") entries)"
  else
    (cd "$DIST" && sha256sum -c manifest.sha256 2>&1 | grep -v ': OK$' >&2) || true
    fail "dist/ drifted from manifest.sha256 — rebuild with ./build.sh"
  fi
fi

for n in "${NAMES[@]}"; do
  # 2) plugin layout in dist ----------------------------------------------------------
  for d in agents rules skills; do
    if [ -d "$DIST/$n/$d" ]; then ok "$n/$d present in dist"; else fail "$n/$d missing in dist"; fi
  done

  # 3) plugin.json parses (pure JSON; JSONC-superset safe — see README contract notes)
  if json_parses "$DIST/$n/plugin.json"; then
    ok "$n: plugin.json parses"
  elif [ ! -f "$DIST/$n/plugin.json" ]; then
    fail "$n: plugin.json missing in dist"
  else
    fail "$n: plugin.json is not valid JSON"
  fi

  # 4) F4 hooks surface (suite only — personal ships NO hooks, by design) + F5 mcp ----
  if [ "$n" = "opencode-suite" ]; then
    if [ -f "$DIST/$n/hooks.json" ]; then ok "suite: hooks.json present (plugin root)"; else fail "suite: hooks.json missing at plugin root (F4)"; fi
    if json_parses "$DIST/$n/hooks.json"; then ok "suite: hooks.json parses"; else fail "suite: hooks.json is not valid JSON"; fi
    for ev in SessionStart PreToolUse PostToolUse; do
      if grep -q "\"$ev\"" "$DIST/$n/hooks.json" 2>/dev/null; then ok "suite: hooks.json declares $ev"; else fail "suite: hooks.json missing $ev (F4)"; fi
    done
    for s in gate.sh audit.sh session-start.sh; do
      if [ -x "$DIST/$n/hooks/$s" ]; then ok "suite: hooks/$s present + executable"; else fail "suite: hooks/$s missing or non-executable (F4)"; fi
    done
    FL="$DIST/$n/hooks/floors.txt"
    if [ -f "$FL" ]; then
      npat=$(grep -Ec '^[^#[:space:]]' "$FL")
      if [ "$npat" -ge 14 ]; then ok "suite: floors.txt presente con $npat patrones (>=14)"; else fail "suite: floors.txt con solo $npat patrones (<14)"; fi
    else
      fail "suite: hooks/floors.txt missing (F4 data file)"
      npat=0
    fi
    CT="$DIST/$n/hooks/contracto.md"
    if [ -s "$CT" ]; then
      csz=$(wc -c < "$CT")
      if [ "$csz" -le 4096 ]; then ok "suite: hooks/contracto.md presente (${csz} B <= 4096)"; else fail "suite: contracto.md ${csz} B excede 4096 (presupuesto ~2 KB)"; fi
    else
      fail "suite: hooks/contracto.md missing/empty (F4 SessionStart payload)"
    fi
  else
    ok "$n: sin hooks.json — por diseño (el gate vive solo en el suite técnico)"
  fi
  if [ -f "$DIST/$n/mcp_config.json" ]; then
    ok "$n: mcp_config.json present"
  elif [ "$n" = "opencode-personal" ]; then
    ok "$n: sin mcp_config.json — por diseño (F5: solo el suite expone MCPs)"
  else
    fail "$n: mcp_config.json ausente — es artefacto F5 del suite"
  fi

  # 5) installed tree vs same manifest (nothing installed until F6 -> WARN) -----------
  if [ ! -d "$LOCAL_BASE/$n" ]; then
    warn "$n not installed under $LOCAL_BASE — expected until F6"
    continue
  fi
  # F6 fix: manifest lines start with the HASH — match the PATH column, and let
  # --strict fail on malformed input instead of silently passing (T1 lesson).
  if [ -f "$DIST/manifest.sha256" ] && grep -Eq "^[0-9a-f]{64}  $n/" "$DIST/manifest.sha256"; then
    if grep -E "^[0-9a-f]{64}  $n/" "$DIST/manifest.sha256" | (cd "$LOCAL_BASE" && sha256sum --strict -c - >/dev/null 2>&1); then
      ok "installed $n matches manifest"
    else
      fail "installed $n drifted from manifest — re-run ./sync.sh (hand-edits under ~/.gemini are not allowed)"
    fi
  else
    warn "$n: no manifest entries — rebuild dist"
  fi
  json_parses "$LOCAL_BASE/$n/plugin.json" && ok "$n: installed plugin.json parses" || fail "$n: installed plugin.json invalid/missing"
  if [ "$n" = "opencode-suite" ]; then
    [ -x "$LOCAL_BASE/$n/hooks/gate.sh" ] && ok "installed suite: gate.sh executable (sync 755)" || fail "installed suite: gate.sh NOT executable — re-run ./sync.sh (F4 chmod)"
  fi
done

# 6) F4 gate.sh LOCAL dry-test (synthetic JSON + FAKE canaries — no real protected
#    paths, no agy invocation, no network). Expect deny / deny / allow.
GATE="$DIST/opencode-suite/hooks/gate.sh"
FL="$DIST/opencode-suite/hooks/floors.txt"
if [ -x "$GATE" ] && [ -f "$FL" ]; then
  export AGY_FLOORS_FILE="$FL"
  # t1: fake path canary (matches the ssh floor; FAKEHOME is not a real dir)
  d1=$(printf '%s' '{"toolCall":{"id":"t1","name":"view_file","args":{"path":"/home/andres/FAKEHOME/.ssh-canary"}},"hookEventName":"PreToolUse","cwd":"/tmp"}' | sh "$GATE" 2>/dev/null)
  # t2: destructive command shape (harmless string, matched by pattern only)
  d2=$(printf '%s' '{"toolCall":{"id":"t2","name":"run_command","args":{"CommandLine":"rm -rf / --no-preserve-root"}},"hookEventName":"PreToolUse","cwd":"/tmp"}' | sh "$GATE" 2>/dev/null)
  # t3: innocuous command
  d3=$(printf '%s' '{"toolCall":{"id":"t3","name":"run_command","args":{"CommandLine":"echo hola"}},"hookEventName":"PreToolUse","cwd":"/tmp"}' | sh "$GATE" 2>/dev/null)
  # t4: fail-closed probe — unparseable stdin must deny
  d4=$(printf '%s' 'no-json-at-all{' | sh "$GATE" 2>/dev/null)
  is_deny() { case "$1" in *'"decision"'*'"deny"'*|*'"decision": "deny"'*) return 0;; *) return 1;; esac; }
  is_allow() { case "$1" in *'"decision"'*'"allow"'*|*'"decision": "allow"'*) return 0;; *) return 1;; esac; }
  is_deny "$d1" && ok "dry-test t1 fake-canary path  -> deny"  || fail "dry-test t1 expected deny, got: $d1"
  is_deny "$d2" && ok "dry-test t2 rm-rf-root cmd   -> deny"  || fail "dry-test t2 expected deny, got: $d2"
  is_allow "$d3" && ok "dry-test t3 innocuous echo   -> allow" || fail "dry-test t3 expected allow, got: $d3"
  is_deny "$d4" && ok "dry-test t4 broken stdin     -> deny (fail-closed)" || fail "dry-test t4 expected deny, got: $d4"
  unset AGY_FLOORS_FILE
else
  fail "dry-test SKIP: gate.sh o floors.txt ausentes en dist (F4 roto)"
fi

# 7) functional LIVE deny-test sigue pendiente: requiere sesión autenticada de agy
#    (F0 K3). Herramienta: ./live-kit.sh en el terminal de Tony -> dumps + resumen.
warn "PENDING: live hook firing (K1) — usar antigravity/live-kit.sh con agy autenticado"

if [ "$FAILED" -ne 0 ]; then
  printf '[verify] RESULT: FAIL\n' >&2
  exit 1
fi
printf '[verify] RESULT: PASS (warnings above are pending-live-verification states)\n'
