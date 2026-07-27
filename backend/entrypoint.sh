#!/bin/sh
set -e

if [ "$SKIP_MIGRATIONS" != "true" ]; then
  echo "Running database migrations..."
  npx knex migrate:latest --knexfile knexfile.js
else
  echo "SKIP_MIGRATIONS=true — skipping database migrations"
fi

echo "Starting Quickpass API..."
exec node src/app.js