# Google Sign-In ঠিক করার গাইড (৫ মিনিট)

## সমস্যা কী ছিল?

`clicker_pro/android/app/google-services.json` ফাইলে `"oauth_client": []` — **খালি**।
মানে Firebase প্রজেক্টে অ্যাপের SHA ফিঙ্গারপ্রিন্ট রেজিস্টার করা নেই এবং Google
sign-in provider চালু নেই। এ কারণে অ্যাপে "Continue with Google" চাপলেই
`ApiException: 10` (DEVELOPER_ERROR) হয়ে **"sign in failed"** আসে।

কোড ঠিক আছে (অ্যাপ + Laravel ব্যাকএন্ড দুটোই রেডি) — শুধু Firebase Console-এ
নিচের ৩টা ধাপ করলেই কাজ করবে।

## ধাপ ১ — Google provider চালু করুন

1. খুলুন: https://console.firebase.google.com/project/clickerpro-4b238/authentication/providers
2. **Google** → Enable → Save

## ধাপ ২ — SHA ফিঙ্গারপ্রিন্ট যোগ করুন

1. খুলুন: https://console.firebase.google.com/project/clickerpro-4b238/settings/general
2. **Your apps → com.clickerpro.app → Add fingerprint**
3. নিচের **৪টা ফিঙ্গারপ্রিন্টই** যোগ করুন (debug + release দুই বিল্ডেই কাজ করার জন্য):

**Release keystore (`keystores/clicker_pro.jks`):**
```
SHA1:   E4:D1:92:6A:BA:F0:61:F5:8A:3A:20:F4:78:AB:A7:06:56:16:BF:64
SHA256: 45:C2:5E:02:12:5C:97:98:08:68:5C:3E:36:2B:53:D5:92:F0:81:C0:05:33:24:8A:2A:C4:74:F8:BA:73:48:FC
```

**Debug keystore (এই PC-র `~/.android/debug.keystore`):**
```
SHA1:   0E:CD:E1:EF:1C:CF:9E:ED:7C:6D:92:CD:8E:D8:FE:74:32:C6:9E:F1
SHA256: BE:03:E7:EA:55:09:49:EE:63:1E:41:A2:09:CB:86:50:61:FB:1B:B4:F2:F7:63:79:FE:6E:DF:AB:6D:D7:D6:63
```

## ধাপ ৩ — নতুন google-services.json নামিয়ে বসান

1. একই Settings পেজে **google-services.json** ডাউনলোড করুন
2. পুরনোটার জায়গায় রাখুন: `clicker_pro/android/app/google-services.json`
3. ফাইল খুলে দেখুন `"oauth_client"` এখন আর খালি নেই
4. অ্যাপ rebuild করুন: `flutter clean && flutter run`

## (ঐচ্ছিক কিন্তু recommended) ব্যাকএন্ড হার্ডেনিং

নতুন json-এ `client_type: 3` (web client) এর `client_id` কপি করে Laravel `.env`-এ দিন:

```
GOOGLE_CLIENT_IDS=<সেই-client-id>.apps.googleusercontent.com
```

এতে ব্যাকএন্ড শুধু আপনার অ্যাপের টোকেনই গ্রহণ করবে।

## যাচাই

অ্যাপে "Continue with Google" → অ্যাকাউন্ট বাছুন → সরাসরি ড্যাশবোর্ডে ঢুকবে।
এখন কনফিগ ভুল থাকলে অ্যাপ generic "failed" না দেখিয়ে স্পষ্ট মেসেজ দেখাবে
("Google সাইন-ইন এই বিল্ডে এখনো কনফিগার করা হয়নি")।
