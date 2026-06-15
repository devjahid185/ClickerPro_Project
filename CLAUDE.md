# Clicker Pro — Agent / Developer Context

Clicker Pro is a photography-studio SaaS with four parts in this monorepo:

| Dir | Stack | Purpose | Default port |
|-----|-------|---------|--------------|
| `clicker_pro/` | Flutter (Dart 3) | Mobile app (Android/iOS) | — |
| `laravel_backend/` | Laravel 11 (PHP 8.2) | REST API + DB | 5000 |
| `web_app/` | Next.js 14 (Pages router) | Public web app + public booking | 3000 |
| `admin_panel/` | Next.js 14 (App router) | Studio/admin dashboard | 3001 |

> **Full file/code map for developers:** see [DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md).
> **Shared-hosting deploy:** see [SHARED_HOSTING_DEPLOY.md](SHARED_HOSTING_DEPLOY.md).

## Key conventions (do not break)

- **API response wrapper:** Laravel returns payloads as `{ "data": ... }`. Clients must unwrap `data`.
- **Postgres JSON:** never use `whereJsonContains` blindly on PG — see DEVELOPER_GUIDE Gotchas.
- **Shared host build:** `web_app` builds with `RAYON_NUM_THREADS=1` (cPanel thread cap). On low-RAM machines do NOT cap `--max-old-space-size` too low (512 MB crashes the Next worker; use 2048+ or omit). `admin_panel` (App router) must ship a **prebuilt `.next`** — never build on the shared server; run `next start`.
- **Secrets:** `keystores/`, `*.jks`, `.env`, firebase admin keys are gitignored. Never commit them.
- **i18n:** Flutter strings live in `clicker_pro/lib/l10n/` (English + Bengali). Regenerate with `flutter gen-l10n`.

## Build / run quick reference

```bash
# Flutter
cd clicker_pro && flutter pub get && flutter analyze && flutter test
flutter build apk --release           # signed via android/key.properties

# Backend
cd laravel_backend && composer install && php artisan migrate && php artisan serve --port=5000

# Web app
cd web_app && npx next build && npx next start          # add RAYON_NUM_THREADS=1 on shared host

# Admin (ship prebuilt .next, then)
cd admin_panel && npx next start -p 3001
```

## Test logins / seed

See [DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md) → "Local setup & seed data".
