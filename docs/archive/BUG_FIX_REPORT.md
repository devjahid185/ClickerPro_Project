# Bug Fix Report — Bug 1 (Booking Editor Crash) + Bug 2 (Light-Mode White-on-White)

> Date: 2026-06-08
> Scope: minimal changes only; existing behavior / API contracts / UI preserved;
> no refactoring outside the affected areas. Not committed / merged / pushed.

---

## BUG 1 — Booking editor crash ("Could not open the booking editor")

### 1. Root cause
`bookings.clientId` carries a **foreign-key reference** to `clients_table`
(`bookings_table.dart`: `text().references(ClientsTable, #id).nullable()`).
Some older booking rows hold a `clientId` that has **no matching client row** —
e.g. the placeholder `'pending'`, or ids dropped during an incomplete v4→v5
sync/migration. Loading/saving such a row trips the FK reference and the booking
editor's draft future throws, which the screen renders as the generic
"Could not open the booking editor." There was:
- no migration step to repair the already-corrupted rows,
- no validation when writing a booking to Drift (so bad ids kept getting cached),
- no graceful handling of an unresolvable `clientId` in the edit screen.

### 2. Applied fix (three layers, all minimal)
- **a) `app_database.dart` — data repair via migration.** Bumped
  `schemaVersion` 5 → 6 and added a `v5 → v6` step that nulls out any dangling
  `clientId`:
  ```sql
  UPDATE bookings_table SET client_id = NULL
  WHERE client_id IS NOT NULL
    AND client_id NOT IN (SELECT id FROM clients_table)
  ```
  Done as its own version so devices **already on v5** (the corrupted state) also
  get repaired, not just fresh upgrades. The booking keeps its
  `clientName`/`clientPhone`, so no client info is lost.
- **b) `booking_repository_impl.dart` — prevent new corruption.** Added a private
  `_validClientId(id)` that returns the id only if it resolves to a real client
  row, else `null`. Made `_bookingToCompanion` `async` and route `clientId`
  through it. Updated the 4 call sites to `await` the companion
  (`refreshFromRemote`, `save` ×2, `_upsertEnvelope`). Same write behavior,
  except a non-existent client id is stored as `NULL` instead of a dangling value.
- **c) `booking_edit_screen.dart` — graceful display.** `_clientLabel` now takes
  the `BookingDraft` and, when `clientId` is null/empty **or resolves to no
  client**, falls back to the booking's own `clientName · clientPhone` (or
  nothing) instead of rendering the raw id (e.g. "pending"). No crash, no raw id.

### 3. Files changed
- `clicker_pro/lib/core/db/app_database.dart` (schemaVersion 5→6 + v6 cleanup)
- `clicker_pro/lib/features/bookings/data/booking_repository_impl.dart`
  (`_validClientId`, async `_bookingToCompanion`, 4 awaited call sites)
- `clicker_pro/lib/features/bookings/presentation/booking_edit_screen.dart`
  (`_clientLabel` made draft-aware + fallback; 1 call site updated)

### 4. Verification performed
- `flutter analyze` on the 3 files → **No issues found**.
- Logic trace: the migration repairs existing bad rows; the repo guard stops new
  bad rows; the screen no longer shows/needs the bad id. The crash path
  (FK on a dangling `clientId`) is closed at write time and repaired at rest.

### 5. Regression checks
- The FK column definition, table schema, and API contract are **unchanged** —
  only data values are sanitized and a new migration step added.
- `clientName`/`clientPhone` preserved → bookings still show client info.
- Write paths keep identical semantics for **valid** client ids (the guard is a
  no-op when the id is real).
- Full-project `flutter analyze` clean (see bottom).

---

## BUG 2 — Light-mode white-on-white text

### 1. Root cause
The app's theme (`AppTheme.orangeHorizon()`) is `Brightness.light` with a light
`scaffoldBackgroundColor` (`AppColors.appBg = #F8FAFC`), and `AppColors.surface`
is `#FFFFFF`. A handful of widgets hardcode **`Colors.white` as the text/content
color while sitting directly on a light surface** (not on a colored chip/button),
so the text renders white-on-near-white and is invisible. (Most `Colors.white`
uses are fine — they sit on solid teal/orange/red backgrounds — so only the
genuine surface-text cases were touched.)

### 2. Applied fix (only the truly-invisible cases)
`booking_edit_screen.dart`:
- **Save button flash text**: `Color.lerp(Colors.white, teal, flash)` →
  `Color.lerp(AppColors.film, teal, flash)` (dark→teal, both readable on light).
- **Package label** (on a surface): `Colors.white` → `AppColors.film`.
- **Selected segment label** (light teal-tint bg, icon was already teal):
  `Colors.white` → `AppColors.teal` (now consistent with its icon, readable).

`dashboard_screen.dart`:
- **Info-card stat number** (card bg is `AppColors.surface` = white):
  `isCancel ? red : Colors.white` → `isCancel ? red : AppColors.film`.

**Left unchanged (verified correct):** `Colors.white` on solid teal "today" date
cell, on teal selected shift chip, on red/orange filled buttons, switch thumb on
gold track, `onPrimary`, and the teal-cell event dot — all sit on colored
backgrounds and remain readable.

### 3. Files changed
- `clicker_pro/lib/features/bookings/presentation/booking_edit_screen.dart` (3 colors)
- `clicker_pro/lib/features/dashboard/presentation/dashboard_screen.dart` (1 color)

### 4. Verification performed
- `flutter analyze` on both files → **No issues found**.
- Each changed line was checked against its container's background: every fix
  was white text on a light surface; every untouched `Colors.white` is on a
  colored background.

### 5. Regression checks
- No layout, widget structure, or behavior changed — only text-color values on
  light surfaces.
- Colored-background white text (buttons/chips/today-cell) untouched → those
  surfaces look identical.
- Full-project `flutter analyze` clean.

---

## Overall verification
```
flutter analyze lib   →  No issues found! (0 issues, full project)
```
- Bug 1: 3 files, Bug 2: 2 files (1 file — booking_edit — touched by both).
- No commit / merge / push performed.

## Files changed (combined)
| File | Bug | Change |
|------|-----|--------|
| `core/db/app_database.dart` | 1 | schemaVersion 5→6 + v6 dangling-clientId cleanup |
| `features/bookings/data/booking_repository_impl.dart` | 1 | `_validClientId` + async companion + 4 awaited calls |
| `features/bookings/presentation/booking_edit_screen.dart` | 1 + 2 | clientId fallback + 3 white-on-light color fixes |
| `features/dashboard/presentation/dashboard_screen.dart` | 2 | info-card number color fix |

---

## Result
- ✅ Bug 1 fixed at all three layers (repair + prevent + display); crash path closed.
- ✅ Bug 2: 4 genuine white-on-white cases fixed; colored-bg white text preserved.
- ✅ Full `flutter analyze` clean — no regressions introduced.
- ⏹️ Stopped after both bugs verified. **Not committed.** Awaiting approval.

> Note on full device verification: these were validated by static analysis +
> careful per-line context review. A device run (build + drive the booking editor
> and toggle light mode) is the ideal final confirmation; it can be done next if
> you want a live screenshot pass.
