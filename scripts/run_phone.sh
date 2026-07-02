#!/usr/bin/env bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════
# Quickpass Phone Runner — Linux / macOS
#
# Runs the Flutter app on a physical Android device connected via USB,
# with an ADB reverse tunnel so the phone can reach the backend API
# running on this machine.
#
# Prerequisites:
#   1. Run ./scripts/setup.sh first (installs Android SDK + Flutter)
#   2. Enable Developer Options & USB Debugging on your phone
#   3. Connect phone via USB and accept the RSA fingerprint
#   4. Make sure the backend is running on port 3000
#
# Usage:
#   ./scripts/run_phone.sh
#
# ═══════════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROPERTIES="$PROJECT_DIR/flutter_app/android/local.properties"

# ── Resolve SDK paths ──

resolve_sdk_path() {
  local key="$1"
  local fallback="$2"
  if [ -f "$PROPERTIES" ]; then
    local val
    val=$(grep "^$key=" "$PROPERTIES" | cut -d= -f2-)
    if [ -n "$val" ]; then
      echo "$val"
      return 0
    fi
  fi
  echo "$fallback"
}

ANDROID_SDK_DIR=$(resolve_sdk_path "sdk.dir" "$PROJECT_DIR/tools/android-sdk")
FLUTTER_DIR=$(resolve_sdk_path "flutter.sdk" "$PROJECT_DIR/tools/flutter")
ADB="$ANDROID_SDK_DIR/platform-tools/adb"
FLUTTER="$FLUTTER_DIR/bin/flutter"

# ── Environment ──

export ANDROID_HOME="$ANDROID_SDK_DIR"

# Prefer bundled JDK, then system Java
BUNDLED_JDK="$PROJECT_DIR/tools/jdk"
if [ -f "$BUNDLED_JDK/bin/javac" ]; then
  export JAVA_HOME="$BUNDLED_JDK"
elif [ -z "${JAVA_HOME:-}" ]; then
  JAVA_BIN=$(command -v java 2>/dev/null || true)
  [ -n "$JAVA_BIN" ] && JAVA_HOME=$(dirname "$(dirname "$(readlink -f "$JAVA_BIN")")")
  export JAVA_HOME
fi

# ── Colors ──
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RESET='\033[0m'
log()  { printf "  ${GREEN}✓${RESET} %s\n" "$1"; }
warn() { printf "  ${YELLOW}⚠${RESET} %s\n" "$1"; }
err()  { printf "  ${RED}✗${RESET} %s\n" "$1"; exit 1; }
info() { printf "  ${CYAN}::${RESET} %s\n" "$1"; }
br()   { echo ""; }

# ── Check dependencies ──

[ -f "$FLUTTER" ] || err "Flutter SDK not found at $FLUTTER_DIR\n  Run ./scripts/setup.sh to install it."
[ -f "$ADB" ]     || err "ADB not found at $ADB\n  Run ./scripts/setup.sh to install the Android SDK."

# ── Find connected device ──

DEVICE=$("$ADB" devices | awk 'NR>1 && $2=="device" {print $1; exit}')
if [ -z "$DEVICE" ]; then
  br
  err "No Android device detected.\n\n  ${YELLOW}1.${RESET} Enable Developer Options on your phone:\n     Settings → About Phone → Tap Build Number 7 times\n  ${YELLOW}2.${RESET} Enable USB Debugging:\n     Settings → Developer Options → USB Debugging\n  ${YELLOW}3.${RESET} Connect your phone via USB and accept the RSA prompt\n  ${YELLOW}4.${RESET} Verify with: $ADB devices\n"
fi

br
echo "  ${CYAN}╔══════════════════════════════════════════════╗${RESET}"
echo "  ${CYAN}║${RESET}      Quickpass — Phone Runner                ${CYAN}║${RESET}"
echo "  ${CYAN}╚══════════════════════════════════════════════╝${RESET}"
br
info "Device:     $DEVICE"
info "Project:    $PROJECT_DIR"
br

# ── Set up ADB reverse tunnel ──

info "Setting up ADB reverse tunnel (phone:3000 → host:3000)..."
if "$ADB" reverse tcp:3000 tcp:3000 >/dev/null 2>&1; then
  log "ADB reverse tunnel established"
else
  warn "Failed to set up reverse tunnel — is the port already in use?"
fi

# ── Cleanup on exit ──

cleanup() {
  info "Cleaning up ADB reverse tunnel..."
  "$ADB" reverse --remove tcp:3000 2>/dev/null || true
  log "Done"
}
trap cleanup EXIT

# ── Run ──

cd "$PROJECT_DIR/flutter_app"
info "Starting Flutter on $DEVICE..."
br
"$FLUTTER" run --dart-define=API_BASE_URL=http://localhost:3000/api
