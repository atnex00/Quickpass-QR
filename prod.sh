#!/usr/bin/env bash
set -euo pipefail

export NODE_ENV=${NODE_ENV:-production}

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKEND_DIR="$ROOT_DIR/backend"
WEB_DIR="$ROOT_DIR/web"

echo "╔════════════════════════════════════╗"
echo "║      Quickpass Production Mode    ║"
echo "╚════════════════════════════════════╝"
echo ""

[ -d "$BACKEND_DIR" ] || { echo "ERROR: Backend directory not found at $BACKEND_DIR"; exit 1; }
[ -d "$WEB_DIR" ] || { echo "ERROR: Web directory not found at $WEB_DIR"; exit 1; }

echo "[1/2] Building Web Frontend..."
cd "$WEB_DIR"
npm run build
echo "  ✓ Build complete"

echo "[2/2] Starting Backend API (port ${PORT:-3000})..."
cd "$BACKEND_DIR"
exec node src/app.js
