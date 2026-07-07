#!/usr/bin/env bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════
# ZANECO QuickPass — Database Setup Script
#
# Creates the PostgreSQL database, runs migrations, seeds data,
# and optionally creates an admin user.
#
# Usage:
#   ./scripts/setup_db.sh                  # uses .env.dev
#   NODE_ENV=production ./scripts/setup_db.sh
#
# ═══════════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKEND_DIR="$PROJECT_DIR/backend"

# ── Colors ──
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RESET='\033[0m'
log()  { printf "  ${GREEN}✓${RESET} %s\n" "$1"; }
warn() { printf "  ${YELLOW}⚠${RESET} %s\n" "$1"; }
err()  { printf "  ${RED}✗${RESET} %s\n" "$1"; exit 1; }
info() { printf "  ${CYAN}::${RESET} %s\n" "$1"; }
br()   { echo ""; }

# ── Load env ──

NODE_ENV="${NODE_ENV:-development}"
ENV_FILE="$BACKEND_DIR/.env.$NODE_ENV"

if [ "$NODE_ENV" = "development" ] && [ ! -f "$ENV_FILE" ]; then
  ENV_FILE="$BACKEND_DIR/.env.dev"
fi

if [ ! -f "$ENV_FILE" ]; then
  err "Environment file not found: $ENV_FILE"
fi

DB_CONNECTION=$(grep -E "^DB_CONNECTION=" "$ENV_FILE" | cut -d= -f2- | tr -d '"'"'")
[ -z "$DB_CONNECTION" ] && err "DB_CONNECTION not found in $ENV_FILE"

# ── Parse connection string ──
# postgresql://user:password@host:port/database

DB_USER=$(echo "$DB_CONNECTION" | sed -E 's|^postgresql://([^:]+):.*|\1|')
DB_PASS=$(echo "$DB_CONNECTION" | sed -E 's|^postgresql://[^:]+:([^@]+)@.*|\1|')
DB_HOST=$(echo "$DB_CONNECTION" | sed -E 's|^postgresql://[^@]+@([^:]+).*|\1|')
DB_PORT=$(echo "$DB_CONNECTION" | sed -E 's|^postgresql://[^@]+@[^:]+:([0-9]+)/.*|\1|')
DB_NAME=$(echo "$DB_CONNECTION" | sed -E 's|^.*/([^?]+).*|\1|')

[ -z "$DB_PORT" ] && DB_PORT=5432

log "Environment:   $NODE_ENV"
log "Host:          $DB_HOST:$DB_PORT"
log "Database:      $DB_NAME"
log "User:          $DB_USER"
br

# ── Check PostgreSQL ──

info "Checking PostgreSQL connection..."
if command -v psql &>/dev/null; then
  export PGPASSWORD="$DB_PASS"
  if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -c "SELECT 1" &>/dev/null; then
    log "PostgreSQL is running"
  else
    err "Cannot connect to PostgreSQL at $DB_HOST:$DB_PORT"
  fi
else
  warn "psql not found — will assume PostgreSQL is reachable"
fi
br

# ── Create database if not exists ──

info "Checking if database '$DB_NAME' exists..."
DB_EXISTS=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -tAc \
  "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'" 2>/dev/null || echo "")

if [ "$DB_EXISTS" = "1" ]; then
  log "Database '$DB_NAME' already exists"
else
  info "Creating database '$DB_NAME'..."
  createdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$DB_NAME"
  log "Database '$DB_NAME' created"
fi
br

unset PGPASSWORD

# ── Run migrations ──

info "Running migrations..."
cd "$BACKEND_DIR"
NODE_ENV=dev npx knex migrate:latest --knexfile knexfile.js
log "Migrations complete"
br

# ── Run seeds ──

info "Running seeds..."
NODE_ENV=dev npx knex seed:run --knexfile knexfile.js
log "Seeds complete"
br

# ── Admin user prompt ──

echo ""
echo "  ${CYAN}┌────────────────────────────────────────────┐${RESET}"
echo "  ${CYAN}│${RESET}  Create admin user?                          ${CYAN}│${RESET}"
echo "  ${CYAN}└────────────────────────────────────────────┘${RESET}"
echo ""
info "Email:    admin@zaneco.ph"
info "Password: admin123"
info "ID:       999999"
echo ""
read -r -p " ? Create admin user? [Y/n] " REPLY
REPLY="${REPLY:-Y}"
if [[ "$REPLY" =~ ^[Yy]$ ]]; then
  info "Creating admin user..."
  cd "$BACKEND_DIR"
  NODE_ENV=dev node scripts/createAdmin.js
  log "Admin user created"
else
  warn "Skipped admin user creation"
  warn "Run later:  cd backend && node scripts/createAdmin.js"
fi
br

# ── Done ──

echo "  ${CYAN}╔══════════════════════════════════════════════╗${RESET}"
echo "  ${CYAN}║${RESET}      Database setup complete                  ${CYAN}║${RESET}"
echo "  ${CYAN}╚══════════════════════════════════════════════╝${RESET}"
echo ""
info "Start the backend:  cd backend && npm run dev"
echo ""
