# Implementation Checklist — ClickerPro Web App

Work through this in order; check every box. The README.md holds full specs (tokens, per-screen anatomy, data). The prototype `ClickerPro Dashboard v2.dc.html` is the visual source of truth — open it in a browser and compare side-by-side as you build.

## Phase 0 — Setup
- [ ] Load Google Fonts: Sora (600/700/800), DM Sans (400–700), Space Mono (400/700), Noto Sans Bengali (400–700)
- [ ] Define all color tokens from README §Design Tokens (27 colors — copy exactly)
- [ ] Define radii, shadow, and spacing tokens
- [ ] Define motion primitives: fadeUp, slideIn, popIn, barGrow, pulse + the two cubic-bezier easings

## Phase 1 — Shell
- [ ] 3-column grid layout (248 / 1fr / 316, max 1440, gap 20) on cream `#FBF6F0`
- [ ] Dark sidebar: logo, avatar block w/ gold ring, role badge, 9 nav items with cream active pill (flush right edge, `border-radius:999px 0 0 999px`), Active Team avatars
- [ ] Shared header: dynamic title, date line, search pill, bell + pulsing dot
- [ ] Screen-switch state: right panel only on Dashboard; main column expands elsewhere; sub-screens (New Booking, Event Details, Self-Booking) keep parent nav highlighted
- [ ] Entry animations replay on every screen switch (remount)

## Phase 2 — Screens (compare each against prototype before moving on)
- [ ] 1. Dashboard: week strip, split hero (03 pop-in), delivered strip w/ bars, Today's Bookings rows, quick actions
- [ ] Dashboard right panel: Finance·July (role-aware variants!), Announcement card, mini calendar
- [ ] 2. Bookings: status chips, 🔗 SELF-BOOKING chip, + New Booking, Day|Night columns (mirrored borders + hover slide directions)
- [ ] 3. Calendar: month grid, event chips, MONTH/WEEK/DAY toggle, per-cell pop-in stagger
- [ ] 4. Finance — 6 tabs:
  - [ ] Overview (3 stat cards, income/expense chart, client dues w/ progress bars)
  - [ ] Expenses (summary tiles + list w/ receipt indicator + category tags)
  - [ ] Cash Flow (solid/hatched/tan bars, 3 months, PDF chip)
  - [ ] Petty Cash (opening/current balance, category pills, running balance)
  - [ ] Salary Sheet (7-col grid, PAY / PAID ✓ buttons, MARK ALL PAID)
  - [ ] Payouts (approve/reject rows, payment methods, pending total card)
- [ ] 5. Team: stat tiles, gold Chief card, member rows (status dots, role tags, call buttons)
- [ ] 6. Chat: header w/ online count, bubbles (me=orange right / others=white left), typing indicator, composer
- [ ] 7. Announcements: pinned dark post w/ read receipts + expiry, feed cards
- [ ] 8. Packages: 3 cards w/ colored top borders, struck prices, spec grids, Edit/Delete
- [ ] 9. Settings: dark profile hero, role-aware rows, live toggles, red Logout
- [ ] 10. New Booking: sticky save bar, Client, Schedule (shift pills, outdoor toggle→expand, conflict warning), Package selector→payment auto-fill, Team chips, Event Type chips, Payment (Total/Advance/Due + method chips). Freelancer variant: Booked By + Notes + 2-event limit
- [ ] 11. Event Details: orange hero, Client/Payment/Checklist cards, Assigned Team tiles, invoice panel (monospace block + COPY/WHATSAPP/MESSENGER)
- [ ] 12. Self-Booking: public link bar, client form preview, approval queue w/ Approve→Booking
- [ ] Auth overlay: splash (1.2s logo pop) → phone+OTP → role cards → Enter App; step dots; opened from Logout

## Phase 3 — Cross-cutting
- [ ] Notifications dropdown from bell (4 seeded items, quick-action chips)
- [ ] Role switching (owner / both / manager / freelancer) — verify all 6 role-dependent spots: sidebar label, user identity, quick actions, right panel, settings rows, New Booking form variant
- [ ] All hover states (lifts, tint fills, border→orange, slide directions)
- [ ] ৳ renders correctly everywhere (Bengali font fallback)

## Verification pass
- [ ] Click through every nav item + every entry point (VIEW ALL, quick actions, booking rows, announcement card, self-booking chip, logout)
- [ ] Toggle every role and re-check dashboard + settings + new booking
- [ ] Confirm no screen shows the right panel except Dashboard
