// src/controllers/authController.js
//
// Auth flow এর সব handler এখানে। Flutter app যেই shape গুলো expect করে
// (`{ token, user }`) সেটাই সব response এ ফেরত যায়।
//
// Endpoints covered:
//   POST /api/auth/register         — Owner / Freelancer / Both signup
//   POST /api/auth/login            — email + password login
//   POST /api/auth/forgot           — generic ack + dev OTP (testing)
//   POST /api/auth/reset            — token + newPassword
//   POST /api/auth/otp/request      — request OTP for purpose
//   POST /api/auth/otp/verify       — verify OTP
//   POST /api/auth/accept-invite    — Manager onboarding via 6-digit code
//   POST /api/profile/role          — change role for self
//   POST /api/account/delete-request — 7-day grace
//   POST /api/account/cancel-delete  — undo deletion
//   GET  /api/profile               — exposed via profileController
//   GET  /api/legal/privacy|terms   — legalController

const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');

const prisma = require('../lib/prisma');
const { ok, fail, asyncHandler } = require('../lib/response');
const { presentUser, USER_SELECT } = require('../lib/userPresenter');
const { normalizeRole, isSelfRegistrable } = require('../lib/roles');

const JWT_SECRET = process.env.JWT_SECRET || 'ClickerPro_Super_Secret_Key_12345';
const JWT_EXPIRES_IN = '30d';

// ─── helpers ───────────────────────────────────────────────────────

function signToken(user) {
  return jwt.sign({ id: user.id, role: user.role }, JWT_SECRET, {
    expiresIn: JWT_EXPIRES_IN,
  });
}

function isValidEmail(s) {
  return typeof s === 'string' && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(s.trim());
}

function isStrongPassword(s) {
  return (
    typeof s === 'string' &&
    s.length >= 8 &&
    /[A-Za-z]/.test(s) &&
    /\d/.test(s)
  );
}

function generateOtp() {
  // crypto-strong 6-digit OTP (avoids predictable Math.random)
  const buf = crypto.randomBytes(4).readUInt32BE(0);
  return String(buf % 1_000_000).padStart(6, '0');
}

function generateInviteCode() {
  // 6-digit numeric code (Req 1.14)
  const buf = crypto.randomBytes(4).readUInt32BE(0);
  return String(buf % 1_000_000).padStart(6, '0');
}

async function buildSessionResponse(user) {
  const token = signToken(user);
  return { token, user: presentUser(user) };
}

// ─── REGISTER ──────────────────────────────────────────────────────
//
// Body: { name | fullName, email, phone, password, role, language? }
// Response 201: { token, user }
//
// Manager role এই endpoint এ reject — তাদের জন্য /accept-invite।
exports.register = asyncHandler(async (req, res) => {
  const body = req.body || {};
  const fullName = (body.fullName || body.name || '').trim();
  const email = (body.email || '').trim().toLowerCase();
  const phone = (body.phone || '').trim() || null;
  const password = body.password || '';
  const language = body.language === 'bn' ? 'bn' : 'en';
  const businessName =
    (body.businessName || body.companyName || '').toString().trim() || null;

  // role default = OWNER (signup form এর first segment)
  const role = normalizeRole(body.role) || 'OWNER';

  // ── validation
  if (!fullName || fullName.length < 1 || fullName.length > 80) {
    return fail(res, 400, 'Full name 1–80 characters হতে হবে');
  }
  if (!isValidEmail(email)) {
    return fail(res, 400, 'সঠিক email দিন');
  }
  if (!isStrongPassword(password)) {
    return fail(res, 400, 'Password ৮ অক্ষরের বেশি হতে হবে এবং অন্তত ১টি letter ও ১টি digit থাকতে হবে');
  }
  if (!isSelfRegistrable(role)) {
    return fail(res, 400, 'Manager / Admin role এই path এ register করতে পারে না');
  }
  // Owner / Both → company name required.
  if ((role === 'OWNER' || role === 'BOTH') && !businessName) {
    return fail(res, 400, 'Company name দিতে হবে');
  }

  // ── duplicate check
  const existing = await prisma.user.findUnique({ where: { email } });
  if (existing) {
    return fail(res, 409, 'এই email-এ আগে থেকেই একটি account আছে');
  }

  const hashed = await bcrypt.hash(password, 10);

  const user = await prisma.user.create({
    data: {
      fullName,
      email,
      phone,
      password: hashed,
      role,
      language,
      businessName,
    },
    select: USER_SELECT,
  });

  return ok(res, 201, await buildSessionResponse(user));
});

// Records a login attempt for the security/device-history views. Never throws
// (best-effort logging must not break auth).
async function logLogin(req, email, userId, success, reason) {
  try {
    await prisma.loginActivity.create({
      data: {
        email,
        userId: userId || null,
        ip: req.ip || req.headers['x-forwarded-for'] || null,
        userAgent: req.headers['user-agent'] || null,
        success,
        reason: reason || null,
      },
    });
  } catch (_) {
    /* ignore */
  }
}

// ─── LOGIN ─────────────────────────────────────────────────────────
exports.login = asyncHandler(async (req, res) => {
  const email = (req.body?.email || '').trim().toLowerCase();
  const password = req.body?.password || '';
  const totp = req.body?.totp || req.body?.twoFactorToken;

  if (!email || !password) {
    return fail(res, 400, 'Email এবং password দিতে হবে');
  }

  // Reject blocked IPs early.
  const ip = req.ip || req.headers['x-forwarded-for'];
  if (ip) {
    const blocked = await prisma.blockedIp.findUnique({ where: { ip } }).catch(() => null);
    if (blocked) {
      await logLogin(req, email, null, false, 'blocked_ip');
      return fail(res, 403, 'এই IP ব্লক করা হয়েছে');
    }
  }

  const user = await prisma.user.findUnique({ where: { email } });
  if (!user) {
    await logLogin(req, email, null, false, 'no_user');
    // Generic message — কোনো enumeration leak নয়
    return fail(res, 401, 'Email বা password ভুল');
  }

  const passwordOk = await bcrypt.compare(password, user.password);
  if (!passwordOk) {
    await logLogin(req, email, user.id, false, 'bad_password');
    return fail(res, 401, 'Email বা password ভুল');
  }

  // hard-deleted account purge হলে এখানে Login রিজেক্ট হবে
  if (user.deletedAt && user.deletedAt < new Date()) {
    await logLogin(req, email, user.id, false, 'deleted');
    return fail(res, 401, 'এই account এর existence নেই');
  }

  // 2FA gate (admins who enabled it). If enabled and no/invalid code, ask for it.
  if (user.twoFactorEnabled && user.totpSecret) {
    if (!totp) {
      return fail(res, 401, 'twoFactorRequired');
    }
    const speakeasy = require('speakeasy');
    const valid = speakeasy.totp.verify({
      secret: user.totpSecret,
      encoding: 'base32',
      token: String(totp),
      window: 1,
    });
    if (!valid) {
      await logLogin(req, email, user.id, false, 'bad_2fa');
      return fail(res, 401, '2FA কোড সঠিক নয়');
    }
  }

  await logLogin(req, email, user.id, true, null);
  return ok(res, 200, await buildSessionResponse(user));
});

// ─── OTP REQUEST ───────────────────────────────────────────────────
exports.requestOtp = asyncHandler(async (req, res) => {
  const identifier = (req.body?.identifier || '').trim().toLowerCase();
  const purpose = req.body?.purpose;

  if (!identifier) return fail(res, 400, 'identifier দিতে হবে');
  if (!['signup', 'login', 'forgotPassword'].includes(purpose)) {
    return fail(res, 400, 'purpose সঠিক নয়');
  }

  // rate limit — গত 10 মিনিটে 5 এর বেশি না
  const since = new Date(Date.now() - 10 * 60 * 1000);
  const recentCount = await prisma.otpCode.count({
    where: { identifier, purpose, createdAt: { gt: since } },
  });
  if (recentCount >= 5) {
    return fail(res, 429, 'অনেকবার চেষ্টা করেছেন — 10 মিনিট পরে চেষ্টা করুন');
  }

  // আগের unconsumed OTP গুলো invalidate করি (replay-prevention)
  await prisma.otpCode.updateMany({
    where: { identifier, purpose, consumedAt: null },
    data: { consumedAt: new Date() },
  });

  const code = generateOtp();
  const codeHash = await bcrypt.hash(code, 8);

  await prisma.otpCode.create({
    data: {
      identifier,
      purpose,
      codeHash,
      expiresAt: new Date(Date.now() + 10 * 60 * 1000),
    },
  });

  // TODO: production-এ email/SMS gateway hook করুন।
  // এখন development-এ console-এ log করে দিচ্ছি যাতে test করা যায়।
  if (process.env.NODE_ENV !== 'production') {
    console.log(`[OTP] ${purpose} → ${identifier} = ${code}`);
  }

  return ok(res, 200, {});
});

// ─── OTP VERIFY ────────────────────────────────────────────────────
exports.verifyOtp = asyncHandler(async (req, res) => {
  const identifier = (req.body?.identifier || '').trim().toLowerCase();
  const code = (req.body?.code || '').trim();
  const purpose = req.body?.purpose;

  if (!identifier || !code || !purpose) {
    return fail(res, 400, 'identifier, code এবং purpose দিতে হবে');
  }

  const otp = await prisma.otpCode.findFirst({
    where: { identifier, purpose, consumedAt: null },
    orderBy: { createdAt: 'desc' },
  });

  if (!otp) return fail(res, 410, 'Code expired বা invalid');
  if (otp.expiresAt < new Date()) return fail(res, 410, 'Code expired হয়ে গেছে');

  // attempts limit
  if (otp.attempts >= 5) {
    return fail(res, 410, 'অনেকবার ভুল code দিয়েছেন — নতুন code নিন');
  }

  const matches = await bcrypt.compare(code, otp.codeHash);
  if (!matches) {
    await prisma.otpCode.update({
      where: { id: otp.id },
      data: { attempts: { increment: 1 } },
    });
    return fail(res, 400, 'Code সঠিক নয়');
  }

  // consume
  await prisma.otpCode.update({
    where: { id: otp.id },
    data: { consumedAt: new Date() },
  });

  // signup / login: email-এ মিলে যাওয়া user থাকলে session ফেরত দিই
  if (purpose === 'signup' || purpose === 'login') {
    const user = await prisma.user.findUnique({
      where: { email: identifier },
      select: USER_SELECT,
    });
    if (!user) return fail(res, 404, 'এই email-এ কোনো account নেই');
    return ok(res, 200, await buildSessionResponse(user));
  }

  // forgotPassword: 30-min reset token issue করি; Flutter সেটা reset endpoint-এ পাঠাবে
  if (purpose === 'forgotPassword') {
    const user = await prisma.user.findUnique({
      where: { email: identifier },
      select: { id: true, fullName: true, email: true, role: true },
    });
    if (!user) return fail(res, 404, 'এই email-এ কোনো account নেই');

    const rawToken = crypto.randomBytes(32).toString('hex');
    const tokenHash = crypto.createHash('sha256').update(rawToken).digest('hex');

    await prisma.passwordResetToken.create({
      data: {
        userId: user.id,
        tokenHash,
        expiresAt: new Date(Date.now() + 30 * 60 * 1000),
      },
    });

    // Flutter side এ verifyOtp `{ token, user }` expect করে। Reset flow-এ
    // `token` হিসেবে এই reset-token ই পাঠাই; `user` শুধু display এর জন্য।
    return ok(res, 200, {
      token: rawToken,
      user: presentUser(user),
    });
  }

  return fail(res, 400, 'অজানা purpose');
});

// ─── FORGOT PASSWORD ───────────────────────────────────────────────
//
// Generic ack — registered না হলেও same response (no enumeration)।
exports.forgotPassword = asyncHandler(async (req, res) => {
  const email = (req.body?.email || '').trim().toLowerCase();
  if (!isValidEmail(email)) return fail(res, 400, 'সঠিক email দিন');

  const user = await prisma.user.findUnique({ where: { email } });
  if (user) {
    // OTP issue (একই table)
    const code = generateOtp();
    const codeHash = await bcrypt.hash(code, 8);
    await prisma.otpCode.updateMany({
      where: { identifier: email, purpose: 'forgotPassword', consumedAt: null },
      data: { consumedAt: new Date() },
    });
    await prisma.otpCode.create({
      data: {
        identifier: email,
        purpose: 'forgotPassword',
        codeHash,
        expiresAt: new Date(Date.now() + 10 * 60 * 1000),
      },
    });
    if (process.env.NODE_ENV !== 'production') {
      console.log(`[OTP] forgotPassword → ${email} = ${code}`);
    }
  }

  // সব সময় same generic response
  return ok(res, 200, {});
});

// ─── RESET PASSWORD ────────────────────────────────────────────────
exports.resetPassword = asyncHandler(async (req, res) => {
  const token = req.body?.token || '';
  const newPassword = req.body?.newPassword || '';

  if (!token) return fail(res, 400, 'token দিতে হবে');
  if (!isStrongPassword(newPassword)) {
    return fail(res, 400, 'Password ৮ অক্ষরের বেশি, ১টি letter ও ১টি digit থাকতে হবে');
  }

  const tokenHash = crypto.createHash('sha256').update(token).digest('hex');
  const record = await prisma.passwordResetToken.findUnique({
    where: { tokenHash },
  });

  if (!record || record.consumedAt || record.expiresAt < new Date()) {
    return fail(res, 410, 'Reset link expired বা invalid');
  }

  const hashed = await bcrypt.hash(newPassword, 10);
  await prisma.$transaction([
    prisma.user.update({
      where: { id: record.userId },
      data: { password: hashed },
    }),
    prisma.passwordResetToken.update({
      where: { id: record.id },
      data: { consumedAt: new Date() },
    }),
  ]);

  return ok(res, 200, {});
});

// ─── ACCEPT INVITE (Manager onboarding) ────────────────────────────
//
// Body: { code, name, email, password }
// Response 201: { token, user }
exports.acceptInvite = asyncHandler(async (req, res) => {
  const body = req.body || {};
  const code = (body.code || '').trim();
  const fullName = (body.fullName || body.name || '').trim();
  const email = (body.email || '').trim().toLowerCase();
  const password = body.password || '';

  if (!code || code.length !== 6) return fail(res, 400, 'সঠিক 6-digit invite code দিন');
  if (!fullName) return fail(res, 400, 'Full name দিতে হবে');
  if (!isValidEmail(email)) return fail(res, 400, 'সঠিক email দিন');
  if (!isStrongPassword(password)) {
    return fail(res, 400, 'Password ৮ অক্ষরের বেশি, ১টি letter ও ১টি digit থাকতে হবে');
  }

  const invite = await prisma.teamInviteCode.findUnique({ where: { code } });
  if (!invite) return fail(res, 404, 'Invalid or expired code');
  if (invite.consumedAt) return fail(res, 410, 'Invalid or expired code');
  if (invite.expiresAt < new Date()) return fail(res, 410, 'Invalid or expired code');

  const existing = await prisma.user.findUnique({ where: { email } });
  if (existing) {
    return fail(res, 409, 'এই email-এ আগে থেকেই একটি account আছে');
  }

  const hashed = await bcrypt.hash(password, 10);

  // Atomic: user create + invite consume + team membership add
  const user = await prisma.$transaction(async (tx) => {
    const newUser = await tx.user.create({
      data: {
        fullName,
        email,
        password: hashed,
        role: invite.role || 'MANAGER',
        ownerId: invite.ownerId,
      },
      select: USER_SELECT,
    });

    await tx.teamInviteCode.update({
      where: { id: invite.id },
      data: { consumedAt: new Date(), consumedBy: newUser.id },
    });

    await tx.teamMembership.create({
      data: {
        userId: newUser.id,
        ownerId: invite.ownerId,
        role: invite.role || 'MANAGER',
      },
    });

    return newUser;
  });

  return ok(res, 201, await buildSessionResponse(user));
});

// ─── CHANGE ROLE (self) ────────────────────────────────────────────
//
// Manager / Admin block here.
exports.changeRole = asyncHandler(async (req, res) => {
  const newRole = normalizeRole(req.body?.newRole);
  if (!newRole) return fail(res, 400, 'newRole সঠিক নয়');
  if (newRole === 'MANAGER' || newRole === 'ADMIN') {
    return fail(res, 403, 'Manager / Admin role আপনি নিজে নিতে পারবেন না');
  }

  const current = await prisma.user.findUnique({
    where: { id: req.user.id },
    select: { role: true },
  });
  if (!current) return fail(res, 404, 'Account নেই');
  if (current.role === 'MANAGER') {
    return fail(res, 403, 'Manager role থেকে আপনি নিজে role বদলাতে পারবেন না');
  }

  const updated = await prisma.user.update({
    where: { id: req.user.id },
    data: { role: newRole },
    select: USER_SELECT,
  });

  return ok(res, 200, { user: presentUser(updated) });
});

// ─── DELETE ACCOUNT REQUEST (7-day grace) ──────────────────────────
exports.requestDeleteAccount = asyncHandler(async (req, res) => {
  const deletedAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
  await prisma.user.update({
    where: { id: req.user.id },
    data: { deletedAt },
  });
  return ok(res, 200, { deletedAt: deletedAt.toISOString() });
});

exports.cancelDeleteAccount = asyncHandler(async (req, res) => {
  const updated = await prisma.user.update({
    where: { id: req.user.id },
    data: { deletedAt: null },
    select: USER_SELECT,
  });
  return ok(res, 200, { user: presentUser(updated) });
});

// ─── DATA EXPORT (stub) ────────────────────────────────────────────
exports.requestDataExport = asyncHandler(async (req, res) => {
  // Phase 2 এ background job এ চলে যাবে। এখন stub URL ফেরত পাঠাই।
  return ok(res, 202, {
    downloadUrl:
      'https://clickerpro.app/exports/coming-soon?userId=' +
      encodeURIComponent(req.user.id),
  });
});
