# ClickerPro — Bug & Stability Audit (Phase 3)

> Date: 2026-06-08
> Auditor: Senior QA / Engineer (read-only review — **no fixes applied**)
> Scope: clicker_pro (Flutter), web_app, admin_panel, laravel_backend
> Method: static scan (controllers/dispose, mounted guards, try/catch coverage,
> useEffect cleanup, transactions, null-safety) + `flutter analyze` + `tsc`.

Severity:
- 🔴 **Critical** — can crash / corrupt data / lose money in normal use.
- 🟠 **High** — crash or wrong behavior in a reachable edge case.
- 🟡 **Medium** — leak / degradation over time; not immediately user-visible.
- 🟢 **Low** — minor / cosmetic / defensive.

---

## Executive Summary

| # | Issue | Area | Severity |
|---|-------|------|----------|
| 1 | `TextEditingController` created in `ConsumerWidget` build/dialog, never disposed | Flutter waitlist + petty_cash | 🟡 Medium |
| 2 | `TextEditingController` in profile dialog helper, not disposed | Flutter profile | 🟡 Medium |
| 3 | Landing `resize` listener not removed on effect cleanup | web_app landing | 🟢 Low |
| 4 | Some pages have more `await api` than `catch` blocks (possible unhandled rejection) | web_app (7 pages) | 🟢 Low |
| 5 | Admin route protection is client-side only (backend enforces, but UX/defense-in-depth) | admin_panel | 🟢 Low |
| 6 | `deleteId` etc. accept any id; no confirm on some destructive actions (varies) | web_app | 🟢 Low |

**No Critical or High issues found.** The codebase is notably disciplined:
- ✅ Flutter `flutter analyze lib` → **0 issues**; **0** force-unwrap (`!`), **0** `late` fields.
- ✅ **144 `mounted` guards** across 49 files → async-after-dispose well handled.
- ✅ Web `JSON.parse` calls guarded; chat poll `setInterval` has `clearInterval` cleanup.
- ✅ Backend: money/balance multi-step write wrapped in `DB::transaction` (PaymentService); remaining `increment`/`decrement` are single atomic ops (broadcast/coupon counters) — safe.
- ✅ `find()`-then-null-check pattern present (48 `404`/Not-found returns).
- ✅ AppShell + admin Shell redirect to `/login` when unauthenticated.

---

## Detailed Findings

### 🟡 Medium

#### M1. Undisposed `TextEditingController` in stateless widgets — waitlist & petty_cash
- `features/bookings/presentation/waitlist_screen.dart:94-96` — `nameCtrl`, `phoneCtrl`, `noteCtrl` created inside a `ConsumerWidget` (a dialog/sheet builder).
- `features/petty_cash/presentation/petty_cash_screen.dart:232-233` — `titleCtrl`, `amountCtrl` likewise.
- **Why it matters:** `ConsumerWidget` has no `dispose()`. Each time the dialog/sheet opens, new controllers are allocated and never freed → memory grows with repeated opens. Not a crash, but a slow leak.
- **Impact:** Medium — accumulates over a long session of repeated add-dialogs.
- **Fix direction (later):** convert the dialog body to a small `StatefulWidget` that disposes its controllers, or use `useTextEditingController` (hooks) / dispose in the sheet's close callback.

#### M2. Undisposed controller in profile dialog helper
- `features/profile/presentation/profile_screen.dart:1186` — `TextEditingController` created in a helper/dialog; the screen is `ConsumerStatefulWidget` but this controller isn't tracked/disposed.
- **Impact:** Medium — same leak class as M1, lower frequency.
- **Fix direction:** dispose after the dialog resolves, or hoist into the State and dispose in `dispose()`.

> Note: `lens_form_fields.dart` was flagged by the scan but is a **false positive** — it receives the controller via `final TextEditingController controller` (owned by the parent), so it must NOT dispose it. ✅ correct as-is.

### 🟢 Low

#### L1. Landing `resize` listener not cleaned up
- `web_app/src/pages/index.tsx:~203` — inside the GSAP `useEffect`, `window.addEventListener('resize', onResize)` is added but the cleanup only sets `destroyed = true`; it doesn't `removeEventListener('resize', …)`.
- **Impact:** Low — landing page mounts once; a stale listener could linger across fast-refresh/HMR in dev, negligible in prod.
- **Fix direction:** return `() => window.removeEventListener('resize', onResize)` from the effect.

#### L2. `await api` count exceeds `catch` count on 7 web pages
- e.g. `bookings/[id].tsx` (12 awaits / 9 catches), bookings/clients/expenses/gear/packages/petty-cash index pages.
- **Why "Low":** multiple awaits often share one `try`, so this is a heuristic, not a confirmed bug. But some tab-load or mutation paths may lack a `catch`, surfacing as an unhandled rejection (console error, no UI feedback) rather than a crash.
- **Fix direction:** audit each flagged file; ensure every `await api` is inside a try with user-facing error state. (Low priority — no crash, just silent failures.)

#### L3. Admin route protection is client-side
- `admin_panel/components/Shell.tsx` checks `getToken()` and redirects; the real gate is the backend `admin` middleware (✅ enforced server-side). A logged-in non-admin could briefly render an admin shell before API calls 403.
- **Impact:** Low — no data exposure (backend blocks); only a UX/defense-in-depth gap.
- **Fix direction:** add a client-side `user.role === 'ADMIN'` check for a clean redirect.

#### L4. Destructive actions — confirm coverage varies
- Some delete buttons open a confirm modal (good); a few call delete via `alert`/inline. Not a bug, but inconsistent UX. (Informational.)

---

## Categories With No Issues Found ✅

| Category | Result |
|----------|--------|
| Crash risks | None found (Flutter analyze clean, no force-unwrap) |
| Null safety (Flutter) | 0 `!` assertions, 0 `late`, analyze clean |
| Async-after-dispose | 144 `mounted` guards; no analyzer warnings |
| Stream/subscription leaks | `outbox_worker` & `session_controller` have `.cancel()` (4 & 2) |
| Navigation | AppShell + admin Shell redirect unauthenticated → /login |
| State management | Riverpod (Flutter) disciplined; web useState scoped |
| Lifecycle | StatefulWidgets dispose controllers (except M1/M2) |
| Error handling (backend) | 48 not-found/404 guards; transaction on money path |
| Data integrity | PaymentService balance update is transactional |

---

## Recommended Fix Order (await approval — nothing changed yet)

1. **M1 + M2** (Medium) — dispose the dialog `TextEditingController`s. Small, isolated, no behavior change. Highest value (real leaks).
2. **L1** (Low) — add `resize` cleanup. One line.
3. **L2** (Low) — sweep the 7 pages, wrap any uncaught `await api`. Per-file, low risk.
4. **L3** (Low) — admin client-side role check. Optional UX hardening.

**No Critical/High remediation needed.** Overall stability grade: **A−** — clean async/null discipline; the only real defects are a few dialog-controller leaks.
