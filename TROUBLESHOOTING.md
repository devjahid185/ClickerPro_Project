# ClickerPro — Troubleshooting

Common errors, debug steps, and recovery procedures. The entries below are the
**actual issues encountered in this project** (and how they were resolved), plus
the standard failure modes for the stack.

---

## Backend (Laravel)

### "could not find driver (Connection: pgsql)"
**Cause:** the PostgreSQL PHP extension is disabled.
**Fix:** enable `pdo_pgsql` (and `pgsql`) in `php.ini`, then restart.
```bash
php -m | grep -i pgsql      # should list pdo_pgsql and pgsql
```
On XAMPP/Windows, uncomment `extension=pdo_pgsql` and `extension=pgsql` in
`C:\xampp\php\php.ini`.

### Backend returns HTTP 000 / connection refused
**Cause:** `php artisan serve` isn't running (it stops when its terminal closes).
**Debug:** `curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/`
**Fix:** restart `cd laravel_backend && php artisan serve --port=5000`.

### Login/API returns 302 redirect instead of JSON 422
**Cause:** the request lacks `Accept: application/json`, so Laravel redirects
(web guard) instead of returning a JSON validation error.
**Fix:** always send `Accept: application/json` (and `Content-Type:
application/json`) from API clients. The web/admin `api.ts` and Flutter
`ApiClient` already do this.

### Validation error: "The selected role is invalid" on register
**Expected behavior (security fix C1):** registration only accepts
`OWNER`/`FREELANCER`/`BOTH`. Sending `ADMIN`/`MANAGER` returns 422 by design.

### Config/route changes not taking effect
**Cause:** cached config/routes.
**Fix:**
```bash
php artisan config:clear && php artisan route:clear && php artisan cache:clear
```
(In production you instead re-run `config:cache`/`route:cache` after a deploy.)

### Migration fails / schema out of date
```bash
php artisan migrate:status        # see what's applied
php artisan migrate               # apply pending
php artisan migrate:rollback      # undo last batch (additive index/attempts migrations are reversible)
```

### 403 "Forbidden" on a resource that should be visible
**Cause (by design):** resources are owner-scoped. Payments/assignments/tasks/
re-edits/invoices return **403** if the `event`/record isn't owned by the
current user (IDOR protection). Verify you're authenticated as the owner.

### 429 "Too Many Requests"
**Cause:** rate limiting — auth routes `6/min`, other public `30/min`,
protected `120/min`. Also, OTP verify returns **429** after 5 wrong attempts.
**Fix:** wait for the window to reset, or request a fresh OTP.

---

## Database (PostgreSQL)

### `psql` not found at expected path (Windows)
The bundled tools live under the installed major version, e.g.
`C:\Program Files\PostgreSQL\18\bin\psql.exe` (the project dev used **18**, not
17). Use the path matching your installed version.

### Connection refused / auth failed
Check `.env` `DB_HOST/DB_PORT/DB_DATABASE/DB_USERNAME/DB_PASSWORD` against the
running server; confirm the database exists and the user has access.

### Recovery: restore from backup
```bash
gunzip -c /backups/clickerpro_YYYY-MM-DD.sql.gz | psql "$DATABASE_URL"
```

---

## Web App & Admin Panel (Next.js)

### MODULE_NOT_FOUND / every page returns 500 in dev
**Cause (observed in this project):** installing then removing a package with
`npm install --no-save … && rm -rf node_modules/<pkg>` corrupts `node_modules`
and the `.next` cache.
**Fix:**
```bash
rm -rf .next
npm install            # reinstall cleanly
# restart: npm run dev
```
**Prevention:** never `rm -rf` a package out of `node_modules`; use
`npm uninstall <pkg>`. (This is why browser-automation tools aren't kept in the
web project — verify with `npm run build` + `curl` instead.)

### Dev server starts on the wrong port (3002/3003 instead of 3000/3001)
**Cause:** the intended port is already in use by a previous `next dev`.
**Debug (Windows):** `netstat -ano | findstr :3000`
**Fix:** stop the stale process (`Stop-Process -Id <pid> -Force`) and restart, or
just use the port Next reports.

### Login "succeeds" but app says no token / stays logged out
**Cause:** the API wraps responses as `{ data: { token, user } }`. Code reading
`json.token` directly will miss it.
**Fix:** read `json.data?.token` (the shipped `lib/api.ts` already does
`json.data ?? json`). All API responses use the `{ data: ... }` envelope.

### Page shows stale data / API field appears `undefined`
**Cause:** snake_case vs camelCase mismatch, or an un-typed `any` masking a
renamed field. The backend returns snake_case; some UI reads camelCase aliases.
**Debug:** inspect the Network response shape; check `src/types/api.ts`.

### Build fails / type errors
```bash
npx tsc --noEmit       # find the exact type error (strict mode is on)
npm run build          # full build (catches runtime/route issues)
```

---

## Mobile App (Flutter)

### App can't reach the API
**Cause:** wrong API base URL, or (Android emulator) using `localhost` instead of
the host bridge.
**Fix:** point the app's API base at the reachable host; on Android emulator the
host is `10.0.2.2`, not `localhost`.

### Token/session lost between launches
Tokens are stored in `flutter_secure_storage` (Keychain/Keystore). If lost,
re-login; check device keystore availability.

### Build/signing failures (Android)
Signing uses `android/key.properties` (gitignored). Ensure the keystore file and
`key.properties` exist locally; they are **never** committed (`keystores/`,
`*.jks`, `key.properties` are gitignored).

### Analyzer issues
```bash
flutter analyze            # should report "No issues found!"
flutter pub get            # if dependency errors
```

---

## Cross-cutting debug checklist

1. **Is the backend up?** `curl http://localhost:5000/` → expect 200.
2. **Are you authenticated?** Missing/expired bearer token → 401 (token TTL is
   7 days). Re-login to get a fresh token.
3. **Right headers?** `Accept: application/json` + `Content-Type: application/json`.
4. **Right port?** web 3000, admin 3001, API 5000 (watch for stale processes).
5. **Cleared caches?** Laravel `config:clear/route:clear`; Next `.next` rebuild.
6. **Owner scope?** A 403 usually means the resource belongs to another user.
7. **Rate limited?** 429 → wait for the per-minute window.

---

## Recovery Procedures

- **Backend wedged after config edits:** `php artisan optimize:clear` (clears
  config/route/cache/view), then restart.
- **Next app broken after dependency churn:** `rm -rf .next && npm install`, restart.
- **Bad migration:** `php artisan migrate:rollback` (the additive index/attempts
  migrations have working `down()` methods).
- **Lost DB data:** restore from the latest `pg_dump` backup (see
  DEPLOYMENT_GUIDE §5).
- **Accidentally removed code:** the deprecated Node backend is recoverable from
  the `archive/node-backend` git tag (`git checkout archive/node-backend -- backend/`).
