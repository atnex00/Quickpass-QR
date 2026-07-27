#!/usr/bin/env bash
set -euo pipefail

# Quickpass Database Backup Script
# Usage: ./scripts/backup-db.sh [output-dir]
# Requires: DB_CONNECTION env var to be set (from backend/.env.prod)

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BACKUP_DIR="${1:-$SCRIPT_DIR/backups}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/quickpass-backup-$TIMESTAMP.sql"

if [ -z "${DB_CONNECTION:-}" ]; then
  if [ -f "$SCRIPT_DIR/backend/.env.prod" ]; then
    set -a
    # shellcheck source=/dev/null
    . "$SCRIPT_DIR/backend/.env.prod"
    set +a
  else
    echo "Error: DB_CONNECTION is not set and backend/.env.prod not found"
    echo "Usage: DB_CONNECTION=postgresql://... ./scripts/backup-db.sh"
    exit 1
  fi
fi

mkdir -p "$BACKUP_DIR"

echo "Backing up database to $BACKUP_FILE ..."
pg_dump --no-owner --clean --if-exists "$DB_CONNECTION" > "$BACKUP_FILE"

gzip "$BACKUP_FILE"
echo "Done: ${BACKUP_FILE}.gz ($(du -h "${BACKUP_FILE}.gz" | cut -f1))"

# Keep only the last 30 backups
find "$BACKUP_DIR" -name 'quickpass-backup-*.sql.gz' -mtime +30 -delete