// src/controllers/legalController.js
//
// Privacy Policy এবং Terms of Service এর reader।  Database এ doc থাকলে
// সেটা ফেরত যায়; না থাকলে built-in fallback text — তাতে frontend never
// ব্যর্থ হয়।

const prisma = require('../lib/prisma');
const { ok, fail, asyncHandler } = require('../lib/response');

const FALLBACKS = {
  privacy: {
    en: {
      version: 'fallback-1',
      body: `Clicker Pro respects your privacy.

**What we collect**
- Account info you provide (name, email, phone)
- Bookings, payments, and gear data you create
- Device id and language for sync

**How we use it**
- To run your studio and sync across your devices
- To send service notifications you've opted in to

**Your rights**
- Export your data any time from Settings → Account
- Delete your account; full purge after a 7-day grace window

**Contact**
support@clickerpro.app`,
    },
    bn: {
      version: 'fallback-1',
      body: `Clicker Pro আপনার গোপনীয়তাকে সম্মান করে।

**আমরা কী সংগ্রহ করি**
- আপনি যে অ্যাকাউন্ট তথ্য দেন (নাম, ইমেইল, ফোন)
- আপনার তৈরি বুকিং, পেমেন্ট এবং গিয়ার ডেটা
- সিঙ্কের জন্য ডিভাইস আইডি এবং ভাষা

**আপনার অধিকার**
- যেকোনো সময় Settings → Account থেকে ডেটা এক্সপোর্ট করুন
- অ্যাকাউন্ট ডিলিট করুন; ৭-দিনের গ্রেস উইন্ডোর পরে সম্পূর্ণ মুছে ফেলা হয়

**যোগাযোগ**
support@clickerpro.app`,
    },
  },
  terms: {
    en: {
      version: 'fallback-1',
      body: `By using Clicker Pro you agree to:

**Account responsibility**
Keep your credentials secure. You are responsible for your team and your data.

**Acceptable use**
No unlawful activity. Respect client privacy and copyright.

**Termination**
We may suspend accounts that violate these terms.

**Governing law**
Laws of Bangladesh apply.

**Contact**
support@clickerpro.app`,
    },
    bn: {
      version: 'fallback-1',
      body: `Clicker Pro ব্যবহার করে আপনি সম্মত হচ্ছেন:

**অ্যাকাউন্টের দায়িত্ব**
আপনার ক্রেডেনশিয়াল সুরক্ষিত রাখুন।

**গ্রহণযোগ্য ব্যবহার**
কোনো বেআইনি কার্যকলাপ নয়।

**প্রযোজ্য আইন**
বাংলাদেশের আইন প্রযোজ্য হবে।

**যোগাযোগ**
support@clickerpro.app`,
    },
  },
};

async function readDoc(kind, language) {
  const lang = language === 'bn' ? 'bn' : 'en';
  const doc = await prisma.legalDocument.findUnique({
    where: { kind_language: { kind, language: lang } },
  });
  if (doc) return { version: doc.version, body: doc.body };
  return FALLBACKS[kind]?.[lang] || FALLBACKS[kind].en;
}

exports.getPrivacy = asyncHandler(async (req, res) => {
  const lang = (req.query?.lang || 'en').toLowerCase();
  return ok(res, 200, await readDoc('privacy', lang));
});

exports.getTerms = asyncHandler(async (req, res) => {
  const lang = (req.query?.lang || 'en').toLowerCase();
  return ok(res, 200, await readDoc('terms', lang));
});

exports.recordConsent = asyncHandler(async (req, res) => {
  const version = (req.body?.version || '').trim();
  if (!version) return fail(res, 400, 'version দিতে হবে');
  // আপাতত notificationPrefs JSON এ stamp করে রাখছি; পরে আলাদা
  // ConsentLog table আসবে।
  const me = await prisma.user.findUnique({
    where: { id: req.user.id },
    select: { notificationPrefs: true },
  });
  const prefs = (me?.notificationPrefs && typeof me.notificationPrefs === 'object')
    ? me.notificationPrefs
    : {};
  await prisma.user.update({
    where: { id: req.user.id },
    data: {
      notificationPrefs: {
        ...prefs,
        legalConsent: { version, at: new Date().toISOString() },
      },
    },
  });
  return ok(res, 200, {});
});
