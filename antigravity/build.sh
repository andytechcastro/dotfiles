#!/usr/bin/env bash
# build.sh — compile the agy-port sources into dist/ ready for sync to ~/.gemini/config/plugins/.
#
# Sources : suite/opencode-suite/  personal/opencode-personal/  includes/<key>.md (fragments)
# Output  : dist/opencode-suite/   dist/opencode-personal/      dist/manifest.sha256
# Guards  : *.md {{INCLUDE:key}} flatten (whole-line tokens only); stray token after flatten = FAIL;
#           agents/*.md <= 24576 B; rules/*.md <= 6144 B (flattened bytes).
# Policy  : fail-closed. ATOMIC (FIX-R1 ACP): the whole build happens in the staging tree
#           dist.stage/ and every guard runs against it; dist/ is replaced with `mv` ONLY
#           after all guards pass, so a failed build leaves the previous dist/ + manifest
#           untouched (deviation flagged: the literal "dist/.stage" cannot be mv'd onto its
#           own parent, so staging is the sibling dist.stage/).
set -euo pipefail
export LC_ALL=C

cd "$(dirname "${BASH_SOURCE[0]}")"

DIST="dist"           # final tree (only ever written by the atomic swap)
STAGE="dist.stage"    # staging tree: built + validated here
INCLUDES="includes"
LIMIT_AGENTS=24576
LIMIT_RULES=6144
PAIRS=("suite/opencode-suite:opencode-suite" "personal/opencode-personal:opencode-personal")

log()  { printf '[build] %s\n' "$*"; }
fail() { printf '[build] FAIL: %s\n' "$*" >&2; exit 1; }

[ -d "$INCLUDES" ] || fail "includes/ missing ({{INCLUDE:key}} contract lives there)"

rm -rf "$STAGE"
mkdir -p "$STAGE"

for pair in "${PAIRS[@]}"; do
  src="${pair%%:*}"
  dst="${pair#*:}"
  [ -d "$src" ] || fail "source tree missing: $src"
  cp -a "$src" "$STAGE/$dst"
  [ -f "$STAGE/$dst/plugin.json" ] || fail "plugin.json missing in $STAGE/$dst"
  log "copied $src -> $STAGE/$dst"
done

# --- {{INCLUDE:key}} flatten ---------------------------------------------------
# One pass, no nesting: a line whose sole content is {{INCLUDE:key}} (surrounding
# blanks allowed) is replaced with the full contents of includes/<key>.md.
# Inline/partial tokens are NOT replaced -> caught by the stray-token guard below.
find "$STAGE" -type f -name '*.md' -print0 | sort -z | while IFS= read -r -d '' f; do
  grep -q '{{INCLUDE:' "$f" || continue
  log "flatten: ${f#"$STAGE"/}"
  if ! awk -v incdir="$INCLUDES" '
    {
      t = $0
      gsub(/^[ \t]+|[ \t]+$/, "", t)
      if (t ~ /^\{\{INCLUDE:[A-Za-z0-9_.-]+\}\}$/) {
        key = t
        sub(/^\{\{INCLUDE:/, "", key)
        sub(/\}\}$/, "", key)
        frag = incdir "/" key ".md"
        r = (getline ln < frag)
        if (r < 0) { printf "awk: missing include fragment: %s\n", frag > "/dev/stderr"; exit 42 }
        if (r > 0) { print ln; while ((getline ln < frag) > 0) print ln }
        close(frag)
        next
      }
      print
    }' "$f" > "$f.tmp"; then
    rm -f "$f.tmp"
    fail "flatten failed: $f"
  fi
  mv "$f.tmp" "$f"
done

if grep -rn '{{INCLUDE' "$STAGE" >/dev/null 2>&1; then
  grep -rn '{{INCLUDE' "$STAGE" >&2 || true
  fail "stray {{INCLUDE token survived flatten (inline tokens are not supported; whole-line only)"
fi

# --- size guards (flattened bytes) ---------------------------------------------
while IFS= read -r -d '' f; do
  sz=$(wc -c < "$f")
  [ "$sz" -le "$LIMIT_AGENTS" ] || fail "agents budget exceeded: ${f#"$STAGE"/} = ${sz} B > ${LIMIT_AGENTS} B"
done < <(find "$STAGE" -type f -path '*/agents/*.md' -print0)
while IFS= read -r -d '' f; do
  sz=$(wc -c < "$f")
  [ "$sz" -le "$LIMIT_RULES" ] || fail "rules budget exceeded: ${f#"$STAGE"/} = ${sz} B > ${LIMIT_RULES} B"
done < <(find "$STAGE" -type f -path '*/rules/*.md' -print0)

# --- F4: hooks surface (gate/audit/session-start) + data files ---------------------
# hooks.json lives at the PLUGIN ROOT (plugins.md NOTE: native plugins do not run
# extension staging). gate.sh/audit.sh/session-start.sh live in hooks/ (staged in the
# source tree); floors.txt + contracto.md are DATA files from includes/ — the protected
# literals live ONLY in floors.txt, never inline in commands.
HOOKS="$STAGE/opencode-suite/hooks"
[ -f "$STAGE/opencode-suite/hooks.json" ] || fail "F4: suite hooks.json missing at plugin root"
[ -d "$HOOKS" ] || fail "F4: suite hooks/ dir missing (gate.sh/audit.sh/session-start.sh)"
[ -f "$INCLUDES/floors.txt" ] || fail "F4: includes/floors.txt missing (gate data file)"
[ -f "$INCLUDES/contracto.md" ] || fail "F4: includes/contracto.md missing (SessionStart payload)"
cp "$INCLUDES/floors.txt" "$HOOKS/floors.txt"
cp "$INCLUDES/contracto.md" "$HOOKS/contracto.md"
# the contract must survive the flatten pass as final bytes: it carries no token
grep -q '{{INCLUDE' "$HOOKS/contracto.md" && fail "F4: contracto.md carries an unflattened token" || true
chmod 755 "$HOOKS"/*.sh
# bake the INSTALLED absolute floors path (gate.sh tries it first, falls back to its own
# dir, so dist-local runs and the verify.sh dry-test still work pre-sync)
sed -i "s|__AGY_FLOORS_ABS__|$HOME/.gemini/config/plugins/opencode-suite/hooks/floors.txt|" "$HOOKS/gate.sh"
grep -q '{{INCLUDE' "$HOOKS/gate.sh" && fail "token leaked into gate.sh" || true
FLOORS_N=$(grep -Ec '^[^#[:space:]]' "$HOOKS/floors.txt")
[ "$FLOORS_N" -ge 14 ] || fail "F4: floors.txt has only $FLOORS_N patterns (<14)"
CSZ=$(wc -c < "$HOOKS/contracto.md")
[ "$CSZ" -le 4096 ] || fail "F4: contracto.md ${CSZ} B > 4096 B (~2 KB budget)"
log "F4: hooks.json + gate.sh fail-closed (floors=$FLOORS_N, contracto=${CSZ} B, scripts 755)"

# --- workspace-root distribution stage (F8) -------------------------------------
# agy 1.5.12 registers plugin agents/ in listing but NOT in the agent catalog
# (plugins.md has no `agents` surface field; proto discovery = <repo>/.agents/).
# dotagents/ is a GENERATED stage (like dist/): flattened agents from BOTH plugins
# + the suite skills + the .agents/skills.json manifest. sync.sh distributes it to
# the explicit DOTAGENTS_TARGETS list only.
rm -rf dotagents
mkdir -p dotagents/agents dotagents/skills
cp -a "$STAGE/opencode-suite/agents/." dotagents/agents/
cp -a "$STAGE/opencode-personal/agents/." dotagents/agents/
cp -a "$STAGE/opencode-suite/skills/." dotagents/skills/
cp -a skills.json dotagents/skills.json
touch dotagents/.opencode-suite-managed   # ownership marker checked by sync.sh

# --- P1: personal-recipe validation (superficie opencode, NO plugins agy) -----------
# The recipe is a standalone XDG-isolated tree validated in place. It NEVER enters
# dist/manifest.sha256 (that manifest only covers the agy plugin surfaces).
REC="personal-recipe"
if [ -d "$REC" ]; then
  for b in bin/oc-personal bin/oc-personal-serve bin/agy-shim; do
    [ -f "$REC/$b" ] || fail "P1 recipe: $b missing"
    bash -n "$REC/$b" || fail "P1 recipe: bash -n failed in $b"
    [ -x "$REC/$b" ] || fail "P1 recipe: $b not executable"
  done
  REC_CFG="$REC/config/opencode/opencode.json"
  [ -f "$REC_CFG" ] || fail "P1 recipe: config/opencode/opencode.json missing (XDG layout, see recipe README)"
  if command -v python3 >/dev/null 2>&1; then
    python3 - "$REC_CFG" <<'PYPIN' || fail "P1 recipe: opencode.json no parseable o pin != opencode-antigravity-acp@0.1.0"
import json, sys
d = json.load(open(sys.argv[1], encoding="utf-8"))
assert d.get("plugin") == ["opencode-antigravity-acp@0.1.0"], "plugin pin drifted"
PYPIN
  else
    grep -q '"opencode-antigravity-acp@0.1.0"' "$REC_CFG" || fail "P1 recipe: pin string missing"
  fi
  NA=$(find "$REC/config/opencode/agent" -maxdepth 1 -name '*.md' | wc -l)
  [ "$NA" -eq 7 ] || fail "P1 recipe: $NA agentes personales (!= 7)"
  # FIX-R1 (ACP): el modelo SOLO se fija en la sesión interactiva del dueño (B.1 dice
  # "noAuto"). Por eso cada agente acepta EITHER un pin real `model: antigravity-acp/...`
  # OR el marcador explicito `# model: sin fijar`. Lo que sigue siendo FAIL: un fichero
  # sin ninguna de las dos (placeholder roto) y CERO pins reales entre los 7.
  PINNED=0
  MARKED=0
  for f in "$REC"/config/opencode/agent/*.md; do
    if grep -q '^model: antigravity-acp/' "$f"; then
      PINNED=$((PINNED + 1))
    elif grep -q 'model: sin fijar' "$f"; then
      MARKED=$((MARKED + 1))
    else
      fail "P1 recipe: ${f##*/} sin pin antigravity-acp/* NI marcador 'model: sin fijar'"
    fi
    grep -q 'opencode-go' "$f" && fail "P1 recipe: ${f##*/} conserva referencia de producción opencode-go" || true
  done
  [ "$PINNED" -ge 1 ] || fail "P1 recipe: 0 agentes con pin real antigravity-acp/* (>=1 exigido)"
  echo "5cd9e913d2a7dcef2d649730dd409107aa62fd2e402dbef8713b0e9972e4e16b  $REC/bin/agy-shim" \
    | sha256sum -c --status - || fail "P1 recipe: agy-shim sha256 != sandbox auditado (B.2)"
  log "P1: personal-recipe OK (3 bins, pin 0.1.0, 7 agents: $PINNED con pin real + $MARKED con marcador, shim sha)"
fi

# --- manifest (sorted, paths relative to the staged tree) ----------------------
(
  cd "$STAGE"
  find opencode-suite opencode-personal -type f -print0 | sort -z | xargs -0 sha256sum
) > "$STAGE/manifest.sha256"

# second manifest for the .agents distribution (paths relative to dotagents/)
(
  cd dotagents
  find agents skills skills.json -type f -print0 | sort -z | xargs -0 sha256sum
) > "manifest.dotagents.sha256.tmp" && mv manifest.dotagents.sha256.tmp dotagents/manifest.sha256

# --- ATOMIC SWAP (FIX-R1 ACP) --------------------------------------------------
# Todo lo anterior corrio contra el staging. dist/ se reemplaza SOLO ahora, con un
# rename: si un guard falla antes, dist/ y su manifest sobreviven intactos.
rm -rf "$DIST"
mv "$STAGE" "$DIST"

log "OK: dist/ construido atomicamente — $(find "$DIST" -type f | wc -l) files, manifest $DIST/manifest.sha256 ($(wc -l < "$DIST/manifest.sha256") entries)"
