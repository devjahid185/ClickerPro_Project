// src/controllers/couponController.js
//
// Promo/discount codes. Admin CRUD + a public redeem-check used by the app.

const prisma = require('../lib/prisma');

// GET /api/admin/coupons
exports.listCoupons = async (req, res) => {
  try {
    const coupons = await prisma.coupon.findMany({ orderBy: { createdAt: 'desc' } });
    res.json({ success: true, count: coupons.length, data: coupons });
  } catch (err) {
    console.error('listCoupons error:', err);
    res.status(500).json({ success: false, message: 'কুপন আনতে সমস্যা হয়েছে' });
  }
};

// POST /api/admin/coupons
exports.createCoupon = async (req, res) => {
  try {
    const { code, description, discountType, discountValue, maxRedemptions, expiresAt } = req.body;
    if (!code) return res.status(400).json({ success: false, message: 'code দিন' });
    const type = ['PERCENT', 'FLAT', 'PRO_DAYS'].includes((discountType || '').toUpperCase())
      ? discountType.toUpperCase()
      : 'PERCENT';
    const coupon = await prisma.coupon.create({
      data: {
        code: code.trim().toUpperCase(),
        description: description || null,
        discountType: type,
        discountValue: Number(discountValue) || 0,
        maxRedemptions: maxRedemptions ? Number(maxRedemptions) : null,
        expiresAt: expiresAt ? new Date(expiresAt) : null,
      },
    });
    res.status(201).json({ success: true, data: coupon });
  } catch (err) {
    if (err.code === 'P2002') {
      return res.status(409).json({ success: false, message: 'এই code আগে থেকেই আছে' });
    }
    console.error('createCoupon error:', err);
    res.status(500).json({ success: false, message: 'কুপন তৈরিতে সমস্যা হয়েছে' });
  }
};

// PATCH /api/admin/coupons/:id  { active, ... }
exports.updateCoupon = async (req, res) => {
  try {
    const { id } = req.params;
    const { active, description, discountValue, maxRedemptions, expiresAt } = req.body;
    const data = {};
    if (active !== undefined) data.active = active === true;
    if (description !== undefined) data.description = description;
    if (discountValue !== undefined) data.discountValue = Number(discountValue);
    if (maxRedemptions !== undefined) data.maxRedemptions = maxRedemptions ? Number(maxRedemptions) : null;
    if (expiresAt !== undefined) data.expiresAt = expiresAt ? new Date(expiresAt) : null;
    const coupon = await prisma.coupon.update({ where: { id }, data });
    res.json({ success: true, data: coupon });
  } catch (err) {
    console.error('updateCoupon error:', err);
    res.status(500).json({ success: false, message: 'কুপন আপডেটে সমস্যা হয়েছে' });
  }
};

// DELETE /api/admin/coupons/:id
exports.deleteCoupon = async (req, res) => {
  try {
    await prisma.coupon.delete({ where: { id: req.params.id } });
    res.json({ success: true, message: 'মুছে ফেলা হয়েছে' });
  } catch (err) {
    console.error('deleteCoupon error:', err);
    res.status(500).json({ success: false, message: 'মুছতে সমস্যা হয়েছে' });
  }
};

// POST /api/coupons/redeem  { code } — authed; validates & (for PRO_DAYS)
// extends the caller's plan. Returns the discount for the app to apply.
exports.redeemCoupon = async (req, res) => {
  try {
    const code = (req.body.code || '').trim().toUpperCase();
    if (!code) return res.status(400).json({ success: false, message: 'code দিন' });

    const coupon = await prisma.coupon.findUnique({ where: { code } });
    if (!coupon || !coupon.active) {
      return res.status(404).json({ success: false, message: 'কুপন বৈধ নয়' });
    }
    if (coupon.expiresAt && coupon.expiresAt.getTime() < Date.now()) {
      return res.status(400).json({ success: false, message: 'কুপনের মেয়াদ শেষ' });
    }
    if (coupon.maxRedemptions != null && coupon.redeemedCount >= coupon.maxRedemptions) {
      return res.status(400).json({ success: false, message: 'কুপন রিডিম সীমা শেষ' });
    }

    // PRO_DAYS coupons grant PRO time directly.
    let appliedPlan = null;
    if (coupon.discountType === 'PRO_DAYS' && coupon.discountValue > 0) {
      const user = await prisma.user.findUnique({ where: { id: req.user.id } });
      const base = user.planExpiresAt && user.planExpiresAt.getTime() > Date.now()
        ? user.planExpiresAt.getTime()
        : Date.now();
      const newExpiry = new Date(base + coupon.discountValue * 86400000);
      await prisma.user.update({
        where: { id: req.user.id },
        data: { plan: 'PRO', planExpiresAt: newExpiry },
      });
      appliedPlan = { plan: 'PRO', planExpiresAt: newExpiry };
    }

    await prisma.coupon.update({
      where: { id: coupon.id },
      data: { redeemedCount: { increment: 1 } },
    });

    res.json({
      success: true,
      data: {
        discountType: coupon.discountType,
        discountValue: coupon.discountValue,
        appliedPlan,
      },
    });
  } catch (err) {
    console.error('redeemCoupon error:', err);
    res.status(500).json({ success: false, message: 'কুপন রিডিমে সমস্যা হয়েছে' });
  }
};
