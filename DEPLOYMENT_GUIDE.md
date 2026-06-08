# ClickerPro — Deployment Guide

Production deployment for the four components. Based on the actual configs:
`laravel_backend/.env.production.example`, `config/cors.php`,
`config/sanctum.php`, and the Next.js `next.config` proxies.

> Recommended topology: a reverse proxy (nginx) terminating TLS in front of
> PHP-FPM (Laravel API) and the two Next.js Node servers; managed PostgreSQL.

---

## 1. VPS Setup

### Packages
```bash
# Ubuntu example
sudo apt update
sudo apt install -y nginx php8.2-fpm php8.2-cli php8.2-pgsql php8.2-mbstring \
  php8.2-xml php8.2-curl php8.2-zip unzip postgresql-client
# Composer
curl -sS https://getcomposer.org/installer | php && sudo mv composer.phar /usr/local/bin/composer
# Node 18+ (for web_app & admin_panel)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - && sudo apt install -y nodejs
```

### Backend (Laravel) — deploy
```bash
cd /var/www/clickerpro/laravel_backend
composer install --no-dev --optimize-autoloader
cp .env.production.example .env       # then fill in all values (below)
php artisan key:generate
php artisan migrate --force
# DO NOT run db:seed in production (it ships dev credentials)
php artisan config:cache
php artisan route:cache
php artisan view:cache
```

### Web app & Admin panel — deploy
```bash
cd web_app && npm ci && npm run build && npm run start    # serves on :3000
cd admin_panel && npm ci && npm run build && npm run start # serves on :3001
# (use pm2 / systemd to keep `next start` running)
# Set API_URL / API_PROXY_TARGET to the backend's internal URL.
```

### Mobile app — release builds
```bash
cd clicker_pro
flutter build appbundle    # Android (Play Store) — signed via android/key.properties
flutter build ios          # iOS (App Store) — via Xcode signing
# Point the app's API base URL at https://api.yourdomain.com
```

---

## 2. Environment Variables

Fill `laravel_backend/.env` (template: `.env.production.example`). Items marked
**[NEEDS ACCOUNT]** require an external service.

```ini
APP_NAME=ClickerPro
APP_ENV=production
APP_KEY=                      # php artisan key:generate
APP_DEBUG=false               # MUST be false in production
APP_URL=https://api.yourdomain.com

# Database (managed PostgreSQL recommended)
DB_CONNECTION=pgsql
DB_HOST=...
DB_PORT=5432
DB_DATABASE=clickerpro
DB_USERNAME=...
DB_PASSWORD=...

# CORS — exact app origins (comma-separated). Bearer-token auth, no cookies.
CORS_ALLOWED_ORIGINS=https://app.yourdomain.com,https://admin.yourdomain.com

# Sanctum token lifetime (minutes); default 7 days
SANCTUM_EXPIRATION=10080

# Mail (real delivery — needed for OTP/password-reset)  [NEEDS ACCOUNT]
MAIL_MAILER=smtp
MAIL_HOST=...                  # e.g. Amazon SES / Mailgun / Postmark
MAIL_PORT=587
MAIL_USERNAME=...
MAIL_PASSWORD=...
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS=noreply@yourdomain.com

# File storage (S3 / DigitalOcean Spaces)  [NEEDS ACCOUNT]
FILESYSTEM_DISK=s3
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
AWS_DEFAULT_REGION=us-east-1
AWS_BUCKET=...

# Push (Firebase Cloud Messaging)  [NEEDS ACCOUNT]
FCM_CREDENTIALS_PATH=storage/app/firebase-service-account.json

# Payment gateways (Bangladesh)  [NEEDS MERCHANT ACCOUNT]
BKASH_APP_KEY=...  BKASH_APP_SECRET=...  BKASH_USERNAME=...  BKASH_PASSWORD=...
NAGAD_MERCHANT_ID=...  NAGAD_MERCHANT_PRIVATE_KEY=...  NAGAD_PG_PUBLIC_KEY=...

# Infra drivers
SESSION_DRIVER=database
CACHE_STORE=database
QUEUE_CONNECTION=database
LOG_CHANNEL=stack
LOG_LEVEL=error               # avoid leaking detail in prod logs
```

Frontend env:
- `web_app/.env.production`: `API_URL=https://api.yourdomain.com`
- `admin_panel`: `API_PROXY_TARGET=https://api.yourdomain.com`

---

## 3. SSL / HTTPS

Terminate TLS at nginx (or Cloudflare). Redirect 80→443. HSTS is already emitted
by the backend's `SecurityHeaders` middleware **when the request is HTTPS**, so
just ensure traffic reaches Laravel over HTTPS (or with `X-Forwarded-Proto`).

```nginx
# api.yourdomain.com → Laravel (php-fpm)
server {
  listen 443 ssl http2;
  server_name api.yourdomain.com;
  ssl_certificate     /etc/letsencrypt/live/api.yourdomain.com/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/api.yourdomain.com/privkey.pem;
  root /var/www/clickerpro/laravel_backend/public;
  index index.php;
  location / { try_files $uri $uri/ /index.php?$query_string; }
  location ~ \.php$ {
    fastcgi_pass unix:/run/php/php8.2-fpm.sock;
    fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
    include fastcgi_params;
    fastcgi_param HTTPS on;            # so $request->secure() is true
  }
}
# app.yourdomain.com → proxy_pass http://127.0.0.1:3000  (web_app)
# admin.yourdomain.com → proxy_pass http://127.0.0.1:3001 (admin_panel)
server { listen 80; server_name api.yourdomain.com app.yourdomain.com admin.yourdomain.com;
         return 301 https://$host$request_uri; }
```
Issue certs with certbot: `sudo certbot --nginx -d api… -d app… -d admin…`.

---

## 4. Queue Worker

The app is configured for `QUEUE_CONNECTION=database`. There is **no
`app/Jobs/` yet** (CSV export/notifications currently run synchronously), so a
worker is **optional today** but recommended before adding heavy/async work
(per PERFORMANCE_AUDIT P4). When you add jobs, run a worker via systemd:

```ini
# /etc/systemd/system/clickerpro-queue.service
[Service]
User=www-data
WorkingDirectory=/var/www/clickerpro/laravel_backend
ExecStart=/usr/bin/php artisan queue:work --sleep=3 --tries=3 --max-time=3600
Restart=always
[Install]
WantedBy=multi-user.target
```
`sudo systemctl enable --now clickerpro-queue`. (Optionally add
`php artisan schedule:work` / cron for scheduled tasks.)

---

## 5. Backups

- **Database:** automated `pg_dump` to off-site storage, with a tested restore.
```bash
# daily cron
pg_dump "$DATABASE_URL" | gzip > /backups/clickerpro_$(date +\%F).sql.gz
```
- **Uploaded files:** if on S3/Spaces, enable bucket versioning; if on local
  disk, back up `storage/app`.
- **.env / secrets:** store in a secret manager, not in the repo.
- Verify restores periodically (a backup you can't restore isn't a backup).

---

## 6. Production Checklist

Security & config (from the security audits):
- [ ] `APP_DEBUG=false`, `APP_ENV=production`
- [ ] `APP_KEY` generated
- [ ] `CORS_ALLOWED_ORIGINS` = exact app + admin domains only
- [ ] TLS on all three domains; 80→443 redirect; HSTS active over HTTPS
- [ ] `LOG_LEVEL=error`; confirm passwords/tokens/OTP are never logged
- [ ] **Do not** run `db:seed` in prod; rotate the dev seed passwords
      (`Admin@1234`/`Test@1234`) — gate `DatabaseSeeder` behind `local`
- [ ] Real `MAIL_*` configured so OTP / password-reset are delivered out-of-band
- [ ] DB on a private network; least-privilege DB user; automated encrypted backups
- [ ] WAF / Cloudflare for DDoS + bot mitigation (mitigates residual Next.js DoS advisories)
- [ ] `php artisan config:cache route:cache view:cache` run on deploy
- [ ] `composer install --no-dev`; `npm ci && npm run build` for web + admin
- [ ] Dependency CVE follow-up: `composer audit`, `npm audit`
      (note: residual Next.js advisories need a Next 15/16 upgrade — see
      DEPENDENCY_FIX_REPORT.md)
- [ ] Mobile: signed release builds; API base URL → production; `keystores/` never committed

External services to provision (optional features):
- [ ] SMTP/SES (mail) · S3/Spaces (files) · Firebase FCM (push) ·
      bKash & Nagad merchant accounts (payments)

---

## Verification
- All env keys above exist in `laravel_backend/.env.production.example`.
- Driver values (`SESSION_DRIVER`/`CACHE_STORE`/`QUEUE_CONNECTION=database`)
  match the example file.
- CORS is env-driven (`CORS_ALLOWED_ORIGINS`) with `supports_credentials:false`
  per `config/cors.php` (bearer-token auth).
- Sanctum expiration is configurable via `SANCTUM_EXPIRATION` (default 7 days)
  per `config/sanctum.php`.
- `app/Jobs/` confirmed absent → queue worker noted as optional-until-needed.
