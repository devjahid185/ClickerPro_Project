// src/controllers/securityController.js
//
// Admin security surface: login-activity history, IP blocklist, and TOTP 2FA
// enrollment for the calling admin.

const prisma = require('../lib/prisma');
const speakeasy = require('speakeasy');
const QRCode = require('qrcode');

// ─────────────────────── Login activity / device history ───────────────────────

// GET /api/admin/security/login-activity?email=&onlyFailed=&limit=
exports.listLoginActivity = async (req, res) => {
  try {
    const { email, onlyFailed, limit = 100 } = req.query;
    const where = {};
    if (email) where.email = { contains: email, mode: 'insensitive' };
    if (onlyFailed === 'true') where.success = false;
    const rows = await prisma.loginActivity.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      take: Math.min(Number(limit) || 100, 300),
    });
    res.json({ success: true, count: rows.length, data: rows });
  } catch (err) {
    console.error('listLoginActivity error:', err);
    res.status(500).json({ success: false, message: 'লগইন অ্যাক্টিভিটি আনতে সমস্যা' });
  }
};

// GET /api/admin/security/suspicious — emails/IPs with many recent failures.
exports.suspicious = async (req, res) => {
  try {
    const since = new Date(Date.now() - 24 * 3600 * 1000);
    const rows = await prisma.$queryRaw`
      SELECT "email", "ip", COUNT(*)::int AS fails
      FROM "LoginActivity"
      WHERE "success" = false AND "createdAt" >= ${since}
      GROUP BY "email", "ip"
      HAVING COUNT(*) >= 3
      ORDER BY fails DESC LIMIT 50`;
    res.json({ success: true, data: rows });
  } catch (err) {
    console.error('suspicious error:', err);
    res.status(500).json({ success: false, message: 'ডেটা আনতে সমস্যা' });
  }
};

// ─────────────────────────── IP blocklist ───────────────────────────

exports.listBlockedIps = async (req, res) => {
  try {
    const rows = await prisma.blockedIp.findMany({ orderBy: { createdAt: 'desc' } });
    res.json({ success: true, count: rows.length, data: rows });
  } catch (err) {
    res.status(500).json({ success: false, message: 'ব্লক লিস্ট আনতে সমস্যা' });
  }
};

exports.blockIp = async (req, res) => {
  try {
    const { ip, reason } = req.body;
    if (!ip) return res.status(400).json({ success: false, message: 'ip দিন' });
    const row = await prisma.blockedIp.upsert({
      where: { ip },
      update: { reason: reason || null },
      create: { ip, reason: reason || null },
    });
    res.status(201).json({ success: true, data: row });
  } catch (err) {
    res.status(500).json({ success: false, message: 'ব্লক করতে সমস্যা' });
  }
};

exports.unblockIp = async (req, res) => {
  try {
    await prisma.blockedIp.delete({ where: { ip: req.params.ip } });
    res.json({ success: true, message: 'আনব্লক করা হয়েছে' });
  } catch (err) {
    res.status(500).json({ success: false, message: 'আনব্লক করতে সমস্যা' });
  }
};

// ─────────────────────────── 2FA (TOTP) ───────────────────────────

// POST /api/admin/security/2fa/setup — generates a secret + QR for the admin
// to scan. Secret is stored but NOT yet enabled (must verify first).
exports.setup2fa = async (req, res) => {
  try {
    const secret = speakeasy.generateSecret({
      name: `Clicker Pro Admin (${req.user.id.slice(0, 8)})`,
    });
    await prisma.user.update({
      where: { id: req.user.id },
      data: { totpSecret: secret.base32 },
    });
    const qr = await QRCode.toDataURL(secret.otpauth_url);
    res.json({ success: true, data: { secret: secret.base32, qr } });
  } catch (err) {
    console.error('setup2fa error:', err);
    res.status(500).json({ success: false, message: '2FA সেটআপে সমস্যা' });
  }
};

// POST /api/admin/security/2fa/verify  { token } — confirms a code & enables.
exports.verify2fa = async (req, res) => {
  try {
    const { token } = req.body;
    const user = await prisma.user.findUnique({ where: { id: req.user.id } });
    if (!user.totpSecret) {
      return res.status(400).json({ success: false, message: 'আগে 2FA setup করুন' });
    }
    const ok = speakeasy.totp.verify({
      secret: user.totpSecret,
      encoding: 'base32',
      token: String(token || ''),
      window: 1,
    });
    if (!ok) return res.status(400).json({ success: false, message: 'কোড সঠিক নয়' });
    await prisma.user.update({
      where: { id: req.user.id },
      data: { twoFactorEnabled: true },
    });
    res.json({ success: true, message: '2FA চালু হয়েছে' });
  } catch (err) {
    console.error('verify2fa error:', err);
    res.status(500).json({ success: false, message: '2FA যাচাইয়ে সমস্যা' });
  }
};

// POST /api/admin/security/2fa/disable
exports.disable2fa = async (req, res) => {
  try {
    await prisma.user.update({
      where: { id: req.user.id },
      data: { twoFactorEnabled: false, totpSecret: null },
    });
    res.json({ success: true, message: '2FA বন্ধ হয়েছে' });
  } catch (err) {
    res.status(500).json({ success: false, message: '2FA বন্ধ করতে সমস্যা' });
  }
};

// GET /api/admin/security/2fa/status
exports.status2fa = async (req, res) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
      select: { twoFactorEnabled: true },
    });
    res.json({ success: true, data: { enabled: user.twoFactorEnabled } });
  } catch (err) {
    res.status(500).json({ success: false, message: 'স্ট্যাটাস আনতে সমস্যা' });
  }
};
