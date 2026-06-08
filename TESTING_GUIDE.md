# ClickerPro — Testing Guide

How to test each component, based on the test infrastructure actually present in
the repo.

| Component | Automated tests present | How to verify |
|-----------|------------------------|---------------|
| Flutter (clicker_pro) | ✅ 31 test files (`test/`) | `flutter test`, manual on device |
| Laravel (laravel_backend) | ⚠️ phpunit set up; only example tests | `php artisan test`; live API checks |
| Web app (web_app) | ❌ no test suite | `tsc` + `npm run build` + manual/curl |
| Admin panel (admin_panel) | ❌ no test suite | `tsc` + `npm run build` + manual/curl |

> The current project verification approach (used throughout the audit/fix
> phases) is: **typecheck + build + live API checks with a bearer token**, plus
> Flutter's own widget/unit tests.

---

## 1. Flutter — Android & iOS

### Automated tests
The app has **31 test files** under `clicker_pro/test/` — widget "smoke" tests,
DAO tests, property tests, and serialization round-trips. Examples:
`bookings/booking_list_screen_smoke_test.dart`,
`core/db/daos/bookings_dao_test.dart`,
`core/booking_status/booking_status_machine_property_test.dart`,
`bookings/round_trip_serialization_test.dart`.

```bash
cd clicker_pro
flutter test                      # run all tests
flutter test test/bookings/       # a folder
flutter test test/core/db/daos/bookings_dao_test.dart   # a single file
flutter analyze                   # static analysis — expect "No issues found!"
```

### Android (device/emulator)
```bash
flutter devices                   # list attached devices/emulators
flutter run -d <deviceId>         # debug run
flutter build apk --debug         # build a debug APK
flutter build appbundle           # release bundle (signed via key.properties)
```
- Emulator note: the API host is `10.0.2.2` (not `localhost`).

### iOS
```bash
flutter run -d <iosDeviceId>      # requires macOS + Xcode
flutter build ios                 # then archive/sign in Xcode for the App Store
```

### Manual smoke flow (any platform)
Login → Dashboard → create a booking → record a payment (due drops) →
generate an invoice → check Finance/Reports → Settings (2FA, password change).

---

## 2. Backend (Laravel) — API testing

### PHPUnit
`phpunit.xml` is configured with `tests/Feature` and `tests/Unit` (currently the
default `ExampleTest`s — feature coverage is minimal).
```bash
cd laravel_backend
php artisan test                  # or: vendor/bin/phpunit
```
**Recommended:** add Feature tests for auth, bookings, payments, and the
ownership/IDOR rules (these were verified manually during the security phases —
see the *_FIX_*.md reports — and should be codified as tests).

### Live API testing (the approach used in this project)
Get a token, then exercise endpoints:
```bash
# login
TOKEN=$(curl -s -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" -H "Accept: application/json" \
  -d '{"email":"owner@test.com","password":"Test@1234"}' \
  | python -c "import sys,json;print(json.load(sys.stdin)['data']['token'])")

# authenticated GET
curl -s -H "Authorization: Bearer $TOKEN" -H "Accept: application/json" \
  http://localhost:5000/api/bookings

# create
curl -s -X POST -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" -H "Accept: application/json" \
  -d '{"title":"Test","date":"2026-09-01","client_name":"X"}' \
  http://localhost:5000/api/bookings
```
Key checks to cover (all behave this way in the code):
- **Auth:** login 200 + token; bad creds 401; disabled account 403.
- **Validation:** missing required field → 422 with `errors`.
- **Ownership/IDOR:** accessing another user's event → 403.
- **Rate limit:** >6 auth calls/min → 429.
- **OTP:** 5 wrong codes → 429; response never contains the OTP.
- **Admin gate:** `/api/admin/*` with a non-admin token → 403.
- Use Postman/Insomnia by importing the routes from `API_DOCUMENTATION.md`.

---

## 3. Web App testing

No JS test runner is configured. Verify with:
```bash
cd web_app
npx tsc --noEmit        # strict type check (catches shape/type errors)
npm run build           # full production build (catches route/runtime issues)
npm run lint            # next lint
npm run dev             # manual testing at http://localhost:3000
```
**Manual smoke (authenticated app):** login → dashboard loads KPIs → Bookings
(Day/Night split, filters, create/edit) → Clients → Finance → Invoices →
Settings (theme labels, profile, password). Confirm images/avatars render and
API calls return data (Network tab shows `{ data: ... }`).

> Do **not** add browser-automation deps into this project ad-hoc — installing
> and removing them has corrupted `node_modules`/`.next` (see TROUBLESHOOTING).
> Prefer `build` + `curl` for verification.

---

## 4. Admin Panel testing

Same toolchain as the web app:
```bash
cd admin_panel
npx tsc --noEmit
npm run build
npm run dev             # http://localhost:3001
```
**Manual smoke:** login as admin (`admin@clickerpro.app` / `Admin@1234`) →
Dashboard (stats + analytics) → Users (role/plan/suspend) → Businesses →
Bookings/Payments (all studios) → Broadcasts/Support/Coupons → Security
(login activity, blocked IPs, 2FA) → Settings/Feature flags.
Verify a non-admin token is rejected (the backend `admin` middleware returns 403).

---

## 5. API integration across clients

- All three clients hit the same Laravel API; test via the Next.js proxy too:
  `curl http://localhost:3000/api/auth/login …` should reach the backend.
- Confirm the response envelope `{ data: ... }` everywhere.
- Confirm bearer-token flow end-to-end (login → store token → authenticated call).

---

## Verification commands quick-reference

```bash
# Flutter
cd clicker_pro && flutter analyze && flutter test

# Backend
cd laravel_backend && php artisan test
php artisan route:list | grep -c "api/"        # expect 166

# Web / Admin
cd web_app     && npx tsc --noEmit && npm run build
cd admin_panel && npx tsc --noEmit && npm run build
```

---

## Notes / Gaps (accurate state)

- **Flutter** has real automated coverage (31 files); keep `flutter test` green.
- **Laravel** PHPUnit is wired but feature tests are essentially empty — the
  security/perf behaviors were verified with live API calls and should be
  back-filled as automated Feature tests.
- **Web/Admin** have no unit/e2e tests; verification relies on strict
  TypeScript + production build + manual/curl checks.
