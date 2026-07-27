#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ANY_FAILED=0

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

summary() {
  local tier="$1" result="$2"
  if [ "$result" -eq 0 ]; then
    printf "  ${GREEN}✓${NC} %s\n" "$tier"
  else
    printf "  ${RED}✗${NC} %s\n" "$tier"
    ANY_FAILED=1
  fi
}

echo ""
printf "${CYAN}════════════════════════════════════════${NC}\n"
printf "${CYAN}      Quickpass Test Suite${NC}\n"
printf "${CYAN}════════════════════════════════════════${NC}\n"
echo ""

# ── Backend ──
printf "${YELLOW}▸${NC} Backend tests...\n"
cd "$ROOT_DIR/backend"
npm test > /tmp/quickpass-backend-test.log 2>&1 && summary "Backend" 0 || summary "Backend" 1

# ── Web ──
printf "${YELLOW}▸${NC} Web tests...\n"
cd "$ROOT_DIR/web"
npx vitest run > /tmp/quickpass-web-test.log 2>&1 && summary "Web" 0 || summary "Web" 1

# ── Flutter (optional, skip if SDK missing) ──
printf "${YELLOW}▸${NC} Flutter tests..."
if command -v flutter &>/dev/null; then
  echo ""
  cd "$ROOT_DIR/flutter_app"
  flutter test > /tmp/quickpass-flutter-test.log 2>&1 && summary "Flutter" 0 || summary "Flutter" 1
else
  printf " ${YELLOW}skipped (SDK not found)${NC}\n"
fi

echo ""
if [ "$ANY_FAILED" -eq 0 ]; then
  printf "${GREEN}════════════════════════════════════════${NC}\n"
  printf "${GREEN}      All tests passed${NC}\n"
  printf "${GREEN}════════════════════════════════════════${NC}\n"
else
  printf "${RED}════════════════════════════════════════${NC}\n"
  printf "${RED}      Some tests failed${NC}\n"
  printf "${RED}════════════════════════════════════════${NC}\n"
  echo ""
  echo "Check log files for details:"
  echo "  Backend:  /tmp/quickpass-backend-test.log"
  echo "  Web:      /tmp/quickpass-web-test.log"
  echo "  Flutter:  /tmp/quickpass-flutter-test.log"
fi

exit "$ANY_FAILED"
