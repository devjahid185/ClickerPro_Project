# ClickerPro — Cleanup Audit (Phase 2)

> Date: 2026-06-08
> Auditor: Senior Engineer (read-only scan — **no code changed**)
> Scope: clicker_pro, laravel_backend, web_app, admin_panel
> Method: linters (`flutter analyze`, `tsc --noUnusedLocals --noUnusedParameters`), route cross-reference, grep duplication scan.

Classification:
- 🟢 **Safe To Remove** — dead/unused, removing has no runtime effect.
- 🟡 **Needs Review** — likely improvement, but touches shared/working code; confirm first.
- 🔴 **High Risk** — large/structural; only with a deliberate plan.

---

## Executive Summary

| Category | Finding | Class |
|----------|---------|-------|
| Dead folder | `backend/` (231 MB old Node API) | 🟡 Needs Review |
| Empty dirs | `data/`, `projects/` (0 bytes, unrelated) | 🟢 Safe |
| Tooling dir | `.jetro/` (AI tooling, not project) | 🟢 Safe (gitignore) |
| Boilerplate | `web_app/src/pages/api/hello.ts` (Next default) | 🟢 Safe |
| Unused locals | 6 web + 1 admin (tsc-detected) | 🟢 Safe |
| Duplicate helpers | `tk()` ×17, `fmtDate` ×22, `statusBadge` ×11 (web pages) | 🟡 Needs Review |
| Duplicate client | `api.ts` web vs admin (near-identical) | 🟡 Needs Review |
| Type safety | 215 `any` in web pages | 🟡 Needs Review |
| Naming | `followup` (singular) vs other plural routes | 🟡 Needs Review |
| Unused Flutter | 0 (clean) | ✅ none |
| SQLite legacy | 0 `strftime` (PostgreSQL-clean) | ✅ none |
| Unused controllers/models | 0 (all routed) | ✅ none |

**Headline:** No dangerous dead code. The real wins are (1) deleting the obvious dead/empty dirs, (2) removing tsc-flagged unused locals, (3) consolidating the copy-pasted web helpers into one `lib/format.ts`.

---

## 🟢 Safe To Remove

### S1. Empty/unrelated top-level dirs
- `data/` — 0 bytes (datasets/lists/stocks — not ClickerPro)
- `projects/` — 0 bytes, empty
- **Impact:** none. Pure clutter.

### S2. Next.js default boilerplate
- `web_app/src/pages/api/hello.ts` — the starter API route, unused. (Also the source of one tsc unused-param warning.)
- **Impact:** none; no caller.

### S3. tsc-flagged unused locals (7 total) — delete the declarations only
| File | Symbol |
|------|--------|
| `web_app/src/pages/api/hello.ts:9` | `req` param (whole file is S2 anyway) |
| `web_app/src/pages/app/bookings/index.tsx:29` | `router` (declared, never used) |
| `web_app/src/pages/app/calendar/index.tsx:18` | `fmtDate` (defined, unused) |
| `web_app/src/pages/app/clients/[id].tsx:76` | `getName` (defined, unused) |
| `web_app/src/pages/app/finance/index.tsx:20` | `showPayReqModal`, `setShowPayReqModal` (dead state pair) |
| `admin_panel/app/users/page.tsx:24` | `roleBadge` (defined, unused) |
- **Impact:** none — these are provably unreferenced. Removing is mechanical and safe.

### S4. `.jetro/` (if not already)
- AI tooling cache (`cache.duckdb`, connectors) — not part of the app. Confirm it's gitignored; otherwise add it. Do not ship.

---

## 🟡 Needs Review

### R1. Dead Node backend — `backend/` (231 MB)
- Fully replaced by `laravel_backend/`. Already marked with `backend/DEPRECATED.md`.
- **Why "review" not "safe":** It's large and was the original source of truth; some may want it on an archive branch before deletion. Recommend: confirm Laravel is production-final, then `git rm -r backend/` (or move to an `archive/` branch).

### R2. Duplicated web helpers → consolidate into `web_app/src/lib/format.ts`
- `const tk = …` currency formatter copy-pasted in **17** pages.
- `fmtDate` / inline `toLocaleDateString('en-BD', …)` in **22** pages.
- `statusBadge` + `STATUS_COLORS` map in **11** pages.
- **Recommendation:** create one `lib/format.ts` (`tk`, `fmtDate`) and `components/StatusBadge.tsx`; import everywhere. **Behavior-neutral** but touches many files — hence review/approval. High maintainability win.

### R3. Duplicated API client — `web_app/src/lib/api.ts` vs `admin_panel/lib/api.ts`
- Near-identical (token storage, fetch wrapper, login, 401 handling). Two copies drift (already happened with the `{data}` login fix applied twice).
- **Recommendation:** extract a shared module. True sharing needs a small monorepo/workspace setup → larger change; flagged for a deliberate decision.

### R4. `any` overuse in web pages (215 occurrences)
- Pages use `any` for API data instead of the new `src/types/api.ts` interfaces (added in Phase 2 Batch 4).
- **Recommendation:** incrementally type pages using the existing interfaces. Low risk per page, but 215 spots — do it gradually, not in one sweep.

### R5. Naming inconsistency — `followup`
- Route folder is `web_app/src/pages/app/followup` (singular) while siblings are plural (`bookings`, `clients`, `payments`, `reminders`). Mobile uses `followup` too.
- **Why "review":** renaming a route changes its URL (`/app/followup` → `/app/followups`) and the AppShell nav link — small but a user-facing path change. Decide if consistency is worth the URL change.

### R6. Two legacy markers (TODO/FIXME)
- Only 2 across backend+web+admin. Trivial — review and resolve or document.

---

## 🔴 High Risk (do not touch without a plan)

### H1. `backend/` deletion as a git operation
- Removing 231 MB + its git history footprint is irreversible on the branch. Treat as a deliberate, reviewed commit (see R1). Listed High-Risk because of size + "it was the original backend."

### H2. Mass `any` → typed refactor in one pass
- Touching 215 sites at once risks subtle runtime behavior changes (the defensive `any` access tolerates shape variance). Must be incremental + tested per page.

### H3. Route/folder renames (`followup` → `followups`)
- Changes public URLs and nav; if any bookmarks/links/deep-links exist, they break. Needs a redirect plan if done.

---

## ✅ Already Clean (no action)
- Flutter: **0** unused imports/vars/dead code (`flutter analyze lib` clean).
- Backend: **0** unused controllers/models (all routed); **0** SQLite `strftime` legacy (PostgreSQL-clean); no stub controllers.
- Keystores: gitignored (verified in architecture audit).

---

## Proposed cleanup sequence (await approval)

- **Step 1 (🟢 Safe):** delete `data/`, `projects/`, `web_app/src/pages/api/hello.ts`; remove the 7 unused locals. Zero behavior risk.
- **Step 2 (🟡 R2):** consolidate `tk`/`fmtDate`/`statusBadge` into shared `lib/format.ts` + `StatusBadge` component; update imports. Behavior-neutral, verify build.
- **Step 3 (🟡 R1):** remove dead `backend/` (your call on archive-first).
- **Step 4 (🟡 R4, gradual):** type web pages from `src/types/api.ts`, a few per pass.
- **Defer (🔴):** R5 rename, anything URL-affecting.

**No files will be removed or changed until you approve specific steps.**
Recommended start: **Step 1 + Step 2** (highest value, lowest risk).
