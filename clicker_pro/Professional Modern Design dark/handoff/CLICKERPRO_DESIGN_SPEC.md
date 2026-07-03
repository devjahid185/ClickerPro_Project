# ClickerPro — Design System & Build Spec

> Handoff document for Claude Code. Everything needed to rebuild the ClickerPro UI
> (mobile app → web app → admin panel) with a consistent, pixel-accurate look.
> **All tokens below are extracted from the finished, hand-tuned mockup** — do not
> substitute or "improve" colors, sizes, or fonts. Match them exactly.

ClickerPro is a **photography-studio management app** (bookings, events, packages,
finance, team, freelancer payouts). Owner + team roles. Warm, editorial, professional
— a light "paper" theme with a single confident orange accent.

---

## 1. Design Tokens

### Color

| Token | Hex | Use |
|---|---|---|
| **Primary** | `#E2620E` | Brand orange — buttons, active states, key figures, logo |
| **Primary Light** | `#F89A2B` | Gradient partner / lighter orange, logo highlight blade |
| **Primary Dark** | `#B84E0A` | Gradient end (avatar, pressed) |
| **Primary Tint** | `#FBEBDE` | Soft orange fill behind icons/chips |
| **Background** | `#FBFAF7` | App canvas (warm off-white) |
| **Surface** | `#FFFFFF` | Cards, inputs, sheets |
| **Surface Alt** | `#F4F3EF` | Phone body / muted panels |
| **Text Primary** | `#1A1A18` | Headings, primary text |
| **Text Secondary** | `#3A3A36` | Body labels |
| **Text Muted** | `#9A988F` | Meta, placeholders, captions |
| **Border** | `rgba(0,0,0,0.06)` | Hairline card & input borders |
| **Success** | `#2F8F6B` | Paid / delivered / positive |
| **Warning / Gold** | `#C99A2E` | Pending, tentative dots |
| **Danger** | `#C0392B` | Alerts, overdue, notification dot |
| **Info Teal** | `#00898B` | "Upcoming" stat card |
| **Info Blue** | `#3541AF` | "Total" stat card |
| **Accent Violet** | `#6D5BD0` | Secondary calendar marker |

> Stat/accent cards (`#00898B`, `#3541AF`) are intentional multi-color data cards on the
> Dashboard — keep them as-is; they are not part of the general button palette.

### Typography

- **Body / UI:** `'Hanken Grotesk'`, weights **400 / 500 / 600 / 700 / 800**
- **Mono / labels:** `'IBM Plex Mono'`, weights **400 / 500 / 600** — used for ALL-CAPS
  micro-labels with `letter-spacing: 0.1em–0.22em`
- **Icons:** `Material Symbols Rounded` (opsz 20–48, grade 0, fill 0–1)

```html
<link href="https://fonts.googleapis.com/css2?family=Hanken+Grotesk:wght@400;500;600;700;800&family=IBM+Plex+Mono:wght@400;500;600&display=swap" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Rounded:opsz,wght,FILL,GRAD@20..48,400,0..1,0&display=block" rel="stylesheet">
```

Type scale (mobile, px): hero figure `58`, section number `30`, screen title `20`,
card title `14–15`, body `13`, meta `11–12`, micro-label `9–10`.
Headings use tight tracking `letter-spacing: -0.03em to -0.04em` and weight `800`.

### Radius

| Element | Radius |
|---|---|
| Hero / feature card | `22px` |
| **Card (standard)** | `18px` |
| Small card / quick-action | `16px` |
| Input / search field | `14px` |
| Calendar day / chip | `13px` |
| Icon tile | `12px` |
| Phone frame | `36px` |
| Pill / full round | `50%` / `999px` |

### Spacing & Elevation

- Screen gutter: `18px`. Card padding: `14–18px`. Section gap: `20–22px`.
- Card border: `1px solid rgba(0,0,0,0.06)` (most cards are border, not shadow).
- Primary shadow (raised orange): `0 8px 16px -6px rgba(226,98,14,0.55)`.
- Phone shadow: `0 44px 100px -32px rgba(20,20,18,0.40), 0 0 0 1px rgba(0,0,0,0.04)`.

---

## 2. Logo

Pure **orange aperture** (6-blade camera iris, three orange tones, no black, transparent
opening). Works on light, dark, or transparent. File: `logo.svg`.

```html
<svg viewBox="0 0 200 200" width="200" height="200" role="img" aria-label="ClickerPro">
  <path d="M100 14 A86 86 0 0 1 174.48 57 L119 100 L109.5 83.55 Z" fill="#F9A52E"/>
  <path d="M174.48 57 A86 86 0 0 1 174.48 143 L109.5 116.45 L119 100 Z" fill="#F4881C"/>
  <path d="M174.48 143 A86 86 0 0 1 100 186 L90.5 116.45 L109.5 116.45 Z" fill="#EA7414"/>
  <path d="M100 186 A86 86 0 0 1 25.52 143 L81 100 L90.5 116.45 Z" fill="#E2620E"/>
  <path d="M25.52 143 A86 86 0 0 1 25.52 57 L90.5 83.55 L81 100 Z" fill="#F4881C"/>
  <path d="M25.52 57 A86 86 0 0 1 100 14 L109.5 83.55 L90.5 83.55 Z" fill="#F9A52E"/>
</svg>
```

**Wordmark:** "Clicker" in `#1A1A18` + "Pro" in `#E2620E`, Hanken Grotesk `800`,
`letter-spacing:-0.04em`. Optional mono tagline under it, `#9A988F`, tracking `0.34em`,
uppercase: `PHOTOGRAPHY STUDIO MANAGER`.
Horizontal lockup may include a 3-line motion trail (`#E2620E`, stroke 10, round caps)
to the left of the mark.

---

## 3. Component Patterns

**Screen frame** — 390px wide column; status bar (9:41 + signal/wifi/battery) →
header → scrollable content, `18px` gutter.

**Header** — `menu` icon · wordmark · spacer · `notifications` (with danger dot) ·
circular avatar (`linear-gradient(135deg,#E2620E,#B84E0A)`, white initials).

**Search field** — white, `border rgba(0,0,0,.06)`, radius `14px`, `search` icon `#A3A199`,
placeholder `#9A988F`.

**Micro-label** — IBM Plex Mono, `9–14px`, uppercase, `letter-spacing:0.12–0.22em`.
Section headers pair it with an orange `26×1.5px` rule.

**Primary button** — bg `#E2620E`, white text, weight `700`, radius `14px`, raised orange
shadow. **Secondary** — white bg, `#1A1A18` text, hairline border.

**Stat card** — colored bg (`#E2620E` hero / `#00898B` / `#3541AF`), white figure `30–58px`
weight `800`, mono uppercase label, decorative `rgba(255,255,255,0.06)` circle bleeding
off a corner.

**List row** — white card, radius `18px`, left icon tile (`#FBEBDE` bg, `#E2620E` icon,
radius `12px`), title + meta, right chevron or status pill.

**Status pill** — tint bg + saturated text: Paid `#2F8F6B`, Pending `#C99A2E`,
Overdue `#C0392B`, Confirmed `#E2620E`. Radius `999px`, mono/`600`, `~9–10px`.

**Quick-action grid** — 4-col, white cards radius `16px`, icon tile `#FBEBDE`, label
`11px` `#3A3A36`.

**Bottom nav** — 5 items, active = orange icon + label, inactive = `#9A988F`.

---

## 4. Screen Inventory (21 mobile screens, already designed)

Core: **Dashboard**, Add Booking, Booking List, Event Details, Packages, Finance,
Profile & Settings.
Roles/auth: FL-12 Freelancer Booking, MOD-01 Authentication (login), MOD-02 Onboarding
(3 slides w/ photos).
Ops: MOD-12 Calendar, MOD-14 Invoice, MOD-08 Team Management, MOD-40 Team Chat,
MOD-41 Announcement Board.
Finance: MOD-18/54 Expense + Petty Cash, MOD-16 Freelancer Payout, MOD-53 Cash-Flow
Timeline.
Client: MOD-13 Client Self-Booking, MOD-55/56/57 Template / Duplicate / Waitlist.

Reference mockup: `ClickerPro App.dc.html` (all screens, hand-tuned).

---

## 5. Extending to Web App & Admin Panel

Keep the **same tokens, logo, and type**. Translate mobile patterns to wider layouts:

- **Web app:** left sidebar nav (replace bottom nav) using the same icons + orange active
  state; content max-width ~1100px on `#FBFAF7`; cards keep `18px` radius + hairline border.
- **Admin panel:** denser data tables, but same color roles — orange for primary actions,
  status pills unchanged, stat cards for KPIs. Use `#FFFFFF` surfaces on `#FBFAF7`.
- Micro-labels (mono uppercase + orange rule) are the signature — use them for section
  headers everywhere.
- Never introduce a second accent hue for buttons; orange is the only interactive color.

---

## 6. File Manifest

- `ClickerPro App.dc.html` — 21 finished mobile screens (source of truth)
- `ClickerPro Logo.dc.html` — logo lockups, app-icon, color usage
- `logo.svg` — standalone aperture mark
- `CLICKERPRO_DESIGN_SPEC.md` — this document
