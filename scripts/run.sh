#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKEND_DIR="$PROJECT_DIR/backend"
WEB_DIR="$PROJECT_DIR/web"
FLUTTER_DIR="$PROJECT_DIR/flutter_app"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RESET='\033[0m'
log()  { printf "  ${GREEN}✓${RESET} %s\n" "$1"; }
warn() { printf "  ${YELLOW}⚠${RESET} %s\n" "$1"; }
err()  { printf "  ${RED}✗${RESET} %s\n" "$1"; exit 1; }
info() { printf "  ${CYAN}::${RESET} %s\n" "$1"; }
br()   { echo ""; }

PIDS=()

cleanup() {
  br
  info "Shutting down..."
  for pid in "${PIDS[@]}"; do
    kill "$pid" 2>/dev/null || true
  done
  wait 2>/dev/null || true
  adb reverse --remove tcp:3000 2>/dev/null || true
  log "All processes stopped"
  exit 0
}
trap cleanup EXIT INT TERM

br
echo "  ${CYAN}╔══════════════════════════════════════════════╗${RESET}"
echo "  ${CYAN}║${RESET}          Quickpass — Run All                  ${CYAN}║${RESET}"
echo "  ${CYAN}╚══════════════════════════════════════════════╝${RESET}"
br

[ -d "$BACKEND_DIR" ] || err "Backend directory not found at $BACKEND_DIR"
[ -d "$WEB_DIR" ] || err "Web directory not found at $WEB_DIR"

info "Starting Backend API (port 3000)..."
cd "$BACKEND_DIR"
npm run dev &
PIDS+=($!)
log "Backend started (PID $!)"

sleep 2

info "Starting Web Frontend (port 8080)..."
cd "$WEB_DIR"
npx vite --host 0.0.0.0 --port 8080 &
PIDS+=($!)
log "Web started (PID $!)"

sleep 2

DEVICE=$(adb devices | awk 'NR>1 && $2=="device" {print $1; exit}' 2>/dev/null || true)
if [ -z "$DEVICE" ]; then
  warn "No Android device detected — skipping Flutter"
  br
  echo "  ${CYAN}────────────────────────────────────────────${RESET}"
  echo "  Backend  →  http://localhost:3000"
  echo "  Web      →  http://localhost:8080"
  echo "  ${CYAN}────────────────────────────────────────────${RESET}"
  echo "  Press Ctrl+C to stop all"
  br
  wait
else
  info "Setting up ADB reverse tunnel (phone:3000 → host:3000)..."
  adb reverse tcp:3000 tcp:3000 2>/dev/null && log "ADB reverse tunnel established" || warn "ADB reverse tunnel failed"

  info "Starting Flutter on $DEVICE..."
  cd "$FLUTTER_DIR"
  flutter run --dart-define=API_BASE_URL=http://localhost:3000/api &
  FLUTTER_PID=$!
  PIDS+=($FLUTTER_PID)
  log "Flutter started (PID $FLUTTER_PID)"

  br
  echo "  ${CYAN}────────────────────────────────────────────${RESET}"
  echo "  Backend  →  http://localhost:3000"
  echo "  Web      →  http://localhost:8080"
  echo "  Phone    →  $DEVICE"
  echo "  ${CYAN}────────────────────────────────────────────${RESET}"
  echo "  Press Ctrl+C to stop all"
  br

  wait "$FLUTTER_PID"
fi
