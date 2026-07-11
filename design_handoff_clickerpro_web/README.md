# Handoff: ClickerPro — Web App Dashboard (Sunset Studio / Orange theme)

## Overview
ClickerPro is a photography-studio management platform for Bangladesh (bookings, finance, team, packages). This handoff covers the **web app UI**: a single-page dashboard application — 12 screens + an auth overlay + a notifications dropdown — with a persistent left sidebar, screen switching, role-aware data, and a modern motion system. Full product spec lives in `App_Architecture_v12.html` (module IDs referenced below, e.g. MOD-09).

## About the Design Files
The files in this bundle are **design references created in HTML** — a working prototype showing intended look and behavior, **not production code to copy directly**. Your task is to **recreate this design in the target codebase's environment** (React, Vue, Flutter Web, etc.) using its established patterns. If no environment exists yet, choose an appropriate stack (the product spec targets Flutter + Firebase; for web, React + Tailwind or similar is fine).

`ClickerPro Dashboard v2.dc.html` is the prototype. It uses a small custom template runtime (`support.js`) — ignore the runtime; read the file for **markup structure, inline styles (all exact values), and the logic class at the bottom** (a React-style class named `Component` whose `renderVals()` computes all data/handlers).

## Fidelity
**High-fidelity.** All colors, typography, spacing, radii, shadows, copy, and animations are final. Recreate pixel-perfectly.

---

## Design Tokens

### Colors
| Token | Hex | Usage |
|---|---|---|
| Primary orange | `#EA5B0C` | Primary buttons, active states, hero card, today highlight, links |
| Orange hover/dark | `#C2410C` | Button hover, hero gradient end |
| Orange deep text | `#B8430A` | Orange-tinted labels, DAY shift text |
| Gold | `#F5B02E` | Secondary accent, gradients, sidebar accent, DAY shift border, Chief card |
| Gold dark | `#C99414` / `#B8860B` | Gold-tinted text |
| Page background | `#FBF6F0` | Warm cream app background; also nested row background |
| Card white | `#FFFFFF` | All cards |
| Card border | `#EBDDCE` | Default card/input border |
| Inner border | `#F0E4D6` | Borders inside cards (rows, dividers) |
| Text primary | `#2B1D12` | Dark brown — headings, body; ALSO the sidebar background |
| Text secondary | `#6B5844` | Body-muted |
| Text muted | `#A08469` | Labels, captions |
| Text faint | `#B99C82` | Placeholders, inactive sidebar text |
| Sidebar bg | `#2B1D12` | Dark brown; also announcement card + settings hero |
| Sidebar avatar bg | `#3D2A1A` | Circle behind initials |
| Cream on dark | `#FFF6EE` | Text/logo on dark or orange surfaces |
| Orange tint bg | `#FFF3E8` (border `#F5C9A3`) | DAY chips, orange stat tiles, hover fills |
| Purple (night) | `#8B5CF6`, text `#6D3FD4`, bg `#F3EEFD`, border `#D8C8F7` | NIGHT shift everywhere |
| Green (success) | `#1E9E6A`, bg `#E9F7F0`, border `#BCE3CF` | Paid, delivered, online status |
| Red (danger) | `#D64545`, text alt `#B23A3A`, bg `#FDECEC`, border `#F3BCBC` | Dues, delete, logout |
| Gold tint bg | `#FFF7E5`, border `#F2DFAE` | Pending/gold tiles |
| Expense bar | `#E3CDB4` | Chart secondary bars, toggle-off track |
| On-orange text | `#FFD9B8` (labels) / `#FFE4CC` (body) | Text on orange gradient |

### Typography
- **Display / headings / big numbers:** `Sora` 600–800 (Google Fonts)
- **Body / UI:** `DM Sans` 400–700
- **Labels / mono / numbers-in-tables:** `Space Mono` 400/700 — always uppercase with letter-spacing 0.08–0.25em for labels
- **Bengali:** `Noto Sans Bengali` (currency ৳ appears throughout)
- Scale: page title 26px/800 Sora · card title 16–17px/700 Sora · hero number 104px/800 Sora · stat numbers 28–38px/800 Sora · body 12–14px DM Sans · micro labels 8–10px Space Mono uppercase

### Radii
Cards 22px · sidebar 30px · small cards/tiles 14–18px · rows 12–14px · chips/buttons/pills 999px · icon squares 10–11px · calendar cells 10–14px

### Shadows
- Card: `0 6px 20px rgba(43,29,18,0.06)`
- Small card: `0 4px 14px rgba(43,29,18,0.05)`
- Sidebar: `0 16px 44px rgba(43,29,18,0.22)`
- Orange glow (hero/buttons): `0 16px 40px rgba(234,91,12,0.3)` / buttons `0 6px 16px rgba(234,91,12,0.3)`
- Gold glow (Chief card): `0 14px 34px rgba(245,176,46,0.35)`
- Dark card: `0 12px 32px rgba(43,29,18,0.25)`

### Spacing
Page padding 24px · grid gap 20px (outer) / 18px (sections) / 14px (tiles) / 10px (rows) · card padding 22–26px.

---

## Global Layout
- Max width **1440px**, centered. CSS grid: `248px (sidebar) | 1fr (main) | 316px (right panel)`, gap 20px, `align-items:start`.
- **Right panel is visible ONLY on the Dashboard screen.** On all other screens the main column spans columns 2–4 (full width).
- Sidebar is `position:sticky; top:24px`, min-height 860px.
- SPA behavior: one page, 7 screens toggled by sidebar nav state. Header (title + search + bell) is shared and persistent; the title changes per screen.

## Sidebar (persistent, all screens)
Dark brown `#2B1D12`, radius 30px, `overflow:hidden`, vertical flex, padding `28px 0 26px` (note: NO horizontal padding on the nav container — the active pill bleeds to the right edge).
1. **Logo row** (padding 0 24px): 34px orange rounded square (radius 10) with Sora 800 "C" in cream + wordmark "Clicker**Pro**" ("Pro" in `#F59E4C`), Sora 800 19px.
2. **Profile block** (centered, bottom border `rgba(255,246,238,0.10)`): 92px circular avatar with 2px gold ring `rgba(245,176,46,0.6)` and 4px gap; inside, initials on `#3D2A1A`, Sora 700 28px gold. Name: Sora 700 16px UPPERCASE cream. Email/studio line 10.5px `#B99C82`. Role badge pill: Space Mono 9px uppercase gold text on `rgba(245,176,46,0.14)` with border `rgba(245,176,46,0.35)`.
3. **Nav** (7 items, gap 8): each row `margin-left:16px`, padding `9px 16px 9px 18px`, `border-radius:999px 0 0 999px` (rounded left, flush right edge). Icon: 30px circle, 1px border (`rgba(245,176,46,0.35)` inactive / `rgba(234,91,12,0.35)` active), glyph in Space Mono 12px — gold inactive, orange active. Label: 11px/700, letter-spacing 0.16em, UPPERCASE — `#B99C82` inactive.
   **Active state: cream pill** — background `#FBF6F0`, label `#2B1D12`, icon orange. Transition 0.25s on background/color.
   Items (9): Dashboard ◈ · Bookings ▤ · Calendar ▦ · Finance ৳ · Team ◎ (Freelancer role sees "My Companies") · Chat ✉ · Announce ✦ · Packages ❖ · Settings ⚙. Sub-screens New Booking and Event Details keep **Bookings** highlighted. (Replace glyphs with a real icon set, keep outline style.)
4. **Active Team** (margin-top:auto, padding 0 24px): gold Space Mono label + overlapping 32px avatars (−8px margin, 2px `#2B1D12` border) + "+5" chip.

## Shared Header (all screens)
- Left: screen title (Sora 800 26px) + date line `SAT · 11 JUL 2026 · DHAKA` (Space Mono 10px `#A08469`).
- Center-right: search pill (max-width 420px, white, border `#EBDDCE`, radius 999, padding 10×18, orange ⌕ icon, placeholder "Search client, booking, venue…" in `#B99C82`).
- Right: 42px white circular bell button with 7px orange notification dot (1.5px white border) that **pulses** (opacity 1→0.45, 2s infinite). **Clicking the bell toggles a Notifications dropdown** (MOD-44): 352px white panel, absolute right-aligned under the bell (z-index 40, popIn entry), header "Notifications" + "MARK ALL READ" mono link, then 4 rows — 34px tinted icon tile · title 700 12.5px + sub 11px muted · relative time (mono 9px). Rows with actions show a quick-action chip (orange-tint pill, e.g. "VIEW EVENT", "SEND REMINDER"). Seeded: delivery deadline ⏰, payment due ৳ (red tint), weather alert 🌦 (purple tint), milestone 🎉 (green tint). Bell bg turns orange-tint while open.

---

## Screen 1 — Dashboard (MOD-04, unified across roles)
Order top→bottom in main column:
1. **Week strip** — 7 equal cards: DOW (Space Mono 9px), date number (Sora 800 20px), up to 3 event pips (5px dots, gold=day event, purple=night). Today (SAT 11): orange bg, cream text, glow shadow. Hover: lift −3px.
2. **Split hero** — grid `1.5fr 1fr`:
   - Left: orange gradient card (`135deg #EA5B0C→#C2410C`), blurred gold glow blob top-right (240px circle, blur 90px, opacity .35). Label "TODAY'S EVENTS" (Space Mono 9px `#FFD9B8`), giant "03" (Sora 800 104px cream) with **pop-in** animation, legend "2 Day shift" (gold dot) / "1 Night shift" (dark dot), footer "Next: Wedding — Community Center, Dhanmondi · reporting 4:30 PM".
   - Right: two stacked white cards — "UPCOMING / 12 / next 30 days" (12 in orange) and "TOTAL BOOKINGS / 148 / ↑ 9 this month" (green delta).
3. **Delivered strip** — white card: "DELIVERED / 96" (green Sora 34px) + 7 mini bars (last bar orange→gold gradient, others `rgba(234,91,12,0.18)`) growing with stagger + "JAN – JUL / ▲ 12%".
4. **Today's Bookings** — white card, "VIEW ALL →" navigates to Bookings. Rows: grid `64px 1.4fr 90px 1fr auto`, cream bg, 3px left border in shift color; date block (day Sora 800 21px + "JUL"), client 700 14px + type line, shift chip (DAY orange-tint / NIGHT purple-tint, Space Mono 9px), venue, amount (Space Mono 700) + due line (red "Due ৳ 30,000" / green "Paid ✓"). Hover: orange border, `#FFF3E8` bg, translateX(4px).
   Data: Rafiq & Mim (Wedding·Premium, ৳85,000, due 30k) · Nexus Corp (Corporate, ৳45,000, paid) · Sadia & Family (Birthday, NIGHT, ৳25,000, due 20k).
5. **Quick Actions** — 4 cards (icon tile 38px tinted + label), each navigates: Calendar/Invoice→Finance/Chat→Team/Team. **Freelancer role:** Calendar/Company/Chat/Expense. Hover: lift + orange border + orange-tinted shadow.

### Right panel (dashboard only, top→bottom)
1. **Finance · July** (Owner/Both): 2 tiles Collection `৳ 2,84,500` (orange tint) + Due `৳ 68,000` (red tint); "TOP DUES" list (Rafiq & Mim 30k, Sadia 20k, Nexus 18k, red amounts); full-width orange "SEND REMINDERS" button (Space Mono uppercase).
   - **Freelancer role:** "My Earnings · July" — Received ৳42,000 (green) + Pending ৳15,500 (gold) + "Request Payment" button.
   - **Manager role:** notice card "Income & profit hidden for the Manager role. Client dues remain visible below." + dues list only.
2. **Announcement** (dark `#2B1D12` card): "📌 ANNOUNCEMENT" gold label, title "Gear check before Friday's wedding", body in `#B99C82`, read-receipt dots (3 green + 1 dim) + "3/4 read".
3. **Mini calendar** — "July 2026" + ‹ › round buttons; MO–SU header (SA/SU orange); 7-col grid, Monday start (1 Jul = Wed ⇒ 2 leading blanks); today 11 = orange square, cream text; event dots gold/purple under dates 6,8,10,12,18,25. Footer: green dot + "Next holiday: Ashura · 17 Jul".

## Screen 2 — Bookings (MOD-09, Day|Night two-column)
1. Top row: status chips All/Pending/Confirmed/Successful/Delivered/Cancelled (pill, Space Mono 10px uppercase; active = orange bg cream text; state-driven) + right-aligned orange "+ New Booking" pill button.
2. Two equal white cards:
   - **Day Shift** — header "☀ Day Shift" + count chip, 2px gold bottom border. Rows have **3px gold LEFT border**; hover slides **right** (+4px).
   - **Night Shift** — header "☾ Night Shift" + purple count chip, 2px purple bottom border. Rows have **3px purple RIGHT border**; hover slides **left** (−4px).
   - Row: 40px date block (day + month) · client (700 13px) + "type · area" (11px muted) · › chevron.
   - Day data: 11 Rafiq & Mim (Wedding·Dhanmondi), 11 Nexus Corp (Corporate·Banani), 14 Imran & Nusrat (Holud·Mirpur DOHS), 18 Ayaan Portraits (Portrait·Studio), 25 Farhan & Richi (Engagement·Gulshan 2).
   - Night data: 11 Sadia & Family (Birthday·Uttara 7), 12 Mehedi & Tuli (Reception·Bashundhara), 19 Zara's Aqiqah (Aqiqah·Banasree), 26 BDApps Ltd (Corporate Gala·Radisson).
   - NO status badges on rows (spec decision).

## Screen 3 — Calendar (MOD-12)
One large white card: header "July 2026" + ‹ › + right segmented control MONTH/WEEK/DAY (active = orange pill). MON–SUN labels (SAT/SUN orange). 7-col grid of day cells: min-height 86px, radius 14, `#FBF6F0` bg with `#F0E4D6` border; today = orange border + `#FFF3E8` bg + orange number. Event chips inside cells (9.5px/600, radius 5, ellipsized): day events orange-tint, night events purple-tint. Events: 6 Holud—Imran · 8 Corporate + Reception · 10 Mehendi · 11 Wedding—Rafiq + Corporate + Birthday · 12 Reception—Mehedi · 14 Holud—Imran · 18 Portrait · 19 Aqiqah · 25 Engagement · 26 Corporate Gala. Cells pop-in with per-cell stagger (~12ms each); hover: orange border + lift.

## Screen 4 — Finance (MOD-14–22 + 53/54/58/16)
**Tab bar at top** (mono pills, active = orange fill): OVERVIEW / EXPENSES / CASH FLOW / PETTY CASH / SALARY / PAYOUTS. Each tab is live state.

### Tab 1 — Overview
1. Row: MONTHLY/YEARLY segmented pill (active orange) + "JULY 2026" label right.
2. **3 stat cards**: Income `৳ 2,84,500` "↑ 14% vs June" (orange gradient card, cream text) · Expense `৳ 96,200` "Gear rent + travel + prints" (white) · Net Profit `৳ 1,88,300` "Tap for source breakdown" (white, green border + green value). Values Sora 800 30px.
3. **Income vs Expense · 6 months** — white card, legend (orange=Income, `#E3CDB4`=Expense). 6 month groups (FEB–JUL), two 22px bars each (income: orange→gold vertical gradient; expense: `#E3CDB4`), height area 150px, values ≈ FEB 62/40 … JUL 120/60 (relative %). Bars **scaleY-grow from bottom** with per-month stagger.
4. **Client Dues** — white card + orange "SEND REMINDERS" pill. Rows: 38px tinted initial avatar · name + "event · date" · **progress bar** (6px track `#F0E4D6`, orange→gold fill) with caption "65% PAID OF ৳ 85,000" · red due amount. Data: Rafiq & Mim 65%/due 30k · Sadia & Family 20%/due 20k · Nexus Corp 60%/due 18k. Tap row → per-event payment history (spec).

### Tab 2 — Expenses (MOD-18)
3 summary tiles (This Month ৳96,200 · Event-linked ৳64,000 orange · General ৳32,200) + list card with "+ Add Expense" orange pill. Rows: 36px tinted emoji tile · title 700 + date line (with "📎 receipt" when a receipt photo exists) · category tag pill (WEDDING orange-tint / CORPORATE gold-tint / GENERAL neutral) · red amount "− ৳ 8,500" (mono 700, right-aligned 90px). Seeded: microbus rent, album prints, batteries+cards, light rental.

### Tab 3 — Cash Flow Timeline (MOD-53)
One card: title "Cash Flow · next 3 months" + "PDF ↓" chip. Legend: **solid orange→gold gradient = confirmed income; hatched (45° repeating stripes + dashed orange border) = pending; tan `#E3CDB4` = projected expense**. 3 month groups (AUG/SEP/OCT), three 34px bars each, 190px chart height, barGrow stagger; month label + projected total under each ("৳ 1.1L proj.").

### Tab 4 — Petty Cash Book (MOD-54)
Header row: dark card "Opening Balance · July ৳ 10,000" + white card "Current Balance ৳ 8,660" (green) + "+ Entry" orange pill and "PDF ↓" chip. Entry rows: fixed-width category pill (TRANSPORT orange / FOOD green / PRINT purple / PHONE gold, mono 9px) · description 700 + date · red "− ৳ 180" · running balance (mono muted, right 80px).

### Tab 5 — Team Salary Sheet (MOD-58)
One card: "Salary Sheet · July" + "PDF ↓" chip + green "MARK ALL PAID" pill. Column-header row (mono 8.5px uppercase): Member / Events / Rate / Earned / Paid / Due / (action). Grid rows `1.4fr 70px 90px 100px 100px 100px 90px`: avatar + name · events count · rate · earned 700 · paid (green) · due (red, or green ৳0) · button: orange "PAY" pill, or green-tint "PAID ✓" when settled. Data: Kamrul 8ev/৳4,000/32k/24k/8k · Rasel 6/2.5k/15k/15k/0 · Sumi 5/3k/15k/10k/5k · Tanvir 4/2.5k/10k/6k/4k.

### Tab 6 — Payouts (MOD-16)
Grid `1.4fr 1fr`:
- **Payout Requests** card — rows: avatar · name + "Requested date · N events" · method pill (purple-tint: bKash/Nagad/Bank) · amount · **Approve** (green fill) / **Reject** (red-tint) buttons; settled rows show "PAID ✓" green chip instead.
- Right column: **Payment Methods** card (bKash row with DEFAULT chip, Nagad row, dashed "+ Add bKash / Nagad / Bank") + dark **Pending Total** card (৳ 23,500 · "2 requests awaiting approval · payouts go out on the 15th").
Freelancer role uses this same tab to add methods and request payouts; Owner/Manager approve.

## Screen 5 — Team (MOD-08)
1. **4 stat tiles**: Members 9 (dark) · Photographers 5 (orange) · Cinematographers 3 (purple) · Active Today 6 (green).
2. **Chief card** — full-width gold gradient (`135deg #F5B02E→#E89A0C`), gold glow shadow: 52px dark avatar "K", "Kamrul Islam ★" (Sora 700 dark), "Chief Photographer · 82 events", dark "CHIEF" pill right.
3. **Members** — white card: filter chips ALL (active orange) / 📷 PHOTO / 🎬 CINE + orange "+ Invite" button. Rows: 40px tinted avatar with 10px **status dot** (green=online, gold=busy, tan=offline) · name + phone · role tag pill (Photo=orange-tint, Cine=purple-tint) · "46 ev" count (Space Mono) · round call button ✆ (hover: green tint). Data: Rasel Mia/Photo/46/online · Sumi Akter/Cine/38/online · Tanvir Ahmed/Photo/31/busy · Jahid Hasan/Cine/24/online · Mithila Rahman/Photo/18/offline.
Freelancer role sees this screen as "My Companies" (per spec; prototype shows Owner view).

## Screen 6 — Packages (MOD-25)
Intro line "Selecting a package in the booking form auto-fills the payment total." + orange "+ Add Package". 3-col grid of cards with **4px colored top border**:
- **Premium** (orange, tag POPULAR): net **৳ 85,000**, struck `৳ 95,000`. Specs: Prints 4 × 12×18 · Album Premium 40p · Trailer 1/event · Full Video 1/event · Delivery Drive + Pendrive · Team 4 + Chief.
- **Standard** (gold, VALUE): ৳ 45,000 / struck 52,000. Prints 2 × 10×12 · Album Classic 24p · Trailer 1/event · Full Video — · Delivery Google Drive · Team 2 + Chief.
- **Basic** (purple, STARTER): ৳ 25,000 / struck 28,000. Prints 1 × 8×10 · rest — · Delivery Google Drive · Team 2.
Card anatomy: name (Sora 800 18px) + tag pill; net price Sora 800 26px orange + struck original (Space Mono, `#B99C82`); 2-col spec grid of tiles (micro label + 12px/700 value); Edit (orange-tint, hover fills orange) + Delete (red-tint, hover fills red) buttons. Hover: lift −4px + deeper shadow.

## Screen 7 — New Booking (Form v6 / FL-12, reached via "+ New Booking" on Bookings)
Max-width 860px column of white section cards (radius 20, standard shadow), each fading up staggered:
1. **Sticky action bar** (`position:sticky; top:24px`, white, stronger shadow `0 10px 26px rgba(43,29,18,0.1)`): "← BACK" (Space Mono, → Bookings) · "Saved ✓ · auto-save on" (green, right-aligned) · orange "Save Booking" pill.
2. **Booked By** (FREELANCER ROLE ONLY): FREELANCER/COMPANY segmented pill toggle + "Company Name" text input.
3. **Client** card (Owner/Both/Manager): required marker `*` in red. 2-col: Client Name / Phone Number inputs. Input style everywhere: `#FBF6F0` bg, `#EBDDCE` border, radius 12, padding 12×16, placeholder `#B99C82` 13px; micro label above (Space Mono 9px uppercase muted).
4. **Schedule** card:
   - Shift selector: two equal pills "☀ DAY · 12–5" / "☾ NIGHT · 6–11" — selected DAY = orange fill, selected NIGHT = purple `#8B5CF6` fill, unselected = cream/muted. Live state.
   - Date field (tap = calendar) with orange ▦ icon: "Sat, 11 July 2026".
   - Venue input.
   - **Outdoor Event toggle row** (cream tile): when ON, a 2-col Location + Reporting Time block **expands with fadeUp**. Toggle = same 44×24 switch as Settings.
   - **Conflict warning** (red tint tile `#FDECEC`/`#F3BCBC`): "⚠ Conflict: a Day-shift booking already exists on 11 Jul — Rafiq & Mim. Distribution mode allows saving anyway." (shown when a same-date/shift booking exists AND distribution mode is on; blocks save when off — see spec).
5. **Package** card (not freelancer): 4 selector tiles (Premium ৳85,000 / Standard ৳45,000 / Basic ৳25,000 / Custom "manual"), 4px colored left border (orange/gold/purple/tan), selected = orange-tint bg. **Selecting auto-fills Payment Total.** Live state.
6. **Team** card (not freelancer): gold "★ Chief Photographer" toggle row (gold track when ON) revealing "Kamrul Islam" field; then 2-col: 📷 Photographers and 🎬 Cinematographers — removable member chips (tinted pills with ✕) + dashed "+ Add" chip, count badge per column.
7. **Event Type** card: 9 single-select chips — Wedding, Holud, Reception, Corporate, Birthday, Engagement, Aqiqah, Portrait, Other (selected = orange fill). Live state.
8. **Notes** card (FREELANCER ONLY): textarea + limit note "Max 2 events per day — 1 of 2 used on this date" with gold dot.
9. **Payment** card (not freelancer): header with "👁 HIDE FROM TEAM" mono link. 3 tiles: **Total (auto)** orange-tint — driven by selected package · **Advance** ৳25,000 editable · **Due (auto)** red-tint = total − advance. Method chips bKash/Bank/Cash (single-select, orange fill). Footer note: 'Invoice is generated after save — "Saved ✓ — Invoice →"'.

## Screen 8 — Event Details (reached by clicking ANY booking row anywhere)
1. "← BACK TO BOOKINGS" mono link.
2. **Hero** — orange gradient card (same treatment as dashboard hero, blurred gold blob): label "WEDDING · PREMIUM PACKAGE", frosted "Confirmed" status pill right, client name Sora 800 34px cream, meta row "▦ Sat, 11 July 2026 · ☀ Day shift · 12–5 PM · ◎ Community Center, Dhanmondi".
3. **3-col info grid**:
   - **Client** card: name, phone (Space Mono), "✆ Call" (green tint, hover fills green) + "WhatsApp" (orange tint, hover fills orange) buttons.
   - **Payment** card: Total ৳85,000 / Advance ৳55,000 (green) / Due ৳30,000 (red, above divider); orange→gold progress bar 65%; caption "65% PAID · bKash".
   - **Delivery Checklist**: ☑ Photos culled, ☑ Trailer edited (struck through), ☐ Album printed, ☐ Pendrive handover.
4. **Assigned Team** — 3 tinted member tiles: Kamrul Islam ★ (gold tile, dark avatar), Rasel Mia (orange tile, 📷), Sumi Akter (purple tile, 🎬), each with phone + ✆.
5. **Action row**: orange "⚡ Auto-generate Invoice" (toggles invoice panel) · outline "Re-edit Request" · red outline "Cancel Booking" (right-aligned).
6. **Invoice panel** (revealed by the button, dark `#2B1D12` card, fadeUp): monospace key-value block — DATE / TIME / EVENT / CLIENT / PHONE / VENUE / CHIEF / TEAM / TEAM NO / TOTAL / ADVANCE / DUE (due in `#FF9B7A`). Footer chips: COPY (gold tint) / WHATSAPP (green tint) / MESSENGER (purple tint) + "PDF ↓ · BN/EN" right. Matches spec's auto-invoice text format (FL-06/MOD-13).

## Screen 9 — Team Chat (MOD-10, sidebar "Chat" ✉)
Single white card, fixed height 720px, flex column, `overflow:hidden`:
1. **Header**: 40px orange-tint ✉ tile, "Lens & Light — Team", status "● 6 online · text-only · offline queue on" (green), overlapping member avatars right.
2. **Message area** (cream `#FBF6F0` bg, scrollable): centered "TODAY · 11 JUL" date pill. Bubbles max-width 58%:
   - Others: left-aligned, 32px tinted avatar + tiny name label (colored 10.5px/700), white bubble with `#F0E4D6` border, radius `16px 16px 16px 4px`.
   - Me (owner): right-aligned, orange `#EA5B0C` bubble, cream text, radius `16px 16px 4px 16px`, no avatar.
   - Timestamp under each (Space Mono 8.5px `#B99C82`).
   - **Typing indicator**: white bubble with 3 dots pulsing at 0/0.2/0.4s offsets.
   - 5 seeded messages (gear check conversation — see prototype data).
3. **Composer**: cream pill input "Message the team…" + 44px round orange send button (hover scales 1.06).

## Screen 10 — Announcements (MOD-11, sidebar "Announce" ✦; dashboard announcement card links here)
Max-width 860px:
1. Intro line "Pinned posts show on every member's dashboard with read receipts." + orange "+ New Post" pill.
2. **Pinned post** — dark `#2B1D12` card: "📌 PINNED" gold label + "expires 13 Jul" right; title cream 700 15px; body `#B99C82`; footer read-receipt dots (3 green + 1 dim) "3/4 read" + gold "💬 2 COMMENTS" link.
3. **Feed** — 3 white post cards (hover: lift + orange border): 30px tinted author avatar + meta line "Name · Role · date"; title 700 14.5px; body 12.5px `#6B5844`; footer "7/9 READ" + comment count (mono micro). Posts: July payout cycle (Arif/Owner) · New Premium package live (Arif/Owner) · Editing turnaround (Kamrul/Chief).

## Screen 11 — Settings (MOD-03, role-aware)
Max-width 760px column:
1. **Profile hero** — dark `#2B1D12` card: 72px gold-ring avatar, name (Sora 700 19px cream), "+880 17XX-XXXXXX · Lens & Light Studio · Dhaka", role badge pill.
2. **Settings list** — white card, rows (icon tile 36px tinted + label 700 13.5px + sub 11px muted + trailing control), dividers `#F0E4D6`:
   - Account (chevron) · Studio (Owner/Both only, chevron) · Language "বাংলা ⇄ English" (chevron) · Theme "Light · Sunset Studio" (chevron) · **Distribution Mode** (Owner/Both only, toggle ON) · **Notifications** (toggle ON) · Team Access (Owner/Both only, chevron) · **Logout** (red, at bottom).
   - Toggle: 44×24 pill, ON = orange track/knob left 23px, OFF = `#E3CDB4` track/knob left 3px, 0.25s transition. Toggles are live state.

---

## Screen 12 — Client Self-Booking (MOD-13, via "🔗 SELF-BOOKING" chip on Bookings)
1. "← BACK TO BOOKINGS" mono link.
2. **Public link bar** — dark card: "🔗 PUBLIC LINK" gold label · mono link field `clickerpro.app/book/lens-and-light` (frosted inset) · COPY (gold-tint) + WHATSAPP (green-tint) chips.
3. Grid `1fr 1.2fr`:
   - **"What clients see"** — a client-facing form preview card (deeper shadow): studio logo + name header, inputs (Your name, Phone), event-type chips (Wedding selected orange), "Preferred date" field with orange ▦, note textarea, full-width orange "Request Booking" button, footer "POWERED BY CLICKERPRO" (mono micro).
   - **Approval queue** ("2 pending") — request cards with 3px gold left border: avatar · name + "event · date · shift" · phone (mono); quoted client note in cream inset; actions: green "✓ Approve → Booking" / red-tint "✕ Reject" / green ✆ call square. Approve converts the request into a Pending booking (spec).

## Auth Overlay — Splash / Login / Role (MOD-01, MOD-02; opened via Settings → Logout)
Full-viewport fixed overlay (z-index 60) over everything: dark `#2B1D12` bg with two blurred glow blobs (orange top-right, gold bottom-left). Centered 440px column with **step dots** (active dot stretches to 26px orange pill; dots clickable) and a "SKIP — BACK TO APP" mono link at the bottom.
- **Step 1 Splash**: 96px orange-gradient logo square (radius 26, big orange glow) with **1.2s overshoot pop-in** (spec: logo reveal 1.2s), wordmark Sora 800 34px, tagline, "Get Started →" orange pill.
- **Step 2 Login**: white card (radius 26, deep shadow): "Sign in", phone field with +880 prefix box, "OTP · sent ✓" label + 6 OTP boxes (first 3 filled: orange-tint bg, 1.5px orange border, mono orange digits), "Verify →" button, OR divider, Google / Email outline buttons.
- **Step 3 Role**: "How do you work?" heading on dark; 2×2 role cards — 👑 Owner / 📸 Both / 🗂 Manager / 🕊 Freelancer with one-line descriptions; unselected = frosted dark (`rgba(255,246,238,0.06)` bg, faint border), selected = cream bg + orange border; "Enter App →" pill returns to Dashboard.

## Roles (prop/state: `role` = owner | both | manager | freelancer)
Same layout for all roles; differences only:
- **Freelancer:** sidebar/team = "My Companies"; Quick Actions = Calendar/Company/Chat/Expense; right panel = My Earnings; user = Tanvir Ahmed (gmail).
- **Manager:** right panel finance replaced with hidden-income notice + dues.
- **Owner/Both:** full finance; Studio/Distribution/Team Access settings rows visible.

## Interactions & Behavior
- Sidebar nav click → switch screen (state), header title updates, right panel shows only on Dashboard, main column expands elsewhere.
- Dashboard "VIEW ALL →" → Bookings. Quick Action cards → their screens (Chat action → Team Chat).
- **"+ New Booking" (Bookings) → New Booking form. Clicking any booking row (Dashboard Today's Bookings, or Day/Night lists) → Event Details. Dashboard announcement card → Announcements. "🔗 SELF-BOOKING" chip (Bookings) → Client Self-Booking. Settings → Logout → Auth overlay. Bell → Notifications dropdown.**
- Finance tab bar switches between Overview / Expenses / Cash Flow / Petty Cash / Salary / Payouts (state).
- Event Details "⚡ Auto-generate Invoice" toggles the dark invoice panel.
- New Booking live state: shift pills, package tiles (auto-fill payment total/due), event-type chips, payment method chips, Outdoor toggle (expands fields), Chief toggle (reveals name field).
- Bookings status chips: single-select state. Settings toggles: live boolean state.
- All hover states listed per component (lifts −2 to −4px, tint fills, border→orange), `transition: all 0.2–0.25s`.

## Motion System (recreate exactly)
Easing: `cubic-bezier(0.2, 0.8, 0.2, 1)` (standard) and `cubic-bezier(0.34, 1.56, 0.64, 1)` (overshoot pop). All entry animations use `both` fill and replay on every screen switch (elements remount).
- `fadeUp`: opacity 0 + translateY(18px) → visible; 0.45–0.5s; section-level stagger 50ms steps (header 0s, then 0.05/0.10/0.15/0.20/0.25s).
- `slideIn`: opacity 0 + translateX(−14px) → 0; 0.4s; list rows stagger 50–60ms per row.
- `popIn`: scale 0.92 → 1; hero "03" uses overshoot easing at 0.25s delay; calendar cells 0.35s with 12ms/cell stagger.
- `barGrow`: scaleY 0→1 from bottom origin; 0.7s; 60–70ms stagger per bar.
- `pulse`: notification dot opacity 1→0.45→1, 2s infinite.

## State Management
- `screen`: 'dashboard' | 'bookings' | 'calendar' | 'finance' | 'team' | 'chat' | 'announcements' | 'packages' | 'settings' | 'newbooking' | 'eventdetails' | 'selfbooking' | 'auth' (sub-screens keep their parent nav item highlighted)
- `finTab`: 0–5 (Finance tabs) · `notifOpen`: boolean · `authStep`: 0–2 · `pickRole`: selected role card
- `form`: { shift, pkg, evType, method, outdoor, chief } — New Booking form state; package drives payment total (total − 25,000 advance = due)
- `invoiceOpen`: boolean (Event Details invoice panel)
- `role` (prop/config): drives labels, quick actions, right-panel variant, settings rows
- `statusChip` (Bookings filter index), `settingToggles` { distribution, notifications }
- Future data fetching: bookings, finance summaries, team, packages from Firestore (see architecture file, MOD-23 offline-first with Drift/SQLite on mobile).

## Assets
- No image assets. Fonts from Google Fonts: **Sora** (600–800), **DM Sans** (400–700), **Space Mono** (400/700), **Noto Sans Bengali** (400–700).
- Icons in prototype are unicode glyphs (◈ ▤ ▦ ৳ ◎ ❖ ⚙ ⌕ ☀ ☾ ✆ ›) — replace with a consistent outline icon set (e.g. Lucide/Phosphor), keep the circled-outline treatment in the sidebar.
- Currency symbol ৳ (Bengali Taka) must render — ensure Bengali font fallback.

## Files
- `ClickerPro Dashboard v2.dc.html` — the full hi-fi prototype (markup + inline styles + `Component` logic class with all data arrays)
- `support.js` — prototype template runtime (reference only, do not port)
- `App_Architecture_v12.html` — full product architecture spec v12 (roles, permission matrix, all modules MOD-01…65 + FL-01…12, UX decisions)
