# Clicker Pro — Developer Guide

> **One-stop map of the whole product.** Where every part lives, how to run it,
> how to build it, and where to look when something breaks.
> App version: **3.8.1+39** · Stack: Flutter · Laravel 11 (PHP 8.2) · Next.js 14.

---

## 1. What Clicker Pro is

A SaaS for photography studios: bookings, clients, packages, team, finance
(payments / expenses / petty-cash / rent), invoicing, reports, chat, public
booking links, push notifications, and an admin dashboard.

## 2. Monorepo layout

```
ClickerPro_Project/
├── clicker_pro/        # Flutter mobile app (Android + iOS)
├── laravel_backend/    # Laravel 11 REST API + database
│                       # web app = Flutter built for web (clicker_pro)
│                       # admin = Laravel Blade (laravel_backend, /admin)
├── keystores/          # release signing keystore (gitignored)
├── tools/              # helper scripts
├── data/               # sample/seed data
└── docs/archive/       # historical audit / fix / changelog reports
```

| Component | Stack | Dev port | Entry point |
|-----------|-------|----------|-------------|
| Mobile | Flutter / Dart 3 | — | `clicker_pro/lib/main.dart` |
| API | Laravel 11 / PHP 8.2 | 5000 | `laravel_backend/routes/api.php` |
| Web app | Flutter Web (`clicker_pro`) | 3000 | `flutter build web` → `build/web/` |
| Admin | Laravel Blade (web routes) | 5000 | `laravel_backend/routes/web.php` (`/admin`) |

Live API base (used by web & admin proxies by default): `https://api.deyalghori.com`.

---

## 3. Mobile app — `clicker_pro/`

```
lib/
├── main.dart                 # bootstrap (DI, Firebase, providers)
├── app.dart                  # root MaterialApp, routing, theme wiring
├── firebase_options.dart     # generated Firebase config
├── core/                     # config, networking, error handling, utils
├── services/                 # API clients, local storage, push, sync
├── providers/                # state management (app-wide providers)
├── models/                   # shared data models
├── shared/                   # reusable widgets
├── theme/                    # orange/black theme, colors, text styles
├── l10n/                     # localization (English + Bengali) — gen-l10n
├── screens/                  # top-level / cross-feature screens
└── features/                 # 37 feature modules (see below)
```

### Feature modules (`lib/features/`)
Each is self-contained (data / presentation). The 37 modules:

`announcements`, `audit`, `auth`, `backup`, `bookings`, `broadcasts`,
`calendar_sync`, `chat`, `crash_reporting`, `dashboard`, `data_export`,
`entitlements`, `expenses`, `finance`, `followup`, `freelancer`, `gear`,
`help`, `home_widget`, `invoice`, `legal`, `notifications`, `onboarding`,
`payments`, `performance`, `petty_cash`, `profile`, `public_booking`, `push`,
`reminders`, `rent`, `reports`, `search`, `security`, `settings`, `team`,
`whatsapp`.

> Convention: feature UI under `features/<name>/presentation/…_screen.dart`,
> feature logic/data under `features/<name>/data/` or `…/domain/`.

### Tests — `clicker_pro/test/`
31 test files / **132 tests** (smoke tests per screen + sync/outbox + boot).
Run: `flutter test`. All currently passing.

### Build & sign
- Signing reads `clicker_pro/android/key.properties` → `keystores/clicker_pro.jks`.
  Falls back to debug keystore if `key.properties` is absent.
- `key.properties` and `*.jks` are **gitignored** (secrets).
```bash
cd clicker_pro
flutter pub get
flutter analyze          # 0 issues
flutter test             # 132 passing
flutter build apk --release           # → build/app/outputs/flutter-apk/app-release.apk
flutter build appbundle --release     # → .aab for Play Store
flutter install                       # install release to a connected device
```

---

## 4. Backend API — `laravel_backend/`

```
app/
├── Http/Controllers/Api/   # 46 API controllers (see list below)
├── Models/                 # 35+ Eloquent models
├── …
routes/
├── api.php                 # 196 API routes
└── web.php
database/
├── migrations/            # schema
└── seeders/               # sample data
config/  bootstrap/  public/  storage/  tests/
```

### API controllers (`app/Http/Controllers/Api/`)
Account, Admin, Announcement, AppVersion, Assignment, Auth, Booking, Broadcast,
Chat, Client, Contact, Coupon, CrashReport, Delivery, DeviceToken, Entitlement,
Expense, ExtraTime, Faq, FeatureFlag, File, Followup, Freelancer, Gear, Invoice,
Notification, Package, Payment, PettyCash, Profile, PublicBooking, ReEdit,
Reminder, Rent, Report, Search, Security, Settings, SocialAuth, Support, Task,
Team, Waitlist. (+ `Concerns/` traits.)

### Models (`app/Models/`)
Announcement, AppSetting, Assignment, AuditLog, BlackoutDate, BlockedIp,
Broadcast, ChatGroup, ChatMessage, Checkin, Client, Coupon, CrashReport,
DeviceToken, Event, Expense, Faq, FeatureFlag, Followup, GearItem, Invoice,
LeaveRequest, LoginActivity, OtpCode, Package, Payment, PettyCashEntry,
ReEditRequest, Reminder, RentRecord, StatusHistory, SupportTicket,
TaskProgress, TeamInviteCode, User, Waitlist.

### Run
```bash
cd laravel_backend
composer install
cp .env.example .env && php artisan key:generate   # first time
php artisan migrate          # add --seed for sample data
php artisan serve --port=5000
```

### Conventions (important)
- **Response wrapper:** every API payload is wrapped as `{ "data": ... }`.
  Clients must read `response.data`.
- **Postgres JSON:** avoid `whereJsonContains` on PG without casting — it has
  silently failed before. Prefer explicit `->>` / cast queries.

---

## 5. Web app — Flutter Web (`clicker_pro`, built for web)

The web app is the **same Flutter codebase** as the mobile app, built for
web (it replaced the old Next.js `web_app/`). All features come from
`clicker_pro/lib/` — no separate web source tree.

- **API base:** `--dart-define=API_BASE_URL=...` (read by
  `lib/core/env/app_config.dart`). Local dev: `http://localhost:5000`.
- **Deep links:** clean URLs via path strategy; `/book/<token>` (public
  booking) resolves through `onGenerateInitialRoutes` → the router.
- **Persistence:** Drift → IndexedDB; JWT → secure_storage (localStorage).

### Build
```bash
cd clicker_pro
flutter build web --release --dart-define=API_BASE_URL=http://localhost:5000
# output: build/web/  — serve with an SPA fallback (see clicker_pro/WEB_DEPLOY.md)
```

---

## 6. Admin console — Laravel Blade (`laravel_backend`, `/admin`)

The admin panel is now a server-rendered Blade app inside `laravel_backend`
(it replaced the old Next.js `admin_panel/`). No separate build or port —
it's served by the Laravel app itself at `/admin`.

```
laravel_backend/
├── routes/web.php                       # /admin/* routes (session auth, ADMIN-only)
├── app/Http/Controllers/Admin/          # Dashboard, Users, Bookings, Finance, …
├── resources/views/admin/               # Blade views (layouts, partials, modules)
└── public/admin-assets/                 # design-system.css + minimal admin.js
```

- **Auth:** web session (CSRF), `admin.web` middleware gates ADMIN role.
- **Data:** read/list endpoints reuse the API `AdminController` (one source of
  truth for console + mobile). Mutations post back to `Admin/*Controller`.
- **No JS framework:** pure CSS design system; tiny vanilla JS only for the
  theme toggle, sidebar, and modals.

### Run
```bash
cd laravel_backend
php artisan serve          # admin at http://localhost:8000/admin/login
# seeded admin: admin@clickerpro.app / Admin@1234
```

---

## 7. Local setup & seed data

- Backend test logins & sample seeder: `php artisan migrate --seed`.
- Ports: API + admin 5000 (admin at `/admin`), web 3000.
- Firebase / Google sign-in needs OAuth client + `WEB_BASE_URL` env — see
  [GOOGLE_SIGNIN_SETUP.md](GOOGLE_SIGNIN_SETUP.md).

---

## 8. Deploy

- **Shared hosting (current):** [SHARED_HOSTING_DEPLOY.md](SHARED_HOSTING_DEPLOY.md)
  — the authoritative step-by-step for cPanel/Passenger.
- **General / VPS:** [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md).
- **Store listing copy/assets:** [STORE_LISTING.md](STORE_LISTING.md).

Deploy-ready build outputs:
| Component | Artifact |
|-----------|----------|
| Mobile | `clicker_pro/build/app/outputs/flutter-apk/app-release.apk` (+ `.aab` for Play Store) |
| Web app | `clicker_pro/build/web/` (static; serve with SPA fallback) |
| Admin | served by Laravel at `/admin` (no separate build) |
| Backend | upload `laravel_backend/` minus `.env`; run migrate on server |

---

## 9. Reference docs (still maintained)

| Topic | File |
|-------|------|
| Agent/AI context | [CLAUDE.md](CLAUDE.md) |
| API endpoints | [API_DOCUMENTATION.md](API_DOCUMENTATION.md) |
| DB schema | [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md) |
| Module guide | [MODULE_GUIDE.md](MODULE_GUIDE.md) |
| Testing | [TESTING_GUIDE.md](TESTING_GUIDE.md) |
| Troubleshooting | [TROUBLESHOOTING.md](TROUBLESHOOTING.md) |
| Google sign-in setup | [GOOGLE_SIGNIN_SETUP.md](GOOGLE_SIGNIN_SETUP.md) |
| Shared-host deploy | [SHARED_HOSTING_DEPLOY.md](SHARED_HOSTING_DEPLOY.md) |

Historical audits, fix reports and changelogs are archived under
[`docs/archive/`](docs/archive/) (kept for traceability; not part of daily dev).

---

## 10. Gotchas (learned the hard way)

1. **`{data}` wrapper** — unwrap `response.data` on every client call.
2. **PG `whereJsonContains`** — cast/`->>'key'` instead; it can silently no-op.
3. **Shared host Next build** — single worker (`cpus:1`, `workerThreads:false`),
   `RAYON_NUM_THREADS=1`, and never cap Node heap to 512 MB.
4. **Admin on shared host** — ship prebuilt `.next`, never `standalone`, never
   build on the server.
5. **HTML caching** — HTML shell is `no-store`; only hashed `_next/static`
   assets are immutable. Prevents stale-bundle login failures after redeploy.
6. **API target under Passenger** — `NODE_ENV` isn't reliably `production`, so
   the proxy defaults to the LIVE API explicitly (not `localhost:5000`).
