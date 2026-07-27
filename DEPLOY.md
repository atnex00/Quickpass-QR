# Quickpass Production Deployment

> End-to-end guide for deploying Quickpass to a production server with Docker, Cloudflare HTTPS, and Supabase PostgreSQL.

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Overview](#quick-overview)
- [1. Server Preparation](#1-server-preparation)
- [2. Database Setup](#2-database-setup)
- [3. Environment Configuration](#3-environment-configuration)
- [4. Cloudflare HTTPS](#4-cloudflare-https)
- [5. Firewall Rules](#5-firewall-rules)
- [6. Docker Deployment](#6-docker-deployment)
- [7. Verification](#7-verification)
- [8. Maintenance](#8-maintenance)
- [Optional: Sentry Error Tracking](#optional-sentry-error-tracking)
- [Optional: Flutter App Build](#optional-flutter-app-build)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

| Item | Details |
|------|---------|
| Domain name | e.g., `quickpass.example.com` — buy from any registrar |
| Linux server | Ubuntu 22.04+ recommended, 2 GB RAM, public IP |
| Docker & Compose | Installed on the server |
| Cloudflare account | [Free tier](https://dash.cloudflare.com/sign-up) |
| Supabase project | [Cloud PostgreSQL](https://supabase.com) — see [Supabase Setup in README](README.md#supabase-setup) |

---

## Quick Overview

```
User's browser → https://quickpass.example.com
                        │
                  [Cloudflare Edge]
                   TLS terminated here
                   (auto certificate, auto renewal)
                        │
                  HTTPS (origin certificate)
                        │
              nginx container (port 443)
                  │         │
           static files   proxy_pass
           (web/dist)         │
                        backend:3000
                             │
                       Supabase PostgreSQL
```

The stack:
- **nginx** serves the built React frontend and proxies `/api/` to the backend
- **Backend** (Node.js/Express) handles API requests and connects to Supabase
- **Cloudflare** terminates TLS and forwards to nginx over HTTPS
- No local PostgreSQL — all data lives in Supabase cloud

---

## 1. Server Preparation

### Install Docker

```bash
# Ubuntu / Debian
curl -fsSL https://get.docker.com | sudo bash
sudo usermod -aG docker $USER

# Log out and back in, then verify:
docker --version
docker compose version
```

### Clone the repository

```bash
git clone https://github.com/atnex00/Quickpass-QR.git
cd Quickpass-QR
```

### Create required directories

```bash
mkdir -p certs backend/uploads
```

---

## 2. Database Setup

Quickpass uses **Supabase** as its PostgreSQL provider. Follow the [Supabase Setup guide in README.md](README.md#supabase-setup) to:

1. Create a Supabase project
2. Get the connection string
3. Allowlist your server's IP in **Supabase Dashboard → Project Settings → Database → Network**

### Run Migrations & Seed

After configuring the environment (next section), run:

```bash
cd backend
npm run migrate
npm run seed
```

> Migrations live in `database/migrations/` outside the backend folder. The knex config points to `../database/migrations` so this works from the `backend/` directory.

---

## 3. Environment Configuration

Create `backend/.env.prod` on the server with these values:

```env
NODE_ENV=production
PORT=3000

# Supabase connection (replace with your own)
DB_CONNECTION=postgresql://postgres:YOUR_PASSWORD@db.YOUR_REF.supabase.co:5432/postgres
DB_SSL=true

# Secrets — generate strong random values:
JWT_SECRET=<run: openssl rand -hex 64>
COOKIE_SECRET=<run: openssl rand -hex 64>
QR_SECRET=<run: openssl rand -hex 64>

JWT_EXPIRES_IN=24h
SESSION_EXPIRES_IN=7d
QR_VALIDITY_WINDOW_MINUTES=15

# Frontend origin (your domain)
CORS_ORIGIN=https://quickpass.example.com

# Optional: Firebase Cloud Messaging for push notifications
# FCM_PROJECT_ID=...
# FCM_PRIVATE_KEY=...
# FCM_CLIENT_EMAIL=...

# Optional: Sentry error tracking
# SENTRY_DSN=https://your-dsn@sentry.io/your-project
```

### Generate secrets

```bash
openssl rand -hex 64
# Copy the output into JWT_SECRET, COOKIE_SECRET, QR_SECRET
# Use a DIFFERENT random value for each
```

### Required variables

The backend **will not start** in production if any of these are missing:

| Variable | Why it's required |
|----------|-------------------|
| `DB_CONNECTION` | No database = no app |
| `JWT_SECRET` | Token signing |
| `COOKIE_SECRET` | Signed session cookies |
| `QR_SECRET` | QR code HMAC signing |
| `CORS_ORIGIN` | Browser security |

---

## 4. Cloudflare HTTPS

### 4.1 Add your domain to Cloudflare

1. Sign up at [dash.cloudflare.com](https://dash.cloudflare.com) (free tier)
2. Click **Add a Site** → enter your domain → **Add**
3. Select the **Free** plan
4. Cloudflare scans existing DNS records — proceed
5. You'll get **two nameserver addresses** (e.g., `dahlia.ns.cloudflare.com`, `chad.ns.cloudflare.com`)
6. Go to your **domain registrar** and replace current nameservers with Cloudflare's
7. Wait for propagation (5 min to a few hours)

### 4.2 Create a DNS record

In Cloudflare Dashboard → **DNS** → **Records** → **Add Record**:

| Field | Value |
|---|---|
| Type | `A` |
| Name | `quickpass` (or `@` for root domain) |
| IPv4 Address | Your server's public IP |
| Proxy status | **Proxied** (orange cloud) |

> **Proxied is critical** — this enables Cloudflare's SSL/TLS, DDoS protection, and caching.

### 4.3 Set SSL/TLS mode

Cloudflare Dashboard → **SSL/TLS** → **Overview** → set to **Full (strict)**.

This means:
- User connects via HTTPS (Cloudflare edge cert)
- Cloudflare connects to your server via HTTPS (verifying your origin cert)
- End-to-end encryption

### 4.4 Generate an Origin Certificate

Cloudflare Dashboard → **SSL/TLS** → **Origin Server** → **Create Certificate**:

1. **Private key type**: RSA (2048-bit)
2. **Hostnames**: `quickpass.example.com` (your actual domain)
3. **Validity**: 15 years
4. Click **Create**

You'll see two blocks:

- **Origin Certificate** — save as `certs/server.crt`
- **Private Key** — save as `certs/server.key` (shown only once!)

```bash
# On your server, from the Quickpass-QR directory:
nano certs/server.crt   # paste origin certificate
nano certs/server.key   # paste private key
chmod 600 certs/server.key
```

The nginx config already expects certs at `/etc/nginx/certs/server.crt` and `server.key`, and `docker-compose.yml` maps `./certs` to that path. No config changes needed.

---

## 5. Firewall Rules

Since all legitimate traffic comes through Cloudflare, restrict port 443 to only Cloudflare's IP ranges:

### UFW (Ubuntu)

```bash
# Download Cloudflare IPv4 ranges
curl -s https://www.cloudflare.com/ips-v4 -o /tmp/cf-ipv4.txt

# Allow each Cloudflare IP range on port 443
while IFS= read -r ip; do
  sudo ufw allow from "$ip" to any port 443 proto tcp
done < /tmp/cf-ipv4.txt

# Then deny everyone else
sudo ufw deny 443

# Also allow SSH and HTTP (for ACME challenge if needed)
sudo ufw allow 22
sudo ufw allow 80
sudo ufw enable
```

### Cloud Firewall (DigitalOcean, AWS, etc.)

Create an allow rule for ports 80 and 443 with **source = Cloudflare IPs only**. Cloudflare publishes their IP ranges at:

- [https://www.cloudflare.com/ips-v4](https://www.cloudflare.com/ips-v4)
- [https://www.cloudflare.com/ips-v6](https://www.cloudflare.com/ips-v6)

---

## 6. Docker Deployment

### 6.1 Build and start

```bash
# From the Quickpass-QR directory:

# Build images and start in detached mode
docker compose up --build -d

# Check that both containers are running
docker compose ps
```

Expected output:

```
NAME              IMAGE               STATUS          PORTS
quickpass-api     quickpass-backend   Up 3 minutes    0.0.0.0:3000->3000/tcp
quickpass-web     quickpass-web       Up 3 minutes    0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp
```

### 6.2 View logs

```bash
# Backend logs
docker compose logs -f backend

# Web (nginx) logs
docker compose logs -f web

# All logs
docker compose logs -f
```

### 6.3 Stop the stack

```bash
docker compose down
```

---

## 7. Verification

### Health check

```bash
curl -k https://localhost/api/health
# Or from outside using your domain:
curl https://quickpass.example.com/api/health
```

Expected response:

```json
{ "success": true, "message": "OK", "timestamp": "..." }
```

### Web app

Visit `https://quickpass.example.com` in a browser — you should see the login page with a valid SSL lock icon.

### SSL test

```bash
# Verify TLS is working
curl -vI https://quickpass.example.com 2>&1 | grep "SSL connection"
```

### Full flow

1. Log in as an employee (e.g., ID `000001`, password `pass1234`)
2. Submit a leave request
3. Log in as a supervisor (e.g., ID `000011`, password `pass1234`)
4. Navigate to **Pending Requests** and approve
5. Log in as security (e.g., ID `090901`, password `pass1234`)
6. Scan the OUT QR code → status should become **active**
7. Scan the IN QR code → status should become **completed**

---

## 8. Maintenance

### Applying new migrations

```bash
# SSH into the server
cd Quickpass-QR
docker compose exec backend npx knex migrate:latest --knexfile knexfile.js
```

### Rolling back a migration

```bash
docker compose exec backend npx knex migrate:rollback --knexfile knexfile.js
```

### Updating the app

```bash
cd Quickpass-QR
git pull
docker compose up --build -d
```

### Updating secrets

Never change secrets (`JWT_SECRET`, `QR_SECRET`, `COOKIE_SECRET`) in production without coordinating downtime — all active sessions and existing QR codes will be invalidated.

### Backing up the database

Supabase provides automated backups. You can also manually export:

```bash
pg_dump --no-owner "$DB_CONNECTION" > quickpass-backup-$(date +%Y%m%d).sql
```

### Monitoring

Check the backend logs for errors:

```bash
docker compose logs --tail=100 -f backend | grep -i error
```

---

## Optional: Sentry Error Tracking

Sentry integration is built in but disabled by default. To enable:

1. Create a project at [sentry.io](https://sentry.io) for Node.js/Express
2. Add to `backend/.env.prod`:

```env
SENTRY_DSN=https://your-dsn@sentry.io/your-project
SENTRY_SAMPLE_RATE=0.1
```

3. Rebuild and restart:

```bash
docker compose up --build -d
```

Errors will now appear in your Sentry dashboard with request IDs, stack traces, and environment context.

---

## Optional: Flutter App Build

If you're deploying the Android app to users:

### 1. Set up the production API URL

Edit `flutter_app/env.prod.json`:

```json
{
  "API_BASE_URL": "https://quickpass.example.com/api"
}
```

### 2. Build the release APK

```bash
cd flutter_app

# Using the production config
flutter build apk --split-per-abi --dart-define-from-file=env.prod.json

# Or for Play Store
flutter build appbundle --dart-define-from-file=env.prod.json
```

### 3. Sign the APK

Follow the [Android Keystore setup in README](README.md#android-keystore-release-builds) to create a signing key and `key.properties`.

The APK will be at `flutter_app/build/app/outputs/flutter-apk/`.

---

## Troubleshooting

### nginx fails to start — "cannot load certificate"

```
nginx: [emerg] cannot load certificate "/etc/nginx/certs/server.crt"
```

The `certs/` directory is empty or missing. Run the cert generation script:

```bash
bash scripts/generate-certs.sh   # self-signed for testing
```

Or copy your Cloudflare origin certs to `certs/server.crt` and `certs/server.key`.

### Backend won't start — missing env vars

```
JWT_SECRET is required in production. Set it in your backend/.env file.
```

Check that `backend/.env.prod` exists and has all [required variables](#required-variables).

### "Cannot reach database"

```
Error: connect ECONNREFUSED db.xxxxx.supabase.co:5432
```

1. Go to **Supabase Dashboard → Project Settings → Database → Network**
2. Add your server's IP to the allowlist
3. Ensure `DB_SSL=true` is set
4. Verify the connection string is correct

### "Mixed content" warning in browser

If the browser shows "This page is trying to load resources from an insecure source", Cloudflare might be set to **Flexible** instead of **Full (strict)**. Change it:

```
Cloudflare Dashboard → SSL/TLS → Overview → Full (strict)
```

### Mobile camera not working

The web-based QR scanner requires HTTPS. Verify:
- You're visiting `https://` not `http://` (Cloudflare should auto-redirect)
- The browser isn't blocking camera access (check site permissions)
- You're using a supported browser (Chrome, Safari, Edge)

### Slow first load

Cloudflare caches static assets after the first request. For consistently fast loads:

```
Cloudflare Dashboard → Speed → Optimization → Auto Minify (enable JS, CSS, HTML)
Cloudflare Dashboard → Caching → Configuration → Browser Cache TTL: 4 hours
```

### "429 Too Many Requests"

The built-in rate limiter may trigger if testing aggressively. Wait 15 minutes or check the backend logs:

```bash
docker compose logs backend | grep "rate-limit"
```