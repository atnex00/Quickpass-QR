#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo ""
echo "  ╔══════════════════════════════════════════════╗"
echo "  ║    Quickpass Desktop Admin — Setup           ║"
echo "  ╚══════════════════════════════════════════════╝"
echo ""

# 1. Check Rust
echo "  [1/2] Checking Rust toolchain..."
if command -v rustc &>/dev/null; then
  echo "  ✓ Rust already installed: $(rustc --version)"
else
  echo "  ⚠ Rust not found. Installing via rustup..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
  source "$HOME/.cargo/env"
  echo "  ✓ Rust installed: $(rustc --version)"
fi

# 2. Install admin-desktop npm deps
echo "  [2/2] Installing npm dependencies..."
cd "$PROJECT_DIR/admin-desktop"
npm install
echo "  ✓ npm dependencies installed"

echo ""
echo "  ╔══════════════════════════════════════════════╗"
echo "  ║    Setup complete!                            ║"
echo "  ╚══════════════════════════════════════════════╝"
echo ""
echo "  Build the desktop app:"
echo "    npm run desktop:build"
echo ""
echo "  Or run in development mode (two terminals):"
echo "    cd web && npm run dev"
echo "    cd admin-desktop && npm run dev"
echo ""
