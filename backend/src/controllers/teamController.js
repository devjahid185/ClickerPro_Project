// src/controllers/teamController.js
//
// Team / Membership management।
//
// Endpoints:
//   POST   /api/team/invite             — Owner / Both, 24h 6-digit code
//   GET    /api/team/invites            — list active invites I've issued
//   POST   /api/team/invite-by-email    — directly add an existing user (legacy)
//   GET    /api/team/my-companies       — companies I work for (Freelancer / Both)
//   GET    /api/team/members            — members of my studio (Owner / Both / Manager)
//   DELETE /api/team/members/:userId    — remove a member from my studio

const crypto = require('crypto');
const prisma = require('../lib/prisma');
const { ok, fail, asyncHandler } = require('../lib/response');

function generateInviteCode() {
  // crypto-strong 6-digit code
  const buf = crypto.randomBytes(4).readUInt32BE(0);
  return String(buf % 1_000_000).padStart(6, '0');
}

function isOwnerLike(role) {
  return role === 'OWNER' || role === 'BOTH';
}

// ─── POST /api/team/invite ─────────────────────────────────────────
//
// Owner / Both → 6-digit code, expires in 24h, single-use, role=MANAGER।
// Response: { code, expiresAt }
exports.generateInvite = asyncHandler(async (req, res) => {
  if (!isOwnerLike(req.user.role)) {
    return fail(res, 403, 'শুধু Owner বা Both invite generate করতে পারে');
  }

  // try a few times for the (extremely rare) collision
  let code = null;
  for (let i = 0; i < 5; i++) {
    const candidate = generateInviteCode();
    const exists = await prisma.teamInviteCode.findUnique({
      where: { code: candidate },
    });
    if (!exists || exists.consumedAt || exists.expiresAt < new Date()) {
      code = candidate;
      break;
    }
  }
  if (!code) return fail(res, 500, 'Code generate করা যাচ্ছে না — আবার চেষ্টা করুন');

  const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000);

  // upsert (যদি collision হয়ে আগের consumed entry replace হয়)
  await prisma.teamInviteCode.upsert({
    where: { code },
    update: {
      ownerId: req.user.id,
      role: 'MANAGER',
      expiresAt,
      consumedAt: null,
      consumedBy: null,
    },
    create: {
      code,
      ownerId: req.user.id,
      role: 'MANAGER',
      expiresAt,
    },
  });

  return ok(res, 201, {
    code,
    expiresAt: expiresAt.toISOString(),
  });
});

// ─── GET /api/team/invites ─────────────────────────────────────────
exports.listInvites = asyncHandler(async (req, res) => {
  if (!isOwnerLike(req.user.role)) {
    return fail(res, 403, 'শুধু Owner বা Both list দেখতে পারে');
  }
  const invites = await prisma.teamInviteCode.findMany({
    where: { ownerId: req.user.id },
    orderBy: { createdAt: 'desc' },
    take: 20,
  });
  return ok(res, 200, {
    invites: invites.map((i) => ({
      code: i.code,
      expiresAt: i.expiresAt.toISOString(),
      consumedAt: i.consumedAt ? i.consumedAt.toISOString() : null,
      role: String(i.role).toLowerCase(),
    })),
  });
});

// ─── POST /api/team/invite-by-email (legacy) ───────────────────────
exports.inviteMember = asyncHandler(async (req, res) => {
  const email = (req.body?.email || '').trim().toLowerCase();
  const role = (req.body?.role || 'FREELANCER').toUpperCase();

  if (!email) return fail(res, 400, 'email দিতে হবে');
  if (!isOwnerLike(req.user.role)) {
    return fail(res, 403, 'শুধু Owner বা Both team build করতে পারে');
  }

  const member = await prisma.user.findUnique({ where: { email } });
  if (!member) return fail(res, 404, 'এই email-এ কোনো user নেই — আগে register করতে বলুন');
  if (member.id === req.user.id) return fail(res, 400, 'নিজেকে নিজে invite করা যাবে না');

  const existing = await prisma.teamMembership.findUnique({
    where: { userId_ownerId: { userId: member.id, ownerId: req.user.id } },
  });
  if (existing) return fail(res, 409, 'এই user আপনার team-এ আগে থেকেই আছে');

  const membership = await prisma.teamMembership.create({
    data: {
      userId: member.id,
      ownerId: req.user.id,
      role,
    },
    include: {
      user: { select: { id: true, fullName: true, email: true, phone: true } },
    },
  });
  return ok(res, 201, { membership });
});

// ─── GET /api/team/my-companies ────────────────────────────────────
exports.getMyCompanies = asyncHandler(async (req, res) => {
  const memberships = await prisma.teamMembership.findMany({
    where: { userId: req.user.id },
    include: {
      owner: {
        select: {
          id: true,
          fullName: true,
          email: true,
          businessName: true,
          logoUrl: true,
        },
      },
    },
  });
  return ok(res, 200, {
    count: memberships.length,
    companies: memberships,
  });
});

// ─── GET /api/team/members ─────────────────────────────────────────
exports.listMembers = asyncHandler(async (req, res) => {
  if (!isOwnerLike(req.user.role) && req.user.role !== 'MANAGER') {
    return fail(res, 403, 'শুধু Owner / Both / Manager team list দেখতে পারে');
  }
  // Manager এর জন্য তার ownerId এর team দেখাই; Owner এর জন্য নিজের team
  const ownerId = req.user.role === 'MANAGER'
    ? (await prisma.user.findUnique({
        where: { id: req.user.id },
        select: { ownerId: true },
      }))?.ownerId
    : req.user.id;
  if (!ownerId) return ok(res, 200, { members: [] });

  const members = await prisma.teamMembership.findMany({
    where: { ownerId },
    include: {
      user: {
        select: {
          id: true,
          fullName: true,
          email: true,
          phone: true,
          role: true,
          avatarUrl: true,
        },
      },
    },
  });
  return ok(res, 200, { members });
});

// ─── DELETE /api/team/members/:userId ──────────────────────────────
exports.removeMember = asyncHandler(async (req, res) => {
  if (!isOwnerLike(req.user.role)) {
    return fail(res, 403, 'শুধু Owner বা Both member remove করতে পারে');
  }
  const { userId } = req.params;
  const result = await prisma.teamMembership.deleteMany({
    where: { userId, ownerId: req.user.id },
  });
  if (result.count === 0) return fail(res, 404, 'Membership পাওয়া যায়নি');
  return ok(res, 200, {});
});
