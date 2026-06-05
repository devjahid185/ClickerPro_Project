// src/controllers/deviceTokenController.js
//
// FCM device-token registry।  Flutter calls these endpoints during
// auth bootstrap so the backend can target the right phone/tablet
// when emitting push notifications.
//
// Endpoints:
//   POST   /api/devices/register   { token, platform, appVersion?, language? }
//   DELETE /api/devices/:token     — call from logout / "remove this device"
//   GET    /api/devices/me         — list caller's registered devices

const prisma = require('../lib/prisma');

const PLATFORMS = ['android', 'ios', 'web'];

exports.registerToken = async (req, res) => {
  try {
    const { token, platform, appVersion, language } = req.body || {};
    const userId = req.user.id;

    if (!token || typeof token !== 'string' || token.length < 10) {
      return res.status(400).json({
        success: false,
        message: 'token দেওয়া বাধ্যতামূলক (FCM registration token)',
      });
    }
    if (!platform || !PLATFORMS.includes(platform)) {
      return res.status(400).json({
        success: false,
        message: "platform 'android' | 'ios' | 'web' হতে হবে",
      });
    }

    // Upsert on the composite unique key (userId, token) so re-register
    // just bumps lastSeenAt instead of duplicating rows.
    const row = await prisma.deviceToken.upsert({
      where: { userId_token: { userId, token } },
      update: {
        platform,
        appVersion: appVersion || null,
        language: language || null,
      },
      create: {
        userId,
        token,
        platform,
        appVersion: appVersion || null,
        language: language || null,
      },
    });

    return res.status(201).json({
      success: true,
      message: 'ডিভাইস টোকেন রেজিস্টার করা হয়েছে',
      device: {
        id: row.id,
        platform: row.platform,
        appVersion: row.appVersion,
        language: row.language,
      },
    });
  } catch (error) {
    console.error('Register Device Token Error:', error);
    return res.status(500).json({
      success: false,
      message: 'টোকেন রেজিস্টার করতে সমস্যা হয়েছে',
    });
  }
};

exports.unregisterToken = async (req, res) => {
  try {
    const { token } = req.params;
    const userId = req.user.id;

    const result = await prisma.deviceToken.deleteMany({
      where: { userId, token },
    });

    if (result.count === 0) {
      return res.status(404).json({
        success: false,
        message: 'এই টোকেন আপনার ডিভাইস তালিকায় নেই',
      });
    }

    return res.status(200).json({ success: true });
  } catch (error) {
    console.error('Unregister Device Token Error:', error);
    return res.status(500).json({
      success: false,
      message: 'টোকেন অপসারণে সমস্যা হয়েছে',
    });
  }
};

exports.listMyDevices = async (req, res) => {
  try {
    const userId = req.user.id;
    const devices = await prisma.deviceToken.findMany({
      where: { userId },
      orderBy: { lastSeenAt: 'desc' },
      select: {
        id: true,
        platform: true,
        appVersion: true,
        language: true,
        createdAt: true,
        lastSeenAt: true,
      },
    });
    return res.status(200).json({
      success: true,
      count: devices.length,
      devices,
    });
  } catch (error) {
    console.error('List Devices Error:', error);
    return res.status(500).json({
      success: false,
      message: 'ডিভাইস তালিকা লোড করতে সমস্যা হয়েছে',
    });
  }
};
