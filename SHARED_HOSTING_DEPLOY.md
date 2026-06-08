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
deyalghori.com / api.deyalghori.com  → Laravel API (PHP)
app.deyalghori.com                   → web_app (Next.js, Node)
admin.deyalghori.com                 → admin_panel (Next.js, Node)
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

## STEP 4 — web_app (Next.js) via "Setup Node.js App"

cPanel → **Setup Node.js App** → **Create Application**:
- Node version: pick the highest (18+)
- Application mode: **Production**
- Application root: `clickerpro/web_app`
- Application URL: `app.deyalghori.com` (create the subdomain when prompted)
- Application startup file: leave default; we'll use `npm start`

After it's created, click **"Run JS script"** isn't enough — open **Terminal**:
```bash
cd ~/clickerpro/web_app
# activate the Node env cPanel made (it prints this command on the Node App page —
# looks like: source /home/deyalgho/nodevenv/clickerpro/web_app/18/bin/activate)
source ~/nodevenv/clickerpro/web_app/*/bin/activate
npm install
echo "API_URL=https://api.deyalghori.com" > .env.production
npm run build
```
Back on the **Setup Node.js App** page → set **Start command** to `npm start`
(or startup file to `node_modules/.bin/next start`) → **Restart**.

Test: `https://app.deyalghori.com` → landing/login page loads.

---

## STEP 5 — admin_panel (Next.js) — same pattern

cPanel → **Setup Node.js App** → **Create Application**:
- Application root: `clickerpro/admin_panel`
- Application URL: `admin.deyalghori.com`
```bash
cd ~/clickerpro/admin_panel
source ~/nodevenv/clickerpro/admin_panel/*/bin/activate
npm install
echo "API_PROXY_TARGET=https://api.deyalghori.com" > .env.production
npm run build
```
Start command: `npm start` (it runs on port 3001 per package.json; cPanel maps
the subdomain to it). **Restart**.

Test: `https://admin.deyalghori.com` → admin login. Sign in with
`admin@clickerpro.app` / `Admin@1234`.

---

## STEP 6 — Mobile app (Flutter) → point at the live API

The phone app isn't "hosted" — we build an APK that talks to the live API.
On **this PC** (I run these), set the API base and build:
```bash
cd clicker_pro
flutter build apk --release --dart-define=API_BASE_URL=https://api.deyalghori.com
```
Then install the APK on your phone (I'll give the transfer/install command).
Now the phone uses the real server over HTTPS — true end-to-end test.

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
cd ~/clickerpro && git pull
# backend:
cd laravel_backend && composer install --no-dev -o && php artisan migrate --force && php artisan config:cache
# web/admin: source the nodevenv, then: npm install && npm run build, Restart in Node App page
```

---

### Where we are
- Step 0 (GitHub push) — **I do this next, on your approval.**
- Steps 1–5 — **you run in cPanel**, pasting output back to me each step.
- Step 6 — **I build the APK** here.
- I'll fix anything that errors as we go.

**Say "push to GitHub" to start Step 0.**
