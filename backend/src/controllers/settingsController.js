// src/controllers/settingsController.js
//
// Platform settings as a flat key→value store. Admin reads/writes grouped
// settings (general / smtp / gateway / social). Secret values are masked on
// read (returned as "••••••" if set) so keys never leak to the browser, but
// can still be overwritten.

const prisma = require('../lib/prisma');

const MASK = '••••••';

// Known settings + their group + secrecy. Seeded lazily so the admin UI has
// a stable set of fields even before anything is saved.
const KNOWN = [
  { key: 'app.name', group: 'general', isSecret: false },
  { key: 'app.supportEmail', group: 'general', isSecret: false },
  { key: 'app.maintenanceMode', group: 'general', isSecret: false },
  { key: 'smtp.host', group: 'smtp', isSecret: false },
  { key: 'smtp.port', group: 'smtp', isSecret: false },
  { key: 'smtp.user', group: 'smtp', isSecret: false },
  { key: 'smtp.password', group: 'smtp', isSecret: true },
  { key: 'smtp.fromEmail', group: 'smtp', isSecret: false },
  { key: 'gateway.provider', group: 'gateway', isSecret: false },
  { key: 'gateway.apiKey', group: 'gateway', isSecret: true },
  { key: 'gateway.apiSecret', group: 'gateway', isSecret: true },
  { key: 'social.facebook', group: 'social', isSecret: false },
  { key: 'social.instagram', group: 'social', isSecret: false },
  { key: 'social.youtube', group: 'social', isSecret: false },
  { key: 'social.website', group: 'social', isSecret: false },
  { key: 'branding.primaryColor', group: 'branding', isSecret: false },
  { key: 'branding.logoUrl', group: 'branding', isSecret: false },
  { key: 'branding.bannerUrl', group: 'branding', isSecret: false },
];

// GET /api/admin/settings — grouped, secrets masked.
exports.getSettings = async (req, res) => {
  try {
    const rows = await prisma.appSetting.findMany();
    const byKey = Object.fromEntries(rows.map((r) => [r.key, r]));

    const data = {};
    for (const def of KNOWN) {
      const row = byKey[def.key];
      const hasValue = row && row.value != null && row.value !== '';
      if (!data[def.group]) data[def.group] = [];
      data[def.group].push({
        key: def.key,
        isSecret: def.isSecret,
        value: def.isSecret ? (hasValue ? MASK : '') : (row ? row.value : ''),
        hasValue,
      });
    }
    res.json({ success: true, data });
  } catch (err) {
    console.error('getSettings error:', err);
    res.status(500).json({ success: false, message: 'সেটিংস আনতে সমস্যা হয়েছে' });
  }
};

// GET /api/branding — PUBLIC (no secrets): app reads theme/social/branding.
exports.getPublicBranding = async (req, res) => {
  try {
    const rows = await prisma.appSetting.findMany({
      where: { group: { in: ['branding', 'social', 'general'] }, isSecret: false },
    });
    const out = {};
    for (const r of rows) out[r.key] = r.value;
    res.json({ success: true, data: out });
  } catch (err) {
    console.error('getPublicBranding error:', err);
    res.status(500).json({ success: false, message: 'ব্র্যান্ডিং আনতে সমস্যা' });
  }
};

// PUT /api/admin/settings  { settings: { key: value, ... } }
// Skips masked secret values (•••) so a save without re-typing keeps them.
exports.updateSettings = async (req, res) => {
  try {
    const incoming = req.body.settings || {};
    const defByKey = Object.fromEntries(KNOWN.map((d) => [d.key, d]));

    for (const [key, value] of Object.entries(incoming)) {
      const def = defByKey[key];
      if (!def) continue; // ignore unknown keys
      if (def.isSecret && value === MASK) continue; // unchanged secret
      await prisma.appSetting.upsert({
        where: { key },
        update: { value: value == null ? null : String(value), group: def.group, isSecret: def.isSecret },
        create: { key, value: value == null ? null : String(value), group: def.group, isSecret: def.isSecret },
      });
    }
    res.json({ success: true, message: 'সেটিংস সংরক্ষিত হয়েছে' });
  } catch (err) {
    console.error('updateSettings error:', err);
    res.status(500).json({ success: false, message: 'সেটিংস সংরক্ষণে সমস্যা হয়েছে' });
  }
};
