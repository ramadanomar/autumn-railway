# Autumn — Self-Hosted on Railway

One-click deploy [Autumn](https://github.com/useautumn/autumn) to [Railway](https://railway.com).

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/TEMPLATE_CODE)

---

## What gets deployed

| Service       | Image                                       | Port | Description                        |
|---------------|---------------------------------------------|------|------------------------------------|
| **Postgres**  | Railway plugin                              | 5432 | Primary database                   |
| **Redis**     | Railway plugin                              | 6379 | Cache + BullMQ queue               |
| **server**    | `ghcr.io/ramadanomar/autumn`                | 8080 | API backend (Hono)                 |
| **workers**   | `ghcr.io/ramadanomar/autumn`                | —    | Background job processor (BullMQ)  |
| **cron**      | `ghcr.io/ramadanomar/autumn`                | —    | Scheduled jobs (every minute)      |
| **dashboard** | `ghcr.io/ramadanomar/autumn-dashboard`      | 3000 | Admin UI (React + Vite)            |
| **checkout**  | `ghcr.io/ramadanomar/autumn-checkout`       | 3001 | Customer checkout pages            |

Server, workers, and cron all use the **same Docker image** with different
start commands. Database URLs, secrets, and inter-service URLs are
auto-configured by Railway.

**Database migrations run automatically** — the server entrypoint syncs the
schema on every deploy using `drizzle-kit push`. No SSH or manual steps needed.

---

## Deploy

1. Click the **Deploy on Railway** button above.
2. Railway auto-generates all required secrets and wires database URLs.
3. Optionally fill in the fields below during deploy (or add them later):

| Variable                        | Where to get it                                   |
|---------------------------------|---------------------------------------------------|
| `STRIPE_SANDBOX_SECRET_KEY`     | Stripe Dashboard > Developers > API keys (test)   |
| `STRIPE_LIVE_SECRET_KEY`        | Stripe Dashboard > Developers > API keys (live)   |
| `STRIPE_SANDBOX_WEBHOOK_SECRET` | Stripe Dashboard > Developers > Webhooks          |
| `STRIPE_LIVE_WEBHOOK_SECRET`    | Stripe Dashboard > Developers > Webhooks          |
| `STRIPE_SANDBOX_CLIENT_ID`      | Stripe Dashboard > Connect > Settings             |
| `STRIPE_LIVE_CLIENT_ID`         | Stripe Dashboard > Connect > Settings             |
| `RESEND_API_KEY`                | [resend.com](https://resend.com) > API Keys       |
| `RESEND_DOMAIN`                 | Your verified sending domain in Resend             |
| `SVIX_API_KEY`                  | [svix.com](https://www.svix.com) > API Keys       |
| `GOOGLE_CLIENT_ID`              | Google Cloud Console > Credentials                 |
| `GOOGLE_CLIENT_SECRET`          | Google Cloud Console > Credentials                 |
| `SUPABASE_URL`                  | Supabase project settings (for file storage)       |
| `SUPABASE_SERVICE_KEY`          | Supabase project settings > API                    |
| `ANTHROPIC_API_KEY`             | [console.anthropic.com](https://console.anthropic.com) |

4. Click **Deploy**. Your instance will be live in ~2-3 minutes.

---

## Post-deploy setup

### Stripe webhooks

After deploy, configure Stripe to send webhook events to your server:

1. Go to **Stripe Dashboard > Developers > Webhooks**
2. Add endpoint: `https://<your-server>.railway.app/stripe/webhook`
3. Select events: `checkout.session.completed`, `customer.subscription.*`,
   `invoice.*`, `subscription_schedule.*`
4. Copy the signing secret into your Railway service variables as
   `STRIPE_SANDBOX_WEBHOOK_SECRET` / `STRIPE_LIVE_WEBHOOK_SECRET`

### Custom domains

Railway generates `*.railway.app` domains by default. To use your own domain:

1. Go to your Railway project > service > Settings > Networking
2. Add your custom domain and configure DNS as instructed

### Email / OTP

Without `RESEND_API_KEY`, sign-in OTP codes are printed to the **server logs**
in Railway. Check the server service logs to find them.

---

## Updating

To update to a newer Autumn version:

1. Go to the [GitHub Actions](../../actions) tab of this repo
2. Run the **Build and Push Docker Images** workflow
3. Set the `autumn_version` input to the desired tag or branch
4. After images are pushed, Railway will detect the update and offer to redeploy
5. Database schema changes are applied automatically on server startup

---

## Architecture

```text
Browser ──> dashboard (port 3000)
              |
              v
Browser ──> server (port 8080) <── Stripe webhooks
              |
         ┌────┴────┐
         v         v
      Postgres    Redis <── workers (BullMQ)
                    ^
                    |
                   cron

Browser ──> checkout (port 3001)
              |
              v
            server (API)
```

- **dashboard** and **checkout** are static SPAs served by `serve`. They call
  the server API from the browser via the server's public Railway domain.
- **workers** poll Redis (BullMQ) for background jobs.
- **cron** runs scheduled tasks every minute (entitlement resets, invoice
  processing, trial cleanup).
- All backend services connect to Postgres and Redis via Railway's internal
  networking.

---

## Environment variables reference

### Auto-configured (you don't need to set these)

| Variable              | Value                                             |
|-----------------------|---------------------------------------------------|
| `DATABASE_URL`        | `${{Postgres.DATABASE_URL}}`                      |
| `CACHE_URL`           | `${{Redis.REDIS_URL}}`                            |
| `QUEUE_URL`           | `${{Redis.REDIS_URL}}`                            |
| `BETTER_AUTH_SECRET`  | `${{secret(64)}}` (auto-generated)                |
| `ENCRYPTION_PASSWORD` | `${{secret(32)}}` (auto-generated)                |
| `ENCRYPTION_IV`       | `${{secret(32)}}` (auto-generated)                |
| `BETTER_AUTH_URL`     | `https://${{server.RAILWAY_PUBLIC_DOMAIN}}`       |
| `CLIENT_URL`          | `https://${{dashboard.RAILWAY_PUBLIC_DOMAIN}}`    |
| `CHECKOUT_BASE_URL`   | `https://${{checkout.RAILWAY_PUBLIC_DOMAIN}}`     |
| `STRIPE_WEBHOOK_URL`  | `https://${{server.RAILWAY_PUBLIC_DOMAIN}}`       |
| `VITE_BACKEND_URL`    | `https://${{server.RAILWAY_PUBLIC_DOMAIN}}`       |
| `VITE_FRONTEND_URL`   | `https://${{dashboard.RAILWAY_PUBLIC_DOMAIN}}`    |
| `VITE_API_URL`        | `https://${{server.RAILWAY_PUBLIC_DOMAIN}}`       |

### Optional (add after deploy if needed)

| Variable                        | Purpose                              |
|---------------------------------|--------------------------------------|
| `STRIPE_SANDBOX_SECRET_KEY`     | Stripe test mode secret key          |
| `STRIPE_LIVE_SECRET_KEY`        | Stripe live mode secret key          |
| `STRIPE_SANDBOX_WEBHOOK_SECRET` | Stripe webhook signing (test)        |
| `STRIPE_LIVE_WEBHOOK_SECRET`    | Stripe webhook signing (live)        |
| `STRIPE_SANDBOX_CLIENT_ID`      | Stripe Connect OAuth (test)          |
| `STRIPE_LIVE_CLIENT_ID`         | Stripe Connect OAuth (live)          |
| `RESEND_API_KEY`                | Transactional emails                 |
| `RESEND_DOMAIN`                 | Email sending domain                 |
| `SVIX_API_KEY`                  | Outbound webhook delivery            |
| `GOOGLE_CLIENT_ID`              | Google sign-in                       |
| `GOOGLE_CLIENT_SECRET`          | Google sign-in secret                |
| `SUPABASE_URL`                  | File storage (org logos)             |
| `SUPABASE_SERVICE_KEY`          | Supabase service key                 |
| `ANTHROPIC_API_KEY`             | AI feature name generation           |
| `SENTRY_DSN`                    | Error tracking                       |
| `POSTHOG_API_KEY`               | Product analytics                    |
| `POSTHOG_HOST`                  | PostHog API host                     |

---

## License

Apache 2.0 — same as [Autumn](https://github.com/useautumn/autumn).
