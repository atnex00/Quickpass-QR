#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo ""
echo "  ╔══════════════════════════════════════════════╗"
echo "  ║    Quickpass Desktop Admin — Remove All      ║"
echo "  ╚══════════════════════════════════════════════╝"
echo ""

confirm() {
  read -p "  Remove $1? (y/N) " -n 1 -r
  echo
  [[ $REPLY =~ ^[Yy]$ ]]
}

# 1. Uninstall Rust
if command -v rustup &>/dev/null; then
  RUSTUP_SIZE=$(du -sh "$HOME/.rustup" 2>/dev/null | cut -f1 || echo "unknown")
  CARGO_SIZE=$(du -sh "$HOME/.cargo" 2>/dev/null | cut -f1 || echo "unknown")
  echo "  [1/5] Rust toolchain (~ $RUSTUP_SIZE) + registry (~ $CARGO_SIZE)"
  if confirm "Rust toolchain, cargo registry, and all toolchains"; then
    rustup self uninstall -y
    rm -rf "$HOME/.cargo" "$HOME/.rustup" 2>/dev/null
    echo "  ✓ Rust uninstalled"
  fi
else
  echo "  [1/5] Rust not installed, skipping"
fi

# 2. Clean Tauri build cache
TAURI_TARGET="$PROJECT_DIR/admin-desktop/src-tauri/target"
if [ -d "$TAURI_TARGET" ]; then
  TARGET_SIZE=$(du -sh "$TAURI_TARGET" 2>/dev/null | cut -f1)
  echo "  [2/5] Tauri build cache target/ (~ $TARGET_SIZE)"
  rm -rf "$TAURI_TARGET"
  echo "  ✓ target/ removed"
else
  echo "  [2/5] target/ not found, skipping"
fi

# 3. Clean admin-desktop node_modules
NM_DIR="$PROJECT_DIR/admin-desktop/node_modules"
if [ -d "$NM_DIR" ]; then
  echo "  [3/5] admin-desktop node_modules"
  rm -rf "$NM_DIR"
  echo "  ✓ node_modules removed"
else
  echo "  [3/5] node_modules not found, skipping"
fi

# 4. Remove cargo linker config
CARGO_CONFIG="$PROJECT_DIR/admin-desktop/src-tauri/.cargo/config.toml"
if [ -f "$CARGO_CONFIG" ]; then
  echo "  [4/5] Cargo linker config"
  rm -rf "$(dirname "$CARGO_CONFIG")"
  echo "  ✓ .cargo/config.toml removed"
else
  echo "  [4/5] No Cargo config, skipping"
fi

# 5. Clean temp files
echo "  [5/5] Temp installer files"
rm -f /tmp/rustup-init.exe /tmp/vs_BuildTools.exe 2>/dev/null
rm -f "$HOME/Downloads/rustup-init.exe" 2>/dev/null
echo "  ✓ Temp files cleaned"

echo ""
echo "  ╔══════════════════════════════════════════════╗"
echo "  ║    All desktop build dependencies removed     ║"
echo "  ╚══════════════════════════════════════════════╝"
echo ""
