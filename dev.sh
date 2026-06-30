#!/usr/bin/env bash
set -e

export NODE_ENV=${NODE_ENV:-dev}

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKEND_DIR="$ROOT_DIR/backend"
WEB_DIR="$ROOT_DIR/web"

cleanup() {
  echo ""
  echo "Shutting down..."
  kill $BACKEND_PID $WEB_PID 2>/dev/null
  wait $BACKEND_PID $WEB_PID 2>/dev/null
  echo "Done."
}

trap cleanup EXIT INT TERM

echo "╔════════════════════════════════════╗"
echo "║        PassLynx Dev Server        ║"
echo "╚════════════════════════════════════╝"
echo ""

# Start backend
echo "[1/2] Starting Backend API (port 3000)..."
cd "$BACKEND_DIR"
npm run dev &
BACKEND_PID=$!

# Start web frontend
echo "[2/2] Starting Web Frontend (port 8080)..."
cd "$WEB_DIR"
npx vite --host 0.0.0.0 &
WEB_PID=$!

echo ""
echo "──────────────────────────────────────"
echo "  Backend  →  http://localhost:3000"
echo "  Web      →  http://localhost:8080"
echo "──────────────────────────────────────"
echo "  Press Ctrl+C to stop both servers"
echo ""

wait
