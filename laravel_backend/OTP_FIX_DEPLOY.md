# 🔐 OTP Fix — লাইভ সার্ভারে আপডেট গাইড

> **কী ঠিক হয়েছে:** আগে register করলেই সাথে সাথে login হয়ে যেত, OTP শুধু নামের ছিল।
> এখন **OTP verify না করা পর্যন্ত login হবে না** — সঠিক OTP দিলে তবেই অ্যাকাউন্ট active।

> ⚠️ এই ফিক্স কাজ করতে **লাইভ সার্ভারে একটা ফাইল আপডেট** করতে হবে, নাহলে অ্যাপ আর সার্ভারের
> মধ্যে অমিল হবে (register আটকে যেতে পারে)। নিচের **যেকোনো একটা** পদ্ধতি বেছে নিন।

পরিবর্তিত ফাইল মাত্র **১টা**:
`app/Http/Controllers/Api/AuthController.php`

---

## ✅ পদ্ধতি ১ — git দিয়ে (সবচেয়ে নিরাপদ, সার্ভারে repo আছে)

আমরা দেখেছি সার্ভারে git repo আছে:
`/home/deyalgho/repositories/ClickerPro_Project/`

> ⚠️ তবে লাইভ যেটা চলে সেটা `/home/deyalgho/clickerpro/laravel_backend/`।
> দুটো একই কিনা নিশ্চিত না হলে **পদ্ধতি ২ (ম্যানুয়াল)** ব্যবহার করুন — সেটা নিরাপদ।

আমি কোডটা GitHub-এ push করে দিলে, cPanel Terminal-এ:

```bash
cd /home/deyalgho/repositories/ClickerPro_Project
git pull origin fix/heaven-feedback-19-items

# তারপর লাইভ ফোল্ডারে কপি (যদি আলাদা হয়):
cp app/Http/Controllers/Api/AuthController.php \
   /home/deyalgho/clickerpro/laravel_backend/app/Http/Controllers/Api/AuthController.php

cd /home/deyalgho/clickerpro/laravel_backend
php artisan config:clear
php artisan route:clear
```

> git push আমি করব না যতক্ষণ আপনি না বলেন — বললে করে দেব।

---

## ✅ পদ্ধতি ২ — ম্যানুয়াল ফাইল আপলোড (non-coder বান্ধব, recommended)

1. আপনার PC-তে এই ফাইলটা খুঁজুন:
   `C:\Users\photo\Desktop\ClickerPro_Project\laravel_backend\app\Http\Controllers\Api\AuthController.php`

2. cPanel → **File Manager** খুলুন।

3. এই ফোল্ডারে যান:
   `/home/deyalgho/clickerpro/laravel_backend/app/Http/Controllers/Api/`

4. পুরনো `AuthController.php` টা আগে **rename করে রাখুন** ব্যাকআপ হিসেবে
   (ডান-ক্লিক → Rename → `AuthController.php.old`)।

5. উপরে **Upload** বাটনে ক্লিক করে আপনার PC-র নতুন `AuthController.php` আপলোড করুন।

6. cPanel → **Terminal** এ:
   ```bash
   cd /home/deyalgho/clickerpro/laravel_backend
   php artisan config:clear
   php artisan route:clear
   ```

---

## ✅ ধাপ শেষ — টেস্ট

1. মোবাইল অ্যাপে (নতুন বিল্ড ইনস্টল করা থাকতে হবে) একটা **নতুন ইমেইল দিয়ে register** করুন।
2. OTP screen আসবে → অ্যাপ বন্ধ করে আবার খুলুন → **এবার login screen-এ ফিরবে** (আগের মতো ঢুকে যাবে না)। ✅
3. সঠিক OTP দিলে তবেই Dashboard-এ ঢুকবে।

> **OTP কোথায় পাবেন?** সার্ভারের `.env`-এ যদি `MAIL_MAILER=log` থাকে, OTP কোড
> `storage/logs/laravel.log`-এ লেখা হয় (টেস্টের জন্য)। আসল ইমেইলে পাঠাতে হলে
> `.env`-এ SMTP সেট করতে হবে — বললে গাইড দেব।

---

## ⚠️ গুরুত্বপূর্ণ

- **App আর backend একসাথে আপডেট হতে হবে।** শুধু একটা করলে register সাময়িক ভাঙবে।
  তাই: আগে এই backend ফাইল আপলোড করুন, **তারপর** নতুন APK ইনস্টল করা ফোনে টেস্ট করুন
  (নতুন APK আমি ২ ফোনে দিয়ে দিচ্ছি)।
- সমস্যা হলে rename করা `AuthController.php.old` ফিরিয়ে দিলেই আগের অবস্থায় ফিরবে।
