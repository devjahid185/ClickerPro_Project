# ClickerPro — Project Structure

Folder tree and the purpose of each major directory, derived from the actual
codebase.

```
ClickerPro_Project/
├── laravel_backend/      Laravel 12 REST API (the single backend)
├── clicker_pro/          Flutter mobile app (Android + iOS)
├── web_app/              Next.js web app (Pages Router)
├── admin_panel/          Next.js admin panel (App Router)
├── keystores/            Android signing material (gitignored)
└── *.md                  Documentation, audit & fix reports, STATUS
```

---

## laravel_backend/ — Backend API

```
laravel_backend/
├── app/
│   ├── Enums/                     PHP-backed enums (roles, statuses, etc.)
│   ├── Http/
│   │   ├── Controllers/Api/       42 API controllers (one per resource)
│   │   │   └── Concerns/          shared controller traits (e.g. ChecksEventOwnership)
│   │   ├── Middleware/            AdminMiddleware, ManagerMiddleware, SecurityHeaders
│   │   ├── Requests/              Form Request validation (BookingRequest, ClientRequest)
│   │   └── Resources/             API serializers (UserResource, BookingResource)
│   ├── Models/                    34 Eloquent models
│   ├── Policies/                  authorization policies (EventPolicy, InvoicePolicy)
│   ├── Providers/                 service providers
│   └── Services/                  business-logic services (PaymentService)
├── config/                        framework config (cors, sanctum, database…)
├── database/
│   ├── migrations/                40 migrations (schema source of truth)
│   └── seeders/                   DatabaseSeeder, SampleDataSeeder
├── routes/
│   └── api.php                    all 166 API routes
└── .env(.example/.production.example)  environment config
```

**Layering:** Route → Middleware (auth/admin/throttle/headers) →
FormRequest (validation) → Controller → Service (multi-step logic) →
Eloquent Model → Resource (response shape).

---

## clicker_pro/ — Flutter mobile app

```
clicker_pro/
├── lib/
│   ├── main.dart                  entry point
│   ├── app.dart                   MaterialApp + theme/router wiring
│   ├── core/                      cross-cutting infrastructure
│   │   ├── network/               ApiClient (HTTP + bearer token + retry)
│   │   ├── storage/               SecureStore (token), KV store
│   │   ├── db/                    Drift local database
│   │   ├── sync/                  offline outbox / sync worker
│   │   ├── navigation/            router + route names
│   │   ├── providers.dart         central Riverpod DI wiring
│   │   ├── role/ booking_status/ format/ logging/ pdf/ env/
│   ├── features/                  37 feature modules (see MODULE_GUIDE.md)
│   │   └── <feature>/
│   │       ├── domain/            entities + abstract repositories
│   │       ├── data/              repository implementations + API classes
│   │       ├── application/       Riverpod providers / controllers
│   │       └── presentation/      screens + widgets
│   ├── shared/                    shared widgets/states (empty, loader)
│   ├── theme/                     AppColors (dark), AppColorsLight, AppTheme(s)
│   ├── l10n/                      localization
│   └── models/ services/ widgets/ screens/   legacy/shared helpers
├── android/                       Android project (signing via key.properties)
└── ios/                           iOS project
```

**Architecture:** Clean Architecture per feature
(`domain / data / application / presentation`) with Riverpod for state/DI.
Most features have all four layers; a few auxiliary ones are partial (see
`ARCHITECTURE_AUDIT.md`).

---

## web_app/ — Web app (Next.js Pages Router)

```
web_app/
├── src/
│   ├── pages/                     routes (Pages Router)
│   │   ├── index.tsx              public landing page
│   │   ├── login.tsx register.tsx
│   │   ├── book/[token].tsx       public booking page
│   │   └── app/                   authenticated app (26 pages)
│   │       ├── index.tsx          dashboard
│   │       ├── bookings/ clients/ invoices/  (+ [id] detail pages)
│   │       ├── finance/ payments/ expenses/ petty-cash/ freelancer/
│   │       ├── calendar/ packages/ waitlist/ gear/ rent/ team/ chat/
│   │       ├── reports/ search/ reminders/ followup/ support/ help/
│   │       └── announcements/ activity/ notifications/ settings/ onboarding/
│   ├── components/                shared components (AppShell)
│   ├── hooks/                     typed data hooks (useApiResource)
│   ├── lib/                       api client (api.ts) + formatters (format.ts)
│   ├── types/                     shared API TypeScript types (api.ts)
│   └── styles/                    globals.css (design system), landing.module.css
└── next.config.mjs                /api/* proxy + security headers + CSP
```

---

## admin_panel/ — Admin panel (Next.js App Router)

```
admin_panel/
├── app/                           routes (App Router) — 17 pages
│   ├── page.tsx                   admin dashboard
│   ├── login/
│   ├── users/ (+ [id]/) studios/ bookings/ payments/ finance/
│   ├── analytics/ broadcasts/ support/ coupons/ audit/
│   ├── security/ settings/ subscription/ files/
│   └── globals.css
├── components/                    Shell, BarChart
├── lib/                           api.ts (client) + types.ts
└── next.config.js                 /api/* proxy + security headers + CSP
```

---

## Key cross-component facts

- **One backend, three clients.** Mobile, web, and admin all call the same
  Laravel API under `/api/*`.
- **Auth:** Sanctum bearer tokens. Web/admin store the token in `localStorage`
  and proxy `/api/*` to the backend; Flutter stores it in secure storage.
- **Response envelope:** the API wraps payloads as `{ "data": ... }`
  (login/register return `{ "data": { "token", "user" } }`).
- **`keystores/`** holds Android signing keys and is gitignored — never commit.
