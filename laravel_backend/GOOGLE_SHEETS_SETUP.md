# 📊 Google Sheets — Booking Auto-Update সেটআপ গাইড

> নতুন booking হলে সেটা স্বয়ংক্রিয়ভাবে আপনার Google Sheet-এ একটা নতুন row হিসেবে যুক্ত হবে।
> এই গাইডটা একদম শুরু থেকে, ধাপে ধাপে — coding জানার দরকার নেই।

---

## 🔧 যা যা লাগবে
- একটা Google account
- আপনার Laravel সার্ভারে (cPanel) ফাইল আপলোড করার access
- ~15 মিনিট

---

## ধাপ ১ — Google Sheet তৈরি করুন

1. [sheets.google.com](https://sheets.google.com) এ যান → নতুন একটা blank sheet বানান।
2. নাম দিন, যেমন: **Clicker Pro Bookings**
3. নিচের tab-এর নাম **`Bookings`** রাখুন (ডিফল্ট "Sheet1" থাকলে rename করুন — ডাবল ক্লিক করে)।
4. প্রথম row-তে (header) এই কলামগুলো লিখুন (A1 থেকে শুরু — ঐচ্ছিক কিন্তু সুন্দর দেখায়):

   | A | B | C | D | E | F | G | H | I | J | K | L | M |
   |---|---|---|---|---|---|---|---|---|---|---|---|---|
   | ID | Created | Title | Type | Client | Phone | Date | Shift | Venue | Status | Price | Advance | Due |

5. ব্রাউজারের URL দেখুন — এমন হবে:
   `https://docs.google.com/spreadsheets/d/`**`1A2B3C...XYZ`**`/edit`
   মাঝের ঐ লম্বা অংশটাই আপনার **Sheet ID**। কপি করে রাখুন।

---

## ধাপ ২ — Google Cloud Service Account তৈরি

1. [console.cloud.google.com](https://console.cloud.google.com) এ যান (Google account দিয়ে লগইন)।
2. উপরে **project dropdown → New Project** → নাম দিন `clicker-pro-sheets` → Create।
3. বাঁ পাশের মেনু (☰) → **APIs & Services → Library**।
4. সার্চ করুন **Google Sheets API** → ক্লিক করুন → **Enable**।
5. আবার ☰ → **APIs & Services → Credentials**।
6. উপরে **+ CREATE CREDENTIALS → Service account**।
   - Name: `clicker-booking-writer` → Create and Continue → Done (role দরকার নেই)।
7. তৈরি হওয়া service account-এ ক্লিক করুন → উপরে **KEYS** tab → **ADD KEY → Create new key → JSON → Create**।
8. একটা **`.json`** ফাইল ডাউনলোড হবে। **এটা খুব গুরুত্বপূর্ণ ও গোপন** — নিরাপদে রাখুন।
9. সেই service account-এর **email** কপি করুন (দেখতে এমন: `clicker-booking-writer@clicker-pro-sheets.iam.gserviceaccount.com`)।

---

## ধাপ ৩ — Sheet টা service account-কে share করুন

1. ধাপ ১-এর Google Sheet খুলুন → উপরে ডানে **Share**।
2. ধাপ ২.৯-এর service account **email** পেস্ট করুন।
3. **Editor** access দিন → **Send/Share**।

> এই ধাপটা না করলে অ্যাপ sheet-এ লিখতে পারবে না (403 error)।

---

## ধাপ ৪ — JSON key সার্ভারে আপলোড

1. cPanel → **File Manager** খুলুন।
2. Laravel ফোল্ডারে যান: `/home/deyalgho/clickerpro/laravel_backend/storage/`
3. সেখানে ধাপ ২.৮-এর `.json` ফাইলটা আপলোড করুন।
4. নাম সহজ করুন, যেমন: `google-sheets-key.json`
5. পুরো path টা হবে:
   `/home/deyalgho/clickerpro/laravel_backend/storage/google-sheets-key.json`

> ⚠️ এই ফাইলটা `storage/`-এ রাখুন (public_html-এ নয়), যাতে কেউ ব্রাউজার দিয়ে ডাউনলোড করতে না পারে।

---

## ধাপ ৫ — .env এ ৩টা লাইন যোগ

cPanel → File Manager → Laravel ফোল্ডারের **`.env`** ফাইল edit করুন → একদম নিচে যোগ করুন:

```env
GOOGLE_SHEETS_CREDENTIALS=/home/deyalgho/clickerpro/laravel_backend/storage/google-sheets-key.json
GOOGLE_SHEETS_ID=এখানে_ধাপ_১.৫_এর_Sheet_ID_বসান
GOOGLE_SHEETS_TAB=Bookings
```

Save করুন।

---

## ধাপ ৬ — Config cache রিফ্রেশ

cPanel → **Terminal** এ:

```bash
cd /home/deyalgho/clickerpro/laravel_backend
php artisan config:clear
```

---

## ✅ ধাপ ৭ — টেস্ট

1. মোবাইল অ্যাপ থেকে একটা **নতুন booking** তৈরি করুন।
2. Google Sheet-এ গিয়ে দেখুন — একটা নতুন row স্বয়ংক্রিয়ভাবে এসেছে। 🎉

**না এলে কী করবেন:** cPanel Terminal-এ এই command দিয়ে error দেখুন:
```bash
tail -50 /home/deyalgho/clickerpro/laravel_backend/storage/logs/laravel.log
```
"GoogleSheets" লেখা কোনো warning থাকলে — সাধারণত (১) Sheet share করা হয়নি (ধাপ ৩), বা (২) path/ID ভুল (ধাপ ৫)। আমাকে error-টা দেখালে ঠিক করে দেব।

---

## 📌 গুরুত্বপূর্ণ নোট

- **Sheet বন্ধ থাকলেও booking কাজ করবে** — যদি Google কোনো কারণে fail করে, booking তবু সেভ হবে, শুধু sheet-এ row যাবে না (পরে আবার চেষ্টা করলে যাবে)। কোনো crash হবে না।
- এই মুহূর্তে শুধু **নতুন booking** sheet-এ যায়। পুরনো booking বা edit/payment চাইলে পরে যোগ করা যাবে — বললে করে দেব।
- **শুধু booking** sheet-এ যাচ্ছে — payment/income/expense নয় (আপনার privacy চাওয়া অনুযায়ী)।
