# Theme Fix — Phase 1 (T3 + T4)

> Date: 2026-06-08
> Approved scope: T3 (Settings theme labels) + T4 (status colors → CSS vars).
> No redesign / layout / business-logic / API changes.
> (Not touched: T1, T2 Flutter; T5 admin mobile; T6 Flutter Color literals.)

---

## T3 — Correct Settings theme labels

**Root cause:** the Settings → Theme section showed **"Dark (Active)"** and
**"Light (Coming Soon)"**, but the web app actually runs the **light** theme
(white surfaces, orange accent). The labels were inverted/stale and contradicted
the visible UI.

**Fix applied:** swapped the labels to reflect reality —
**"Light (Active)"** (the active button) and **"Dark (Coming Soon)"** (disabled).
Also changed the active button's hardcoded `background:#111` to
`background: var(--orange)` so it matches the light theme's active-button style
(no longer a dark chip on a light page).

**Labels corrected:**
| Before | After |
|--------|-------|
| `Dark (Active)` (active btn) | `Light (Active)` (active btn) |
| `Light (Coming Soon)` (disabled) | `Dark (Coming Soon)` (disabled) |

No behavior change — both buttons remain non-functional placeholders (theme
switching itself is not in scope); only the text and the active style are
corrected so they no longer mislead.

**Files changed:** `web_app/src/pages/app/settings/index.tsx`

---

## T4 — Standardize status colors to design-system variables

**Root cause:** pages inlined raw status hex (e.g. `#22c55e`, `#ef4444`) that
differ from the central palette in `globals.css` (`--green #16a34a`,
`--red #dc2626`, …). The same semantic state rendered in two shades — e.g. a
status **badge** used `var(--green)` while an inline amount used `#22c55e`.

**Fix applied:** replaced every inlined status hex with the matching CSS variable
so one palette drives both badges and inline text. Mapping used:

| Hardcoded | → CSS var | Semantic |
|-----------|-----------|----------|
| `#22c55e` (28×) | `var(--green)` | received / positive amounts |
| `#ef4444` (24×) | `var(--red)` | due / expenses / negative |
| `#f59e0b` (14×) | `var(--gold)` | day-shift (matches `.pill.day`) |
| `#a855f7` (8×) | `var(--purple)` | night-shift (matches `.pill.night`) |
| `#38bdf8` (7×) | `var(--blue)` | info accents |
| `#14b8a6` (2×) | `var(--teal)` | teal accents |
| `#f97316` (2×) | `var(--orange)` | orange accents |
| `#6b7280` (2×) | `var(--film-muted)` | "Other" category / muted |

**Colors standardized:** 8 distinct hex values across the app pages (finance,
payments, expenses, bookings, bookings/[id], clients/[id], calendar, etc.).
`rgba(...)` tints used for badge/pill backgrounds were left as-is (they already
match the badge CSS and aren't part of the var palette).

**Files changed (web_app/src/pages/app/…):** finance, payments, expenses,
bookings/index, bookings/[id], clients/[id], calendar (and any other page that
inlined a status hex). No structural/JSX changes — only the color token values.

---

## Verification Results

| Check | Result |
|-------|--------|
| `tsc --noEmit` (web) | ✅ 0 errors |
| `npm run build` (web) | ✅ Compiled successfully |
| Malformed `var()` from replacement | ✅ none (no `var(var(...` etc.) |
| Hardcoded status hex remaining in pages | ✅ 0 |
| **Theme UI unchanged** | ✅ same buttons/layout; only label text + active style corrected |
| **Status colors visually consistent** | ✅ inline text now uses the SAME palette as badges (removes the two-shade mismatch) |
| **Contrast regressions** | ✅ none — vars are the established readable palette; active button is orange/white (high contrast) |
| **Responsive regressions** | ✅ none — no layout/markup touched |

> Note: the standardized greens/reds are the design-system shades
> (`--green #16a34a`, `--red #dc2626`) rather than the old inline `#22c55e`/
> `#ef4444`. This is the intended consistency fix — inline text now matches the
> badges. It is a deliberate, palette-aligned change, not a contrast regression.

---

## Result
- ✅ T3: Settings theme labels now reflect actual (Light active); no contradiction
- ✅ T4: all inline status colors standardized to CSS variables (single source of truth)
- ✅ Build + type check pass; no layout/logic/API changes; no contrast/responsive regressions
- ⏹️ Stopped after T3 + T4. T1, T2, T5, T6 not touched — awaiting approval.
