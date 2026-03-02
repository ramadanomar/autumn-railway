#!/bin/sh
set -e

# ---------------------------------------------------------------------------
# Runtime environment variable injection
#
# Vite inlines import.meta.env.VITE_* as literal strings at build time.
# The Docker image was built with __PLACEHOLDER__ values. This script
# replaces them with the actual environment variables provided by Railway
# before starting the static file server.
# ---------------------------------------------------------------------------

for f in $(find /app/dist -type f \( -name "*.js" -o -name "*.html" \)); do
  sed -i "s|__VITE_BACKEND_URL__|${VITE_BACKEND_URL:-}|g"                   "$f"
  sed -i "s|__VITE_FRONTEND_URL__|${VITE_FRONTEND_URL:-}|g"                 "$f"
  sed -i "s|__VITE_SUPABASE_URL__|${VITE_SUPABASE_URL:-}|g"                 "$f"
  sed -i "s|__VITE_PUBLIC_POSTHOG_KEY__|${VITE_PUBLIC_POSTHOG_KEY:-}|g"     "$f"
  sed -i "s|__VITE_PUBLIC_POSTHOG_HOST__|${VITE_PUBLIC_POSTHOG_HOST:-}|g"   "$f"
  sed -i "s|__VITE_SENTRY_DSN__|${VITE_SENTRY_DSN:-}|g"                     "$f"
done

exec serve -s /app/dist -l 3000
