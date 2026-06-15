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
# Build with the shared-host flags. RAYON_NUM_THREADS=1 avoids the thread-cap
# SIGABRT. Give Node enough heap — do NOT cap it to 512MB (the Next build worker
# crashes with exit 3221226505 / "worker exited"). 1536–2048MB is safe on 1GB+.
RAYON_NUM_THREADS=1 NEXT_TELEMETRY_DISABLED=1 NODE_OPTIONS=--max-old-space-size=1536 npm run build
```
> If the web build still OOMs on the 1 GB plan, build it **locally** (`cd web_app
> && npm run build`) and upload the `web_app/.next` folder via cPanel File
> Manager — same prebuilt approach as admin. Then just `npm start` on the server.
Back on the **Setup Node.js App** page → set **Start command** to `npm start`
(or startup file to `node_modules/.bin/next start`) → **Restart**.

Test: `https://app.deyalghori.com` → landing/login page loads.

---

## STEP 5 — admin_panel (Next.js) — **DO NOT build on the server**

> ⚠️ The admin panel is an **App-Router** Next.js app. Its `next build` **crashes
> on this shared host** (thread cap → `pthread_create: Resource temporarily
> unavailable` / SIGABRT). So the **prebuilt `.next` is committed to git** and
> already came down with `git clone`/`git pull`. On the server you only
> `npm install` + `npm start` — **never `npm run build` here.**

cPanel → **Setup Node.js App** → **Create Application**:
- Application root: `clickerpro/admin_panel`
- Application URL: `admin.deyalghori.com`
```bash
cd ~/clickerpro/admin_panel
source ~/nodevenv/clickerpro/admin_panel/*/bin/activate
npm install --omit=dev               # deps only; .next is already built (committed)
echo "API_PROXY_TARGET=https://api.deyalghori.com" > .env.production
# NO build step — the committed .next is used as-is.
# Sanity check the prebuilt output is present:
test -f .next/BUILD_ID && echo "prebuilt .next OK" || echo "MISSING .next — re-pull the repo"
```
Start command: `npm start` (it runs on port 3001 per package.json; cPanel maps
the subdomain to it). **Restart**.

Test: `https://admin.deyalghori.com` → admin login. Sign in with
`admin@clickerpro.app` / `Admin@1234`.

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

# web_app — rebuild on server (or upload a local .next if it OOMs):
cd ~/clickerpro/web_app && source ~/nodevenv/clickerpro/web_app/*/bin/activate
npm install && RAYON_NUM_THREADS=1 NODE_OPTIONS=--max-old-space-size=1536 npm run build

# admin_panel — DO NOT build; the new .next came from git pull. Just:
cd ~/clickerpro/admin_panel && source ~/nodevenv/clickerpro/admin_panel/*/bin/activate
npm install --omit=dev

# Finally: Restart BOTH apps from the "Setup Node.js App" page.
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
