// src/controllers/entitlementController.js
//
// The app's source of truth for "what can THIS user access right now".
// Combines the global FeatureFlag registry with the user's plan:
//
//   a feature is UNLOCKED if  (not requiresPro) OR (user is on an active PRO plan)
//
// Returned as a simple { key: bool } map so the Flutter side can gate UI
// without knowing about plans. Today all flags are free → everything true.

const prisma = require('../lib/prisma');

function isProActive(user) {
  if (!user || user.plan !== 'PRO') return false;
  if (!user.planExpiresAt) return true; // PRO with no expiry = lifetime
  return new Date(user.planExpiresAt).getTime() > Date.now();
}

// GET /api/entitlements — authenticated; returns this user's unlocked features.
exports.getEntitlements = async (req, res) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
      select: { plan: true, planExpiresAt: true },
    });
    const flags = await prisma.featureFlag.findMany({
      select: { key: true, requiresPro: true },
    });

    const pro = isProActive(user);
    const features = {};
    for (const f of flags) {
      features[f.key] = pro || !f.requiresPro;
    }

    res.json({
      success: true,
      data: {
        plan: user ? user.plan : 'FREE',
        planExpiresAt: user ? user.planExpiresAt : null,
        isPro: pro,
        features,
      },
    });
  } catch (err) {
    console.error('getEntitlements error:', err);
    res.status(500).json({ success: false, message: 'এনটাইটেলমেন্ট আনতে সমস্যা হয়েছে' });
  }
};

module.exports.isProActive = isProActive;
