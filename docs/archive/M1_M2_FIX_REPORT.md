# Bug Fix Report — M1 & M2 (Controller Leaks)

> Date: 2026-06-08
> Approved scope: **M1 + M2 only** — dispose `TextEditingController`s created
> in dialogs/bottom-sheets that were never freed.
> Constraints honored: no UI, business-logic, API, or navigation changes.

---

## Summary

Three dialog/bottom-sheet `TextEditingController` leaks fixed by disposing the
controllers when the sheet/dialog closes. No visual or behavioral change — the
controllers live exactly as long as the sheet is open; they're only freed
afterward (previously they were never freed, leaking on every open).

---

## Files Changed

| File | Leak Fixed | How |
|------|-----------|-----|
| `clicker_pro/lib/features/bookings/presentation/waitlist_screen.dart` | `nameCtrl`, `phoneCtrl`, `noteCtrl` (created in `_showAddSheet`, a `ConsumerWidget` bottom-sheet) leaked on every open | Chained `.whenComplete()` on `showModalBottomSheet(...)` to dispose all 3 controllers when the sheet closes |
| `clicker_pro/lib/features/petty_cash/presentation/petty_cash_screen.dart` | `titleCtrl`, `amountCtrl` (created in `_showAddSheet`) leaked on every open | Chained `.whenComplete()` on `showModalBottomSheet(...)` to dispose both controllers when the sheet closes |
| `clicker_pro/lib/features/profile/presentation/profile_screen.dart` | `controller` (created in `_showAddGearDialog`, an `await showDialog`) leaked on every open | Added `controller.dispose()` at the end of the method, after the dialog result has been fully consumed |

---

## Leak Details (what was wrong)

- **M1 — waitlist & petty_cash:** Both `_showAddSheet` methods allocate
  `TextEditingController`s in a `ConsumerWidget` (which has no `dispose()`
  lifecycle hook) and pass them to a `showModalBottomSheet`. Each time the
  user opened the "Add" sheet, fresh controllers were allocated and the old
  ones were never released → memory grows with repeated opens.
  **Fix:** `showModalBottomSheet(...)` returns a `Future` that completes when
  the sheet is dismissed; `.whenComplete(() => …dispose())` frees them at the
  correct moment (after the sheet — and its `TextField`s — are gone).

- **M2 — profile:** `_showAddGearDialog` allocates a controller, `await`s
  `showDialog`, then reads `controller.text` to create the gear item. The
  controller was never disposed. **Fix:** `controller.dispose()` is called at
  the very end of the method — after the dialog has closed and its text has
  been consumed — so disposal is safe and complete.

> Not touched (correctly excluded): `lens_form_fields.dart` — it receives its
> controller from the parent (`final TextEditingController controller`) and must
> NOT dispose it. Left as-is.

---

## Why There's No Behavior Change

- Controllers are disposed **only after** the sheet/dialog is closed and all
  their values have already been read/used. No code reads them afterward.
- `.whenComplete()` runs on both normal dismiss (tap outside, back) and
  programmatic `Navigator.pop()` — covering every close path.
- No widget tree, layout, text, validation, navigation, or API call changed.

---

## Verification Results

| Check | Result |
|-------|--------|
| `flutter analyze` (3 changed features) | ✅ No issues found |
| `flutter analyze lib` (whole app) | ✅ No issues found |
| New warnings introduced | ✅ None |
| UI / behavior change | ✅ None (disposal happens post-close) |
| Scope adherence | ✅ Only the 3 approved leak sites + nothing else |

---

## Result
- ✅ 3 controller-leak sites fixed (5 controllers total now disposed)
- ✅ Flutter analyzer clean, zero new warnings
- ✅ No UI / logic / API / navigation changes
- ⏹️ **Stopped here. Low-severity items (L1–L4) NOT touched — awaiting approval.**
