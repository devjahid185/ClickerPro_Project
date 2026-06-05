// src/controllers/adminController.js
//
// All admin-panel endpoints, owner of the `/api/admin/*` surface. Every
// handler assumes `authenticate` + `requireAdmin` ran first, so req.user
// is a verified ADMIN. Read-heavy; mutations are deliberately narrow.

const prisma = require('../lib/prisma');
const bcrypt = require('bcryptjs');
const { normalizeRole } = require('../lib/roles');

// ─────────────────────────── Stats dashboard ───────────────────────────

// GET /api/admin/stats — top-line counts for the dashboard cards.
exports.getStats = async (req, res) => {
  try {
    const [
      totalUsers,
      owners,
      freelancers,
      admins,
      totalBookings,
      totalClients,
      activeBroadcasts,
      openTickets,
      revenueAgg,
    ] = await Promise.all([
      prisma.user.count({ where: { deletedAt: null } }),
      prisma.user.count({ where: { role: 'OWNER', deletedAt: null } }),
      prisma.user.count({ where: { role: 'FREELANCER', deletedAt: null } }),
      prisma.user.count({ where: { role: 'ADMIN', deletedAt: null } }),
      prisma.event.count(),
      prisma.client.count(),
      prisma.broadcast.count({ where: { status: 'ACTIVE' } }),
      prisma.supportTicket.count({ where: { status: 'OPEN' } }),
      prisma.user.aggregate({ _sum: { totalRevenueMinor: true } }),
    ]);

    res.json({
      success: true,
      data: {
        totalUsers,
        owners,
        freelancers,
        admins,
        totalBookings,
        totalClients,
        activeBroadcasts,
        openTickets,
        totalRevenueMinor: revenueAgg._sum.totalRevenueMinor || 0,
      },
    });
  } catch (err) {
    console.error('Admin stats error:', err);
    res.status(500).json({ success: false, message: 'স্ট্যাটস আনতে সমস্যা হয়েছে' });
  }
};

// ─────────────────────────── User management ───────────────────────────

const USER_SELECT = {
  id: true,
  email: true,
  fullName: true,
  phone: true,
  role: true,
  plan: true,
  planExpiresAt: true,
  businessName: true,
  totalEvents: true,
  totalRevenueMinor: true,
  totalClients: true,
  deletedAt: true,
  createdAt: true,
};

// GET /api/admin/users?search=&role=&limit=&offset=
exports.listUsers = async (req, res) => {
  try {
    const { search, role, limit = 50, offset = 0 } = req.query;
    const where = {};
    if (role) where.role = normalizeRole(role) || undefined;
    if (search) {
      where.OR = [
        { email: { contains: search, mode: 'insensitive' } },
        { fullName: { contains: search, mode: 'insensitive' } },
        { businessName: { contains: search, mode: 'insensitive' } },
      ];
    }
    const [users, total] = await Promise.all([
      prisma.user.findMany({
        where,
        select: USER_SELECT,
        orderBy: { createdAt: 'desc' },
        take: Math.min(Number(limit) || 50, 200),
        skip: Number(offset) || 0,
      }),
      prisma.user.count({ where }),
    ]);
    res.json({ success: true, total, count: users.length, data: users });
  } catch (err) {
    console.error('Admin listUsers error:', err);
    res.status(500).json({ success: false, message: 'ইউজার আনতে সমস্যা হয়েছে' });
  }
};

// GET /api/admin/users/:id — full profile + their bookings, clients, payments.
exports.getUserDetail = async (req, res) => {
  try {
    const { id } = req.params;
    const user = await prisma.user.findUnique({
      where: { id },
      select: {
        ...USER_SELECT,
        whatsapp: true,
        businessAddress: true,
        createdAt: true,
      },
    });
    if (!user) {
      return res.status(404).json({ success: false, message: 'ইউজার পাওয়া যায়নি' });
    }

    const [events, clientCount, paymentAgg] = await Promise.all([
      prisma.event.findMany({
        where: { ownerId: id },
        orderBy: { date: 'desc' },
        take: 50,
        select: {
          id: true,
          title: true,
          type: true,
          date: true,
          status: true,
          venue: true,
          client: { select: { name: true } },
        },
      }),
      prisma.client.count({ where: { ownerId: id } }),
      // Sum payments across this owner's events.
      prisma.payment.aggregate({
        _sum: { amount: true },
        _count: true,
        where: { event: { ownerId: id } },
      }),
    ]);

    res.json({
      success: true,
      data: {
        user,
        stats: {
          bookings: events.length,
          clients: clientCount,
          paymentsCount: paymentAgg._count || 0,
          paymentsTotal: paymentAgg._sum.amount || 0,
        },
        bookings: events,
      },
    });
  } catch (err) {
    console.error('Admin getUserDetail error:', err);
    res.status(500).json({ success: false, message: 'ইউজার বিস্তারিত আনতে সমস্যা হয়েছে' });
  }
};

// PATCH /api/admin/users/:id/role  { role }
exports.updateUserRole = async (req, res) => {
  try {
    const { id } = req.params;
    const role = normalizeRole(req.body.role);
    if (!role) {
      return res.status(400).json({ success: false, message: 'সঠিক role দিন' });
    }
    // Guard: don't let an admin strip the LAST admin's powers (lockout).
    if (role !== 'ADMIN') {
      const target = await prisma.user.findUnique({ where: { id } });
      if (target && target.role === 'ADMIN') {
        const adminCount = await prisma.user.count({
          where: { role: 'ADMIN', deletedAt: null },
        });
        if (adminCount <= 1) {
          return res.status(400).json({
            success: false,
            message: 'শেষ অ্যাডমিনের role বদলানো যাবে না',
          });
        }
      }
    }
    const user = await prisma.user.update({
      where: { id },
      data: { role },
      select: USER_SELECT,
    });
    res.json({ success: true, data: user });
  } catch (err) {
    console.error('Admin updateUserRole error:', err);
    res.status(500).json({ success: false, message: 'role আপডেট করতে সমস্যা হয়েছে' });
  }
};

// PATCH /api/admin/users/:id/suspend  { suspended: bool }
// Soft action via deletedAt (reuses the 7-day grace column as a flag).
exports.setUserSuspended = async (req, res) => {
  try {
    const { id } = req.params;
    const suspended = req.body.suspended === true;
    if (suspended && id === req.user.id) {
      return res.status(400).json({ success: false, message: 'নিজেকে suspend করা যাবে না' });
    }
    const user = await prisma.user.update({
      where: { id },
      data: { deletedAt: suspended ? new Date() : null },
      select: USER_SELECT,
    });
    res.json({ success: true, data: user });
  } catch (err) {
    console.error('Admin setUserSuspended error:', err);
    res.status(500).json({ success: false, message: 'suspend করতে সমস্যা হয়েছে' });
  }
};

// POST /api/admin/users  { email, password, fullName, role } — create staff/admin
exports.createUser = async (req, res) => {
  try {
    const { email, password, fullName } = req.body;
    const role = normalizeRole(req.body.role) || 'OWNER';
    if (!email || !password || !fullName) {
      return res.status(400).json({ success: false, message: 'email, password, fullName দিন' });
    }
    const exists = await prisma.user.findUnique({ where: { email } });
    if (exists) {
      return res.status(409).json({ success: false, message: 'এই email আগে থেকেই আছে' });
    }
    const hashed = await bcrypt.hash(password, 10);
    const user = await prisma.user.create({
      data: { email, password: hashed, fullName, role },
      select: USER_SELECT,
    });
    res.status(201).json({ success: true, data: user });
  } catch (err) {
    console.error('Admin createUser error:', err);
    res.status(500).json({ success: false, message: 'ইউজার তৈরিতে সমস্যা হয়েছে' });
  }
};

// ─────────────────────────── Analytics ───────────────────────────

// GET /api/admin/analytics — time-series + breakdowns for charts.
// Last 6 months of signups & bookings, booking status split, top studios.
exports.getAnalytics = async (req, res) => {
  try {
    // Monthly user signups (last 6 months), oldest→newest.
    const signups = await prisma.$queryRaw`
      SELECT to_char(date_trunc('month', "createdAt"), 'YYYY-MM') AS month,
             COUNT(*)::int AS count
      FROM "User"
      WHERE "createdAt" >= NOW() - INTERVAL '6 months'
      GROUP BY month ORDER BY month ASC`;

    // Monthly bookings (by event date), last 6 months.
    const bookings = await prisma.$queryRaw`
      SELECT to_char(date_trunc('month', "date"), 'YYYY-MM') AS month,
             COUNT(*)::int AS count
      FROM "Event"
      WHERE "date" >= NOW() - INTERVAL '6 months'
      GROUP BY month ORDER BY month ASC`;

    // Booking status breakdown.
    const statusRows = await prisma.event.groupBy({
      by: ['status'],
      _count: true,
    });
    const statusBreakdown = statusRows.map((r) => ({
      status: r.status,
      count: r._count,
    }));

    // Top studios by booking count.
    const topRows = await prisma.event.groupBy({
      by: ['ownerId'],
      _count: true,
      orderBy: { _count: { ownerId: 'desc' } },
      take: 5,
    });
    const owners = await prisma.user.findMany({
      where: { id: { in: topRows.map((r) => r.ownerId) } },
      select: { id: true, fullName: true, businessName: true },
    });
    const ownerMap = Object.fromEntries(owners.map((o) => [o.id, o]));
    const topStudios = topRows.map((r) => ({
      ownerId: r.ownerId,
      name: ownerMap[r.ownerId]?.businessName || ownerMap[r.ownerId]?.fullName || 'Unknown',
      bookings: r._count,
    }));

    res.json({
      success: true,
      data: { signups, bookings, statusBreakdown, topStudios },
    });
  } catch (err) {
    console.error('Admin getAnalytics error:', err);
    res.status(500).json({ success: false, message: 'অ্যানালিটিক্স আনতে সমস্যা হয়েছে' });
  }
};

// ─────────────────────── Bookings overview (all studios) ───────────────────────

// GET /api/admin/bookings?search=&status=&limit=&offset=
exports.listBookings = async (req, res) => {
  try {
    const { search, status, limit = 50, offset = 0 } = req.query;
    const where = {};
    if (status) where.status = status.toUpperCase();
    if (search) {
      where.OR = [
        { title: { contains: search, mode: 'insensitive' } },
        { venue: { contains: search, mode: 'insensitive' } },
        { client: { name: { contains: search, mode: 'insensitive' } } },
        { owner: { fullName: { contains: search, mode: 'insensitive' } } },
      ];
    }
    const [events, total] = await Promise.all([
      prisma.event.findMany({
        where,
        orderBy: { date: 'desc' },
        take: Math.min(Number(limit) || 50, 200),
        skip: Number(offset) || 0,
        select: {
          id: true,
          title: true,
          type: true,
          date: true,
          status: true,
          venue: true,
          client: { select: { name: true } },
          owner: { select: { id: true, fullName: true, businessName: true } },
        },
      }),
      prisma.event.count({ where }),
    ]);
    res.json({ success: true, total, count: events.length, data: events });
  } catch (err) {
    console.error('Admin listBookings error:', err);
    res.status(500).json({ success: false, message: 'বুকিং আনতে সমস্যা হয়েছে' });
  }
};

// ─────────────────────────── Broadcasts ───────────────────────────

// GET /api/admin/broadcasts — all (any status), newest first.
exports.listBroadcasts = async (req, res) => {
  try {
    const broadcasts = await prisma.broadcast.findMany({
      orderBy: { createdAt: 'desc' },
    });
    res.json({ success: true, count: broadcasts.length, data: broadcasts });
  } catch (err) {
    console.error('Admin listBroadcasts error:', err);
    res.status(500).json({ success: false, message: 'নোটিশ আনতে সমস্যা হয়েছে' });
  }
};

// POST /api/admin/broadcasts
exports.createBroadcast = async (req, res) => {
  try {
    const { title, content, imageUrl, buttonLabel, link, priority, type, audience } = req.body;
    if (!title || !content) {
      return res.status(400).json({ success: false, message: 'title ও content দিন' });
    }
    // audience: 'all' | 'owner' | 'freelancer' — stored as { roles: [...] }.
    // 'all' (or empty) means no targeting (everyone sees it).
    let targetAudience = null;
    if (audience && audience !== 'all') {
      targetAudience = { roles: [audience.toUpperCase()] };
    }
    const broadcast = await prisma.broadcast.create({
      data: {
        title,
        content,
        imageUrl: imageUrl || null,
        buttonLabel: buttonLabel || null,
        link: link || null,
        priority: priority || 'Normal',
        type: type || 'Announcement',
        targetAudience,
        status: 'ACTIVE',
        displayDuration: 10,
      },
    });
    res.status(201).json({ success: true, data: broadcast });
  } catch (err) {
    console.error('Admin createBroadcast error:', err);
    res.status(500).json({ success: false, message: 'নোটিশ তৈরিতে সমস্যা হয়েছে' });
  }
};

// PATCH /api/admin/broadcasts/:id  { status } — toggle ACTIVE/ARCHIVED
exports.updateBroadcast = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, title, content } = req.body;
    const data = {};
    if (status !== undefined) data.status = status;
    if (title !== undefined) data.title = title;
    if (content !== undefined) data.content = content;
    const broadcast = await prisma.broadcast.update({ where: { id }, data });
    res.json({ success: true, data: broadcast });
  } catch (err) {
    console.error('Admin updateBroadcast error:', err);
    res.status(500).json({ success: false, message: 'নোটিশ আপডেটে সমস্যা হয়েছে' });
  }
};

// DELETE /api/admin/broadcasts/:id
exports.deleteBroadcast = async (req, res) => {
  try {
    await prisma.broadcast.delete({ where: { id: req.params.id } });
    res.json({ success: true, message: 'মুছে ফেলা হয়েছে' });
  } catch (err) {
    console.error('Admin deleteBroadcast error:', err);
    res.status(500).json({ success: false, message: 'মুছতে সমস্যা হয়েছে' });
  }
};

// ─────────────────────── Support tickets ───────────────────────

// GET /api/admin/tickets?status=
exports.listTickets = async (req, res) => {
  try {
    const { status } = req.query;
    const where = {};
    if (status) where.status = status.toUpperCase();
    const tickets = await prisma.supportTicket.findMany({
      where,
      orderBy: { createdAt: 'desc' },
    });
    res.json({ success: true, count: tickets.length, data: tickets });
  } catch (err) {
    console.error('Admin listTickets error:', err);
    res.status(500).json({ success: false, message: 'টিকিট আনতে সমস্যা হয়েছে' });
  }
};

// PATCH /api/admin/tickets/:id  { status } — OPEN/IN_PROGRESS/CLOSED
exports.updateTicket = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;
    if (!status) {
      return res.status(400).json({ success: false, message: 'status দিন' });
    }
    const ticket = await prisma.supportTicket.update({
      where: { id },
      data: { status: status.toUpperCase() },
    });
    res.json({ success: true, data: ticket });
  } catch (err) {
    console.error('Admin updateTicket error:', err);
    res.status(500).json({ success: false, message: 'টিকিট আপডেটে সমস্যা হয়েছে' });
  }
};

// ─────────────────────────── FAQ ───────────────────────────

exports.listFaqs = async (req, res) => {
  try {
    const faqs = await prisma.fAQ.findMany({ orderBy: { order: 'asc' } });
    res.json({ success: true, count: faqs.length, data: faqs });
  } catch (err) {
    console.error('Admin listFaqs error:', err);
    res.status(500).json({ success: false, message: 'FAQ আনতে সমস্যা হয়েছে' });
  }
};

exports.createFaq = async (req, res) => {
  try {
    const { question, answer, category, order } = req.body;
    if (!question || !answer) {
      return res.status(400).json({ success: false, message: 'question ও answer দিন' });
    }
    const faq = await prisma.fAQ.create({
      data: {
        question,
        answer,
        category: category || 'General',
        order: Number(order) || 0,
      },
    });
    res.status(201).json({ success: true, data: faq });
  } catch (err) {
    console.error('Admin createFaq error:', err);
    res.status(500).json({ success: false, message: 'FAQ তৈরিতে সমস্যা হয়েছে' });
  }
};

exports.updateFaq = async (req, res) => {
  try {
    const { id } = req.params;
    const { question, answer, category, order } = req.body;
    const data = {};
    if (question !== undefined) data.question = question;
    if (answer !== undefined) data.answer = answer;
    if (category !== undefined) data.category = category;
    if (order !== undefined) data.order = Number(order);
    const faq = await prisma.fAQ.update({ where: { id }, data });
    res.json({ success: true, data: faq });
  } catch (err) {
    console.error('Admin updateFaq error:', err);
    res.status(500).json({ success: false, message: 'FAQ আপডেটে সমস্যা হয়েছে' });
  }
};

exports.deleteFaq = async (req, res) => {
  try {
    await prisma.fAQ.delete({ where: { id: req.params.id } });
    res.json({ success: true, message: 'মুছে ফেলা হয়েছে' });
  } catch (err) {
    console.error('Admin deleteFaq error:', err);
    res.status(500).json({ success: false, message: 'মুছতে সমস্যা হয়েছে' });
  }
};

// ─────────────────────── Feature flags (gating) ───────────────────────

// GET /api/admin/features — the gating registry.
exports.listFeatures = async (req, res) => {
  try {
    const features = await prisma.featureFlag.findMany({ orderBy: { label: 'asc' } });
    res.json({ success: true, count: features.length, data: features });
  } catch (err) {
    console.error('Admin listFeatures error:', err);
    res.status(500).json({ success: false, message: 'ফিচার আনতে সমস্যা হয়েছে' });
  }
};

// PATCH /api/admin/features/:key  { requiresPro: bool } — make a feature paid/free.
exports.updateFeature = async (req, res) => {
  try {
    const { key } = req.params;
    const { requiresPro, label, description } = req.body;
    const data = {};
    if (requiresPro !== undefined) data.requiresPro = requiresPro === true;
    if (label !== undefined) data.label = label;
    if (description !== undefined) data.description = description;
    const feature = await prisma.featureFlag.update({ where: { key }, data });
    res.json({ success: true, data: feature });
  } catch (err) {
    console.error('Admin updateFeature error:', err);
    res.status(500).json({ success: false, message: 'ফিচার আপডেটে সমস্যা হয়েছে' });
  }
};

// PATCH /api/admin/users/:id/plan  { plan, planExpiresAt } — grant/revoke PRO.
exports.updateUserPlan = async (req, res) => {
  try {
    const { id } = req.params;
    const plan = (req.body.plan || '').toString().toUpperCase();
    if (!['FREE', 'PRO'].includes(plan)) {
      return res.status(400).json({ success: false, message: 'plan FREE বা PRO হতে হবে' });
    }
    const planExpiresAt =
      plan === 'PRO' && req.body.planExpiresAt ? new Date(req.body.planExpiresAt) : null;
    const user = await prisma.user.update({
      where: { id },
      data: { plan, planExpiresAt },
      select: { ...USER_SELECT, plan: true, planExpiresAt: true },
    });
    res.json({ success: true, data: user });
  } catch (err) {
    console.error('Admin updateUserPlan error:', err);
    res.status(500).json({ success: false, message: 'plan আপডেটে সমস্যা হয়েছে' });
  }
};

// ─────────────────────── Payments (history view) ───────────────────────

// GET /api/admin/payments?limit=&offset= — all payments across studios.
exports.listPayments = async (req, res) => {
  try {
    const { limit = 50, offset = 0 } = req.query;
    const [payments, total, agg] = await Promise.all([
      prisma.payment.findMany({
        orderBy: { date: 'desc' },
        take: Math.min(Number(limit) || 50, 200),
        skip: Number(offset) || 0,
        select: {
          id: true, amount: true, kind: true, method: true,
          transactionId: true, date: true, note: true,
          event: {
            select: {
              title: true,
              owner: { select: { fullName: true, businessName: true } },
              client: { select: { name: true } },
            },
          },
        },
      }),
      prisma.payment.count(),
      prisma.payment.aggregate({ _sum: { amount: true } }),
    ]);
    res.json({
      success: true,
      total,
      totalAmount: agg._sum.amount || 0,
      data: payments,
    });
  } catch (err) {
    console.error('Admin listPayments error:', err);
    res.status(500).json({ success: false, message: 'পেমেন্ট আনতে সমস্যা হয়েছে' });
  }
};

// POST /api/admin/users/:id/grant-pro  { days } — manual payment approval:
// admin confirms an off-platform payment (bKash etc.) and grants PRO.
exports.grantProManual = async (req, res) => {
  try {
    const { id } = req.params;
    const days = Number(req.body.days) || 30;
    const user = await prisma.user.findUnique({ where: { id } });
    if (!user) return res.status(404).json({ success: false, message: 'ইউজার পাওয়া যায়নি' });
    const base = user.planExpiresAt && user.planExpiresAt.getTime() > Date.now()
      ? user.planExpiresAt.getTime()
      : Date.now();
    const updated = await prisma.user.update({
      where: { id },
      data: { plan: 'PRO', planExpiresAt: new Date(base + days * 86400000) },
      select: { ...USER_SELECT, plan: true, planExpiresAt: true },
    });
    res.json({ success: true, data: updated });
  } catch (err) {
    console.error('Admin grantProManual error:', err);
    res.status(500).json({ success: false, message: 'PRO দিতে সমস্যা হয়েছে' });
  }
};

// ─────────────────────────── CSV export ───────────────────────────

// Minimal CSV serializer — quotes fields, escapes embedded quotes.
function toCsv(headers, rows) {
  const esc = (v) => {
    const s = v === null || v === undefined ? '' : String(v);
    return `"${s.replace(/"/g, '""')}"`;
  };
  const lines = [headers.map(esc).join(',')];
  for (const row of rows) lines.push(row.map(esc).join(','));
  return lines.join('\n');
}

// GET /api/admin/export/users.csv
exports.exportUsers = async (req, res) => {
  try {
    const users = await prisma.user.findMany({
      orderBy: { createdAt: 'desc' },
      select: {
        fullName: true, email: true, phone: true, role: true, plan: true,
        businessName: true, totalEvents: true, totalClients: true,
        deletedAt: true, createdAt: true,
      },
    });
    const headers = ['Name', 'Email', 'Phone', 'Role', 'Plan', 'Business', 'Bookings', 'Clients', 'Status', 'Joined'];
    const rows = users.map((u) => [
      u.fullName, u.email, u.phone || '', u.role, u.plan, u.businessName || '',
      u.totalEvents, u.totalClients, u.deletedAt ? 'Suspended' : 'Active',
      u.createdAt.toISOString().slice(0, 10),
    ]);
    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename="users.csv"');
    res.send(toCsv(headers, rows));
  } catch (err) {
    console.error('Admin exportUsers error:', err);
    res.status(500).json({ success: false, message: 'এক্সপোর্টে সমস্যা হয়েছে' });
  }
};

// GET /api/admin/export/bookings.csv
exports.exportBookings = async (req, res) => {
  try {
    const events = await prisma.event.findMany({
      orderBy: { date: 'desc' },
      select: {
        title: true, type: true, date: true, status: true, venue: true,
        client: { select: { name: true } },
        owner: { select: { fullName: true, businessName: true } },
      },
    });
    const headers = ['Title', 'Type', 'Date', 'Status', 'Venue', 'Client', 'Studio'];
    const rows = events.map((e) => [
      e.title, e.type, e.date.toISOString().slice(0, 10), e.status, e.venue,
      e.client?.name || '', e.owner?.businessName || e.owner?.fullName || '',
    ]);
    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename="bookings.csv"');
    res.send(toCsv(headers, rows));
  } catch (err) {
    console.error('Admin exportBookings error:', err);
    res.status(500).json({ success: false, message: 'এক্সপোর্টে সমস্যা হয়েছে' });
  }
};

// GET /api/admin/export/payments.csv
exports.exportPayments = async (req, res) => {
  try {
    const payments = await prisma.payment.findMany({
      orderBy: { date: 'desc' },
      select: {
        amount: true, kind: true, method: true, transactionId: true, date: true,
        event: { select: { title: true, owner: { select: { fullName: true, businessName: true } } } },
      },
    });
    const headers = ['Date', 'Amount', 'Kind', 'Method', 'TxnId', 'Booking', 'Studio'];
    const rows = payments.map((p) => [
      p.date.toISOString().slice(0, 10), p.amount, p.kind, p.method,
      p.transactionId || '', p.event?.title || '',
      p.event?.owner?.businessName || p.event?.owner?.fullName || '',
    ]);
    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename="payments.csv"');
    res.send(toCsv(headers, rows));
  } catch (err) {
    console.error('Admin exportPayments error:', err);
    res.status(500).json({ success: false, message: 'এক্সপোর্টে সমস্যা হয়েছে' });
  }
};

// ─────────────────────────── Audit log ───────────────────────────

// GET /api/admin/audit?limit=&offset= — ALL audit logs (not owner-scoped,
// unlike the per-user /api/audit-logs surface).
exports.listAudit = async (req, res) => {
  try {
    const { limit = 100, offset = 0 } = req.query;
    const logs = await prisma.auditLog.findMany({
      orderBy: { createdAt: 'desc' },
      take: Math.min(Number(limit) || 100, 300),
      skip: Number(offset) || 0,
    });
    res.json({ success: true, count: logs.length, data: logs });
  } catch (err) {
    console.error('Admin listAudit error:', err);
    res.status(500).json({ success: false, message: 'অডিট লগ আনতে সমস্যা হয়েছে' });
  }
};
