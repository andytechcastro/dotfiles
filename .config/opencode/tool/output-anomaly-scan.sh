#!/usr/bin/env bash
# output-anomaly-scan.sh — PL-4 forensic scanner (post-hoc verification aid).
#
# Purpose: scan squeez content-addressed blobs (== raw tool outputs captured
#   exactly as they were emitted during a session) for instruction-shaped text
#   that would signal a prompt-injection riding inside a tool result. This is a
#   verification aid run by the OWNER or Commander AFTER a session; it is NOT a
#   live plugin and it BLOCKS NOTHING.
#
# Usage:   output-anomaly-scan.sh [--include-self] [BLOB_DIR]
#          default BLOB_DIR = ${SQUEEZ_DIR:-$HOME/.claude/squeez}/blobs
#          --include-self : also scan the scanner's own source and any path
#                           matching /fixture(s)/ (case-insensitive). Audit-on-
#                           platform mode ONLY — on a normal run those paths are
#                           guaranteed matches (pattern self-reference) and are
#                           excluded by default so exit codes stay meaningful.
# Exit:    0 = no matches (clean)
#          1 = matches found (manual review required)
#          2 = blob dir missing / unusable
#
# Blobs are read-only here. The script never writes, moves, or edits any blob.
#
# SECURITY (GATE B P5 FIX, 2026-11-19): this scanner must NEVER echo matched
#   TEXT. A verbatim echo of attacker-controlled blob content is a secondary
#   re-injection channel into the terminal/session that runs it. Therefore:
#   - per-pattern detection uses `grep -rIl` / `grep -rIlP` (PATHS ONLY);
#   - the per-pattern count is the number of matching PATHS, not lines;
#   - detail lines are path + sha256 prefix + line-count digest only.
#   If content review is needed, the owner opens the file manually by path.
#   Also added: bidi/zero-width control class (U+202E, U+2066-U+2069, U+200B),
#   undetected before this fix and invisible to terminal display.
#
# SIGNAL QUALITY (GATE G5 ADDENDUM, QA, 2026-11-19): 13/13 hits measured on the
#   live tree were noise: (a) the scanner's own pattern array re-matches its
#   source, (b) planted test fixtures, (c) benign `"role":` keys inside JSON
#   schema payloads. A permanently-red scanner is alert fatigue = dead control.
#   Fixes: self+fixture exclusion (above) and a role-key scope rule — `"role":`
#   counts only in NON-JSON/JSONL files; strict patterns still count everywhere.
set -u
export LC_ALL=C.UTF-8

INCLUDE_SELF=0
if [ "${1:-}" = "--include-self" ]; then
  INCLUDE_SELF=1
  shift
fi

DIR="${1:-${SQUEEZ_DIR:-$HOME/.claude/squeez}/blobs}"
if [ ! -d "$DIR" ]; then
  echo "ERROR: blob dir not found: $DIR" >&2
  exit 2
fi

SELF="$(readlink -f "$0")"

# Instruction-shaped patterns. Format: <engine>|<pattern>
#   engine E = grep -E, engine P = grep -P (needed for \x{...} codepoints).
# Last entry = bidi/zero-width Trojan-Source class.
declare -a PAT=(
  'E|^\[System Instructions\]'
  'E|ignore[[:space:]]+(all[[:space:]]+)?previous[[:space:]]+instructions'
  'E|disregard'
  'E|<system'
  'E|"role"[[:space:]]*:'
  'P|[\x{200B}\x{202E}\x{2066}-\x{2069}]'
)

# Candidate file list: exclude the scanner itself and fixture-shaped paths
# unless --include-self. The exclusion list is fixed by the caller, so grep
# only ever sees this literal pattern — never attacker content.
LIST=$(find "$DIR" -type f 2>/dev/null \
  | grep -vxF "$SELF" \
  | grep -viE '/fixtures?/')
[ "$INCLUDE_SELF" = 1 ] && LIST=$(find "$DIR" -type f 2>/dev/null)
files=$(printf '%s' "$LIST" | grep -c . || true)

# role-key scope: scan only NON-JSON/JSONL candidates.
ROLE_LIST=$(printf '%s\n' "$LIST" | grep -viE '\.(json|jsonl)$' || true)

echo "output-anomaly-scan: dir=$DIR files_scanned=$files include_self=$INCLUDE_SELF (read-only; paths+digests only, no content echo)"
total=0
report() {
  # $1=pattern label $2=matching paths (NUL-safe list already filtered)
  local n
  n=$(printf '%s' "$2" | grep -c . || true)
  total=$((total + n))
  printf '  %-55s matched_files=%s\n' "$1" "$n"
  if [ "$n" -gt 0 ]; then
    printf '%s\n' "$2" | head -5 | while IFS= read -r f; do
      [ -f "$f" ] || continue
      printf '      %s sha256=%s lines=%s\n' "$f" \
        "$(sha256sum "$f" | cut -c1-12)" "$(wc -l < "$f")"
    done
  fi
}
scan_all() { # $1=engine $2=pattern — over full candidate list
  local e="$1" p="$2" out
  case "$e" in
    P) out=$(grep -rlIP "$p" "$DIR" 2>/dev/null | grep -vxF "$SELF" | grep -viE '/fixtures?/') ;;
    *) out=$(grep -rlIE "$p" "$DIR" 2>/dev/null | grep -vxF "$SELF" | grep -viE '/fixtures?/') ;;
  esac
  report "$p" "$out"
}
scan_role() { # scope-trimmed: ROLE_LIST only (no *.json/*.jsonl)
  local out
  out=$(printf '%s\n' "$ROLE_LIST" | while IFS= read -r f; do
    [ -f "$f" ] && grep -lIE '"role"[[:space:]]*:' "$f" 2>/dev/null
  done)
  report '"role":[[:space:]]*: (non-JSON/JSONL only)' "$out"
}

if [ "$INCLUDE_SELF" = 1 ]; then
  for entry in "${PAT[@]}"; do scan_all "${entry%%|*}" "${entry#*|}"; done
else
  for entry in "${PAT[@]}"; do
    if [ "${entry#*|}" = '"role"[[:space:]]*:' ]; then scan_role; else scan_all "${entry%%|*}" "${entry#*|}"; fi
  done
fi

echo "SUMMARY total_instruction_shaped_matched_files=$total"
if [ "$total" -gt 0 ]; then
  echo "VERDICT: review recommended (exit 1) — open files MANUALLY by path; never re-paste content into a session"
  exit 1
else
  echo "VERDICT: clean (exit 0)"
  exit 0
fi
