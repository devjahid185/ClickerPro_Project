# 🧹 Production সার্ভার (api.deyalghori.com) — সব টেস্ট ইউজার মুছে ফ্রেশ করার গাইড

> **লক্ষ্য:** লাইভ সার্ভারের সব পুরনো টেস্ট ইউজার + তাদের booking/payment/expense মুছে ফেলা,
> শুধু আপনার নতুন admin (`photo.nhh@gmail.com`) রেখে।
> এতে মোবাইল অ্যাপে আর "already registered" আসবে না — একদম ফ্রেশ রেজিস্টার করা যাবে।

> ⚠️ **এটা লাইভ সার্ভার। নিচের যেকোনো একটা পথ বেছে নিন। চালানোর আগে STEP 0 (ব্যাকআপ) অবশ্যই করুন।**

---

## STEP 0 — আগে ব্যাকআপ (খুব গুরুত্বপূর্ণ)

সার্ভারে SSH/Terminal এ গিয়ে, Laravel প্রজেক্ট ফোল্ডারে ঢুকে:

```bash
# MySQL হলে:
mysqldump -u DB_USER -p DB_NAME > backup_before_clean_$(date +%F).sql

# PostgreSQL হলে:
pg_dump -U DB_USER -d DB_NAME > backup_before_clean_$(date +%F).sql
```

ব্যাকআপ ফাইলটা ডাউনলোড করে নিরাপদে রাখুন। তারপর নিচের যেকোনো একটা পথে যান।

---

## ✅ পথ ১ (সবচেয়ে সহজ ও পরিষ্কার) — পুরো DB ফ্রেশ + নতুন admin

সার্ভারের Laravel ফোল্ডারে SSH/Terminal এ:

```bash
# 1) সব টেবিল মুছে নতুন করে বানায় (সব পুরনো ইউজার/ডেটা চলে যায়)
php artisan migrate:fresh --force

# 2) আপনার নতুন admin তৈরি করে
php artisan tinker --execute="\$u=\App\Models\User::create(['name'=>'Heaven Admin','email'=>'photo.nhh@gmail.com','password'=>\Illuminate\Support\Facades\Hash::make('Nhh@2700685')]); \$u->role='ADMIN'; \$u->is_active=true; \$u->plan='PRO'; \$u->save(); echo 'Admin ready: '.\$u->email;"
```

➡️ এতে সার্ভার একদম ফ্রেশ হয়, শুধু আপনার admin থাকে। **এটাই recommended।**

---

## পথ ২ — শুধু ইউজার মুছি, settings/feature flags রাখি

যদি পুরো DB ফ্রেশ না করে শুধু ইউজার ও তাদের ডেটা মুছতে চান:

```bash
php artisan tinker
```

তারপর tinker এর ভিতরে (এক লাইন করে):

```php
// সব ইউজার (এবং cascade-এ তাদের booking/payment/expense) মুছে দেয়
\App\Models\User::query()->delete();

// নতুন admin বানায়
$u = \App\Models\User::create(['name'=>'Heaven Admin','email'=>'photo.nhh@gmail.com','password'=>\Illuminate\Support\Facades\Hash::make('Nhh@2700685')]);
$u->role='ADMIN'; $u->is_active=true; $u->plan='PRO'; $u->save();

exit
```

> দ্রষ্টব্য: যদি foreign key constraint error দেয় (booking/payment ইউজারের সাথে আটকানো),
> তখন পথ ১ (`migrate:fresh`) ব্যবহার করুন — সেটা সব নিরাপদে ক্লিন করে।

---

## পথ ৩ — cPanel/phpMyAdmin (SSH না থাকলে)

আপনার hosting এ phpMyAdmin থাকলে:

1. phpMyAdmin খুলুন → আপনার database সিলেক্ট করুন
2. **Export** ট্যাব → ব্যাকআপ ডাউনলোড করুন (STEP 0)
3. **SQL** ট্যাবে গিয়ে নিচেরটা চালান (MySQL):

```sql
SET FOREIGN_KEY_CHECKS = 0;

-- ইউজার-সম্পর্কিত সব টেবিল খালি করে
TRUNCATE TABLE events;
TRUNCATE TABLE payments;
TRUNCATE TABLE expenses;
TRUNCATE TABLE clients;
TRUNCATE TABLE assignments;
TRUNCATE TABLE personal_access_tokens;
TRUNCATE TABLE users;

SET FOREIGN_KEY_CHECKS = 1;
```

4. তারপর SSH থাকলে পথ ১ এর `tinker` কমান্ড দিয়ে admin বানান,
   অথবা মোবাইল অ্যাপ দিয়ে `photo.nhh@gmail.com` রেজিস্টার করে নিন
   (পরে DB তে গিয়ে তার `role` কে `ADMIN` করুন)।

---

## STEP শেষ — যাচাই

```bash
php artisan tinker --execute="echo 'Users now: '.\App\Models\User::count();"
```

`Users now: 1` (শুধু admin) দেখালে কাজ শেষ। ✅

এখন ২টা ফোনে অ্যাপ খুলে **নতুন ইমেইল দিয়ে রেজিস্টার** করুন — "already registered" আর আসবে না।

---

## ⚠️ আমার একটা পরামর্শ

আপনার মোবাইল অ্যাপ **production সার্ভার** ব্যবহার করে, আপনার এই PC-র local DB নয়।
তাই ভবিষ্যতে অ্যাপ টেস্ট করার সময় মনে রাখবেন — যা মুছবেন তা **লাইভ ইউজারদের** উপর প্রভাব ফেলবে।
টেস্টের জন্য আলাদা একটা staging সার্ভার বা local DB রাখলে ভালো হয়।
