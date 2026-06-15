# Cleanup — Step 1 + Step 2 Changelog

> Date: 2026-06-08
> Scope approved: Step 1 (safe removals) + Step 2 (consolidate identical helpers)
> Constraints honored: **no business-logic, UI, API, route, or database changes.**
> Verification: `tsc --noEmit` clean (web + admin), `npm run build` success (both), Flutter untouched.

---

## Files Removed

| Path | Type | Reason |
|------|------|--------|
| `data/` (incl. `datasets/`, `lists/`, `stocks/`) | empty dir tree | 0 bytes, unrelated to ClickerPro; pure clutter. Not git-tracked. |
| `projects/` | empty dir | 0 bytes, empty. Not git-tracked. |
| `web_app/src/pages/api/` | dir (became empty) | Only contained `hello.ts`; removed after it. |
| `web_app/src/pages/api/hello.ts` | file | Next.js starter boilerplate. Confirmed **fully unused** (no import/caller; only unrelated "Say hello!" UI string elsewhere). Not git-tracked. |

No other files were deleted. Dead `backend/` (Node) was **NOT** removed (out of approved scope; remains marked by `backend/DEPRECATED.md`).

---

## Files Changed — Step 1 (unused locals removed)

Only the unused declaration (and its now-orphaned import) was removed in each. No logic touched.

| File | Removed | Reason |
|------|---------|--------|
| `web_app/src/pages/app/bookings/index.tsx` | `const router = useRouter()` + `useRouter` import | `router` declared but never used (no `router.*` calls). |
| `web_app/src/pages/app/calendar/index.tsx` | `const fmtDate = …` | Defined but never referenced in the file. |
| `web_app/src/pages/app/clients/[id].tsx` | `const getName = …` | Defined but never referenced (`getDate` kept — still used). |
| `web_app/src/pages/app/finance/index.tsx` | `showPayReqModal` / `setShowPayReqModal` state pair | Dead state — the payment-request form renders inline; this toggle was never read in render. Form + `payReqForm` left intact (still used). |
| `admin_panel/app/users/page.tsx` | `function roleBadge()` | Defined but never called (roles render via dropdown, not a badge). |

**Verification:** `tsc --noEmit --noUnusedLocals --noUnusedParameters` → **0 unused** remaining in both apps.

---

## Files Changed — Step 2 (consolidate identical `tk()` helper)

### Added
| File | Reason |
|------|--------|
| `web_app/src/lib/format.ts` | New shared module exporting `tk(n)` — the Taka currency formatter that was copy-pasted **identically** in 17 pages. Byte-for-byte same output: `'৳' + Number(n).toLocaleString('en-BD')`. |

### Updated (17 files — same mechanical change each)
Removed the inline `const tk = …` line; added `import { tk } from '@/lib/format';`.

```
web_app/src/pages/app/index.tsx
web_app/src/pages/app/bookings/index.tsx
web_app/src/pages/app/bookings/[id].tsx
web_app/src/pages/app/clients/[id].tsx
web_app/src/pages/app/expenses/index.tsx
web_app/src/pages/app/finance/index.tsx
web_app/src/pages/app/freelancer/index.tsx
web_app/src/pages/app/gear/index.tsx
web_app/src/pages/app/invoices/index.tsx
web_app/src/pages/app/invoices/[id].tsx
web_app/src/pages/app/packages/index.tsx
web_app/src/pages/app/payments/index.tsx
web_app/src/pages/app/petty-cash/index.tsx
web_app/src/pages/app/rent/index.tsx
web_app/src/pages/app/reports/index.tsx
web_app/src/pages/app/search/index.tsx
web_app/src/pages/app/team/index.tsx
```
**Reason:** remove 17× duplication of an identical helper. Output unchanged → no UI change.

---

## Intentionally NOT Done (would have violated constraints)

| Candidate | Why skipped |
|-----------|-------------|
| Consolidate `fmtDate` (22 pages) | **3 different variants exist** (`month: 'short'` vs `'long'`, with/without `'—'` fallback). Merging would change some dates' display → **UI change**. Left as-is. |
| Consolidate `statusBadge` (11 pages) | Would require editing JSX in 11 pages; subtle map variants risk a UI change; low value vs risk. Left as-is. |
| Shared `api.ts` (web/admin) | Requires monorepo/workspace setup — structural, out of "safe" scope. |
| Delete `backend/` | Out of approved scope (no auto-delete of large/legacy code). |

---

## Result
- ✅ web_app: `tsc` clean, build success, 0 unused locals
- ✅ admin_panel: `tsc` clean, build success, 0 unused locals
- ✅ clicker_pro (Flutter): untouched
- ✅ No business-logic / UI / API / route / DB changes
- ✅ Net: 4 dead paths removed, 6 unused symbols removed, 17× helper duplication eliminated
