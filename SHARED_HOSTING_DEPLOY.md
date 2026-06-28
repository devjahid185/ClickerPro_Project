# ClickerPro — Deploy to ExonHost cPanel (deyalghori.com) — Test Run

> Goal: run the full app on your existing `deyalghori.com` shared hosting for a
> 3–7 day real-world test, at zero extra cost. Your cPanel has everything needed:
> **PostgreSQL**, **Node.js**, **Terminal/SSH**, PHP, Git, and **SSL already active**.

**Your environment (from cPanel):**
- Primary domain: `deyalghori.com` · Shared IP: `103.159.36.86`
- Home directory: `/home/deyalgho` · DB/user prefix: `deyalgho_`
- SSL: Active ✅ · GitHub repo: `github.com/eventfilenhh/ClickerPro_Project`

**Final layout we'll create:**
```
deyalghori.com / api.deyalghori.com  → Laravel API + admin console (PHP)
                                       (admin at api.deyalghori.com/admin)
app.deyalghori.com                   → Flutter Web static (clicker_pro/build/web)
PostgreSQL DB: deyalgho_clickerpro
Mobile app (Flutter): APK on phone, API base → https://api.deyalghori.com
```

> ⚠️ **How we work together:** I can't log into your cPanel (and you should never
> share its password). Instead, each step below gives you **exact copy-paste
> commands** for cPanel's **Terminal**. Do one step, paste the output back to me,
> I confirm or fix, then we move on. No credentials leave your hands.

---

## STEP 0 — Push the code to GitHub (done on your PC, by me)

The code is on this PC, not yet on GitHub. I'll push it when you say so. Nothing
secret goes up — `.env`, `node_modules`, `vendor`, `build/` are all gitignored.

(You don't run anything here — just approve "push to GitHub" and I'll do it.)

---

## STEP 1 — Create the PostgreSQL database

In cPanel → **PostgreSQL Databases** (you were just there):
1. **Create New Database** → name: `clickerpro` → it becomes `deyalgho_clickerpro`.
2. **Add New User** → name: `clicker` → becomes `deyalgho_clicker`. Set a strong
   password — **save it**, we need it for `.env`.
3. **Add User To Database** → pick `deyalgho_clicker` + `deyalgho_clickerpro` →
   grant **ALL PRIVILEGES**.

Write down (you'll paste into .env later):
```
DB_DATABASE=deyalgho_clickerpro
DB_USERNAME=deyalgho_clicker
DB_PASSWORD=<the password you set>
DB_HOST=127.0.0.1
DB_PORT=5432
```

---

## STEP 2 — Clone the repo via cPanel Terminal

cPanel → **Terminal** (Advanced section). Paste:
```bash
cd ~
git clone https://github.com/eventfilenhh/ClickerPro_Project.git clickerpro
cd clickerpro
ls
```
**Paste me the `ls` output.** (If the repo is private, cPanel will ask for a
GitHub token — tell me and I'll guide you to make a read-only token.)

---

## STEP 3 — Laravel API backend

### 3a. Install dependencies
```bash
cd ~/clickerpro/laravel_backend
# find the PHP 8.2+ binary (shared hosts often name it ea-php82)
which php; php -v | head -1
composer install --no-dev --optimize-autoloader
```
If `composer` isn't found, use: `php composer.phar install --no-dev --optimize-autoloader`
(I'll give you the exact path based on your output.)

### 3b. Create `.env`
```bash
cp .env.example .env
php artisan key:generate
nano .env
```
In `nano`, set these (then Ctrl+O, Enter, Ctrl+X to save):
```
APP_ENV=production
APP_DEBUG=false
APP_URL=https://api.deyalghori.com
DB_CONNECTION=pgsql
DB_HOST=127.0.0.1
DB_PORT=5432
DB_DATABASE=deyalgho_clickerpro
DB_USERNAME=deyalgho_clicker
DB_PASSWORD=<your db password>
CORS_ALLOWED_ORIGINS=https://app.deyalghori.com,https://admin.deyalghori.com
SESSION_DRIVER=database
CACHE_STORE=database
QUEUE_CONNECTION=database
MAIL_MAILER=log
LOG_LEVEL=error
```

### 3c. Migrate + seed (creates all 40 tables + admin/owner logins)
```bash
php artisan migrate --force
php artisan db:seed --force          # admin@clickerpro.app / owner@test.com
php artisan config:cache && php artisan route:cache
```
**Paste me the migrate output** — it should list all tables as DONE.

### 3d. Point a subdomain at Laravel's `public/`
cPanel → **Domains** → **Create A New Domain** → `api.deyalghori.com`
→ set **Document Root** to: `/home/deyalgho/clickerpro/laravel_backend/public`
(SSL auto-applies; the wildcard cert covers subdomains.)

Test in a browser: `https://api.deyalghori.com` → should return a Laravel page
or JSON (not a 500). Then:
```bash
curl -s https://api.deyalghori.com/api/auth/login -X POST \
  -H "Content-Type: application/json" -H "Accept: application/json" \
  -d '{"email":"owner@test.com","password":"Test@1234"}'
```
**Paste the result** — a `{"data":{"token":...}}` means the backend is live. 🎉

---

## STEP 4 — Web app (Flutter Web) — static files, no Node app

The web app is the Flutter app built for web — **plain static files**, so
there's no Node app to run. Build it **locally** (the shared host has no
Flutter SDK), then upload the output.

Locally:
```bash
cd clicker_pro
flutter build web --release --dart-define=API_BASE_URL=https://api.deyalghori.com
# → build/web/  (index.html, main.dart.js, assets, Drift WASM worker)
```

On the host:
1. Create the `app.deyalghori.com` subdomain, document root e.g.
   `~/clickerpro_web` (or `public_html/app`).
2. Upload the **contents of `build/web/`** there (zip → upload → extract).
3. **SPA fallback is required** (clean URLs / deep links like `/book/<token>`).
   Add this `.htaccess` in the web root:
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

Test: `https://app.deyalghori.com` → app loads → login → dashboard.
(See `clicker_pro/WEB_DEPLOY.md` for the full recipe incl. nginx.)

---

## STEP 5 — Admin console (Laravel Blade — nothing extra to deploy)

The admin console is **part of the Laravel backend** now (server-rendered
Blade at `/admin`). It needs **no Node app, no subdomain, no build** — STEP 2
(the Laravel deploy) already shipped it.

Test: `https://api.deyalghori.com/admin` → admin login. Sign in with
`admin@clickerpro.app` / `Admin@1234`.

> If you cached config/routes/views during the Laravel deploy, the admin
> routes are included automatically. After any update, re-run
> `php artisan route:cache && php artisan view:cache`.

---

## STEP 6 — Mobile app (Flutter) → already points at the live API ✅

The phone app isn't "hosted" — the installed APK talks to the live API.
**Good news:** the bundled `clicker_pro/.env` already sets
`API_BASE_URL=https://api.deyalghori.com`, so the APK currently on both phones
will hit the live server the moment the backend (STEP 3) is up — **no rebuild
needed** for this test.

If you ever change the API host, edit `clicker_pro/.env` (or pass
`--dart-define=API_BASE_URL=...`) and rebuild:
```bash
cd clicker_pro && flutter build apk --release        # then reinstall on the phones
```
Once STEP 3 is live, open the app on the phone → log in → create a booking →
record a payment. That's the true end-to-end test over HTTPS.

---

## STEP 7 — Verify the whole thing (the actual test)

| Check | How |
|-------|-----|
| API up | `https://api.deyalghori.com` returns JSON |
| Web app | log in at `app.deyalghori.com` |
| Admin | log in at `admin.deyalghori.com` |
| Mobile | APK on phone → login → create booking → record payment |
| SSL | all three show 🔒 (cert already active) |
| OTP email | `MAIL_MAILER=log` writes codes to `storage/logs/laravel.log`; for real email set SMTP later |

---

## Important notes / limits of shared hosting (honest)

- **Queue worker:** shared hosting can't keep a `queue:work` daemon running. Fine
  for the test — the app runs jobs synchronously. (Your future VPS will add a
  real worker.) If you want scheduled tasks, use cPanel **Cron Jobs**.
- **Node app stability:** cPanel restarts Node apps on idle; first hit after idle
  may be slow. Acceptable for a 3–7 day test.
- **Resources:** you have 1 GB RAM, 20 entry processes. Two Node apps + PHP is
  tight but workable for low test traffic. If admin+web together strain it, we
  can run only `app` + `api` and test admin locally.
- **This is a test rig**, not the final home — when the domain expires you move to
  the new VPS using `DEPLOYMENT_GUIDE.md` (same steps, more headroom).

---

## Updating later (after code changes)
```bash
cd ~/clickerpro && git pull          # pulls new code AND the committed admin .next

# backend (run migrate only if there are new migrations):
cd ~/clickerpro/laravel_backend
composer install --no-dev -o
php artisan migrate --force
php artisan config:cache && php artisan route:cache

# web app (Flutter Web) — build LOCALLY, upload build/web/ contents to the
# app subdomain root (static; keep the SPA-fallback .htaccess in place).
#   local:  cd clicker_pro && flutter build web --release \
#             --dart-define=API_BASE_URL=https://api.deyalghori.com

# admin console — nothing to do here; it's served by the Laravel app at /admin.
```
> ⚠️ This release fixed a live bug: Admin **Analytics** and **Reports** pages
> threw 500 on PostgreSQL (MySQL-only `DATE_FORMAT` → now `TO_CHAR`). After this
> `git pull` + `config:cache`, those pages will work. No new migration needed.

---

### Where we are
- Step 0 (GitHub push) — **I do this next, on your approval.**
- Steps 1–5 — **you run in cPanel**, pasting output back to me each step.
- Step 6 — **I build the APK** here.
- I'll fix anything that errors as we go.

**Say "push to GitHub" to start Step 0.**
