# Clicker Pro / Graphy7 — VPS Production Deployment Guide

> **For:** the developer setting up the production VPS.
> **Goal:** publish backend API + admin panel + landing page + Flutter web app on a fresh Ubuntu VPS, clean (no test data), on a **new domain**.
> **Stack:** Laravel 12 (PHP 8.2+) · PostgreSQL · Nginx · Flutter Web (static) · Android APK (OTA-updated).

---

## 0. Before you start — fill these in

| Placeholder | Value (fill in) |
|---|---|
| `NEW_DOMAIN` | e.g. `graphy7.com` (not yet chosen — set once) |
| `API subdomain` | `api.NEW_DOMAIN` |
| `App subdomain` | `app.NEW_DOMAIN` |
| `Landing` | `NEW_DOMAIN` (root) |
| VPS IP | `xxx.xxx.xxx.xxx` |
| VPS OS | Ubuntu 22.04 / 24.04 LTS (assumed) |

**DNS (do first — propagation takes time):** point these A-records to the VPS IP:
- `NEW_DOMAIN` → VPS IP
- `www.NEW_DOMAIN` → VPS IP
- `api.NEW_DOMAIN` → VPS IP
- `app.NEW_DOMAIN` → VPS IP

---

## 1. Server base setup

```bash
# as root
apt update && apt upgrade -y
apt install -y nginx git unzip curl ufw software-properties-common

# PHP 8.3 + extensions Laravel 12 needs
add-apt-repository -y ppa:ondrej/php
apt update
apt install -y php8.3-fpm php8.3-cli php8.3-pgsql php8.3-mbstring \
  php8.3-xml php8.3-curl php8.3-zip php8.3-gd php8.3-bcmath php8.3-intl

# Composer
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

# PostgreSQL
apt install -y postgresql postgresql-contrib

# Firewall
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw --force enable
```

> **Redis is OPTIONAL.** The app uses `database` drivers for queue/cache/session and dispatches no background jobs, so Redis is **not required** to launch. Install it later only if load grows.

---

## 2. PostgreSQL — create clean production DB

```bash
sudo -u postgres psql <<'SQL'
CREATE DATABASE clickerpro;
CREATE USER clickerpro WITH ENCRYPTED PASSWORD 'CHANGE_ME_STRONG_PASSWORD';
GRANT ALL PRIVILEGES ON DATABASE clickerpro TO clickerpro;
ALTER DATABASE clickerpro OWNER TO clickerpro;
SQL
```

Starts empty — this is the intended **fresh, no-test-data** start.

---

## 3. Deploy the Laravel backend (API + admin + landing)

The backend lives in `laravel_backend/` of the repo.

```bash
mkdir -p /var/www
cd /var/www
git clone https://github.com/eventfilenhh/ClickerPro_Project.git clickerpro
cd clickerpro/laravel_backend

composer install --no-dev --optimize-autoloader

cp .env.example .env
php artisan key:generate
```

### 3a. Edit `.env` for production

```env
APP_NAME="Graphy7"
APP_ENV=production
APP_DEBUG=false
APP_URL=https://api.NEW_DOMAIN

DB_CONNECTION=pgsql
DB_HOST=127.0.0.1
DB_PORT=5432
DB_DATABASE=clickerpro
DB_USERNAME=clickerpro
DB_PASSWORD=CHANGE_ME_STRONG_PASSWORD

SESSION_DRIVER=database
QUEUE_CONNECTION=database
CACHE_STORE=database
FILESYSTEM_DISK=public
BROADCAST_CONNECTION=log

# Sanctum / CORS — allow the app + landing origins
SANCTUM_STATEFUL_DOMAINS=app.NEW_DOMAIN,NEW_DOMAIN
SESSION_DOMAIN=.NEW_DOMAIN

# Mail — set real SMTP for OTP/password-reset emails to actually send
MAIL_MAILER=smtp
MAIL_HOST=smtp.your-provider.com
MAIL_PORT=587
MAIL_USERNAME=...
MAIL_PASSWORD=...
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS=noreply@NEW_DOMAIN
MAIL_FROM_NAME="Graphy7"
```

> ⚠️ **OTP/login emails:** shared hosting used `MAIL_MAILER=log` (no real email). For production, **real SMTP is required** or users can't receive OTP / password-reset. Confirm the studio's SMTP (or a service like Postmark/SES/Mailgun).

### 3b. Migrate + optimise

```bash
php artisan migrate --force          # builds schema on the clean DB
php artisan storage:link             # public disk symlink for uploads (invoices, broadcasts, files)
php artisan config:cache
php artisan route:cache
php artisan view:cache

# permissions
chown -R www-data:www-data /var/www/clickerpro/laravel_backend
chmod -R 775 storage bootstrap/cache
```

### 3c. Seed the first admin + app version

There's no data, so create the platform admin and set the OTA version to match the shipped APK:

```bash
php artisan tinker <<'PHP'
// First platform admin — role MUST be 'ADMIN' (uppercase); that is exactly
// what unlocks the admin panel (AdminWebMiddleware checks role === 'ADMIN').
// There is NO is_admin column — role is the only gate.
$u = \App\Models\User::create([
  'name' => 'Admin',
  'email' => 'admin@NEW_DOMAIN',
  'password' => bcrypt('CHANGE_ME_ADMIN_PASSWORD'),
  'role' => 'ADMIN',
  'is_active' => true,
]);

// OTA version — MUST match the published APK (see section 6)
\App\Models\AppSetting::setValue('app_version_code', 40);
\App\Models\AppSetting::setValue('app_version_name', '3.10');
\App\Models\AppSetting::setValue('app_apk_url', 'https://NEW_DOMAIN/Graphy7.apk');
\App\Models\AppSetting::setValue('app_force_update', false);
PHP
```

> Verified against current code: admin gate is `role === 'ADMIN'` (uppercase); `AppSetting::setValue(key, value)` exists. If tinker feels risky, skip the version lines here and set the same 4 keys from the admin panel → App Settings after first login.

---

## 4. Deploy the Flutter web app (static)

The web app is a **static Flutter build** served from its own subdomain. It must be **rebuilt with the new API URL baked in**.

**Build locally (on the dev machine with Flutter), then upload — OR build on a machine with Flutter:**

```bash
cd clicker_pro
flutter build web --release \
  --dart-define=API_BASE_URL=https://api.NEW_DOMAIN \
  --dart-define=ENVIRONMENT=production

# upload build/web/* to the VPS
scp -r build/web/* root@VPS_IP:/var/www/clickerpro-web/
```

> The current bundled URL is `https://api.deyalghori.com` — it **must** change to `api.NEW_DOMAIN`, otherwise the web app talks to the old shared host. (`clicker_pro/.env` + the `--dart-define` above.)

---

## 5. Nginx — 3 server blocks

`/etc/nginx/sites-available/graphy7`:

```nginx
# --- Landing + admin panel + API (Laravel) on root + api subdomain ---
server {
    listen 80;
    server_name NEW_DOMAIN www.NEW_DOMAIN api.NEW_DOMAIN;
    root /var/www/clickerpro/laravel_backend/public;
    index index.php;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }
    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
    }
    client_max_body_size 25M;   # invoice/broadcast image uploads
}

# --- Flutter web app (static) on app subdomain ---
server {
    listen 80;
    server_name app.NEW_DOMAIN;
    root /var/www/clickerpro-web;
    index index.html;

    # SPA fallback so deep links (/#/bookings) work
    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

```bash
ln -s /etc/nginx/sites-available/graphy7 /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx
```

### 5a. HTTPS (Let's Encrypt — free)

```bash
apt install -y certbot python3-certbot-nginx
certbot --nginx -d NEW_DOMAIN -d www.NEW_DOMAIN -d api.NEW_DOMAIN -d app.NEW_DOMAIN
```

Certbot rewrites the config to 443 + auto-renews.

---

## 6. Android APK — build + host for OTA

The app self-updates via `GET /api/app/version`. Build a release APK, host it, and match the version.

```bash
cd clicker_pro
flutter build apk --release --flavor clickerPro \
  --dart-define=API_BASE_URL=https://api.NEW_DOMAIN \
  --dart-define=ENVIRONMENT=production
# output: build/app/outputs/apk/clickerPro/release/app-clickerPro-release.apk
```

- Rename to `Graphy7.apk`, upload to `/var/www/clickerpro/laravel_backend/public/Graphy7.apk`
  → served at `https://NEW_DOMAIN/Graphy7.apk` (matches `app_apk_url` from 3c).
- **pubspec is `3.10.0+40`** → `versionCode 40`. The OTA row (3c) is also `40` → consistent, no false "update available" loop.
- proAdmin (platform admin) app: same build with `--flavor proAdmin` if the admin uses the mobile admin app.

> **Play Store:** if publishing to Play Store instead of OTA-sideload, build an **AAB** (`flutter build appbundle --flavor clickerPro ...`) and upload to Play Console. OTA and Play Store are independent channels.

---

## 7. Go-live checklist

- [ ] DNS A-records resolve to VPS IP (all 4 hostnames)
- [ ] `https://api.NEW_DOMAIN/` → landing loads (200)
- [ ] `https://api.NEW_DOMAIN/admin/login` → 200, can log in as seeded admin
- [ ] `https://app.NEW_DOMAIN/` → Flutter web app loads
- [ ] `POST https://api.NEW_DOMAIN/api/auth/register` → 422 on empty body (route live)
- [ ] Register a real account on the app → **OTP email actually arrives** (SMTP works)
- [ ] `GET https://api.NEW_DOMAIN/api/app/version` → returns `versionCode 40 / 3.10`
- [ ] Fresh APK installs + logs in against the new API
- [ ] `APP_DEBUG=false` (never leak stack traces in production)
- [ ] DB backup cron set up (`pg_dump` daily)

---

## 8. What is intentionally NOT here

- **No test-data migration** — production starts empty by design.
- **No Redis / Supervisor / queue worker** — backend uses DB drivers and dispatches no jobs. Add later only under load.
- **Old shared host** (`*.deyalghori.com`) is abandoned once DNS moves; no wipe needed — it just stops being pointed at.

---

## 9. Redeploy (future updates)

```bash
cd /var/www/clickerpro && git pull
cd laravel_backend
composer install --no-dev --optimize-autoloader
php artisan migrate --force
php artisan config:cache && php artisan route:cache && php artisan view:cache
# web app: rebuild flutter web, re-upload to /var/www/clickerpro-web
# APK: bump pubspec version + OTA app_version_code, rebuild, re-upload
```
