# ClickerPro — Module Guide

How the codebase is organized into modules across the four components, the
service/repository/state layers, and how modules communicate. All facts are
taken from the actual source.

---

## 1. Backend Modules (laravel_backend)

The backend is organized **by resource**: each domain has a controller (+ model),
wired through `routes/api.php`. There are **42 API controllers** and **34 models**.

### Controllers (one per resource)
Auth, Profile, Booking, Client, Payment, Invoice, Assignment, Expense, Gear,
Rent, Team, Broadcast, Report, Search, Notification, Chat, Support, Faq, ReEdit,
Task, Package, Waitlist, Reminder, DeviceToken, Entitlement, Coupon, AuditLog,
Security, Settings, FeatureFlag, Admin, Legal, Account, File, Delivery,
ExtraTime, PublicBooking, PettyCash, Followup, Freelancer, Contact, CrashReport.

### Backend layers (request lifecycle)
```
routes/api.php
   → Middleware (auth:sanctum · admin · manager · throttle · SecurityHeaders)
      → Form Request (validation)
         → Controller (orchestration + authorization checks)
            → Service (multi-step business logic)
               → Eloquent Model (persistence)
                  → API Resource (response shape)
```

**Service layer** (`app/Services/`):
- `PaymentService` — records a payment and atomically updates the event's
  `advance_paid`/`due_amount` inside a DB transaction.

**Policies** (`app/Policies/`):
- `EventPolicy`, `InvoicePolicy` — ownership rules (used via the
  `ChecksEventOwnership` controller trait and `owner_id` scoping).

**Form Requests** (`app/Http/Requests/`):
- `BookingRequest` (booking store/update), `ClientRequest` (client store/update)
  — single source of validation, required-on-create / nullable-on-update.

**API Resources** (`app/Http/Resources/`):
- `UserResource` (allowlisted user fields for auth/profile),
  `BookingResource` (flattened booking shape incl. `client_name`/`client_phone`).

**Middleware** (`app/Http/Middleware/`):
- `AdminMiddleware` (role === ADMIN), `ManagerMiddleware`
  (MANAGER/OWNER/ADMIN/BOTH), `SecurityHeaders` (nosniff, X-Frame, CSP-style
  headers, HSTS over HTTPS).

---

## 2. Flutter Modules (clicker_pro)

**37 feature modules** under `lib/features/`, each following Clean Architecture.

### Feature list
announcements, audit, auth, backup, bookings, broadcasts, calendar_sync, chat,
crash_reporting, dashboard, data_export, entitlements, expenses, finance,
followup, freelancer, gear, help, home_widget, invoice, legal, notifications,
onboarding, payments, performance, petty_cash, profile, public_booking, push,
reminders, rent, reports, search, security, settings, team, whatsapp.

### Per-feature layering
```
features/<name>/
├── domain/         entities + abstract repository interfaces
├── data/           repository implementations + *_api.dart (HTTP)
├── application/    Riverpod providers / notifiers (state)
└── presentation/   screens + widgets
```

### Repository layer
- **28** abstract repositories (`domain/*_repository.dart`)
- **30** implementations (`data/*_repository_impl.dart`)
- **32** API wrapper classes (`data/*_api.dart`) that call `ApiClient`
- Dependency inversion: presentation/application depend on the domain interface;
  the concrete impl is injected via Riverpod.

> Most features have all four layers. A few auxiliary modules are partial (e.g.
> `finance` is a composition view; see `ARCHITECTURE_AUDIT.md`).

### State management
- **Riverpod** throughout (~166 provider definitions). `core/providers.dart`
  centralizes DI wiring (ApiClient, repositories, stores).

### Core infrastructure (`lib/core/`)
- `network/ApiClient` — HTTP with bearer token + retry
- `storage/SecureStore` — token in Keychain/Keystore (`flutter_secure_storage`)
- `db/` — Drift local SQLite database
- `sync/` — offline outbox / sync worker
- `navigation/` — router + route names
- plus `role/`, `booking_status/`, `format/`, `logging/`, `pdf/`, `env/`

---

## 3. Web App Modules (Flutter Web — `clicker_pro`)

The web app is the **Flutter app built for web** (`flutter build web`), so the
modules are the same as the mobile app — see §4 (the 37 Flutter feature
modules under `clicker_pro/lib/features/`). It replaced the old Next.js
`web_app/`.

- **Public deep link:** `/book/<token>` (public self-booking) resolves via the
  router (`onGenerateInitialRoutes` → `app_router.dart`).
- **Auth, persistence, theming** are shared with mobile (secure_storage JWT,
  Drift→IndexedDB, Sunset Studio / Sunrise Pulse).

---

## 4. Admin Console Modules (Laravel Blade — `laravel_backend`, `/admin`)

Server-rendered Blade; routes in `laravel_backend/routes/web.php`
(`admin.*`), controllers in `app/Http/Controllers/Admin/`, views in
`resources/views/admin/`. **17 screens.**

dashboard, login, users (+detail), studios, bookings, payments, finance,
analytics, broadcasts, support, coupons, audit, security, settings,
subscriptions, files.

> Replaced the old Next.js `admin_panel/`. See DEVELOPER_GUIDE §6.

### Shared layers
- `components/Shell.tsx` (nav + auth gate), `components/BarChart.tsx`
- `lib/api.ts` (client incl. `downloadFile`, role check on login), `lib/types.ts`

---

## 5. Module Communication Flow

```
┌─────────────┐   ┌─────────────┐   ┌─────────────┐
│ Flutter app │   │   Web app   │   │ Admin panel │
│ (ApiClient) │   │ (lib/api.ts)│   │ (lib/api.ts)│
└──────┬──────┘   └──────┬──────┘   └──────┬──────┘
       │ Bearer token     │ /api/* proxy    │ /api/* proxy
       │ (secure storage) │ (localStorage)  │ (localStorage)
       └──────────────────┴────────┬────────┘
                                    ▼
                    ┌───────────────────────────┐
                    │  Laravel API (/api/*)      │
                    │  Sanctum auth · 166 routes │
                    └─────────────┬─────────────┘
                                  ▼
                         PostgreSQL (40 tables)
```

- **All three clients** call the same Laravel API. Web & admin use a Next.js
  `/api/*` rewrite to the backend (default `http://localhost:5000`); Flutter
  calls the API base URL directly with a bearer token from secure storage.
- **Auth:** `POST /api/auth/login` → `{ data: { token, user } }`. Clients store
  the token and send `Authorization: Bearer <token>` on protected routes.
- **Response convention:** every endpoint returns `{ "data": ... }` (lists and
  single resources alike); some include `total`/`totalAmount`.
- **Admin endpoints** live under `/api/admin/*` and require the `admin`
  middleware (role === ADMIN) on top of `auth:sanctum`.
- **Offline (Flutter):** writes can queue in the local Drift DB and sync via the
  outbox worker; some feature lists fall back to a cached copy when offline.
