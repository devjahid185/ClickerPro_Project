# Clicker Pro — Play Store Listing Copy

## App Details

- **Package ID:** `com.clickerpro.app`
- **Version:** 1.0.0 (versionCode 1)
- **Category:** Business / Photography
- **Content Rating:** Everyone

---

## App Title (30 chars max)

```
Clicker Pro - Studio Manager
```

## Short Description (80 chars max)

```
Manage bookings, clients, invoices & team for your photography studio.
```

## Full Description (4000 chars max)

```
Clicker Pro is the all-in-one studio management app for professional photographers and photography studio owners.

📅 BOOKINGS
• Create and manage photo sessions with full details — date, shift, venue, event type
• Offline-first: create bookings without internet, sync automatically when back online
• Track booking status from Inquiry → Confirmed → Shooting → Delivered

👥 CLIENT MANAGEMENT
• Maintain a complete client database with contact info, DOB, and anniversary dates
• Quickly search any client, booking, or team member from the global search bar

💸 PAYMENTS & INVOICES
• Record advance and final payments per booking
• Generate professional PDF invoices and share via WhatsApp or system share sheet
• Cash flow, petty cash, and salary sheet reports in PDF

📦 PACKAGES & PRICING
• Create reusable photography packages with base price, hours, and extra hour rate
• Assign packages to bookings or set custom pricing

👨‍💼 TEAM MANAGEMENT
• Add team members (photographers, editors) via invite code
• Assign staff to bookings with role and payout details
• Track individual task progress per shoot

🔔 REMINDERS
• Set payment, delivery, or feedback reminders per booking
• Choose WhatsApp or SMS channel

📋 WAITLIST
• Manage prospective clients whose preferred dates are full
• Track status: Waiting → Contacted → Booked

🔍 UNIVERSAL SEARCH
• Find any booking, client, or team member instantly

📤 EXPORT & SHARE
• Export invoices, earnings, salary sheets, and cash flow as PDF
• Share directly from the app

🌐 OFFLINE FIRST
• Bookings, clients, and payments work offline
• Smart sync with conflict detection when back online

---

Built for professional photographers in Bangladesh and beyond.
```

---

## Screenshots Required (Play Store)

Upload at least 2 screenshots (max 8). Recommended sizes: **1080×1920** or **1080×2400**.

Suggested screens to capture (run app on device, use `adb shell screencap`):

1. **Dashboard** — booking count, sync status, quick actions
2. **Booking List** — list of bookings with client name and status pills
3. **Booking Detail** — full booking info with payment section
4. **New Booking form** — date picker, event type, shift pills
5. **Clients list** — client cards
6. **Invoice PDF preview** — generated invoice
7. **Reminders screen** — reminder list with type icons
8. **Global Search** — search results grouped by type

### Screenshot command

```bash
adb -s a5178cb4 shell screencap -p /sdcard/s.png && adb -s a5178cb4 pull /sdcard/s.png screenshot.png
```

---

## Feature Graphic (1024×500 px)

Design a banner with:
- Orange background (#FF6B00)
- White "Clicker Pro" text (Poppins Bold)
- Camera icon + tagline: "Studio Management, Simplified"

---

## Privacy Policy

Play Store requires a Privacy Policy URL. Options:

### Option 1 — GitHub Pages (free, fast)
1. Create a public GitHub repo named `clickerpro-privacy`
2. Add `index.html` with the policy below
3. Enable GitHub Pages → Settings → Pages → Deploy from main
4. URL: `https://yourusername.github.io/clickerpro-privacy`

### Option 2 — Notion (free)
1. Create a Notion page with the policy text
2. Share → Publish to web
3. Copy the public URL

### Privacy Policy Text

```
Privacy Policy for Clicker Pro

Last updated: June 5, 2026

Clicker Pro ("we", "our", "the app") is a studio management tool for photography professionals.

DATA WE COLLECT
- Account information: email address, name, company name
- Booking data: client names, phone numbers, event details, payment records
- Usage data: app interactions stored locally on your device

HOW WE USE YOUR DATA
- To provide booking management, invoicing, and team coordination features
- Your data is stored on our server only when you are signed in and connected
- We do not sell or share your data with third parties

DATA STORAGE
- Data is stored locally on your device using an encrypted database
- When online, data syncs to our secure backend server
- You can request deletion of your account and all associated data by contacting us

CONTACT
For privacy questions: eventfile.nhh@gmail.com
```

---

## App Icon

Already generated at: `clicker_pro/assets/icon/app_icon.png`
Regenerate with: `dart run flutter_launcher_icons` (from `clicker_pro/`)

---

## Release APK

Already signed. Location: `clicker_pro/build/app/outputs/flutter-apk/app-release.apk`

Rebuild: `cd clicker_pro && flutter build apk --release`

Keystore: `keystores/clicker_pro.jks` (password in `clicker_pro/android/key.properties`)
