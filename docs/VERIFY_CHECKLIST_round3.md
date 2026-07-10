# Verify Checklist — round-2/round-3 feedback (Graphy7)

Branch `fix/heaven-feedback-19-items`. সব কোড ✅ done, pushed. এই checklist =
**deploy-পরবর্তী device + browser verify**। ✅ mark করতে করতে যান।

---

## A. Backend deploy (cPanel/VPS — server-side, একবার)

git-pull করার পর server-এ:

```bash
php artisan migrate --force          # round-2 এর ৫টা + round-3 এর ২টা migration
php artisan config:cache             # আবশ্যক (cors.php * fallback, self-booking)
php artisan route:cache              # নতুন route: support/config + touch.active
php artisan view:clear               # landing.blade আপডেটের জন্য
```

- [ ] migrate সফল (users.last_active_at, waitlists.facebook_link কলাম এসেছে)
- [ ] `GET /api/support/config` 200 রিটার্ন করে (JSON: email/whatsapp)

## B. Admin panel সেটিং (Heaven নিজে — একবার)

- [ ] Settings → `support.whatsapp` = international number বসান (যেমন `8801XXXXXXXXX`)
      → নাহলে Help screen-এ WhatsApp button **hidden** থাকবে (item[14])
- [ ] দরকারে `support.email`-ও সেট করুন

## C. Web deploy (cPanel, docroot `~/clickerpro/web_app_public/`)

- [ ] নতুন Flutter web build আপলোড (`clicker_pro/build/web/` এর পুরো কনটেন্ট)
      — **`.htaccess` সহ** (SPA fallback; নাহলে `/book/<token>` ও deep-routes 404)
- [ ] landing css/blade আপডেট হয়েছে (git-pull + `view:clear`)

## D. Device verify — নতুন APK ইনস্টল করে

- [ ] [1] event-এর reminder OS notification আসে
- [ ] [3] booking list scroll smooth (jank নেই)
- [ ] [4] show-payment toggle কাজ করে (নতুন build-এ)
- [ ] [9] payment receipt tap → সরাসরি booking detail খোলে
- [ ] [13] (round-3 item — নতুন build-এ যাচাই)
- [ ] [14] Help → "Email us" mailto খোলে + WhatsApp button দেখায় (number সেট থাকলে)
- [ ] [16] PDF/ZIP export UI থেকে সরানো; CSV / Google Sheets export আছে
- [ ] [17] Calendar "Sync All Confirmed" → **share sheet আসে না**, সরাসরি device
      calendar-এ লেখে; confirmed booking calendar-এ দেখায়
- [ ] backup/restore ও prayer module UI থেকে সরানো (fake ছিল)
- [ ] [19] booking/payment create/update/delete → Audit Log screen-এ entry আসে
      (backend deploy-এর পর কাজ করবে)

## E. Web browser verify (`flutter run -d chrome`, optional কিন্তু ভালো)

Sidebar-এ নতুন entry সব খোলে কিনা:

- [ ] Chat / Delivery / Reminders / Performance / Cash Flow / Rent / Follow-up /
      Announcements / Broadcasts / Re-edit / Calendar Sync — প্রতিটা খোলে
- [ ] top-bar search icon → GlobalSearchSheet খোলে
- [ ] top-bar bell → notifications খোলে
- [ ] প্রতিটা screen light theme-এ ঠিক দেখায়

> ⚠️ Known edge case: Noir (dark) থিমে web content dark হলে WebNavShell chrome/
> top-bar hardcoded light → mismatch। Default (Graphy7 light) থিমে সমস্যা নেই।

---

### Build কমান্ড (রেফারেন্স)

```bash
# Web
cd clicker_pro
flutter build web --release \
  --dart-define=API_BASE_URL=https://api.deyalghori.com \
  --dart-define=WEB_BASE_URL=https://app.deyalghori.com

# APK
flutter clean            # release build-এ প্রতিবার আবশ্যক (stale AOT bug)
flutter build apk --release --dart-define=API_BASE_URL=https://api.deyalghori.com
```
