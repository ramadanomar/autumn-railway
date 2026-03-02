#!/bin/sh
set -e

# ---------------------------------------------------------------------------
# Runtime environment variable injection for the checkout app.
# Same approach as the dashboard — swap build-time placeholders with
# real values before serving static files.
# ---------------------------------------------------------------------------

for f in $(find /app/dist -type f \( -name "*.js" -o -name "*.html" \)); do
  sed -i "s|__VITE_API_URL__|${VITE_API_URL:-}|g" "$f"
done

exec serve -s /app/dist -l 3001
