# Handoff: ClickerPro — Web App (Studio Owner Dashboard)

## Overview
A desktop web dashboard for photography studio owners to run their business: bookings, calendar, clients, packages, invoicing, expenses, freelancer payouts, cash flow, team members, an internal team chat, and studio announcements. Sidebar-driven single-page app with 13 views.

## About the Design Files
The files in this bundle are **design references created in HTML** — high-fidelity prototypes showing the intended look, content, and interaction points. They are **not production code to copy directly**. The task is to **recreate these designs in the target codebase's existing environment** (React, Vue, etc.) using its established component patterns, state management, and data layer — or, if no environment exists yet, choose the most appropriate modern web framework (React + Tailwind/CSS-in-JS is a safe default) and implement the designs there.

- `ClickerPro-Web-Visual-Reference.html` — open in any browser (works offline). This is the exact target look — all 13 views are live in one file; click sidebar items to switch views.
- `ClickerPro-Web-Design-Source.dc.html` — the underlying markup/logic source, useful for reading exact structure, inline styles, and the mock data shape per view if the visual reference isn't enough.

## Fidelity
**High-fidelity (hifi).** Colors, typography, spacing, and copy are final. Recreate pixel-close using the codebase's existing component library where one exists; otherwise implement fresh using the tokens below.

## Global Layout
- Full-height app shell: fixed **256px dark sidebar** (`#161513`) on the left + fluid main content area on the right. `display:flex; height:100vh; overflow:hidden` on the root — sidebar doesn't scroll, main content scrolls independently.
- **Header bar** (64px tall) inside the main column: sticky, `rgba(251,250,247,0.85)` with `backdrop-filter: blur(8px)`, bottom border `1px solid rgba(0,0,0,0.06)`. Contains: search field (320px, pill-ish 12px radius), spacer, primary "New Booking" button, notification bell with unread dot.
- **Main scroll area**: padding `26px 28px 44px`.
- Page pattern used on every view: `<h1>` (31px/800/-0.035em) + one-line subtitle (15px, `#7A786F`), primary action button top-right, then content grid/cards below.

## Design Tokens

### Colors
- Background (main): `#FBFAF7`
- Sidebar: `#161513`, sidebar text (inactive) `#B8B4AC`, sidebar section labels `#6E6961`
- Card surface: `#FFFFFF`, card border `rgba(0,0,0,0.06)`, card radius `20px`
- Text primary: `#1A1A18`; text secondary: `#7A786F` / `#9A988F`
- Brand orange (primary accent, CTAs, active nav, links): `#E2620E`; hover/gradient pair with `#F0772A` → `#D6520A`
- Avatar palette (rotates per record): `#E2620E, #00898B, #3541AF, #6D5BD0, #C99A2E, #2F8F6B, #B84E0A`
- Status pills (bg/fg pairs): Confirmed `#FBEBDE`/`#C0530B` · Pending `#FBF1D6`/`#9C7614` · Delivered/Paid/Active `#E1F0E9`/`#2F8F6B` · Cancelled/Overdue `#F1E3E1`/`#B0453A` · Waitlist same as Pending · Off `#EFEDE8`/`#8A887F`
- Semantic: success/money-in `#2F8F6B`, error/money-out `#B0453A`, info blue `#3541AF`

### Typography
- UI font: **Hanken Grotesk** (400/500/600/700/800)
- Monospace (labels, tags, dates, ⌘K hint): **IBM Plex Mono** (400/500/600)
- Icons: **Material Symbols Rounded** (via Google Fonts, variable)
- Page title: 31px / 800 / letter-spacing -0.035em
- Card big numbers (KPIs): 30–37px / 800 / -0.035em
- Body text: 13.5–14px / 400–600
- Micro-labels (column headers, eyebrow tags): 9.5–11px, mono, letter-spacing 0.12–0.2em, uppercase, `#9A988F`

### Spacing & Shape
- Card radius: 20px (large), 12–14px (nested rows/inputs/buttons), 999px (pills/badges)
- Grid gaps: 16px standard between cards; 14px within table rows
- KPI card grids: `grid-template-columns: repeat(4, 1fr)` (Dashboard, Invoices)
- Two-column split (main + side widget): `1.62fr 1fr`

## Views (13)

### 1. Dashboard (default view)
- Greeting header + Export button.
- KPI row: hero revenue card (gradient orange `#F0772A→#D6520A`, ৳ value, trend chip) + 3 white KPI cards (Bookings, Payouts Due, Delivered) each with icon chip, big number, sub-caption.
- Two-column: **Revenue Overview** line chart (inline SVG area+line chart, 10-month trend, orange stroke/fill) | **Upcoming Events** list (date block + title + colored dot).
- Second row, same 1.62:1 split: **To-Do** widget (checkbox rows, priority pill, "open" counter, add-task affordance) | **Reminders** widget (icon-chip rows with title + relative time).

### 2. Calendar
- Month header with prev/next chevrons and "July 2026" label.
- Legend: Shoot (orange dot), Holiday (tinted swatch), Bangla date convention note.
- 7-col grid, day-of-week header (mono, uppercase), then day cells (min-height 92px) each showing: day number (western) + Bangla numeral, optional holiday name (red-tinted cell), optional colored event chip(s) (e.g. "Wedding", "Corporate").
- Today's cell gets an orange border; Friday columns get a faint tint.

### 3. Bookings
- Header + "New Booking" CTA.
- Filter/tab row (All/Confirmed/Pending/Delivered/Cancelled, pill tabs, active = orange fill) + search field.
- Table card: header row (CLIENT/EVENT/DATE/PACKAGE/AMOUNT/STATUS + kebab column) then data rows — avatar-initial chip + name/email, event type, date, package tier, amount (right-aligned bold), status pill, overflow menu icon.
- Footer: "Showing 1–8 of 86" + numbered pagination.

### 4. Clients
- Header ("128 clients · 3 on waitlist") + Add Client CTA.
- Table: CLIENT (circular avatar + name/email) / PHONE (mono) / SESSIONS (centered count) / TOTAL SPENT (bold ৳) / STATUS pill (VIP/Active/Waitlist).

### 5. Packages
- Header + New Package CTA.
- 3-column card grid. Each card: mono eyebrow tag (STUDIO/EVENTS/BRANDS/FAMILY/PORTRAIT), package name, big orange price, divider, feature checklist (green check icons), footer row with "booked" count + Edit button. The "popular" package gets a 2px orange border + a "POPULAR" pill top-right.

### 6. Invoices
- Header + New Invoice CTA.
- 4 KPI cards: Total Revenue, Outstanding, Paid this month, Expenses (each with icon chip + trend-tinted number).
- Table: INVOICE (mono id) / CLIENT / DATE / AMOUNT / STATUS pill (Paid/Pending/Overdue).

### 7. Expenses & Petty Cash
- Header + Log Expense CTA.
- Left column (stacked): Petty Cash Balance card (indigo gradient `#3541AF→#242E85`, big ৳ balance + refill note) and Spent this month card (white, red number).
- Right column: Recent Expenses list card — icon chip (category-colored) + title/category+date + red "−amount".

### 8. Freelancer Payouts
- Header ("6 freelancers awaiting payment · ৳1.42L total") + Pay All CTA.
- List card: rows of circular avatar + name/role+shoot-count + right-aligned bold amount + dark "Pay" button per row.

### 9. Cash Flow
- 3 summary cards: Money In (green), Money Out (red), Net Balance (orange gradient).
- Transactions list: icon chip (green in / red out direction arrows) + title + date, amount colored green/red with +/− sign.

### 10. Team Members
- Header ("9 members · 6 photographers, 2 editors, 1 coordinator") + Invite Member CTA.
- 3-column card grid: rounded-square avatar + name/role + status pill (Active/On shoot/Off today), then a 3-stat row (Shoots, Rating, This-week load) with dividers.

### 11. Team Chat
- Two-pane: 260px channel list (channels + 1:1 DMs, unread-count badge, active channel highlighted) + main thread pane.
- Thread header: channel avatar + name + "members · online" status.
- Message list: left-aligned bubbles for others (grey, avatar + name label above first message in a run) vs right-aligned bubbles for "me" (orange, no avatar); timestamp under each bubble.
- Composer: attach icon + text input placeholder + orange circular send button.

### 12. Announcements
- Header + Post Update CTA.
- Feed of cards (max-width 760px), newest first. Pinned posts get a 3px orange left-edge bar and a "PINNED" pill. Each card: author avatar/name/role/time, title, body copy, footer with like/comment counts (icon + number, no interaction shown).

### 13. Settings
- Profile card: large avatar-initial chip, name/email/role, Edit Profile button.
- Settings list card: icon chip + title/subtitle rows, each with either a toggle switch (Push Notifications on, Dark Mode off) or a chevron (Studio Profile, Billing & Plan, Roles & Permissions, Sign Out).

## Interactions & Behavior
- **Sidebar navigation** is the only routing mechanism in the prototype — clicking a nav item swaps the active view in the main pane (no page reload); active item gets solid orange background + white icon/text + weight 700, others are transparent/grey/weight 500. Recreate as real client-side routing (React Router or equivalent) rather than local state, so views are deep-linkable.
- Badges next to nav labels (Bookings "14", Payouts "6", Team Chat "3") are live counts — wire to real pending/unread counts.
- "New Booking", "Add Client", "New Package", "New Invoice", "Log Expense", "Pay All"/"Pay", "Post Update", "Invite Member" buttons are all placeholders in the prototype (no click behavior) — each needs a real modal/flow or navigation in the production build.
- Table row overflow ("⋮") menus and Edit/Manage links are placeholders — needs dropdown/detail-view wiring.
- Settings toggles (Push Notifications, Dark Mode) need real persisted state.
- Chat composer send button and message list need to be backed by a real message store; the prototype's "me" vs "other" bubble alignment and grouped-name-above-first-message-in-a-run pattern should be preserved.
- Calendar prev/next chevrons need real month navigation; the Bangla-numeral day corner and holiday highlighting should be data-driven from a Bangladesh holiday calendar, not hardcoded.
- No responsive/mobile layout was designed for this view — it is desktop/wide-viewport only. If the target needs mobile, ask before designing collapse behavior for the sidebar and tables.

## State Management (suggested shape)
- `currentView`: one of `dashboard | calendar | bookings | clients | packages | invoices | expenses | payouts | cashflow | members | chat | announce | settings`
- Per-view collections mirror the mock arrays in the `.dc.html` source's logic class (`kpis`, `events`, `todos`, `bookings`, `clients`, `packages`, `invoices`, `expenses`, `payouts`, `cashflow`, `team`, `channels`, `messages`, `announcements`, `settings`) — treat each as an API-backed list in production (loading/empty/error states not designed; ask before adding).
- Chat: `activeChannelId` + messages keyed by channel.
- Settings: boolean flags per toggle row.

## Design Tokens Summary (for quick reference)
- Primary: `#E2620E` · Primary gradient: `#F0772A → #D6520A`
- Ink: `#1A1A18` · Muted: `#7A786F` / `#9A988F`
- Surface: `#FBFAF7` (app bg) / `#FFFFFF` (cards) · Sidebar: `#161513`
- Fonts: Hanken Grotesk (UI), IBM Plex Mono (labels/mono data), Material Symbols Rounded (icons)
- Radius scale: 999px (pill) · 20px (card) · 11–14px (control) · 7–10px (chip/icon-box)

## Assets
- No raster images — all icons are the Material Symbols Rounded icon font; the aperture logomark in the sidebar is inline SVG (6-path orange aperture, colors `#F9A52E, #F4881C, #EA7414, #E2620E`). Copy the SVG path data directly from `ClickerPro-Web-Design-Source.dc.html` if the target needs the mark as a component/asset.
- Currency formatting uses the Bengali Taka sign (৳) and Bengali-style lakh notation (e.g. ৳9.24L = 924,000) — preserve this formatting convention, it's a deliberate localization choice for a Bangladeshi audience.

## Files
- `ClickerPro-Web-Visual-Reference.html` — open directly in a browser; interactive click-through of all 13 views (source of truth for visuals).
- `ClickerPro-Web-Design-Source.dc.html` — annotated source with inline styles and the mock-data shape per view (source of truth for structure/content).
