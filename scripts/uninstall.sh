#!/usr/bin/env bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════
# Quickpass SDK Uninstall — Linux / macOS
#
# Removes all project-local SDK installations (Android SDK, Flutter,
# JDK) installed by setup.sh and cleans up related config.
#
# Usage:
#   ./scripts/uninstall.sh
#
# ═══════════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TOOLS_DIR="$PROJECT_DIR/tools"
PROPERTIES_FILE="$PROJECT_DIR/flutter_app/android/local.properties"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RESET='\033[0m'
log()  { printf "  ${GREEN}✓${RESET} %s\n" "$1"; }
warn() { printf "  ${YELLOW}⚠${RESET} %s\n" "$1"; }
err()  { printf "  ${RED}✗${RESET} %s\n" "$1"; exit 1; }
info() { printf "  ${CYAN}::${RESET} %s\n" "$1"; }
br()   { echo ""; }

br
echo "  ${CYAN}╔══════════════════════════════════════════════╗${RESET}"
echo "  ${CYAN}║${RESET}      Quickpass — SDK Uninstall               ${CYAN}║${RESET}"
echo "  ${CYAN}╚══════════════════════════════════════════════╝${RESET}"
br

# ── Confirm ──

printf "  ${YELLOW}?${RESET} This will remove all SDKs from tools/ and reset Flutter config. Continue? [y/N] "
read -r REPLY </dev/tty
case "$REPLY" in
  [yY]|[yY][eE][sS]) ;;
  *) info "Cancelled."; exit 0 ;;
esac
br

# ── Clear Flutter global config referencing this SDK ──

FLUTTER_BIN="$TOOLS_DIR/flutter/bin/flutter"
if [ -f "$FLUTTER_BIN" ]; then
  info "Clearing Flutter android-sdk config..."
  "$FLUTTER_BIN" config --clear-android-sdk 2>/dev/null || true
  log "Cleared Flutter android-sdk config"
fi

# ── Remove SDK directories ──

info "Removing project-local SDKs..."

for dir in "$TOOLS_DIR/android-sdk" "$TOOLS_DIR/flutter" "$TOOLS_DIR/jdk"; do
  if [ -d "$dir" ]; then
    rm -rf "$dir"
    log "Removed $dir"
  else
    warn "Not found: $dir"
  fi
done

# ── Remove local.properties ──

if [ -f "$PROPERTIES_FILE" ]; then
  rm -f "$PROPERTIES_FILE"
  log "Removed $PROPERTIES_FILE"
fi

# ── Clean Gradle caches for this project ──

GRADLE_CACHE="$HOME/.gradle/caches"
if [ -d "$GRADLE_CACHE" ]; then
  info "Gradle caches preserved at $GRADLE_CACHE"
  info "To remove them manually: rm -rf $GRADLE_CACHE"
fi

# ── Done ──

br
echo "  ${GREEN}Uninstall complete.${RESET}"
info "To reinstall, run: ./scripts/setup.sh"
br
