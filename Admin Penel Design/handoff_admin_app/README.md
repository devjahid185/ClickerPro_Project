# Handoff: Graphy7 Admin — Mobile App (Owner/Admin Control Panel)

## Overview
A dark-theme **mobile admin app** for a photography-studio owner to run the business from a phone: dashboard with approvals queue, bookings management with status actions, a booking review/approve/assign flow, finance with freelancer payouts, and team management. 5 screens, all designed at **390px width** (iPhone-class viewport).

Brand note: the product is being renamed **ClickerPro → Graphy7**. Use "Graphy7" for the app name; screens in the reference may still say ClickerPro in places — treat the name as Graphy7 everywhere.

## About the Design Files
These files are **design references created in HTML** — high-fidelity mockups showing the exact intended look. They are **not production code**. Recreate the designs in the target codebase's environment (Flutter, React Native, or web — ask the owner; a companion dark-theme user app for this product was previously specced for Flutter, see `handoff/CLICKERPRO_DARK_FLUTTER_SPEC.md` in the parent project if available).

- `Graphy7-Admin-Visual-Reference.html` — open in any browser, works offline. Shows all 5 phone screens side by side. This is the source of truth for visuals.
- `Graphy7-Admin-Design-Source.dc.html` — the underlying markup with every inline style; source of truth for exact spacing, colors, and content.

## Fidelity
**High-fidelity.** Colors, type, spacing, and copy are final. The mockup is static — every button/interaction listed below needs real wiring.

## Design Tokens

### Colors (dark theme)
- App background: `#060708` (page) / **screen background `#0C0E11`**
- Card surface: `#14171C`, nested/secondary surface `#1B1F26`
- Card border: `rgba(255,255,255,0.07)` (default), `rgba(255,255,255,0.08–0.09)` (nav/buttons)
- Text primary: `#EDF1EA` · secondary: `#9BA1AB` · muted/labels: `#5F6570`
- **Brand accent (lime): `#C8F252`** — primary buttons, active nav, highlights. Text on lime: `#0E1206`
- Semantic: warning/pending `#F5C044` · danger/overdue `#FF6E61` · success `#52E0A1` · purple accent `#A08CFF` · teal accent `#4FD0D2`
- Tinted chip backgrounds: accent color at 12–16% alpha (e.g. `rgba(200,242,82,0.12)`, `rgba(245,192,68,0.12)`, `rgba(255,110,97,0.14)`, `rgba(82,224,161,0.14)`, `rgba(160,140,255,0.14)`, `rgba(0,137,139,0.16)`)
- Avatar chips rotate through: lime, purple, teal, coral tints (bg = tint, fg = full accent)

### Typography
- UI font: **Space Grotesk** (400/500/600/700)
- Mono (eyebrow labels, stat captions, nav labels, tags): **JetBrains Mono** (400–700), uppercase, letter-spacing 0.1–0.16em
- Icons: **Material Symbols Rounded** (Google Fonts variable icon font); active nav icons use `font-variation-settings:'FILL' 1`
- Scale: hero number 36–40px/700/-0.03em · screen title 21–22px/700 · card title 14–15px/700 · body 12–13.5px · micro-labels 8.5–10px mono
- Currency: Bengali Taka `৳` with lakh notation (৳1.4L = 140,000) — deliberate localization, preserve it.

### Shape & Spacing
- Phone frame: 390px wide, radius 36px (device look — in production this is just the screen)
- Card radius: 16–22px · buttons/inputs 11–14px · chips/pills 7–10px · bottom nav 24px
- Screen horizontal padding: 18px · card padding 12–20px · gaps 9–12px between cards
- Status bar mock (9:41 + icons) is decoration — use the platform's real status bar.

### Bottom navigation (identical on all tab screens)
Floating pill bar (`#14171C`, radius 24, 14px inset from screen edges): 5 items — Home (grid_view), Bookings (event_note), center raised **lime FAB** (54px, radius 18, `add` icon, lifted −16px with lime glow shadow), Finance (account_balance_wallet), Team (groups). Active item: lime icon (filled variant) + lime mono label; inactive: `#5F6570`. Labels are 8.5px JetBrains Mono.

## Screens (5)

### 1. Dashboard (Home tab)
- Header: mono eyebrow "ADMIN · CLICKER STUDIO" (→ rename to GRAPHY7 STUDIO), "Hi, Rahim" title, notification bell with red count badge (5), lime avatar chip "RH".
- **Revenue hero card**: solid lime `#C8F252`, dark text, mono label "REVENUE · JULY", 40px amount ৳9,24,000, trend row (trending_up icon + "12.5%" + "vs June"), decorative translucent circle top-right, lime glow shadow.
- **Stat trio** (3-col grid): Bookings 48 (+8 new, green), Payouts ৳1.4L (coral number, "6 pending"), Delivered 132 ("94% on-time", green).
- **Needs approval** section: header with red count badge (3) + "VIEW ALL" mono link. Cards: avatar chip + client name + "Wedding · Jul 12 · ৳85,000" + yellow "NEW" tag; below, a 2-button row — lime **Approve** (check icon) + dark **Decline**.
- **Recent bookings** card: 3 rows (avatar, name, type·date, bold amount, status pill Pending/Done/Confirmed).

### 2. Bookings (Bookings tab)
- Header: "Bookings" + lime count chip "86" + tune (filter) icon.
- Search field (dark card, search icon, placeholder "Search by client or venue…").
- Filter chip row: active chip is **yellow filled** "Pending · 3"; others outlined (All, Confirmed, Delivered).
- Booking cards (4 states shown):
  - **Pending** (yellow-tinted border `rgba(245,192,68,0.28)`): client row + amount + Pending pill, then action row — lime **Confirm** button (flex-1) + 2 square icon buttons (chat green, more_horiz grey).
  - **Confirmed**: client row + Confirmed pill; footer row (divider top) with overlapping assignee avatars + "2 assigned" + lime "Manage" link.
  - **Delivered**: green pill; footer "Delivered · paid in full" + lime "Invoice" link.
  - **Cancelled** (coral-tinted border): struck-through amount + coral Cancelled pill.

### 3. Review Booking (approval detail — pushed screen, no bottom nav)
- Top bar: back arrow + "Review booking" + more_horiz.
- Summary card (yellow-tinted border): "PENDING APPROVAL" yellow tag + "Day shift" dot label; client name 24px; "Wedding · Platinum · Sun, Jul 12 · 12–5 PM"; location row (lime pin icon + venue).
- **Set status** segmented control: 3 segments (Pending [active, yellow fill, dark text] / Confirmed / Delivered) in a dark track.
- **Assign team** cards (one per role): role header (icon + "Photographers" + count), then chip row — assigned members as lime/purple tinted chips with × remove, plus a dashed "+ Add" chip. Two cards shown: Photographers (Zahid, Rafi) and Cinematographer (Sumon).
- **Payment summary** card: 3-col TOTAL ৳85,000 / ADVANCE ৳30,000 (green) / DUE ৳55,000 (coral).
- Primary actions: full-width lime **"Approve & assign"** (verified icon, lime glow); below, half-width **Edit** (dark) + **Decline** (coral-tinted).

### 4. Finance (Finance tab)
- Header: "Finance" + Monthly/Yearly segmented toggle (lime active).
- **Net profit hero** (lime card): "NET PROFIT · JULY" + ৳7,14,000 + INCOME/EXPENSE sub-columns.
- **Freelancer payouts** section: header with red count badge (6) + total ৳1,42,000 in coral. Rows: circular avatar + name + "role · N shoots" + bold amount + small lime **Pay** button per row.
- Full-width lime **"Pay all — ৳1,42,000"** button (account_balance icon).
- **Who owes you** section: header + "REMIND ALL" mono link; rows of client + event·date + coral due amount.

### 5. Team (Team tab)
- Header: "Team" + lime count chip "9" + lime **Invite** button (person_add icon).
- Workload trio (3-col): SHOOTERS 6 / EDITORS 2 / ON SHOOT 1 (yellow number).
- Member cards: rounded-square avatar chip + name + role + status pill (Active green / On shoot yellow); footer stat row (divider top): SHOOTS / RATING / THIS WK (yellow) + lime **Assign** link.

## Interactions to Implement (mock is static)
- Bottom nav switches tabs; center FAB opens a "new booking" flow (not designed — ask before designing).
- Approve/Confirm: moves booking Pending → Confirmed, updates counts (nav badge, filter chips, dashboard queue).
- Decline/Cancel: prompts for confirmation, sets Cancelled state (struck amount, coral pill).
- Review screen: segmented status control sets status; team chips add/remove members per role; "Approve & assign" commits status + assignments together.
- Pay / Pay all: per-freelancer and bulk payout actions — need confirmation + success state (not designed).
- Notification bell, VIEW ALL, Manage, Invoice, REMIND ALL, Invite, Assign, filter chips, search — all live targets, wire to real lists/flows.
- Badge counts (bell 5, approvals 3, payouts 6) are live data.

## Assets
- No raster images. Icons = Material Symbols Rounded font. Avatars are initial chips (tinted bg + accent fg).
- Logo: use the **Graphy7** mark (see `Graphy7 Logo.dc.html` / `Graphy7 Logo Gallery.dc.html` in the parent project) — orange aperture with negative-space 7. Note the admin app itself is lime-accented; the logo appears only on splash/login (not designed — ask).

## Files
- `Graphy7-Admin-Visual-Reference.html` — offline browser preview of all 5 screens (visual source of truth).
- `Graphy7-Admin-Design-Source.dc.html` — full markup with inline styles (structure/spacing source of truth).
