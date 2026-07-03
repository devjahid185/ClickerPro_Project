# ClickerPro — Dark Theme ("Noir") · Flutter Build Spec

> **For:** Claude Code building the ClickerPro mobile app in **Flutter**.
> **This document = the dark theme only.** A separate light theme already exists; do NOT mix the two visual languages. This "Noir" theme is a deliberate new, modern aesthetic.
> **Visual reference:** open `ClickerPro-Dark-Visual-Reference.html` in a browser to see all 8 screens exactly as they should look. Match it pixel-for-feel.

ClickerPro is a booking + finance manager for a **photography studio** (weddings, events). Roles: **Owner**, **Freelancer**, **Both**. Currency is **BDT (৳)**.

---

## 0. How to read this doc
1. Start with **§1 Design Tokens** → paste straight into `lib/theme/`.
2. **§2 ThemeData** → your `MaterialApp` theme.
3. **§3 Reusable widgets** → build these first; every screen composes them.
4. **§4 Screens** → one section per screen, top-to-bottom widget order.
Everything is spaced on an **8pt-ish grid** but values are given literally — use them as-is.

---

## 1. Design Tokens  →  `lib/theme/app_colors.dart` & `app_dimens.dart`

Aesthetic in one line: **near-black canvas · hairline white strokes · lime "glow" accent · mono labels.** No gradients on surfaces, no heavy shadows except the lime glow on primary actions.

```dart
import 'package:flutter/material.dart';

class AppColors {
  // ── Surfaces (darkest → lightest) ──
  static const bg        = Color(0xFF060708); // app scaffold background
  static const surface   = Color(0xFF0C0E11); // phone/page surface, sheets
  static const card      = Color(0xFF14171C); // cards, list tiles, inputs
  static const inset     = Color(0xFF1B1F26); // nested chips inside a card, track bg

  // ── Accent & semantic ──
  static const accent    = Color(0xFFC8F252); // lime — primary actions, active nav, focus
  static const onAccent  = Color(0xFF0E1206); // near-black text/icon ON lime
  static const day       = Color(0xFFF5C044); // "Day shift" amber
  static const night     = Color(0xFFA08CFF); // "Night shift" violet
  static const paid      = Color(0xFF52E0A1); // paid / collected / positive
  static const due       = Color(0xFFFF6E61); // due / cancelled / destructive

  // ── Text ──
  static const text      = Color(0xFFEDF1EA); // primary text
  static const muted     = Color(0xFF9BA1AB); // secondary text
  static const faint     = Color(0xFF5F6570); // labels, disabled, placeholders

  // ── Strokes (always semi-transparent white) ──
  static const stroke    = Color(0x12FFFFFF); // rgba(255,255,255,0.07) — default hairline
  static const strokeStrong = Color(0x1FFFFFFF); // ~0.12 — inputs, emphasis
  static const navStroke = Color(0x14FFFFFF); // ~0.08 — bottom nav border

  // ── Accent tints (icon chips, selected pills) ──
  static const accentTint = Color(0x1AC8F252); // rgba(200,242,82,0.10)
  static const nightTint  = Color(0x24A08CFF);
  static const paidTint   = Color(0x1F52E0A1);
  static const dueTint     = Color(0x24FF6E61);

  // Lime glow shadow (use on primary buttons & FAB)
  static List<BoxShadow> glow([double blur = 26, double y = 10, double a = 0.45]) => [
    BoxShadow(color: accent.withOpacity(a), blurRadius: blur, offset: Offset(0, y)),
  ];
}
```

```dart
class AppRadius {
  static const chip = 9.0;
  static const input = 13.0;
  static const card = 16.0;   // 16–18 for most cards
  static const cardLg = 22.0; // hero / feature cards
  static const nav = 24.0;
  static const page = 36.0;   // phone surface corner
}
class AppGap { static const xs=6.0, sm=9.0, md=12.0, lg=18.0, xl=24.0; }
```

### Typography → `app_text.dart`
Two families. Add to `pubspec.yaml` via `google_fonts` (recommended) or bundle.
- **Space Grotesk** — all UI text, numbers, headings. Weights 400/500/600/700.
- **JetBrains Mono** — ALL small labels, data tags, dates, section headers. This mono/grotesk pairing IS the theme's signature; do not substitute Inter/Roboto.

```dart
// with google_fonts:
final grotesk = GoogleFonts.spaceGrotesk;
final mono    = GoogleFonts.jetBrainsMono;
```

| Role | Family | Size | Weight | Letter-spacing | Color |
|---|---|---|---|---|---|
| Screen title | Grotesk | 22 | 700 | -0.02em | text |
| Big number (hero) | Grotesk | 36–58 | 700 | -0.03em | text/accent/onAccent |
| Card title | Grotesk | 14–16 | 700 | -0.01em | text |
| Body | Grotesk | 12.5–14 | 400–600 | 0 | text/muted |
| **Section label** | **Mono** | 9–10 | 500–600 | **0.12em, UPPERCASE** | faint |
| **Accent eyebrow** | **Mono** | 10 | 500 | **0.22em, UPPERCASE** | accent |
| Data tag / date | Mono | 8.5–11 | 500–700 | 0.06–0.16em | faint/muted |
| Nav label | Mono | 8.5 | 600–700 | 0 | faint / accent(active) |

**Rule of thumb:** if it's a *label, tag, date, or category header* → **JetBrains Mono, uppercase, letter-spaced**. If it's *content or a heading* → **Space Grotesk**.

### Icons
Screens use **Material Symbols Rounded**. In Flutter use `Icons.*` (Material) — closest equivalents:
`menu, notifications, search, calendar_month, receipt_long (→ receipt_long), chat_bubble, groups, add, home, event_note, account_balance_wallet, settings, arrow_back, location_on, call, star, photo_camera, videocam, close, trending_up, schedule, celebration, wb_sunny, push_pin, cloud_done, usb, translate, dark_mode, event_repeat, admin_panel_settings, logout, delete, person, storefront, draw, edit, visibility_off, check_circle, more_horiz, tune, chevron_right`. Active/filled nav icons use the **filled** variant.

---

## 2. ThemeData  →  `lib/theme/app_theme.dart`

```dart
ThemeData buildDarkTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      surface: AppColors.surface,
      primary: AppColors.accent,
      onPrimary: AppColors.onAccent,
      secondary: AppColors.accent,
      error: AppColors.due,
      onSurface: AppColors.text,
    ),
    textTheme: GoogleFonts.spaceGroteskTextTheme(base.textTheme)
        .apply(bodyColor: AppColors.text, displayColor: AppColors.text),
    // Cards default
    cardColor: AppColors.card,
    dividerColor: AppColors.stroke,
    splashFactory: InkRipple.splashFactory,
  );
}
```

**Universal surface recipe** (use everywhere — this is the "card" look):
```dart
BoxDecoration cardDeco({Color? bg, Color border = AppColors.stroke, double r = AppRadius.card}) =>
  BoxDecoration(
    color: bg ?? AppColors.card,
    borderRadius: BorderRadius.circular(r),
    border: Border.all(color: border, width: 1),
  );
```

---

## 3. Reusable Widgets (build these first)

### 3.1 `MonoLabel` — the uppercase mono eyebrow
Text, JetBrains Mono, size 9–10, weight 600, letterSpacing 0.12, uppercase, color `faint` (or `accent` for eyebrows at 0.22 spacing). Used above almost every card.

### 3.2 `SectionEyebrow` — "— DASHBOARD · DARK" strip
Row: a `26×1.5` lime bar + a `MonoLabel` in `accent` at 0.22em spacing. (In the reference these separate the screens; in the real app use them as section headers where useful, or drop them.)

### 3.3 `GlowButton` — primary action
Container, `color: accent`, radius 12, `boxShadow: AppColors.glow()`, child text Grotesk 12.5–14 / 700 in `onAccent`. Secondary variant = `card` bg + `strokeStrong` border + `text` label, **no glow**.

### 3.4 `StatCard`
`cardDeco()` container, padding 14–16. Top: `MonoLabel` (faint). Below: big number Grotesk 30 / 700 / -0.03em (color varies: `text`, `accent`, `paid`, `due`). Optional sub-caption in `muted` 11.

### 3.5 `PillToggle` / segmented control
Row inside a `card` container radius 13, padding 4. Active segment = `accent` bg, `onAccent` 700 label, radius 9. Inactive = transparent, `muted` 600 label. (Used for Owner/Both/Freelancer, Day/Night, Monthly/Yearly, bKash/Bank/Cash.)

### 3.6 `SoftSwitch` — custom toggle
38×22 track radius 11. OFF = `inset` bg + `strokeStrong` border + 16px `faint` knob at left. ON = `accent` track + 18px `onAccent` knob at right. Prefer a custom widget over Material `Switch` to match exactly.

### 3.7 `Chip` (category / filter)
Selected = `accent` bg + `onAccent` 700 label, radius 9. Unselected = `card` bg + `strokeStrong` border + `muted` 600 label. "Add" chip = transparent + **dashed** `strokeStrong` border + leading `add` icon.

### 3.8 `IconChip` — quick-action square
38×38 rounded-12 square, `accentTint` bg, centered `accent` icon 21. Label below in `muted` 11.

### 3.9 `Avatar`
Circle, `accent` bg + `onAccent` initials (or tinted bg + tinted initials for list avatars). Sizes 20 (stacked), 34–36 (header/list), 54 (profile).

### 3.10 `BottomNav` — **shared across Home / Bookings / Finance / Settings**
Container margin ~14, `card` bg, `navStroke` border, radius 24, padding `11,22,13`. Row `spaceBetween`, `crossAxisAlignment: start`. 5 slots:
- 4 tab items: icon 24 + mono label 8.5. Active = `accent` + **filled** icon + 700 label; inactive = `faint`.
- Center = **raised FAB**: 54×54 rounded-18 `accent` square, `add` icon 28 `onAccent`, `boxShadow: glow(30,14,0.55)`, `transform: translateY(-16)` (in Flutter, `Transform.translate(offset: Offset(0,-16))`).

Tabs in order: **Home · Bookings · [FAB] · Finance · Settings**.

### 3.11 `StatusBar` — faux iOS bar (optional, reference only)
`9:41` + signal/wifi/battery. In the real app the OS provides this; you can omit and use a normal `SafeArea`. Kept in the reference for realism.

---

## 4. Screens

> All screens are a `Scaffold(backgroundColor: bg)` → `SafeArea` → `Column`: header, scrollable body (`ListView`/`SingleChildScrollView`, padding 18 horizontal), and `BottomNav` pinned at bottom (on the 4 tab screens). Detail/form screens use an **AppBar row** (back arrow + title + trailing action) instead of the tab bar.

### 4.1 Dashboard (Home tab)
Order top → bottom:
1. **Header row:** `menu` icon · "Clicker**Pro**" (Pro in accent) · spacer · bell with `due` dot badge · `RH` avatar (accent).
2. **Search field:** `card` bg, `search` icon (faint) + placeholder "Search bookings, clients…" (faint). Radius 14.
3. **Weekday strip:** 7 equal columns. Each = mono weekday (faint; active WED in accent 700) + a square rounded-13 date cell + a 5px status dot below. Inactive cell = `card`+stroke, `text` number. **Active (WED/12)** = `accent` bg, `onAccent` number, `glow(20,8,0.5)`. Dots: amber=day booking, violet=night booking, transparent=none.
4. **Split hero (grid 1.22fr / 1fr, gap 12):**
   - Left big card `accent` bg, radius 22, glow. Mono "TODAY" (onAccent 60%), number **2** Grotesk 58, "events scheduled", then two mini pills "1 Day"/"1 Night" on `onAccent`-tinted bg. Decorative circle top-right (black 7%).
   - Right column: two stacked `StatCard`s — "UPCOMING **14** next 7 days" and "TOTAL **86** this year" (86 in accent).
5. **Delivered strip:** `card` row — left: mono "DELIVERED", number **48** + "+12 this month" in `paid`. Right: a 6-bar mini bar chart (dark bars `#2B3320`, mid `#5F7A2A`, tallest `accent`).
6. **Quick Actions:** header row ("Quick Actions" + mono "EDIT" in accent) then 4-col grid of `IconChip`: Calendar, Invoice, Chat, Team.
7. **Announcement card:** `card` with 3px left `accent` bar. `push_pin` + mono "ANNOUNCEMENT" (accent) + timestamp. Title "Team meeting — Friday 4 PM", body in muted, then stacked mini-avatars + "8 of 11 read".
8. **Finance row (grid 1/1):** "COLLECTION ৳1,24,500" (accent, `trending_up` paid) + "DUE ৳38,000" (due, `schedule`).
9. **Holiday / Cancelled / Weather (grid 1.3/1/1):** Holiday card (violet `celebration`, "Eid-ul-Fitr · Apr 12"), Cancelled card (`due` border, number **3**), Weather card (`day` sun, "32° · Clear · Outdoor OK").
10. **BottomNav** (Home active).

### 4.2 Add Booking (FAB → form)
AppBar row: `arrow_back` + "New Booking" + **`GlowButton` "Save"** trailing. Body:
1. **Role `PillToggle`:** Owner / Both / Freelancer (Owner active).
2. **Client Name** (MonoLabel "CLIENT NAME *") → text field `card`+strokeStrong, radius 13. Value "Tahmina Rahman".
3. **Client Phone** → same, "+880 1712-345678".
4. **Row (1/1):** Shift `PillToggle` Day(`day` bg active)/Night · Date field with `calendar_month` accent icon ("Apr 12").
5. **Package** (MonoLabel): two selectable cards. Selected = `accentTint` bg + `accent` 1.5px border + `check_circle` filled accent. Shows name, spec line (muted), price (accent). Unselected = plain card + hollow radio circle.
6. **Two toggle tiles (row):** "Outdoor" (SoftSwitch OFF) · "Chief" (SoftSwitch ON).
7. **Team** (MonoLabel): two cards — Photographers (`photo_camera` accent, member chips in `accentTint` with `close`, + dashed "Add"), Cinematographers (`videocam` night, chips in `nightTint`).
8. **Event Type** chips: Wedding(selected)/Holud/Reception/Corporate/Portrait.
9. **Payment summary card:** rows Total (auto) / Advance (paid) / Due (auto, due color) separated by hairline dividers; payment `PillToggle` bKash/Bank/Cash; "Hide payment from team" row with `visibility_off` + SoftSwitch.

*(No bottom nav on this screen — it's a modal form.)*

### 4.3 Booking List (Bookings tab)
1. Header: "Bookings" title + count badge **86** (`accentTint`/accent) + spacer + `tune` icon.
2. Search field (as dashboard).
3. **Filter chips row** (horizontal scroll): All(selected)/Pending/Confirmed/Delivered — pill radius 20.
4. **Two-column split (grid 1/1):**
   - **DAY column:** header dot(`day`) + mono "DAY · 5". Cards with **left** 3px `day` border, mono date, client name, "Wedding · 12–5".
   - **NIGHT column:** header dot(`night`) + mono "NIGHT · 4". Cards with **right** 3px `night` border.
5. BottomNav (Bookings active).

### 4.4 Event Details (from a booking tap)
AppBar: `arrow_back` + "Event Details" + `more_horiz`. Body:
1. **Hero card:** `card` + faint accent border, decorative accent circle. "CONFIRMED" badge (accent bg) + day-shift dot. Title "Wedding" Grotesk 26, date line, `location_on` accent + venue.
2. **Client card:** avatar + name + phone + green `call` action square (`paidTint`).
3. **Team card:** MonoLabel "TEAM", rows: Karim (filled `star` day + "CHIEF"), Rafi (`photo_camera` accent), Sumon (`videocam` night). Each with `call` in paid. Hairline dividers.
4. **Payment card:** MonoLabel "PAYMENT", three columns TOTAL/ADVANCE(paid)/DUE(due), then a progress track (`inset` bg, `paid` fill 35%) + "35% collected".
5. **`GlowButton` "Generate Invoice"** (`receipt_long`), then secondary row: WhatsApp (`chat` paid) + Edit.

*(No bottom nav — pushed detail route.)*

### 4.5 Finance (Finance tab)
1. Header: "Finance" + `PillToggle` Monthly(active)/Yearly.
2. **Net-profit hero:** full `accent` card + glow. Mono "NET PROFIT · APRIL", number ৳1,86,500 Grotesk 36, then INCOME/EXPENSE mini columns on `onAccent`.
3. **6-month bar chart card:** MonoLabel "LAST 6 MONTHS", 6 bars height-scaled, latest APR = `accent` + soft box glow, older = `#2B3320`/`#5F7A2A`, mono month labels.
4. **3-stat grid:** BOOKED ৳2.4L / COLLECTED ৳2.0L(paid) / DUE ৳38K(due).
5. **"Who owes"** header + "SEND REMINDERS" (accent mono). List rows: avatar + name + event/date + due amount (`due` color).
6. BottomNav (Finance active).

### 4.6 Packages (managed from settings/menu)
AppBar: `arrow_back` + "Packages" + `GlowButton` "＋ New". Two package cards:
- Card = `card` + **top** 3px accent bar (Premium) / night bar (Standard). Name, price (accent/night) + optional strikethrough old price + "-10K" `dueTint` badge. 3-col spec grid on `inset` chips (PRINTS/ALBUM/VIDEO). Delivery line with icon. Footer: "Edit" (accent) | divider | "Delete" (due).

### 4.7 Profile & Settings (Settings tab)
1. Header "Settings".
2. **Profile card:** 54 avatar (RH) + name + phone + "BOTH" role badge (`accentTint`).
3. **Grouped setting sections** (MonoLabel header + a `card` container with hairline-divided rows). Each row = leading icon (muted, or accent for Theme) + label + trailing (chevron / value text / SoftSwitch / role badge):
   - **ACCOUNT:** Name & email ›, Profile photo ›.
   - **STUDIO · OWNER/BOTH:** Studio name = "Clicker Studio", Logo & signature ›.
   - **PREFERENCES:** Language = English, **Theme = "DARK" badge** (accent, `dark_mode` icon accent), Distribution mode (SoftSwitch ON), Manager permissions ›.
4. **Row:** "Log out" (secondary) + "Delete" (`dueTint` bg + due border + due label).
5. BottomNav (Settings active).

---

## 5. Behaviour notes for Claude Code
- **Role gating:** Owner/Both see Finance, Studio settings, payment "hide from team". Freelancers see a reduced set. Wire a `UserRole` enum.
- **Shift** (Day/Night) drives the amber/violet accent everywhere — keep it a single source of truth.
- **Money** formatted with `৳` prefix and `en_IN`-style grouping (1,24,500 — lakh grouping), with `L`/`K` short forms on compact stats.
- **Distribution mode** toggle in settings switches booking distribution logic (assumed existing backend concept — keep the UI, wire later).
- Numbers/stats in this doc are **sample data** — bind to real models.

## 6. Do / Don't
- ✅ Hairline `stroke` borders on every surface; lime glow ONLY on primary CTA + FAB + active date + latest chart bar.
- ✅ Mono uppercase for every label/tag/date; Grotesk for content.
- ❌ No gradients on cards, no drop shadows on ordinary cards, no rounded-corner + left-accent-border "alert" clichés except the deliberate announcement/left-bar pattern shown.
- ❌ Don't reuse the light theme's orange (#E2620E) or Hanken Grotesk — this is a separate, standalone theme.
- ❌ Don't invent new accent colors; the 6-color semantic set above is complete.
