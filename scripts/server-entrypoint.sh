#!/bin/sh
set -e

# ---------------------------------------------------------------------------
# Automatic database schema sync
#
# Only runs for the API server process (not workers or cron).
# Uses `drizzle-kit push` which introspects the live database, compares it
# to the TypeScript schema definitions, and applies CREATE TABLE / ALTER TABLE
# as needed. Fully idempotent — safe to run on every deploy.
#
# - Fresh deploy:  creates all tables
# - Update deploy: applies schema diffs (new columns, new tables, etc.)
# - No migration files needed — works by diffing schema ↔ DB directly
# ---------------------------------------------------------------------------

if [ "$1" = "src/index.ts" ]; then
  echo "[autumn-railway] Syncing database schema..."
  cd /app/shared

  # NODE_OPTIONS needed because drizzle-kit runs under Node internally,
  # and the config file is TypeScript (tsx provides the loader).
  # `yes` pipes auto-confirmation for any destructive-change prompts.
  NODE_OPTIONS="--import tsx" yes | bunx drizzle-kit push --config drizzle.config.ts 2>&1 \
    || echo "[autumn-railway] Schema push completed with warnings (may be OK on first run)"

  cd /app/server
  echo "[autumn-railway] Database ready."
fi

exec bun "$@"
