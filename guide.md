# Railway Template Composer Guide

Go to **https://railway.com/workspace/templates** and click **New Template**.

---

## Step 1: Add Databases

CMD+K -> + New Service -> Database

1. **PostgreSQL** — name it `Postgres`
2. **Redis** — name it `Redis`

---

## Step 2: Add App Services

For each: CMD+K -> + New Service -> Docker Image

| Service     | Image                                           | Start Command                   |
| ----------- | ----------------------------------------------- | ------------------------------- |
| `server`    | `ghcr.io/ramadanomar/autumn:latest`             | _(leave empty, Dockerfile CMD)_ |
| `workers`   | `ghcr.io/ramadanomar/autumn:latest`             | `/entrypoint.sh src/workers.ts` |
| `cron`      | `ghcr.io/ramadanomar/autumn:latest`             | `/entrypoint.sh src/cron.ts`    |
| `dashboard` | `ghcr.io/ramadanomar/autumn-dashboard:latest`   | _(leave empty, uses entrypoint)_|
| `checkout`  | `ghcr.io/ramadanomar/autumn-checkout:latest`    | _(leave empty, uses entrypoint)_|

Set the Start Command in each service's **Settings** tab.

---

## Step 3: Enable Public Networking

Click each service -> **Settings** tab -> enable public domain:

| Service     | Port |
| ----------- | ---- |
| `server`    | 8080 |
| `dashboard` | 3000 |
| `checkout`  | 3001 |

Workers and cron do **NOT** get public domains.

---

## Step 4: Set Environment Variables

Click each service -> **Variables** tab -> add these. The `${{...}}` syntax is preserved by the template composer as template variable functions.

### server

```
NODE_ENV=production # Runtime environment
PORT=8080 # Server listening port
DATABASE_URL=${{Postgres.DATABASE_URL}} # Auto-wired Postgres connection string
CACHE_URL=${{Redis.REDIS_URL}} # Auto-wired Redis connection for caching
BETTER_AUTH_SECRET=${{secret(64)}} # Auth session signing secret (auto-generated)
ENCRYPTION_PASSWORD=${{secret(32)}} # Encryption key for sensitive data (auto-generated)
ENCRYPTION_IV=${{secret(32)}} # Encryption initialization vector (auto-generated, checked at startup)
BETTER_AUTH_URL=https://${{server.RAILWAY_PUBLIC_DOMAIN}} # Public URL of the server for auth callbacks
CLIENT_URL=https://${{dashboard.RAILWAY_PUBLIC_DOMAIN}} # Dashboard URL for CORS and redirects
CHECKOUT_BASE_URL=https://${{checkout.RAILWAY_PUBLIC_DOMAIN}} # Checkout app URL for generating checkout links
STRIPE_WEBHOOK_URL=https://${{server.RAILWAY_PUBLIC_DOMAIN}}/v1/stripe/webhook # Stripe webhook endpoint URL
```

**Optional — Stripe (add to server, leave empty if not needed yet):**

```
STRIPE_SANDBOX_SECRET_KEY= # Stripe test mode secret key (sk_test_...)
STRIPE_LIVE_SECRET_KEY= # Stripe live mode secret key (sk_live_...)
STRIPE_SANDBOX_WEBHOOK_SECRET= # Stripe webhook signing secret for test mode (whsec_...)
STRIPE_LIVE_WEBHOOK_SECRET= # Stripe webhook signing secret for live mode (whsec_...)
STRIPE_SANDBOX_CLIENT_ID= # Stripe Connect OAuth client ID for test mode
STRIPE_LIVE_CLIENT_ID= # Stripe Connect OAuth client ID for live mode
```

**Optional — Email:**

```
RESEND_API_KEY= # Resend API key for transactional emails (OTP codes, invites). Without this, OTP codes print to server logs
RESEND_DOMAIN= # Sending domain configured in Resend (e.g. mail.yourdomain.com)
```

**Optional — Outbound Webhooks:**

```
SVIX_API_KEY= # Svix API key for reliable outbound webhook delivery to your users (Optional)
```

**Optional — OAuth / Social Login:**

```
GOOGLE_CLIENT_ID= # Google OAuth client ID for Google sign-in (Optional)
GOOGLE_CLIENT_SECRET= # Google OAuth client secret (Optional)
```

**Optional — File Storage:**

```
SUPABASE_URL= # Supabase project URL for file storage (org logos, avatars) (Optional)
SUPABASE_SERVICE_KEY= # Supabase service role key (Optional)
```

**Optional — AI:**

```
ANTHROPIC_API_KEY= # Anthropic API key for AI-powered feature name generation (Optional)
```

**Optional — Monitoring (add to server):**

```
SENTRY_DSN= # Sentry DSN for server-side error tracking (Optional)
POSTHOG_API_KEY= # PostHog project API key for product analytics (Optional)
POSTHOG_HOST= # PostHog API host (e.g. https://app.posthog.com) (Optional)
```

### workers

```
NODE_ENV=production # Runtime environment
DATABASE_URL=${{Postgres.DATABASE_URL}} # Auto-wired Postgres connection string
CACHE_URL=${{Redis.REDIS_URL}} # Auto-wired Redis connection for caching
QUEUE_URL=${{Redis.REDIS_URL}} # Redis URL for BullMQ job queue (enables workers)
BETTER_AUTH_SECRET=${{server.BETTER_AUTH_SECRET}} # Shared auth secret (references server's value)
ENCRYPTION_PASSWORD=${{server.ENCRYPTION_PASSWORD}} # Shared encryption key (references server's value)
ENCRYPTION_IV=${{server.ENCRYPTION_IV}} # Shared encryption IV (references server's value)
BETTER_AUTH_URL=https://${{server.RAILWAY_PUBLIC_DOMAIN}} # Public server URL for auth
CLIENT_URL=https://${{dashboard.RAILWAY_PUBLIC_DOMAIN}} # Dashboard URL
CHECKOUT_BASE_URL=https://${{checkout.RAILWAY_PUBLIC_DOMAIN}} # Checkout URL for generating links
```

Workers also need the same optional Stripe/Resend/Svix keys — linked from server so you only set them once:

```
STRIPE_SANDBOX_SECRET_KEY=${{server.STRIPE_SANDBOX_SECRET_KEY}} # Linked from server — workers process Stripe billing jobs
STRIPE_LIVE_SECRET_KEY=${{server.STRIPE_LIVE_SECRET_KEY}} # Linked from server
RESEND_API_KEY=${{server.RESEND_API_KEY}} # Linked from server — workers send transactional emails
RESEND_DOMAIN=${{server.RESEND_DOMAIN}} # Linked from server
SVIX_API_KEY=${{server.SVIX_API_KEY}} # Linked from server — workers dispatch outbound webhooks
```

### cron

```
NODE_ENV=production # Runtime environment
DATABASE_URL=${{Postgres.DATABASE_URL}} # Auto-wired Postgres connection string
CACHE_URL=${{Redis.REDIS_URL}} # Auto-wired Redis connection for caching
BETTER_AUTH_SECRET=${{server.BETTER_AUTH_SECRET}} # Shared auth secret (references server's value)
ENCRYPTION_PASSWORD=${{server.ENCRYPTION_PASSWORD}} # Shared encryption key (references server's value)
ENCRYPTION_IV=${{server.ENCRYPTION_IV}} # Shared encryption IV (references server's value)
BETTER_AUTH_URL=https://${{server.RAILWAY_PUBLIC_DOMAIN}} # Public server URL for auth
CLIENT_URL=https://${{dashboard.RAILWAY_PUBLIC_DOMAIN}} # Dashboard URL
CHECKOUT_BASE_URL=https://${{checkout.RAILWAY_PUBLIC_DOMAIN}} # Checkout URL
```

Cron also needs Stripe keys — linked from server:

```
STRIPE_SANDBOX_SECRET_KEY=${{server.STRIPE_SANDBOX_SECRET_KEY}} # Linked from server — cron runs scheduled billing checks
STRIPE_LIVE_SECRET_KEY=${{server.STRIPE_LIVE_SECRET_KEY}} # Linked from server
```

### dashboard

```
PORT=3000 # Dashboard listening port
VITE_BACKEND_URL=https://${{server.RAILWAY_PUBLIC_DOMAIN}} # API server URL for frontend requests
VITE_FRONTEND_URL=https://${{dashboard.RAILWAY_PUBLIC_DOMAIN}} # Dashboard's own URL (used for auth redirects)
```

**Optional — Dashboard monitoring/analytics (injected at runtime via sed):**

```
VITE_SUPABASE_URL= # Supabase URL for frontend file uploads (same as server's SUPABASE_URL)
VITE_PUBLIC_POSTHOG_KEY= # PostHog project API key for frontend analytics
VITE_PUBLIC_POSTHOG_HOST= # PostHog API host (e.g. https://app.posthog.com)
VITE_SENTRY_DSN= # Sentry DSN for frontend error tracking
```

### checkout

```
PORT=3001 # Checkout app listening port
VITE_API_URL=https://${{server.RAILWAY_PUBLIC_DOMAIN}} # API server URL for checkout oRPC client
```

---

## Step 5: Create the Template

Click **Create Template**. Copy the template URL — it looks like:

```
https://railway.com/new/template/XXXXXX
```

That `XXXXXX` is the template code for the deploy button.

---

## How the Variables Work

- `${{secret(64)}}` — generates a unique random secret per deploy
- `${{server.BETTER_AUTH_SECRET}}` — references the server's secret so workers/cron share the same value
- `${{Postgres.DATABASE_URL}}` / `${{Redis.REDIS_URL}}` — auto-wires database connections
- `${{server.RAILWAY_PUBLIC_DOMAIN}}` — resolves to the server's assigned railway.app domain
- Workers get `QUEUE_URL` pointing at Redis for BullMQ queue processing
- Optional vars left empty are harmless — Autumn logs warnings but runs fine without them
