# ClickerPro

Photography & videography **studio/business management platform** for the
Bangladesh market. Manage bookings, clients, packages, finance, invoicing,
team, gear, and more — from a Flutter mobile app, a web app, and an admin panel,
all served by one Laravel API.

> Currency is Bangladeshi Taka (৳). Payment methods include bKash, Nagad, bank,
> card, and cash.

---

## Components

| Component | Path | Tech | Default URL (dev) |
|-----------|------|------|-------------------|
| Backend API | `laravel_backend/` | Laravel 12, PHP 8.2, PostgreSQL, Sanctum | http://localhost:5000 |
| Mobile app | `clicker_pro/` | Flutter (Dart SDK ^3.12), Riverpod, Drift | device/emulator |
| Web app | `web_app/` | Next.js 14.2 (Pages Router), React 18, TypeScript | http://localhost:3000 |
| Admin panel | `admin_panel/` | Next.js 14.2 (App Router), React 18, TypeScript | http://localhost:3001 |

**Scale (current):** 42 API controllers · 34 models · 40 migrations · 166 API
routes · 37 Flutter feature modules · 36 web pages · 17 admin pages.

---

## Tech Stack

**Backend** — Laravel 12 (`laravel/framework ^12.0`), PHP `^8.2`,
PostgreSQL (`DB_CONNECTION=pgsql`), Laravel Sanctum `^4.3` (bearer-token auth),
database-driven cache/queue/session.

**Mobile** — Flutter (Dart `^3.12.0`), Riverpod (state), Drift (local SQLite),
`flutter_secure_storage` (token storage), `http`, `pdf`/`printing`.

**Web app** — Next.js `14.2.35` (Pages Router), React 18, TypeScript 5; talks to
the API via a `/api/*` rewrite proxy.

**Admin panel** — Next.js `14.2.35` (App Router), React 18, TypeScript; same
`/api/*` proxy pattern.

---

## Prerequisites

- PHP 8.2+ and Composer
- PostgreSQL 14+ (project dev used PostgreSQL 18)
- Node.js 18+ and npm
- Flutter SDK (Dart ^3.12) with Android/iOS toolchain (for the mobile app)

---

## Setup

### 1. Backend (Laravel)
```bash
cd laravel_backend
composer install
cp .env.example .env          # then edit DB_* credentials
php artisan key:generate
php artisan migrate            # creates all 40 tables
php artisan db:seed            # admin + owner + feature flags + broadcasts
php artisan db:seed --class=SampleDataSeeder   # optional demo data
```
Key `.env` values:
```
APP_NAME=ClickerPro
APP_URL=http://localhost:5000
DB_CONNECTION=pgsql
DB_HOST=127.0.0.1
DB_PORT=5432
DB_DATABASE=clickerpro_laravel
DB_USERNAME=postgres
DB_PASSWORD=...
```

### 2. Web app
```bash
cd web_app
npm install
# .env.local: API_URL=http://localhost:5000   (proxy target for /api/*)
```

### 3. Admin panel
```bash
cd admin_panel
npm install
# optional: API_PROXY_TARGET=http://localhost:5000
```

### 4. Mobile app
```bash
cd clicker_pro
flutter pub get
# configure the API base URL via the app's env (flutter_dotenv / --dart-define)
```

---

## Run

```bash
# Terminal 1 — backend
cd laravel_backend && php artisan serve --port=5000

# Terminal 2 — web app  → http://localhost:3000
cd web_app && npm run dev

# Terminal 3 — admin panel → http://localhost:3001
cd admin_panel && npm run dev

# Terminal 4 — mobile app (device/emulator attached)
cd clicker_pro && flutter run
```

### Test logins (from `DatabaseSeeder`)
| Role | Email | Password |
|------|-------|----------|
| Admin | `admin@clickerpro.app` | `Admin@1234` |
| Owner | `owner@test.com` | `Test@1234` |

> ⚠️ These are **development seed credentials** — never deploy them. Rotate and
> gate the seeder behind `local` before production (see `DEPLOYMENT_GUIDE.md`).

---

## Build (production)

```bash
cd web_app     && npm run build && npm run start
cd admin_panel && npm run build && npm run start
cd clicker_pro && flutter build apk         # or: flutter build ios / appbundle
# backend: deploy laravel_backend with php-fpm behind nginx (see DEPLOYMENT_GUIDE.md)
```

---

## Documentation

| Doc | Contents |
|-----|----------|
| [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) | Folder tree + purpose |
| [MODULE_GUIDE.md](MODULE_GUIDE.md) | Modules per app + how they communicate |
| [API_DOCUMENTATION.md](API_DOCUMENTATION.md) | Endpoints, requests, responses, auth |
| [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md) | Tables, relationships, indexes, constraints |
| [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) | VPS, env, SSL, queue, backups, checklist |
| [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | Common errors + recovery |
| [TESTING_GUIDE.md](TESTING_GUIDE.md) | Android/iOS/web/admin/API testing |
| [STATUS.md](STATUS.md) | Feature status + remaining work |
| Security/Architecture/Performance audits | `*_AUDIT.md`, `*_FIX_*.md` |
