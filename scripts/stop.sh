#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RESET='\033[0m'
log()  { printf "  ${GREEN}✓${RESET} %s\n" "$1"; }
warn() { printf "  ${YELLOW}⚠${RESET} %s\n" "$1"; }
err()  { printf "  ${RED}✗${RESET} %s\n" "$1"; }
info() { printf "  ${CYAN}::${RESET} %s\n" "$1"; }
br()   { echo ""; }

br
echo "  ${CYAN}╔══════════════════════════════════════════════╗${RESET}"
echo "  ${CYAN}║${RESET}         Quickpass — Stop All                 ${CYAN}║${RESET}"
echo "  ${CYAN}╚══════════════════════════════════════════════╝${RESET}"
br

info "Finding running Quickpass processes..."

kill_by_port() {
  local port=$1 name=$2
  local pids
  pids=$(lsof -ti :"$port" 2>/dev/null || true)
  if [ -n "$pids" ]; then
    kill $pids 2>/dev/null || true
    sleep 1
    pids=$(lsof -ti :"$port" 2>/dev/null || true)
    if [ -n "$pids" ]; then
      kill -9 $pids 2>/dev/null || true
      warn "$name (port $port) force killed"
    else
      log "$name (port $port) stopped"
    fi
  else
    warn "$name (port $port) — not running"
  fi
}

kill_by_name() {
  local pattern=$1 name=$2
  local pids
  pids=$(pgrep -f "$pattern" 2>/dev/null || true)
  if [ -n "$pids" ]; then
    kill $pids 2>/dev/null || true
    sleep 1
    pids=$(pgrep -f "$pattern" 2>/dev/null || true)
    if [ -n "$pids" ]; then
      kill -9 $pids 2>/dev/null || true
      warn "$name force killed"
    else
      log "$name stopped"
    fi
  else
    warn "$name — not running"
  fi
}

kill_by_port 3000 "Backend API"
kill_by_port 8080 "Web Frontend"
kill_by_name "flutter_tools" "Flutter"
kill_by_name "flutter.*run" "Flutter"

info "Removing ADB reverse tunnel..."
adb reverse --remove tcp:3000 2>/dev/null && log "ADB reverse tunnel removed" || warn "No ADB reverse tunnel found"

br
log "All processes stopped"
