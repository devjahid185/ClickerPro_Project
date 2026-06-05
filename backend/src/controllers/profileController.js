// src/controllers/profileController.js
//
// User profile read + update + settings + VAT।  সব response Flutter এর
// `presentUser()` shape এ ফেরত যায়, তাই Drift এ ১:১ map হয়।

const prisma = require('../lib/prisma');
const { ok, fail, asyncHandler } = require('../lib/response');
const { presentUser, USER_SELECT } = require('../lib/userPresenter');

// ─── GET /api/profile ──────────────────────────────────────────────
exports.getProfile = asyncHandler(async (req, res) => {
  const user = await prisma.user.findUnique({
    where: { id: req.user.id },
    select: USER_SELECT,
  });
  if (!user) return fail(res, 404, 'Account খুঁজে পাওয়া যায়নি');
  return ok(res, 200, { user: presentUser(user) });
});

// ─── PATCH /api/profile ────────────────────────────────────────────
//
// Partial update — শুধু যেগুলো body এ পাঠানো হয়েছে সেই গুলো update হয়।
// Flutter side `UserModel.toJson()` এই keys গুলো পাঠায়।
exports.updateProfile = asyncHandler(async (req, res) => {
  const b = req.body || {};
  const data = {};

  // Flutter sends `name` (legacy `fullName` ও accept করি)
  if (b.name !== undefined) data.fullName = String(b.name);
  if (b.fullName !== undefined) data.fullName = String(b.fullName);

  if (b.phone !== undefined) data.phone = b.phone || null;
  if (b.whatsapp !== undefined) data.whatsapp = b.whatsapp || null;
  if (b.bio !== undefined) data.bio = b.bio || null;
  if (b.specialization !== undefined) data.specialization = b.specialization || null;
  if (b.studioAddress !== undefined) data.businessAddress = b.studioAddress || null;
  if (b.companyName !== undefined) data.businessName = b.companyName || null;
  if (b.businessName !== undefined) data.businessName = b.businessName || null;
  if (b.bkash !== undefined) data.bkash = b.bkash || null;
  if (b.vatBin !== undefined) data.vatBin = b.vatBin || null;
  if (b.logoUrl !== undefined) data.logoUrl = b.logoUrl || null;
  if (b.signatureUrl !== undefined) data.signatureUrl = b.signatureUrl || null;
  if (b.avatarUrl !== undefined) data.avatarUrl = b.avatarUrl || null;

  // bankDetails — Flutter string পাঠায় (legacy structure), JSON নয়।
  if (b.bankDetails !== undefined) {
    if (typeof b.bankDetails === 'string') {
      data.bankDetails = { raw: b.bankDetails };
    } else if (b.bankDetails && typeof b.bankDetails === 'object') {
      data.bankDetails = b.bankDetails;
    } else {
      data.bankDetails = null;
    }
  }

  if (Object.keys(data).length === 0) {
    return fail(res, 400, 'কোনো field দেওয়া হয়নি');
  }

  const updated = await prisma.user.update({
    where: { id: req.user.id },
    data,
    select: USER_SELECT,
  });

  return ok(res, 200, { user: presentUser(updated) });
});

// ─── PATCH /api/profile/settings ───────────────────────────────────
exports.updateSettings = asyncHandler(async (req, res) => {
  const { distributionOn, language, notificationPrefs } = req.body || {};
  if (language !== undefined && language !== 'en' && language !== 'bn') {
    return fail(res, 400, "language শুধু 'en' বা 'bn' হতে পারে");
  }

  const data = {};
  if (distributionOn !== undefined) data.distributionOn = !!distributionOn;
  if (language !== undefined) data.language = language;
  if (notificationPrefs !== undefined) data.notificationPrefs = notificationPrefs;

  if (Object.keys(data).length === 0) {
    return fail(res, 400, 'কোনো field দেওয়া হয়নি');
  }

  const updated = await prisma.user.update({
    where: { id: req.user.id },
    data,
    select: USER_SELECT,
  });

  return ok(res, 200, {
    distributionOn: updated.distributionOn,
    language: updated.language,
    notificationPrefs: updated.notificationPrefs,
  });
});

// ─── PATCH /api/profile/vat ────────────────────────────────────────
exports.updateVatSettings = asyncHandler(async (req, res) => {
  const me = await prisma.user.findUnique({
    where: { id: req.user.id },
    select: { role: true },
  });
  if (!me || (me.role !== 'OWNER' && me.role !== 'BOTH')) {
    return fail(res, 403, 'শুধু Owner বা Both role এই কাজটি করতে পারে');
  }

  const { vatEnabled, vatPercentage, vatBin } = req.body || {};
  if (vatPercentage !== undefined && (vatPercentage < 0 || vatPercentage > 100)) {
    return fail(res, 400, 'VAT percentage 0–100 এর মধ্যে হতে হবে');
  }

  const data = {};
  if (vatEnabled !== undefined) data.vatEnabled = !!vatEnabled;
  if (vatPercentage !== undefined) data.vatPercentage = Number(vatPercentage);
  if (vatBin !== undefined) data.vatBin = vatBin || null;

  const updated = await prisma.user.update({
    where: { id: req.user.id },
    data,
    select: USER_SELECT,
  });

  return ok(res, 200, {
    vatEnabled: updated.vatEnabled,
    vatPercentage: updated.vatPercentage,
    vatBin: updated.vatBin,
  });
});

// ─── GET /api/profile/stats ────────────────────────────────────────
//
// Lifetime stats. Phase 2 এ aggregation worker এই গুলো maintain করবে; এখন
// User row এ যা আছে সেটাই ফেরত দিই।
exports.getLifetimeStats = asyncHandler(async (req, res) => {
  const user = await prisma.user.findUnique({
    where: { id: req.user.id },
    select: {
      totalEvents: true,
      totalRevenueMinor: true,
      totalClients: true,
      statsRefreshedAt: true,
    },
  });
  if (!user) return fail(res, 404, 'Account খুঁজে পাওয়া যায়নি');
  return ok(res, 200, {
    totalEvents: user.totalEvents ?? 0,
    totalRevenueMinor: user.totalRevenueMinor ?? 0,
    totalClients: user.totalClients ?? 0,
    statsRefreshedAt: user.statsRefreshedAt
      ? user.statsRefreshedAt.toISOString()
      : null,
  });
});
