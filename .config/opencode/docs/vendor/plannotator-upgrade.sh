#!/usr/bin/env bash
# =============================================================================
# plannotator-upgrade.sh — terminal-only runbook for the plannotator upgrade
#
# PURPOSE
#   1. Restart the opencode daemon so it re-resolves `@plannotator/opencode@latest`
#      from a clean cache (pins purged in the build session).
#   2. Verify the loaded plugin version actually moved to >= 0.28 (only at >= 0.28
#      do the config `options` — workflow:"plan-agent", planningAgents — become live).
#   3. Run the vendor installer (writes .config/opencode/commands/ + opencode.jsonc
#      — both gitignored; the jsonc is MERGED into config by opencode, see probe).
#   4. Sanity-check repo cleanliness + inbox-server loopback binding.
#
# WHY TERMINAL-ONLY
#   `opencode service restart` kills the daemon on 127.0.0.1:49374 — that is the
#   process hosting the user's LIVE opencode session. No agent may run this;
#   execute it by hand in a terminal window you control.
#
# ROLLBACK
#   Pre-change config snapshot (most recent):  ls -dt /tmp/opencode/backup-config-* | head -1
#   Restore:  cp -a <backup-dir>/opencode.json ~/.config/opencode/opencode.json   (then restart service again)
#   If cache stays frozen on the old version (purge + restart):
#     rm -rf ~/.cache/opencode/npm/@plannotator ~/.cache/opencode/packages/@plannotator
#     rm -f  ~/.cache/opencode/pin-check.json
#     opencode service restart
#   Config-source rollback: revert the `plugins` hunk in
#     .config/opencode/builder/templates/config/config.json  (0.27.20 / snippets 3.2.0)
#     and rebuild: cd .config/opencode/builder && MODEL_PROFILE=opencodego go run main.go
# =============================================================================
set -euo pipefail

REPO="/home/andres/Proyectos/dotfiles"
CACHE_NPM="$HOME/.cache/opencode/npm/@plannotator/opencode@latest"
INSTALLER_URL="https://raw.githubusercontent.com/Saebom/plannotator/main/opencode/install.sh"
INSTALLER_PATH="/tmp/plannotator-install.sh"

step() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
die()  { printf '\033[1;31mFAIL: %s\033[0m\n' "$*" >&2; exit 1; }

# --- 1. Restart daemon (picks up @latest from clean cache) --------------------
step "1/6 opencode service restart"
opencode service restart

# --- 2. Assert loaded plugin version >= 0.28 ----------------------------------
# The resolved cache dir is named `opencode@latest` but the TRUTH is the version
# field inside its package.json.
step "2/6 verify resolved plannotator version"
pkg_json=$(ls "$CACHE_NPM"/*/package.json 2>/dev/null | head -1 || true)
[[ -n "$pkg_json" ]] || die "no resolved package.json under $CACHE_NPM — cache not populated after restart"
version=$(jq -r '.version' "$pkg_json")
echo "resolved @plannotator/opencode = $version  ($pkg_json)"
# numeric compare: version must be >= 0.28
if [[ "$(printf '0.28\n%s\n' "$version" | sort -V | head -1)" != "0.28" ]]; then
  echo "cache still frozen: purge and restart again" >&2
  echo "  rm -rf ~/.cache/opencode/npm/@plannotator ~/.cache/opencode/packages/@plannotator" >&2
  echo "  rm -f  ~/.cache/opencode/pin-check.json" >&2
  echo "  opencode service restart" >&2
  die "plannotator $version < 0.28 — options in opencode.json stay inert at 0.27.x"
fi
echo "OK: $version >= 0.28 (workflow/planningAgents options are live)"

# --- 3. Vendor installer: download, show sha256, human review, execute --------
step "3/6 download installer -> $INSTALLER_PATH"
curl -fsSL "$INSTALLER_URL" -o "$INSTALLER_PATH"
echo "sha256:"
sha256sum "$INSTALLER_PATH"
echo "first 40 lines:"
head -40 "$INSTALLER_PATH"
echo
read -r -p "Review the installer above. Execute it? [y/N] " answer
[[ "$answer" == "y" || "$answer" == "Y" ]] || die "aborted by user (installer not run)"
bash "$INSTALLER_PATH"

# --- 4. plannotator CLI version -----------------------------------------------
step "4/6 plannotator --version"
if command -v plannotator >/dev/null 2>&1; then
  plannotator --version
else
  echo "WARN: 'plannotator' not on PATH after install — check installer output" >&2
fi

# --- 5. Git cleanliness: installer artifacts must be gitignored ---------------
# commands/ and opencode.jsonc are covered by .gitignore; empty porcelain here
# proves those rules work on the live tree.
step "5/6 git cleanliness ($REPO)"
cd "$REPO"
if [[ -n "$(git status --porcelain)" ]]; then
  git status --porcelain
  die "repo dirty — installer wrote something NOT gitignored (check commands/ + opencode.jsonc rules)"
fi
echo "OK: porcelain empty despite installer writes (ignore rules effective)"

# --- 6. Inbox server must bind loopback only ----------------------------------
step "6/6 inbox server binding"
listeners=$(ss -ltnp 2>/dev/null | grep -i plannotator || true)
if [[ -z "$listeners" ]]; then
  echo "WARN: no plannotator listener found yet — inbox server may start lazily; re-check with:" >&2
  echo "  ss -ltnp | grep plannotator" >&2
else
  echo "$listeners"
  if echo "$listeners" | grep -Eq '0\.0\.0\.0:|\*:'; then
    die "plannotator inbox server bound to 0.0.0.0 / * — must be 127.0.0.1 only"
  fi
  echo "OK: loopback-only binding"
fi

step "DONE"
