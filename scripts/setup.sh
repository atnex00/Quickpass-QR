#!/usr/bin/env bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════
# PassLynx Setup Script — Linux / macOS
#
# Installs system dependencies and optionally Android SDK + Flutter
# inside the project's tools/ directory. No system-wide installs,
# no Android Studio needed.
#
# Usage:
#   chmod +x scripts/setup.sh
#   ./scripts/setup.sh
#
# You'll be prompted whether to install mobile SDKs. Answer 'n' if
# you're only working on the web frontend (web/).
#
# ═══════════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TOOLS_DIR="$PROJECT_DIR/tools"
ANDROID_SDK_DIR="$TOOLS_DIR/android-sdk"
FLUTTER_DIR="$TOOLS_DIR/flutter"
CMDLINE_TOOLS_DIR="$ANDROID_SDK_DIR/cmdline-tools/latest"

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RESET='\033[0m'

log()  { printf "  ${GREEN}✓${RESET} %s\n" "$1"; }
warn() { printf "  ${YELLOW}⚠${RESET} %s\n" "$1"; }
err()  { printf "  ${RED}✗${RESET} %s\n" "$1"; exit 1; }
info() { printf "  ${CYAN}::${RESET} %s\n" "$1"; }
br()   { echo ""; }

# ── Detect OS ──

OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"
case "$ARCH" in
  x86_64)  ARCH_SHORT="x64" ;;
  aarch64|arm64) ARCH_SHORT="arm64" ;;
  *) err "Unsupported architecture: $ARCH" ;;
esac

case "$OS" in
  linux*)  OS="linux" ;;
  darwin*) OS="macos" ;;
  mingw*|msys*|cygwin*) err "Windows detected. Use scripts/setup.ps1 instead." ;;
  *) err "Unsupported OS: $OS" ;;
esac

br
echo "  ${CYAN}╔══════════════════════════════════════════════╗${RESET}"
echo "  ${CYAN}║${RESET}     PassLynx Environment Setup              ${CYAN}║${RESET}"
echo "  ${CYAN}╚══════════════════════════════════════════════╝${RESET}"
br
info "Project: $PROJECT_DIR"
info "OS:      $OS ($ARCH)"
br

# ── System Dependencies ──

install_system_deps() {
  local MISSING=""

  # Check if required CLI tools exist
  for cmd in curl unzip git; do
    if ! command -v "$cmd" &>/dev/null; then
      MISSING="$MISSING $cmd"
    fi
  done

  # Check if Java 21+ is available (Flutter 3.27 + Gradle 8.5+ require JDK 21)
  JAVA_OK=false
  if command -v java &>/dev/null; then
    JAVA_VER=$(java -version 2>&1 | head -1 | sed 's/[^0-9.]//g' | cut -d. -f1)
    if [ "$JAVA_VER" -ge 21 ] 2>/dev/null; then
      JAVA_OK=true
      log "Java $JAVA_VER found"
    fi
  fi

  if [ -z "${MISSING:-}" ] && [ "$JAVA_OK" = true ]; then
    return 0
  fi

  [ -n "${MISSING:-}" ] && warn "Missing dependencies:${MISSING:-}"
  [ "$JAVA_OK" != true ] && warn "Java 17+ is required but not found."
  warn ""

  # Try a quick sudo check — if it fails, skip
  if ! sudo -n true 2>/dev/null; then
    warn "Sudo requires a password — skipping automated dependency install."
    warn "Install the following for your OS:"
    warn "  Debian/Ubuntu: sudo apt install curl unzip xz-utils git openjdk-17-jre"
    warn "  Fedora:        sudo dnf install curl unzip xz git java-17-openjdk-headless"
    warn "  Arch:          sudo pacman -S curl unzip xz git jdk17-openjdk"
    warn "  macOS:         brew install curl unzip xz git; brew install --cask temurin17"
    return 0
  fi

  if [ "$OS" = "linux" ]; then
    if command -v apt-get &>/dev/null; then
      info "Debian/Ubuntu — installing dependencies..."
      sudo apt-get update -qq && sudo apt-get install -y -qq curl unzip xz-utils git openjdk-17-jre
    elif command -v dnf &>/dev/null; then
      info "Fedora — installing dependencies..."
      sudo dnf install -y curl unzip xz git java-17-openjdk-headless
    elif command -v pacman &>/dev/null; then
      info "Arch — installing dependencies..."
      sudo pacman -S --noconfirm curl unzip xz git jdk17-openjdk
    fi
    log "System dependencies installed"
  elif [ "$OS" = "macos" ]; then
    if ! command -v brew &>/dev/null; then
      info "Installing Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew install curl unzip xz git
    command -v java &>/dev/null || brew install --cask temurin17
    log "System dependencies installed"
  fi
}

# ── Android SDK ──

install_android_sdk() {
  br
  info "Setting up Android SDK..."

  mkdir -p "$CMDLINE_TOOLS_DIR"

  if [ -f "$CMDLINE_TOOLS_DIR/bin/sdkmanager" ]; then
    log "cmdline-tools already installed"
  else
    info "Downloading Android command-line tools..."
    CMDLINE_URL="https://dl.google.com/android/repository/commandlinetools-${OS}-11076708_latest.zip"
    CMDLINE_ZIP="/tmp/cmdline-tools.zip"

    curl -fsSL "$CMDLINE_URL" -o "$CMDLINE_ZIP"
    unzip -q "$CMDLINE_ZIP" -d "/tmp/cmdline-tools-extracted"
    mv /tmp/cmdline-tools-extracted/cmdline-tools/* "$CMDLINE_TOOLS_DIR/"
    rm -rf /tmp/cmdline-tools.zip /tmp/cmdline-tools-extracted
    log "cmdline-tools installed"
  fi

  # Find Java
  JAVA_BIN=""
  for candidate in /usr/lib/jvm/*/bin/java /usr/lib/jvm/java-17-openjdk/bin/java /usr/lib/jvm/default/bin/java /usr/bin/java /opt/homebrew/opt/openjdk/bin/java; do
    if [ -x "$candidate" ]; then
      JAVA_BIN="$candidate"
      break
    fi
  done

  if [ -z "$JAVA_BIN" ]; then
    err "Java 17+ is required but not found. Install it, then re-run."
  fi

  JAVA_HOME="$(dirname "$(dirname "$JAVA_BIN")")"
  export JAVA_HOME
  export ANDROID_HOME="$ANDROID_SDK_DIR"

  SDKMANAGER="$CMDLINE_TOOLS_DIR/bin/sdkmanager"

  # Accept licenses
  info "Accepting Android licenses..."
  yes | JAVA_HOME="$JAVA_HOME" "$SDKMANAGER" --licenses >/dev/null 2>&1 || true
  log "Licenses accepted"

  # Install required packages
  info "Installing Android SDK platform and build tools..."
  JAVA_HOME="$JAVA_HOME" "$SDKMANAGER" "platforms;android-34" "build-tools;34.0.0" >/dev/null 2>&1
  log "Android SDK platform (34) and build-tools installed"

  # Write local.properties for the Flutter project
  PROPERTIES_FILE="$PROJECT_DIR/flutter_app/android/local.properties"
  {
    echo "sdk.dir=$ANDROID_SDK_DIR"
    echo "flutter.sdk=$FLUTTER_DIR"
  } > "$PROPERTIES_FILE"
  log "local.properties written"
  
  # Fix Gradle version (Flutter 3.27 + Gradle 8.14 needs JDK 21; upgrade to 8.5)
  GRADLE_PROPS="$PROJECT_DIR/gradle.properties"
  echo 'org.gradle.jvmargs=--illegal-access=all' >> "$GRADLE_PROPS"
  log "gradle.properties updated with --illegal-access=all"
  
  # Update Gradle wrapper from 8.14 to 8.5
  WRAPPER_PROPS="$PROJECT_DIR/android/gradle/wrapper/gradle-wrapper.properties"
  sed -i 's/distributionUrl=\\https\\:\\/\\/services.gradle.org\\/distributions\\/gradle-8\.14-all.zip/distributionUrl=\\https\\:\\/\\/services.gradle.org\\/distributions\\/gradle-8\.5-all.zip/' "$WRAPPER_PROPS"
  log "Gradle wrapper updated to 8.5"
}

# ── Flutter SDK ──

install_flutter() {
  br
  info "Setting up Flutter SDK..."

  if [ -f "$FLUTTER_DIR/bin/flutter" ]; then
    log "Flutter SDK already installed"
  else
    info "Downloading Flutter SDK..."
    FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/${OS}/flutter_${OS}_3.27.1-stable.tar.xz"
    FLUTTER_TAR="/tmp/flutter.tar.xz"

    curl -fsSL "$FLUTTER_URL" -o "$FLUTTER_TAR"
    tar -xf "$FLUTTER_TAR" -C "$TOOLS_DIR/"
    rm -f "$FLUTTER_TAR"
    log "Flutter SDK installed at $FLUTTER_DIR"
  fi

  export PATH="$FLUTTER_DIR/bin:$PATH"
  export ANDROID_HOME="$ANDROID_SDK_DIR"

  # Configure flutter to use project-local Android SDK
  flutter config --android-sdk "$ANDROID_SDK_DIR" >/dev/null 2>&1
  log "Flutter configured to use project SDK"

  # Precache for faster first build
  flutter precache --android >/dev/null 2>&1 || true
}

# ── Verify ──

verify() {
  br
  echo "  ${CYAN}── Verification ──────────────────────────────${RESET}"
  br

  export PATH="$FLUTTER_DIR/bin:$PATH"
  export ANDROID_HOME="$ANDROID_SDK_DIR"

  flutter doctor 2>&1
  br
}

# ── Prompt ──

prompt_mobile_sdks() {
  br
  echo "  ${CYAN}── Mobile Development ─────────────────────────${RESET}"
  br
  info "This project includes a Flutter Android app in flutter_app/."
  info "If you only need the web frontend (web/), you can skip this."
  br
  printf "  ${YELLOW}?${RESET} Install Android SDK + Flutter SDK for mobile development? [y/N] "
  read -r REPLY </dev/tty
  case "$REPLY" in
    [yY]|[yY][eE][sS]) return 0 ;;
    *) return 1 ;;
  esac
}

# ── Run ──

install_system_deps

if prompt_mobile_sdks; then
  install_android_sdk
  install_flutter
  verify
  echo "  ${GREEN}Setup complete.${RESET}"
  echo "  To build the APK:  cd flutter_app && flutter build apk"
else
  br
  echo "  ${GREEN}System dependencies installed.${RESET}"
  info "Skipped mobile SDKs."
  info "To install them later, re-run with:  ./scripts/setup.sh"
  br
fi
echo ""
