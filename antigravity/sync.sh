#!/usr/bin/env bash
# sync.sh — install dist/opencode-{suite,personal}/ into ~/.gemini/config/plugins/ via rsync.
#
# Usage:
#   DRY_RUN=1 ./sync.sh   # rsync -n --delete: prints the plan, writes NOTHING (F1: only allowed mode)
#   ./sync.sh             # live install (F6+). DRY_RUN defaults OFF ("1" enables dry-run).
#
# Invariants:
#   * NEVER writes ~/.gemini/config/config.json or the GLOBAL mcp_config.json — see GUARD below.
#   * DRY_RUN: does not even mkdir the plugins/ dir (F1: nothing created under ~/.gemini).
#   * AGY_SYNC_TARGET (host:path, homesrv Pi) is a designed extension point — not implemented:
#     refuses closed with exit 2.
#   * Enable/disable stays agy-side (config.json plugins.<dir>.enabled / agy plugin install):
#     sync.sh only copies files.
set -euo pipefail
export LC_ALL=C

cd "$(dirname "${BASH_SOURCE[0]}")"

DIST="dist"
LOCAL_BASE="${HOME}/.gemini/config/plugins"
NAMES=(opencode-suite opencode-personal)
# Workspace-root .agents/ distribution (F8). EXPLICIT repo targets only — adding a
# repo here IS the permission; sync.sh refuses targets whose existing .agents/ lacks
# the .opencode-suite-managed marker (never clobber a foreign .agents/).
DOTAGENTS_TARGETS=(/home/andres/Proyectos/dotfiles)
DRY_RUN="${DRY_RUN:-0}"

log() { printf '[sync] %s\n' "$*"; }
die() { printf '[sync] REFUSE: %s\n' "$*" >&2; exit 1; }

# --- remote target: fail closed (designed extension point) ----------------------
if [ -n "${AGY_SYNC_TARGET:-}" ]; then
  log "remote sync (homesrv Pi) not implemented yet — designed extension point (AGY_SYNC_TARGET=${AGY_SYNC_TARGET})"
  exit 2
fi

# --- preflight -------------------------------------------------------------------
command -v rsync >/dev/null 2>&1 || die "rsync not found"
[ -d "$DIST" ] || die "$DIST/ missing — run ./build.sh first"
[ -f "$DIST/manifest.sha256" ] || die "$DIST/manifest.sha256 missing — run ./build.sh first"
for n in "${NAMES[@]}"; do
  [ -d "$DIST/$n" ] || die "$DIST/$n missing — run ./build.sh first"
  [ -f "$DIST/$n/plugin.json" ] || die "$DIST/$n/plugin.json missing"
done

# --- GUARD: global agy config surface must be unreachable ------------------------
# The dangerous paths are exactly $HOME/.gemini/config/config.json and the GLOBAL
# $HOME/.gemini/config/mcp_config.json. They sit in LOCAL_BASE's PARENT; every rsync
# here has target $LOCAL_BASE/<name>/, so a correctly-shaped dist can never overwrite
# them. Belt and braces:
#   * `config.json` is not a plugin contract file at all -> hard-refuse anywhere in dist.
#   * mcp_config.json is legitimate only INSIDE a plugin dir (plugins.md). A dist-ROOT
#     mcp_config.json signals a broken layout one step away from the global path -> refuse.
# TODO(F5): when the suite ships its plugin-root mcp_config.json it lives at
#   dist/<name>/mcp_config.json and passes this guard untouched.
for n in "${NAMES[@]}"; do
  if [ -n "$(find "$DIST/$n" -name config.json -print -quit)" ]; then
    die "config.json found inside $DIST/$n — global agy config surface must never enter dist/"
  fi
done
[ -f "$DIST/mcp_config.json" ] && die "mcp_config.json at dist root — plugin files belong under dist/<name>/"
[ "$(basename "$(dirname "$LOCAL_BASE")")" = "config" ] && [ "$(basename "$LOCAL_BASE")" = "plugins" ] \
  || die "LOCAL_BASE sanity failed: expected .../config/plugins, got $LOCAL_BASE"

# --- rsync ------------------------------------------------------------------------
# --no-perms (F6): the privacy-modes block below OWNS the installed bits (dirs 700 /
# files 600). Without it, rsync -a would "restore" the staging 644 bits on every run,
# the itemize would never be empty and idempotency could not be proven by checksum.
RSYNC_ARGS=(-a --delete --no-perms)
if [ "$DRY_RUN" = "1" ]; then
  RSYNC_ARGS+=(-n -v)
  log "DRY_RUN=1 — rsync -n: planning only, nothing written, no mkdir under ~/.gemini"
else
  log "LIVE RUN — writing $LOCAL_BASE"
  mkdir -p "$LOCAL_BASE"
fi

for n in "${NAMES[@]}"; do
  dest="$LOCAL_BASE/$n/"
  case "$dest" in
    "$LOCAL_BASE"/*/) ;;
    *) die "target path sanity failed: $dest" ;;
  esac
  log "rsync ${RSYNC_ARGS[*]} $DIST/$n/ -> $dest"
  rsync "${RSYNC_ARGS[@]}" "$DIST/$n/" "$dest"
done

# --- privacy modes (F6) ----------------------------------------------------------
# Staging bits are 644 (umask); rsync -a/cp -a PRESERVE them. The installed plugin
# trees hold this owner's agents/MCP definitions under ~/.gemini, so force owner-only
# bits post-sync (idempotent; re-applies every run to files rsync just refreshed):
# directories 700, files 600. DRY_RUN writes nothing anywhere, so it is skipped.
if [ "$DRY_RUN" != "1" ]; then
  chmod 700 "$LOCAL_BASE"
  for n in "${NAMES[@]}"; do
    find "$LOCAL_BASE/$n" -type d -exec chmod 700 {} +
    find "$LOCAL_BASE/$n" -type f -exec chmod 600 {} +
    # F4: hook scripts must stay executable in the installed plugin (agy runs them via
    # `sh -c "./hooks/gate.sh"` with cwd = plugin root). Data files keep 600.
    find "$LOCAL_BASE/$n" -type f -path '*/hooks/*.sh' -exec chmod 755 {} +
  done
  log "modos forzados en instalados: dirs 700 / files 600 / hooks/*.sh 755"
fi

# --- .agents/ distribution to explicit workspace targets (F8) -------------------
if [ -d "dotagents" ]; then
  for t in "${DOTAGENTS_TARGETS[@]}"; do
    [ -d "$t" ] || die "target repo missing: $t (fix DOTAGENTS_TARGETS)"
    if [ -e "$t/.agents" ] && [ ! -f "$t/.agents/.opencode-suite-managed" ]; then
      die "$t/.agents exists WITHOUT .opencode-suite-managed marker — foreign directory, refusing --delete"
    fi
    RSYNC_Dargs=(-a --delete --no-perms)
    [ "$DRY_RUN" = "1" ] && RSYNC_Dargs+=(-n -v)
    log "rsync ${RSYNC_Dargs[*]} dotagents/ -> $t/.agents/"
    rsync "${RSYNC_Dargs[@]}" dotagents/ "$t/.agents/"
    if [ "$DRY_RUN" != "1" ]; then
      find "$t/.agents" -type d -exec chmod 700 {} +
      find "$t/.agents" -type f -exec chmod 600 {} +
    fi
  done
else
  log "WARN: dotagents/ not built — run ./build.sh (F8 stage skipped)"
fi

# --- global agents distribution (F8b): ~/.gemini/config/agents/ -----------------
# Measured live by Commander (2 differentiated probes): agy registers agents ONLY
# from this global dir (visible from any cwd, no workspace needed); plugin agents/
# dirs are counted by `agy plugin list` but never enter the catalog. ~/.agents under
# HOME does NOT participate.
# GUARD: NO --delete here. Foreign *.md already in the target (e.g. probe-global
# leftovers) are REPORTED and left untouched; we only add/overwrite our 14 names.
GDIR="${HOME}/.gemini/config/agents"
if [ -d "dotagents/agents" ]; then
  foreign=()
  if [ -d "$GDIR" ]; then
    while IFS= read -r -d '' f; do
      bn="${f##*/}"
      [ -f "dotagents/agents/$bn" ] || foreign+=("$bn")
    done < <(find "$GDIR" -maxdepth 1 -name '*.md' -print0 2>/dev/null)
  fi
  if [ "${#foreign[@]}" -gt 0 ]; then
    log "REPORT: agentes ajenos en $GDIR — NO se tocan ni borran: ${foreign[*]}"
  fi
  RSYNC_Gargs=(-a --no-perms)
  if [ "$DRY_RUN" = "1" ]; then
    RSYNC_Gargs+=(-n -v)
  else
    mkdir -p "$GDIR"; chmod 700 "$GDIR"
  fi
  log "rsync ${RSYNC_Gargs[*]} dotagents/agents/ -> $GDIR/ (additive, sin --delete)"
  rsync "${RSYNC_Gargs[@]}" dotagents/agents/ "$GDIR/"
  if [ "$DRY_RUN" != "1" ]; then
    for m in dotagents/agents/*.md; do chmod 600 "$GDIR/${m##*/}"; done
    log "modos globales: dir 700 / nuestros 14 ficheros 600 (ajenos intactos)"
  fi
else
  log "WARN: dotagents/agents no construido — run ./build.sh (global stage skipped)"
fi

log "done (DRY_RUN=$DRY_RUN). Next: ./verify.sh"
