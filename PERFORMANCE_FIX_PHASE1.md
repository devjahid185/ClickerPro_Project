# Performance Fix — Phase 1 (P1 + P2 + P3 + P6)

> Date: 2026-06-08
> Approved scope: P1 (N+1), P2/P6 (indexes), P3 (caching). Additive only.
> No business-logic / UI / API-contract / route changes. Output values unchanged.
> (Not touched: P4 queue, P5 JSON, P7 Flutter select, P8 image cache, P9 virtualization.)

---

## P1 — Remove N+1 in admin analytics `topStudios`

**Root cause:** the top-5 studios block ran `User::find($row->owner_id)` inside a
`->map()` — one query per row (5 extra queries).

**Fix:** batch-load all needed owners in a single `whereIn('id', …)` query,
`keyBy('id')`, then resolve names from the in-memory map. Output identical.

**Queries reduced:** 5 per-row `find()` → **1 batched query**.

**Files:** `app/Http/Controllers/Api/AdminController.php` (analytics)

---

## P3 — Cache admin statistics & analytics

**Root cause:** `stats()` and `analytics()` recomputed ~8–10 aggregate queries on
every request, even on rapid dashboard refreshes.

**Fix:** wrapped each method's computation in `Cache::remember(key, 60s, …)`:
- key `admin.stats`, key `admin.analytics`
- TTL **60 seconds** (`DASHBOARD_TTL` const) — fresh enough for an operator
  dashboard; recomputes at most once/minute.
- Response shape and values are unchanged (the cached payload is the same array
  previously returned).

**Cache store:** the app's configured cache (database driver per `.env`); no new
infra required.

**Queries reduced (measured):** analytics **cold = 7 queries**, **warm (cached)
= 1** (single cache read). `stats` similarly drops its ~9 aggregates to a cache
read on warm calls.

**Files:** `app/Http/Controllers/Api/AdminController.php` (stats, analytics)

---

## P2 — Indexes on `events.date` and `events.status`

**Root cause:** booking-list filters (date range, status) and calendar/month
queries filtered on un-indexed columns (FKs were already auto-indexed).

**Fix (additive migration):** composite indexes matching the real query shape
(always scoped by owner):
- `events (owner_id, date)` → `events_owner_date_idx`
- `events (owner_id, status)` → `events_owner_status_idx`

## P6 — Index on `payments.created_at`

**Fix (same migration):** `payments (created_at)` → `payments_created_at_idx`
to assist the monthly revenue grouping/aggregation.

**Migration:** `database/migrations/2026_06_08_102629_add_performance_indexes.php`
- `up()` adds the three indexes; `down()` drops them — **fully reversible**.
- **No columns or data changed** (index-only, non-schema-breaking).
- Verified present in PostgreSQL:
  `events_owner_date_idx`, `events_owner_status_idx`, `payments_created_at_idx`.

> Note: on the current tiny dataset (7 events) the planner still chooses a seq
> scan — expected; the indexes take effect as row counts grow (scale-readiness).

---

## Indexes Added (summary)

| Table | Index | Columns | Helps |
|-------|-------|---------|-------|
| events | events_owner_date_idx | (owner_id, date) | date-range filters, calendar |
| events | events_owner_status_idx | (owner_id, status) | status filter chips |
| payments | payments_created_at_idx | (created_at) | monthly revenue grouping |

---

## Cache Strategy

| Endpoint | Key | TTL | Effect |
|----------|-----|-----|--------|
| `/api/admin/stats` | `admin.stats` | 60s | ~9 aggregates → cache read on warm |
| `/api/admin/analytics` | `admin.analytics` | 60s | 7 queries → 1 on warm |

Trade-off: dashboard figures can be up to 60s stale — acceptable for an admin
overview; no correctness impact (values identical within the window).

---

## Verification Results

| Check | Result |
|-------|--------|
| `php -l` (controller + migration) | ✅ No syntax errors |
| Migration applied + reversible | ✅ 3 indexes created; `down()` drops them |
| Indexes exist in DB | ✅ confirmed via pg_indexes |
| admin `tsc --noEmit` | ✅ 0 errors |
| web `tsc --noEmit` | ✅ 0 errors |
| **Stats values unchanged** | ✅ totalUsers/bookings/revenue etc. identical |
| **Analytics values unchanged** | ✅ topStudios names + statusBreakdown identical |
| **Queries reduced** | ✅ analytics 7→1 (warm); topStudios 5 finds→1 batch |
| No API/route/UI/logic change | ✅ same shapes & values |
| Test artifacts | ✅ none created; cache cleared post-test |

---

## Performance Impact Estimate

- **Admin dashboard (repeat loads within 60s):** ~16–17 queries → ~2 (one cache
  read for stats + one for analytics). Large reduction in DB round-trips on the
  most-refreshed admin screen.
- **Admin analytics (cold):** removed the N+1 (5→1 owner query) — ~4 fewer
  queries per cold computation.
- **Booking/payment queries at scale:** index-assisted filtering instead of full
  scans once tables grow (no measurable change on the current tiny dataset, by
  design — this is scale-readiness).

---

## Result
- ✅ P1, P2, P3, P6 applied — additive, reversible, behavior-neutral
- ✅ Output values verified unchanged; query counts measurably reduced
- ✅ Builds + type checks pass; no regressions
- ⏹️ Stopped after P1+P2+P3+P6. P4/P5/P7/P8/P9 not touched — awaiting approval.
