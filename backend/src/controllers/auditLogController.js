const prisma = require('../lib/prisma');

const VALID_ACTION = ['CREATE', 'UPDATE', 'DELETE', 'PERMISSION'];
const norm = (val) => {
  const up = (val || '').toString().toUpperCase();
  return VALID_ACTION.includes(up) ? up : 'UPDATE';
};

// GET /api/audit-logs — owner-scoped (actorId = req.user.id)
exports.getAuditLogs = async (req, res) => {
  try {
    const actorId = req.user.id;
    const { action, from, to, limit = 50, offset = 0 } = req.query;

    const where = { actorId };
    if (action) where.action = norm(action);
    if (from || to) {
      where.createdAt = {};
      if (from) where.createdAt.gte = new Date(from);
      if (to)   where.createdAt.lte = new Date(to);
    }

    const logs = await prisma.auditLog.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      take: Math.min(Number(limit) || 50, 200),
      skip: Number(offset) || 0,
    });
    res.json({ success: true, count: logs.length, data: logs });
  } catch (err) {
    console.error('AuditLog list error:', err);
    res.status(500).json({ success: false, message: 'অডিট লগ আনতে সমস্যা হয়েছে' });
  }
};

// POST /api/audit-logs
exports.createAuditLog = async (req, res) => {
  try {
    const actorId = req.user.id;
    const { actorName, action, entityType, entityId, entityLabel, before, after } = req.body;

    if (!actorName || !action || !entityType || !entityId) {
      return res.status(400).json({
        success: false,
        message: 'actorName, action, entityType, entityId দেওয়া বাধ্যতামূলক।',
      });
    }

    const log = await prisma.auditLog.create({
      data: {
        actorId,
        actorName,
        action: norm(action),
        entityType,
        entityId,
        entityLabel: entityLabel || null,
        before: before || null,
        after:  after  || null,
      },
    });
    res.status(201).json({ success: true, data: log });
  } catch (err) {
    console.error('AuditLog create error:', err);
    res.status(500).json({ success: false, message: 'অডিট লগ সংরক্ষণে সমস্যা হয়েছে' });
  }
};
