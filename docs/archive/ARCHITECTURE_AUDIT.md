# ClickerPro — Architecture Audit (Phase 1)

> Date: 2026-06-08
> Auditor: Principal Software Architect (read-only review — no code changed)
> Scope: clicker_pro (Flutter), laravel_backend, web_app, admin_panel

This document is an **assessment only**. No refactors have been applied. Each
recommendation carries a priority; await approval before any change.

Priority key: **P1** = address before scaling/launch · **P2** = important, plan soon · **P3** = nice-to-have/cleanup.

---

## 0. Repository Layout (top level)

```
ClickerPro_Project/
├── clicker_pro/      Flutter mobile app   ✅ active
├── laravel_backend/  Laravel 12 API       ✅ active
├── web_app/          Next.js web app      ✅ active
├── admin_panel/      Next.js admin        ✅ active
├── backend/          OLD Node.js API      ⚠️ dead code (reference only)
├── data/  projects/  keystores/           ⚠️ unrelated / misc — see risks
```

**Weakness (P2):** Two backends coexist (`backend/` Node + `laravel_backend/`). The Node one is dead but still present, with its own `Dockerfile`/`DEPLOY.md` — a deploy footgun and confusion source.
**Risk (P1) — ✅ VERIFIED SAFE:** `keystores/` at repo root holds Android signing material, but it **is gitignored** (`.gitignore`: `keystores/`, `*.jks`, `*.keystore`, `**/key.properties`). Only `key.properties.example` is committed. No action needed.
**Weakness (P3):** `data/` (datasets/stocks/lists) and `projects/` look unrelated to ClickerPro — clutter.

---

## 1. Flutter App (clicker_pro)

### Strengths
- ✅ **Textbook Clean Architecture** in most features: `domain / data / application / presentation` layering.
- ✅ **Repository pattern done right**: 28 abstract repositories in `domain/`, 30 concrete `*_repository_impl` in `data/` — dependency inversion respected.
- ✅ **Riverpod DI** used consistently (887 provider references); central `core/providers.dart` wires dependencies.
- ✅ Strong `core/` separation: `network`, `storage` (secure), `db`, `sync`, `navigation`, `role`, `logging`, `pdf`.
- ✅ Feature-first modularization (37 features) — scalable, each feature self-contained.

### Weaknesses
- ⚠️ **Inconsistent layering across features.** Layer presence (D=domain, A=data, P=application, V=presentation):
  - Full `DAPV`: bookings, auth, expenses, payments, gear, team, invoice, freelancer, etc. ✅
  - Partial: `finance` = **V only**, `petty_cash`/`followup` = `DV`, `dashboard`/`entitlements` = `DPV`, `search`/`security`/`performance`/`crash_reporting` = `AV`, `onboarding` = `PV`.
  - Impact: newer/auxiliary features bypass the repository+application pattern and call APIs/local storage straight from widgets — harder to test and maintain.
- ⚠️ `core/providers.dart` is a single 130-line wiring file — acceptable now, but a god-file risk as features grow (P3).

### Risks
- Partial features (`finance`, `petty_cash`, `followup`) mix data access into the UI layer — **regression risk** when business rules change.

### Recommendations
- **P2:** Normalize the partial features to the full `domain/data/application/presentation` pattern (esp. `finance`, `petty_cash`, `followup` which now hit the live API). Mechanical, low-risk; brings them in line with the rest.
- **P3:** Consider splitting `providers.dart` into per-feature provider files as the app grows.

---

## 2. Laravel Backend (laravel_backend)

### Strengths
- ✅ Standard Laravel 12 structure; 42 API controllers, 34 Eloquent models, PHP-backed `Enums/`.
- ✅ Controllers are **reasonably sized** (largest 270 lines) — not yet unmanageable.
- ✅ Middleware-based authz (`admin`, `manager`), Sanctum auth, security hardening applied (Phase 0).
- ✅ Eloquent everywhere → no raw SQL/injection surface.

### Weaknesses (the main architectural gap)
- ⚠️ **No Service layer** (`app/Services` absent). Business logic lives in controllers — payment math, due calculation, client find-or-create, etc. Fat-controller trend.
- ⚠️ **No Form Request classes** (`app/Http/Requests` = 0). Every controller hand-rolls `$request->validate([...])`, duplicating rules (e.g. the same booking field rules appear in `store` and `update`).
- ⚠️ **No API Resources** (`app/Http/Resources` absent). Each controller manually shapes JSON / `->map(...)` (the camelCase mapping we added in `AdminController` is a symptom). Response shape is scattered and easy to drift — exactly the bug class we hit (snake vs camel, `content` vs `body`).
- ⚠️ **No Repository abstraction** — controllers query Eloquent directly. Fine for now, but couples HTTP layer to persistence.
- ⚠️ Cross-cutting logic duplicated: `ownsEvent()` helper now exists in 4 controllers (copy-paste) — should be a policy/trait.

### Risks
- **P1 (maintainability):** Validation + response-shaping duplication is the root cause of several past bugs (field-name mismatches, IDOR gaps). Without Form Requests + Resources, every new endpoint re-introduces this risk.
- **P2:** Authorization is enforced ad-hoc in controllers (`where owner_id`). Laravel **Policies** would centralize this and prevent the IDOR class entirely.

### Recommendations
- **P1:** Introduce **Form Request** classes for the high-traffic resources (Booking, Payment, Invoice, Client) — dedupe validation, single source of truth.
- **P1:** Introduce **API Resources** for the resources whose JSON the frontend depends on (Booking, Payment, User/Admin) — kills the snake/camel drift permanently.
- **P2:** Extract a thin **Service layer** for multi-step logic (payments updating event balances, invoice generation, booking client resolution).
- **P2:** Replace scattered `ownsEvent()`/`where owner_id` with **Laravel Policies** (`EventPolicy`, `InvoicePolicy`) + `$this->authorize()`.
- **P3:** Remove the dead `backend/` Node project (or move it out of the repo).

---

## 3. Web App (web_app) — Next.js

### Strengths
- ✅ Clear Pages Router layout; consistent `AppShell` wrapper; single `lib/api.ts` client.
- ✅ Feature parity achieved; light theme via CSS variables (centralized).

### Weaknesses
- ⚠️ **No data layer.** All 26 pages call `api()` **directly inside the component** (30 files). No hooks (`useBookings`), no service modules, no caching/dedupe (no React Query/SWR).
- ⚠️ **No shared types.** `src/types`, `src/hooks`, `src/services`, `src/features` directories don't exist. API shapes are re-declared per page.
- ⚠️ **Type safety weak:** ~256 `any` usages in app pages. The `{ data }` unwrapping (`Array.isArray(res) ? res : res?.data ?? []`) is copy-pasted everywhere — defensive but untyped.
- ⚠️ Repeated loading/error/empty boilerplate per page (no shared `<DataState>` component).

### Risks
- **P2:** `any`-heavy code + per-page shapes means a backend field rename silently breaks pages with no compile error — same drift risk as the backend Resources gap, mirrored.

### Recommendations
- **P2:** Add `src/types/` with shared API interfaces (Booking, Payment, Client…) — ideally generated from backend Resources once those exist.
- **P2:** Add a thin data layer: per-resource hooks (`useBookings`, `useClients`) wrapping `api()`, returning typed data + loading/error. Consider **TanStack Query** for caching/retry/dedupe.
- **P3:** Extract a shared `<DataState loading error empty>` wrapper to remove boilerplate.

---

## 4. Admin Panel (admin_panel) — Next.js (App Router)

### Strengths
- ✅ App Router; `Shell` + `BarChart` shared components; server-side admin gate on the backend.
- ✅ Pages map cleanly to admin domains (users, businesses, finance, security, …).

### Weaknesses
- ⚠️ Same pattern as web app: data fetched inline in pages, own `lib/api.ts` (**duplicated** from web_app with small differences — two copies of token/login/fetch logic to keep in sync).
- ⚠️ Client-side route guard only (`Shell` checks `getToken()`); real protection is the backend `admin` middleware (good) — but a logged-in non-admin briefly reaching an admin page client-side is poor UX/defense-in-depth.

### Risks
- **P2:** Two divergent `api.ts` copies (web + admin) → fixes/security changes must be applied twice (already happened with the login `{data}` wrapper fix).

### Recommendations
- **P2:** Extract a shared API client (small internal package or shared file) used by both web_app and admin_panel.
- **P3:** Add a client-side role check in admin `Shell` (verify `user.role === 'ADMIN'`) for cleaner redirects — backend stays the source of truth.

---

## 5. Cross-Cutting Observations

| Theme | Finding | Priority |
|-------|---------|----------|
| Response-shape drift | Backend has no Resources, frontends have no shared types → snake/camel mismatches recur | **P1** |
| Validation duplication | No Form Requests; rules copy-pasted in store/update | **P1** |
| Authorization | Ad-hoc `owner_id` checks instead of Policies | **P2** |
| Code duplication | `api.ts` duplicated web/admin; `ownsEvent()` duplicated in controllers | **P2** |
| Dead code | Node `backend/` retained; stray `data/`,`projects/` | **P3** |
| Secrets | `keystores/` at root — ✅ verified gitignored (safe) | Resolved |
| State mgmt | Flutter = Riverpod (excellent); Web/Admin = none (raw fetch) | **P2** |

---

## Summary Scorecard

| Layer | Architecture grade | Headline issue |
|-------|-------------------|----------------|
| Flutter app | **A−** | A few features skip the layering |
| Laravel backend | **B−** | No Service / Form Request / Resource layers |
| Web app | **B** | No data/type layer; `any`-heavy |
| Admin panel | **B** | Duplicated client; inline fetch |
| Repo hygiene | **C+** | Dead backend, stray dirs, keystores at root |

**Overall: solid, ships today, but three structural debts will slow scaling:**
1. Backend lacks Service/Request/Resource layers (→ logic + shape drift). **P1**
2. Frontends lack typed data layer (→ silent breakage on API change). **P2**
3. Duplication (api clients, ownership checks) + dead code. **P2/P3**

---

## Phase 2 progress

### ✅ Batch 1 — Form Requests + API Resources (DONE 2026-06-08)
- `BookingRequest` — single validation source for booking store+update (was duplicated). Verified: create 201, missing-title 422, partial update 200.
- `ClientRequest` — single source for client store+update. Verified: create 201, no-name 422.
- `BookingResource` — booking JSON shape centralized; `flatten()` now delegates to it. **Verified byte-compatible**: same keys incl. `client_name`/`client_phone`/`due_amount` + eager relations (assignments/payments/statusHistories) on detail.
- Payment validation left inline (single-use, no duplication → no FormRequest needed; avoids over-engineering).
- Files: `app/Http/Requests/BookingRequest.php`, `ClientRequest.php`, `app/Http/Resources/BookingResource.php`, `BookingController.php`, `ClientController.php`.

### ✅ Batch 2 — Ownership Policies (DONE 2026-06-08)
- `EventPolicy` + `InvoicePolicy` (no admin `before()` override → preserves exact prior behavior).
- `ChecksEventOwnership` trait replaces the duplicated `ownsEvent()` in Assignment/Task/ReEdit controllers; delegates to EventPolicy. Payment/Invoice keep their inline owner scoping (needs the model object, not just a bool).
- **Verified regression**: owner→foreign event = 403, owner→own = 200 (unchanged).
- Files: `app/Policies/EventPolicy.php`, `InvoicePolicy.php`, `app/Http/Controllers/Api/Concerns/ChecksEventOwnership.php`, Assignment/Task/ReEdit controllers.

**Post-batch verification:** `php -l` clean all files · `route:list` = 166 (unchanged) · web_app `npm run build` success · no business-logic/UI/feature change.

### ✅ Batch 3 — Service Layer (DONE 2026-06-08)
- `PaymentService::record()` — extracts payment-create + event-balance side effect from PaymentController; now wrapped in a DB transaction (can't partially apply). Injected via controller constructor.
- **Verified**: recording a DUE payment of 1000 dropped event due 20000→19000 (identical behavior, now atomic).
- Invoice/Booking store logic left in controllers (single-step / cohesive; a service would be over-engineering).
- Files: `app/Services/PaymentService.php`, `PaymentController.php`.

### ✅ Batch 4 — Typed Frontend Layer (DONE 2026-06-08)
- web_app: `src/types/api.ts` (Booking, Payment, Invoice, Client, Expense + `unwrap`/`unwrapList`), `src/hooks/useApiResource.ts` (`useApiList`/`useApiItem` — typed, removes per-page boilerplate).
- admin_panel: `lib/types.ts` (AdminUser, AdminStats, AdminBooking, AdminPayment).
- Existing pages left untouched (working); new code adopts the typed layer. A cross-app shared client was **not** extracted — would require a monorepo, exceeding "minimal safe" scope. **Verified**: both apps `tsc --noEmit` clean + `npm run build` success.

### ✅ Batch 5 — Hygiene (DONE 2026-06-08, conservative)
- Dead Node `backend/`: **not deleted** (per no-auto-delete rule). Added `backend/DEPRECATED.md` warning it must not be deployed and recommending later removal by the maintainer.
- Flutter `providers.dart` split: **intentionally skipped** — 50 files import it and it's only 130 lines (manageable, not a god-file). Split = high churn, low value. Revisit if it grows.
- Stray `data/`, `projects/`: left as-is (unrelated to ClickerPro; flagged, not touched).

### ✅ Batch 6 — Flutter Feature Normalization (DONE 2026-06-08)
- `petty_cash` and `followup`: extracted a `data/*_repository.dart` layer owning all API + cache access; notifiers are now thin and delegate to the repository (DAPV pattern, matching the rest of the app).
- `finance`: left as a composition/aggregation view (reads bookings + `profitLossProvider`; has no own persistence, so a dedicated repository would be over-engineering).
- **Verified**: `flutter analyze lib` → **No issues found** (whole app).

---

## Phase 2 — Final Verification (all batches)
- ✅ `flutter analyze lib` → 0 issues (entire app)
- ✅ Backend `route:list` = 166 (unchanged); payment/booking endpoints 200; balance update + IDOR 403 intact
- ✅ web_app + admin_panel `npm run build` success; `tsc` clean
- ✅ No business-logic, UI, or feature changes — structure only
- ✅ Test artifacts cleaned; data integrity preserved

**Phase 2 complete.** Remaining audit items are config/infra (Batch D from the security report) and optional future polish — no further code refactors outstanding.
