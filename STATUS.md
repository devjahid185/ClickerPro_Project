# ClickerPro — Project Status & Remaining Work

> সর্বশেষ আপডেট: 2026-06-08
> এই ফাইলটা হলো "কী বাকি আছে" এর একমাত্র সত্য তালিকা। নতুন কাজ শেষ হলে এখানে ✅ মার্ক করো।

---

## 🟢 চালু করার নিয়ম (3 server)

```
Terminal 1:  cd laravel_backend && php artisan serve --port=5000
Terminal 2:  cd web_app && npm run dev          # → http://localhost:3000
Terminal 3:  cd admin_panel && npm run dev      # → http://localhost:3001
```

**Login:**
- Owner: `owner@test.com` / `Test@1234`
- Admin: `admin@clickerpro.app` / `Admin@1234`

**Sample data:** `cd laravel_backend && php artisan db:seed --class=SampleDataSeeder`

---

## ✅ সম্পূর্ণ হয়েছে (DONE)

### Backend (Laravel 12 + PostgreSQL, port 5000)
- [x] ৩৭+ controller, সব auth/booking/finance/team/gear endpoint
- [x] petty-cash, followups, freelancer (blackouts/leaves/work-history/earnings) — নতুন
- [x] Admin: stats, analytics, bookings, payments, files, 2FA (TOTP), user role/plan/suspend
- [x] Laravel `{data}` wrapper, Sanctum token auth

### Web App (Next.js, light theme, port 3000) — ২৬ page
- [x] Dashboard, Bookings (+detail), Clients (+detail), Calendar, Search
- [x] Packages, Waitlist, Finance, Invoices (+detail), Payments, Expenses
- [x] Petty Cash, Freelancer (4 tab), Team, Gear, Rental, Chat, Reports
- [x] Reminders, Follow-ups, Support, Notifications, Settings (5 tab)
- [x] Public booking page `/book/[token]`
- [x] Light theme (সাদা card + orange accent)
- [x] Mobile responsive (hamburger drawer < 900px)

### Admin Panel (Next.js, port 3001) — ১৭ page
- [x] সব ১৭ page browser-verified, 0 error
- [x] users, businesses(studios), bookings, payments, finance, analytics
- [x] broadcasts, support, coupons, audit, security(2FA), settings, subscription, files

### Landing Page (dark theme)
- [x] Hero (blade animation, সাদা text)
- [x] Features, App Preview, Download, Pricing
- [x] How It Works, Testimonials, FAQ, CTA band — নতুন

### Mobile App (Flutter) — ৩৭ module
- [x] সব core feature (bookings 63 API call, freelancer 29, expenses 15...)
- [x] petty_cash + followup এখন backend-wired (আগে local ছিল)

---

## ✅ P1/P2/P3 — সম্পন্ন হয়েছে (2026-06-08)

### P1 — Mobile (সব done)
- [x] **Mobile finance** — real income/expense/net-profit band যোগ (profitLossProvider API)
- [x] **Mobile security** — password change + 2FA toggle এখন backend-wired (`/api/auth/change-password`, `/api/security/2fa/*` user-level)
- [x] **Mobile backup + data_export** — যাচাই: আগে থেকেই কার্যকর (backup=device-local file by design, export=real data→CSV)। wiring লাগেনি।
- [x] Fixed: `change-password` backend এখন camelCase + snake_case দুটোই নেয়

### P2 — Web + Mobile (সব done)
- [x] **Web Onboarding** — `/app/onboarding` setup checklist (profile/client/package/booking/team progress)
- [x] **Web Announcements** — `/app/announcements` (broadcasts + NEW badge)
- [x] **Web Activity** — `/app/activity` (My Activity timeline, `/api/my-activity`)
- [x] **Web Help** — `/app/help` (FAQ accordion + Contact cards)
- [x] **Freelancer Badges** — freelancer page এ ৫ম tab (derived from completed jobs)
- [x] **Mobile onboarding** — যাচাই: pure UI flow (intro/language/splash), backend লাগে না

### P3 — done যা সম্ভব
- [x] **Landing contact form** — `/api/contact` public endpoint + form section
- [x] **crash_reporting** — backend-wired (`/api/crash-reports` + table)

---

## ⬜ এখনো বাকি — শুধু external credentials/account লাগে (কোড রেডি)

> এগুলো কোডের কাজ শেষ — শুধু আপনার paid account/credentials দিলে চালু হবে।
> Template রেডি: `laravel_backend/.env.production.example`

- [ ] **Real device test** — Flutter app আসল ফোনে নতুন Laravel backend এর সাথে (আপনাকে `flutter run` করতে হবে)
- [ ] **Push notification** — Firebase FCM service-account JSON [NEEDS FIREBASE ACCOUNT]
- [ ] **calendar_sync** — Google Calendar API credentials [NEEDS GOOGLE CLOUD]
- [ ] **whatsapp** — WhatsApp Business API [NEEDS META BUSINESS ACCOUNT]
- [ ] **Production deploy** — hosting + domain [NEEDS VPS/CLOUD + DOMAIN]
- [ ] **Real email** — SMTP/SES credentials [NEEDS EMAIL SERVICE]
- [ ] **Cloud file upload** — S3/Spaces key [NEEDS AWS/DO ACCOUNT]
- [ ] **Payment gateway** — bKash/Nagad merchant API [NEEDS MERCHANT ACCOUNT + APPROVAL]

### বাদ রাখা (intentional)
- **Landing light version** — আপনি dark রাখতে বলেছেন
- **Freelancer check-in (GPS)** — mobile-only feature, web এ GPS attendance অপ্রাসঙ্গিক
- **home_widget, performance** — platform-specific, already কার্যকর

---

## 📌 গুরুত্বপূর্ণ নোট
- **Theme:** web+admin = light, landing = dark
- **"Studio" শব্দ:** সব দৃশ্যমান জায়গা থেকে বাদ → "Business"/"Workspace"/"Company"
- **Playwright দিয়ে web test করো না** — node_modules+.next নষ্ট করে। বদলে `npm run build` + curl ব্যবহার করো
- Production deploy template: `laravel_backend/.env.production.example`
- বিস্তারিত technical মেমরি: `.claude/.../memory/project_servers_and_seed.md`
