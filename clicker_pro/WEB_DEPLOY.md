# Clicker Pro — Flutter Web deploy

The Flutter app (`clicker_pro/`) builds and runs as a web app, replacing the
old Next.js `web_app/`. This is the build + hosting recipe.

## Build

```bash
cd clicker_pro
flutter build web --release \
  --dart-define=API_BASE_URL=https://api.deyalghori.com \
  --dart-define=WEB_BASE_URL=https://app.deyalghori.com
```

Output: `build/web/` (static files — `index.html`, `main.dart.js`,
`flutter_bootstrap.js`, the Drift WASM worker, assets).

- `API_BASE_URL` — the Laravel API origin the app calls. Provided via
  `--dart-define` (compile-time) and read by `lib/core/env/app_config.dart`.
  Falls back to the bundled `assets/.env` then a localhost default.
- `WEB_BASE_URL` — used to build share links (e.g. the studio's
  `/<WEB_BASE_URL>/book/<token>` public-booking link).

## Hosting — SPA fallback is REQUIRED

The app uses **path URL strategy** (clean URLs, no `#`). Deep links such as
`https://app.deyalghori.com/book/<token>` are client-side routes, so the web
server **must serve `index.html` for any unknown path** (SPA fallback).
Without this, a direct visit to `/book/...` returns 404.

### nginx
```nginx
server {
  listen 443 ssl http2;
  server_name app.deyalghori.com;
  root /var/www/clickerpro/clicker_pro/build/web;
  index index.html;

  # SPA fallback: serve index.html for any path that isn't a real file.
  location / {
    try_files $uri $uri/ /index.html;
  }

  # Long-cache the hashed build assets; never cache index.html.
  location = /index.html { add_header Cache-Control "no-cache"; }
}
```

### Apache (.htaccess in build/web/)
```apache
<IfModule mod_rewrite.c>
  RewriteEngine On
  RewriteBase /
  RewriteRule ^index\.html$ - [L]
  RewriteCond %{REQUEST_FILENAME} !-f
  RewriteCond %{REQUEST_FILENAME} !-d
  RewriteRule . /index.html [L]
</IfModule>
```

## CORS (backend)

The browser calls the API cross-origin, so the Laravel backend must allow the
web app's origin. Set in the backend `.env`:

```
CORS_ALLOWED_ORIGINS=https://app.deyalghori.com
```

(`laravel_backend/config/cors.php` reads this; it already covers `api/*`.)
Auth uses bearer tokens (not cookies), so credentialed CORS isn't needed.

## Notes / known follow-ups

- **Firebase on web:** `main.dart` initialises Firebase with the Android
  options; on web this fails softly (wrapped in try/catch) — push isn't wired
  for web yet. Add web Firebase options + a web push setup if web push is
  wanted later.
- **Drift persistence:** uses the WASM worker in `web/` → IndexedDB DB
  `clicker_pro`. Verified to persist across reloads.
- **Sessions:** the JWT lives in `flutter_secure_storage` (web: backed by
  localStorage). Verified to survive reloads (auto-login).
- **Base href:** keep `<base href="/">` in `web/index.html` if the app is
  served at the domain root. If served under a sub-path, set it accordingly
  and rebuild with `--base-href=/sub/`.
```
