# ClickerPro — Performance Audit (Phase 6)

> Date: 2026-06-08
> Mode: **read-only** — no code changed, nothing optimized.
> Scope: laravel_backend, database, clicker_pro (Flutter), web_app, admin_panel.

Severity: 🔴 High · 🟡 Medium · 🟢 Low

---

## Executive Summary

| # | Finding | Area | Severity |
|---|---------|------|----------|
| P1 | N+1 query in admin analytics `topStudios` (`User::find` in a loop) | Backend | 🟡 Medium |
| P2 | Missing indexes on `events.date`, `events.status` (booking filters) | Database | 🟡 Medium |
| P3 | No caching on admin `stats`/`analytics` (recomputed every request) | Backend | 🟡 Medium |
| P4 | CSV export & other heavy ops run synchronously (no queue) | Backend | 🟡 Medium |
| P5 | `whereJsonContains(manager_permissions->ownerId)` — unindexable JSON scan | DB/Backend | 🟢 Low (scales poorly) |
| P6 | Payments monthly grouping scans `created_at` (no index) | Database | 🟢 Low |
| P7 | Flutter: some `ref.watch` on whole providers instead of `.select` | Flutter | 🟢 Low |
| P8 | Flutter: 2× `Image.network` uncached (no CachedNetworkImage) | Flutter | 🟢 Low |
| P9 | Admin tables render up to 100–200 rows without virtualization | Admin | 🟢 Low |

**Overall: healthy.** The web/admin bundles are small, list rendering is lazy,
most queries are eager-loaded, and dashboards fetch in parallel. No 🔴 High
issues. The Medium items are scaling concerns (indexes, caching, queue, one
N+1) that matter as data grows, not current breakage.

---

## 🟡 Medium

### P1 — N+1 in admin analytics `topStudios`
- **Where:** `AdminController::analytics()` — after grouping events by `owner_id`,
  it `->map()`s and calls `User::find($row->owner_id)` per row.
- **Impact:** 5 top studios → 5 extra queries each analytics load. Small now;
  grows with the result set and request frequency.
- **Expected improvement:** 1 batched `whereIn` (or eager join) instead of N
  finds → fewer round-trips, faster admin dashboard.
- **Risk:** Low — pure query refactor, same output shape.
- **Files:** `app/Http/Controllers/Api/AdminController.php` (analytics)

### P2 — Missing indexes on `events.date` and `events.status`
- **Where:** `events` table. FK columns (`owner_id`, `client_id`, `package_id`)
  are auto-indexed via `constrained()`, but `date` and `status` are not.
- **Impact:** Booking list filters (date range, status chips, calendar month
  queries) do a filtered scan within an owner's rows. Fine at small scale;
  slows as bookings grow per owner.
- **Expected improvement:** composite/single index on `(owner_id, date)` and
  `(owner_id, status)` → index-assisted filtering.
- **Risk:** Low — additive migration (index only); no data/logic change.
- **Files:** new migration for `events` indexes.

### P3 — No caching on admin stats/analytics
- **Where:** `AdminController::stats()` / `analytics()` — every call recomputes
  counts and aggregations (users by role, bookings, revenue sum, monthly
  groupings) with no cache.
- **Impact:** Each admin dashboard load runs ~8–10 aggregate queries; repeated
  refreshes recompute identical data.
- **Expected improvement:** short TTL cache (e.g. 60–300s via `Cache::remember`)
  → near-instant repeat loads, lower DB load.
- **Risk:** Low–Medium — must pick a TTL that's acceptably fresh for admins.
- **Files:** `AdminController.php` (stats, analytics)

### P4 — Synchronous heavy operations (no queue)
- **Where:** no `app/Jobs`; `AdminController::exportCsv` builds the full CSV in
  the request; OTP/contact "delivery" would also be inline once wired.
- **Impact:** A large CSV export holds the HTTP request open and can time out /
  block a worker. Email/SMS sending (when added) would add request latency.
- **Expected improvement:** move exports + notifications to a queued Job →
  responsive requests, no timeouts.
- **Risk:** Medium — introduces async flow (needs a queue worker in deploy).
- **Files:** `AdminController.php` (exportCsv), future notification senders.

---

## 🟢 Low

### P5 — `whereJsonContains(manager_permissions->ownerId)` JSON scan
- `TeamController::members()` filters users by a JSON path. JSON containment
  can't use a normal index → full users-table scan. Negligible for small user
  counts; poor at scale.
- **Improvement:** a dedicated `owner_id` column on team members (normalized)
  would be indexable. **Risk:** schema change — defer unless team feature grows.

### P6 — Payments monthly grouping scans `created_at`
- `ReportController` / admin analytics group payments by `TO_CHAR(created_at,…)`.
  `created_at` is unindexed. Aggregate over a growing payments table will slow.
- **Improvement:** index `payments(created_at)` (or `(event_id, created_at)`).
  **Risk:** Low — additive index.

### P7 — Flutter `ref.watch` granularity
- 124 `ref.watch` vs only 9 `.select(...)`. Some widgets rebuild on any change
  to a watched provider even when only one field matters.
- **Improvement:** use `ref.watch(provider.select((s) => s.field))` on hot
  widgets to cut rebuilds. **Risk:** Low; targeted, per-widget.

### P8 — Uncached network images (2 sites)
- 2× `Image.network` (avatar/logo) with no caching → re-download on each build.
- **Improvement:** `cached_network_image`. **Risk:** Low; adds a dependency.

### P9 — Admin tables without virtualization
- Users/bookings/payments render up to 100–200 rows directly (backend already
  caps the result). DOM cost is modest at these caps.
- **Improvement:** add windowing (react-window) only if caps are raised.
  **Risk:** Low; not needed at current limits.

---

## Verified Healthy (no action) ✅

| Area | Observation |
|------|-------------|
| Backend eager loading | Booking/Payment/Invoice/Followup use `with()` (no N+1 except P1) |
| Reports aggregation | Uses `whereIn` + SQL `SUM`/`GROUP BY` (not per-row loops) |
| DB foreign keys | `constrained()` auto-indexes owner_id/client_id/event_id/etc. |
| Auth lookups | `email` and `public_booking_token` are unique-indexed |
| Web bundle | ~90.6 kB shared First Load; pages ~4–6 kB — small |
| Web data fetching | Dashboard + 8 pages use `Promise.all` (parallel, not sequential) |
| Web/Flutter lists | 23 `ListView.builder` (lazy), 0 eager `ListView`; web uses shimmer states |
| Flutter rebuilds | 3127 `const` widgets — well optimized |
| Admin dashboard | stats + analytics fired in parallel |

---

## Recommended Optimization Order (await approval — nothing changed)

1. **P2 + P6 (indexes)** — additive migrations, zero risk, immediate query wins.
2. **P3 (cache stats/analytics)** — big admin-dashboard win, small change.
3. **P1 (fix analytics N+1)** — one-query refactor.
4. **P4 (queue CSV/notifications)** — needs a queue worker; do with deploy setup.
5. **P7/P8 (Flutter select + cached images)** — minor polish.
6. **P5/P9** — only if team/admin data scales up.

No 🔴 High remediation required. These are scale-readiness improvements.
