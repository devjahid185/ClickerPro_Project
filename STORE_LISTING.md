# Clicker Pro — Store Listing (Play Store + App Store)

> Everything you need to publish. Copy-paste ready. App version **3.8.1 (build 39)**.

## App identity (verified in code)

| Field | Value |
|-------|-------|
| App name (store) | Clicker Pro — Studio Manager |
| Android applicationId | `com.clickerpro.app` |
| iOS bundle ID | `com.clickerpro.app` (fixed from `com.example.*`) |
| Version | 3.8.1 |
| Build / versionCode | 39 |
| Category | Business / Photography |
| Content rating | Everyone / 4+ |
| Support email | eventfile.nhh@gmail.com |

---

## App Title (Play 30 chars / App Store 30 chars)

```
Clicker Pro - Studio Manager
```

## Subtitle (App Store, 30 chars)

```
Bookings, invoices & team
```

## Short / Promo Description (Play 80 chars)

```
Manage bookings, clients, invoices & team for your photography studio.
```

## Full Description (Play 4000 / App Store 4000 chars)

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

Built for professional photographers in Bangladesh and beyond.
```

## Keywords (App Store, 100 chars, comma-separated)

```
photography,studio,booking,invoice,client,crm,photographer,schedule,team,payment,wedding,event
```

---

## Screenshots

**Play Store:** min 2, max 8. Phone: 1080×1920 or 1080×2400 (9:16).
**App Store:** required 6.7" (1290×2796) and 6.5" (1242×2688); 5.5" optional.

Capture these 8 screens (app is already installed on both phones):

1. Dashboard — booking count, sync status, quick actions
2. Booking List — client name + status pills
3. Booking Detail — full info + payment section
4. New Booking form — date picker, event type, shift pills
5. Clients list — client cards
6. Invoice PDF preview
7. Reminders — list with type icons
8. Global Search — results grouped by type

### Screenshot command (device id from `flutter devices`)
```bash
# OnePlus IN2013 (Android 13):
adb -s a5178cb4 shell screencap -p /sdcard/s.png && adb -s a5178cb4 pull /sdcard/s.png screenshot1.png
# Infinix X6812 (Android 11):
adb -s 07302251CL004103 shell screencap -p /sdcard/s.png && adb -s 07302251CL004103 pull /sdcard/s.png screenshot1.png
```
> `adb` ships with the Android SDK platform-tools (already installed via Flutter).

---

## Graphics

| Asset | Size | Notes |
|-------|------|-------|
| App icon (Play) | 512×512 PNG | from `clicker_pro/assets/icon/app_icon.png` |
| App icon (iOS) | 1024×1024 PNG | from `clicker_pro/assets/icon/app_icon_ios.png` |
| Feature graphic (Play) | 1024×500 | orange #FF6B00 bg, white "Clicker Pro" (Poppins Bold), camera icon + "Studio Management, Simplified" |

Regenerate launcher icons: `cd clicker_pro && dart run flutter_launcher_icons`.

---

## Privacy Policy (REQUIRED by both stores — needs a public URL)

Host the text below and use the URL in both consoles.

- **Fastest:** GitHub Pages — new public repo `clickerpro-privacy`, add `index.html`, Settings → Pages → Deploy from main → URL `https://<user>.github.io/clickerpro-privacy`.
- **Or:** Notion page → Share → Publish to web → copy URL.
- **Or:** host on the live site, e.g. `https://deyalghori.com/privacy`.

```
Privacy Policy for Clicker Pro

Last updated: June 15, 2026

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
- You can request deletion of your account and all associated data by contacting us, or in-app via Settings → Account → Delete Account

CONTACT
For privacy questions: eventfile.nhh@gmail.com
```

> The app already has in-app account deletion (`/api/account/cancel-delete` + delete flow) — mention it in the Play "Data safety" form (account deletion supported).

---

## Build artifacts to upload

| Store | File | Build command |
|-------|------|---------------|
| Play Store | `ClickerPro-v3.8.1-39-release.aab` (root) | `cd clicker_pro && flutter build appbundle --release` |
| Direct / test | `ClickerPro-v3.8.1-39-release.apk` (root) | `cd clicker_pro && flutter build apk --release` |
| App Store | (build on a Mac) | `flutter build ipa --release` then upload via Xcode/Transporter |

Both Android artifacts are signed with `keystores/clicker_pro.jks` (creds in `clicker_pro/android/key.properties`). **Keep this keystore safe — losing it means you can never update the app on Play Store.**

---

## App Store extras (you'll be asked for these)

- **Apple Developer account** ($99/yr) + a **Mac with Xcode** to build the `.ipa` (iOS cannot be built on Windows).
- **App privacy details** (App Store "Nutrition Label"): collects Contact Info (email/name) and User Content (booking/client data), linked to identity, used for app functionality — not for tracking/ads.
- **Demo account** for Apple review: provide a test login (see DEVELOPER_GUIDE "Local setup & seed data").
- **Export compliance:** uses standard HTTPS only → answer "No" to custom encryption.

## Play Store extras

- **Google Play Console account** ($25 one-time).
- **Data safety form:** Contact info + app activity collected, encrypted in transit, account deletion available.
- **Target audience:** 18+ / business; not directed at children.
