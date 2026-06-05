// tests/auth.test.js
//
// Auth controller smoke — register / login / OTP guards / accept-invite।
// bcrypt কিছু path-এ asynchronously hash করে; test-এ আমরা একটাই pre-computed
// hash ব্যবহার করি যাতে suite দ্রুত (<2s) থাকে।

const bcrypt = require('bcryptjs');
const request = require('supertest');

const { buildApp, signToken, prismaMock } = require('./helpers/testApp');

let app;
beforeAll(() => {
  app = buildApp();
});

beforeEach(() => {
  prismaMock.reset();
});

// ─────────────────────────────────────────────────────────────────────
// POST /api/auth/register
// ─────────────────────────────────────────────────────────────────────
describe('POST /api/auth/register', () => {
  it('valid payload হলে 201 + token + user', async () => {
    prismaMock.user.findUnique.mockResolvedValueOnce(null); // duplicate check
    prismaMock.user.create.mockResolvedValueOnce({
      id: 'u-1',
      email: 'rahim@example.com',
      fullName: 'Rahim',
      role: 'OWNER',
      businessName: 'Rahim Studio',
      language: 'en',
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    const res = await request(app).post('/api/auth/register').send({
      fullName: 'Rahim',
      email: 'rahim@example.com',
      password: 'secret123',
      role: 'OWNER',
      businessName: 'Rahim Studio',
    });

    expect(res.status).toBe(201);
    expect(res.body).toMatchObject({
      token: expect.any(String),
      user: expect.objectContaining({
        id: 'u-1',
        email: 'rahim@example.com',
        role: 'owner', // denormalized lowercase wire format
      }),
    });

    // Password obviously hashed before insert
    const createCall = prismaMock.user.create.mock.calls[0][0];
    expect(createCall.data.password).not.toBe('secret123');
    expect(createCall.data.password.length).toBeGreaterThan(20);
  });

  it('weak password হলে 400', async () => {
    const res = await request(app).post('/api/auth/register').send({
      fullName: 'Rahim',
      email: 'rahim@example.com',
      password: 'short',
      role: 'OWNER',
      businessName: 'X',
    });

    expect(res.status).toBe(400);
    expect(res.body.message).toMatch(/password/i);
  });

  it('OWNER role-এ businessName নেই → 400', async () => {
    const res = await request(app).post('/api/auth/register').send({
      fullName: 'Rahim',
      email: 'rahim@example.com',
      password: 'secret123',
      role: 'OWNER',
    });

    expect(res.status).toBe(400);
    expect(res.body.message).toMatch(/[Cc]ompany/);
  });

  it('Manager role এই path এ 400', async () => {
    const res = await request(app).post('/api/auth/register').send({
      fullName: 'M',
      email: 'm@example.com',
      password: 'secret123',
      role: 'MANAGER',
    });

    expect(res.status).toBe(400);
  });

  it('duplicate email হলে 409', async () => {
    prismaMock.user.findUnique.mockResolvedValueOnce({ id: 'old', email: 'r@x.com' });

    const res = await request(app).post('/api/auth/register').send({
      fullName: 'R',
      email: 'r@x.com',
      password: 'secret123',
      role: 'FREELANCER',
    });

    expect(res.status).toBe(409);
    expect(prismaMock.user.create).not.toHaveBeenCalled();
  });
});

// ─────────────────────────────────────────────────────────────────────
// POST /api/auth/login
// ─────────────────────────────────────────────────────────────────────
describe('POST /api/auth/login', () => {
  // একটাই hash pre-compute করে সব test-এ reuse — bcrypt slow, ফলে 1 hash যথেষ্ট
  let hashedPassword;
  beforeAll(async () => {
    hashedPassword = await bcrypt.hash('secret123', 4);
  });

  it('সঠিক credential হলে 200 + token + user', async () => {
    prismaMock.user.findUnique.mockResolvedValueOnce({
      id: 'u-1',
      email: 'r@x.com',
      fullName: 'R',
      role: 'OWNER',
      password: hashedPassword,
      deletedAt: null,
    });

    const res = await request(app).post('/api/auth/login').send({
      email: 'r@x.com',
      password: 'secret123',
    });

    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({
      token: expect.any(String),
      user: expect.objectContaining({ id: 'u-1', role: 'owner' }),
    });
  });

  it('email নেই হলে 401 generic', async () => {
    prismaMock.user.findUnique.mockResolvedValueOnce(null);

    const res = await request(app).post('/api/auth/login').send({
      email: 'nope@x.com',
      password: 'whatever123',
    });

    expect(res.status).toBe(401);
    expect(res.body.message).toMatch(/ভুল/);
  });

  it('password ভুল হলে 401 generic', async () => {
    prismaMock.user.findUnique.mockResolvedValueOnce({
      id: 'u-1',
      email: 'r@x.com',
      fullName: 'R',
      role: 'OWNER',
      password: hashedPassword,
      deletedAt: null,
    });

    const res = await request(app).post('/api/auth/login').send({
      email: 'r@x.com',
      password: 'WRONG-pwd1',
    });

    expect(res.status).toBe(401);
  });

  it('email/password missing হলে 400', async () => {
    const res = await request(app).post('/api/auth/login').send({});
    expect(res.status).toBe(400);
  });
});

// ─────────────────────────────────────────────────────────────────────
// POST /api/auth/otp/request — rate-limit guard
// ─────────────────────────────────────────────────────────────────────
describe('POST /api/auth/otp/request', () => {
  it('valid identifier + purpose → 200', async () => {
    prismaMock.otpCode.count.mockResolvedValueOnce(0);
    prismaMock.otpCode.updateMany.mockResolvedValueOnce({ count: 0 });
    prismaMock.otpCode.create.mockResolvedValueOnce({});

    const res = await request(app).post('/api/auth/otp/request').send({
      identifier: 'r@x.com',
      purpose: 'login',
    });

    expect(res.status).toBe(200);
    expect(prismaMock.otpCode.create).toHaveBeenCalled();
  });

  it('invalid purpose → 400', async () => {
    const res = await request(app).post('/api/auth/otp/request').send({
      identifier: 'r@x.com',
      purpose: 'nonsense',
    });
    expect(res.status).toBe(400);
  });

  it('rate-limit exceeded → 429', async () => {
    prismaMock.otpCode.count.mockResolvedValueOnce(5); // hit cap

    const res = await request(app).post('/api/auth/otp/request').send({
      identifier: 'r@x.com',
      purpose: 'signup',
    });

    expect(res.status).toBe(429);
    expect(prismaMock.otpCode.create).not.toHaveBeenCalled();
  });
});

// ─────────────────────────────────────────────────────────────────────
// POST /api/auth/accept-invite
// ─────────────────────────────────────────────────────────────────────
describe('POST /api/auth/accept-invite', () => {
  it('invalid 6-digit code → 400', async () => {
    const res = await request(app).post('/api/auth/accept-invite').send({
      code: '12',
      fullName: 'M',
      email: 'm@x.com',
      password: 'secret123',
    });
    expect(res.status).toBe(400);
  });

  it('expired invite → 410', async () => {
    prismaMock.teamInviteCode.findUnique.mockResolvedValueOnce({
      id: 'inv-1',
      code: '123456',
      ownerId: 'owner-1',
      role: 'MANAGER',
      consumedAt: null,
      expiresAt: new Date(Date.now() - 1000), // already expired
    });

    const res = await request(app).post('/api/auth/accept-invite').send({
      code: '123456',
      fullName: 'M',
      email: 'm@x.com',
      password: 'secret123',
    });

    expect(res.status).toBe(410);
  });
});

// ─────────────────────────────────────────────────────────────────────
// Suppress occasional console.log from authController OTP dev-mode print
// (`[OTP] login → ...`) যাতে test output পরিষ্কার থাকে
// ─────────────────────────────────────────────────────────────────────
beforeAll(() => {
  jest.spyOn(console, 'log').mockImplementation(() => {});
});

// ─────────────────────────────────────────────────────────────────────
// POST /api/auth/forgot — generic ack (no enumeration)
// ─────────────────────────────────────────────────────────────────────
describe('POST /api/auth/forgot', () => {
  it('email registered → 200 + OTP issued', async () => {
    prismaMock.user.findUnique.mockResolvedValueOnce({
      id: 'u-1',
      email: 'r@x.com',
    });
    prismaMock.otpCode.updateMany.mockResolvedValueOnce({ count: 0 });
    prismaMock.otpCode.create.mockResolvedValueOnce({});

    const res = await request(app)
      .post('/api/auth/forgot')
      .send({ email: 'r@x.com' });

    expect(res.status).toBe(200);
    expect(prismaMock.otpCode.create).toHaveBeenCalled();
  });

  it('email not registered → 200 generic (no enumeration leak)', async () => {
    prismaMock.user.findUnique.mockResolvedValueOnce(null);

    const res = await request(app)
      .post('/api/auth/forgot')
      .send({ email: 'nobody@x.com' });

    expect(res.status).toBe(200);
    expect(prismaMock.otpCode.create).not.toHaveBeenCalled();
  });

  it('invalid email → 400', async () => {
    const res = await request(app)
      .post('/api/auth/forgot')
      .send({ email: 'nope' });

    expect(res.status).toBe(400);
  });
});

// ─────────────────────────────────────────────────────────────────────
// POST /api/auth/reset — token + newPassword
// ─────────────────────────────────────────────────────────────────────
describe('POST /api/auth/reset', () => {
  it('valid token + strong password → 200', async () => {
    prismaMock.passwordResetToken.findUnique.mockResolvedValueOnce({
      id: 'tok-1',
      userId: 'u-1',
      consumedAt: null,
      expiresAt: new Date(Date.now() + 30 * 60 * 1000),
    });
    prismaMock.user.update.mockResolvedValueOnce({});
    prismaMock.passwordResetToken.update.mockResolvedValueOnce({});

    const res = await request(app)
      .post('/api/auth/reset')
      .send({ token: 'rawtoken123', newPassword: 'newpass123' });

    expect(res.status).toBe(200);
  });

  it('missing token → 400', async () => {
    const res = await request(app)
      .post('/api/auth/reset')
      .send({ newPassword: 'newpass123' });

    expect(res.status).toBe(400);
  });

  it('weak newPassword → 400', async () => {
    const res = await request(app)
      .post('/api/auth/reset')
      .send({ token: 'x', newPassword: 'short' });

    expect(res.status).toBe(400);
  });

  it('expired token → 410', async () => {
    prismaMock.passwordResetToken.findUnique.mockResolvedValueOnce({
      id: 'tok-1',
      userId: 'u-1',
      consumedAt: null,
      expiresAt: new Date(Date.now() - 1000),
    });

    const res = await request(app)
      .post('/api/auth/reset')
      .send({ token: 'rawtoken123', newPassword: 'newpass123' });

    expect(res.status).toBe(410);
  });

  it('consumed token → 410', async () => {
    prismaMock.passwordResetToken.findUnique.mockResolvedValueOnce({
      id: 'tok-1',
      userId: 'u-1',
      consumedAt: new Date(),
      expiresAt: new Date(Date.now() + 30 * 60 * 1000),
    });

    const res = await request(app)
      .post('/api/auth/reset')
      .send({ token: 'rawtoken123', newPassword: 'newpass123' });

    expect(res.status).toBe(410);
  });
});

// ─────────────────────────────────────────────────────────────────────
// POST /api/auth/otp/verify — purpose branches
// ─────────────────────────────────────────────────────────────────────
describe('POST /api/auth/otp/verify', () => {
  let bcryptHashedCode;
  beforeAll(async () => {
    const bcrypt = require('bcryptjs');
    bcryptHashedCode = await bcrypt.hash('123456', 4);
  });

  it('signup: matching code returns session', async () => {
    prismaMock.otpCode.findFirst.mockResolvedValueOnce({
      id: 'otp-1',
      identifier: 'r@x.com',
      purpose: 'signup',
      consumedAt: null,
      expiresAt: new Date(Date.now() + 10 * 60 * 1000),
      attempts: 0,
      codeHash: bcryptHashedCode,
    });
    prismaMock.otpCode.update.mockResolvedValueOnce({});
    prismaMock.user.findUnique.mockResolvedValueOnce({
      id: 'u-1',
      email: 'r@x.com',
      fullName: 'R',
      role: 'OWNER',
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    const res = await request(app).post('/api/auth/otp/verify').send({
      identifier: 'r@x.com',
      code: '123456',
      purpose: 'signup',
    });

    expect(res.status).toBe(200);
    expect(res.body.token).toBeDefined();
  });

  it('forgotPassword: matching code returns reset-token', async () => {
    prismaMock.otpCode.findFirst.mockResolvedValueOnce({
      id: 'otp-1',
      identifier: 'r@x.com',
      purpose: 'forgotPassword',
      consumedAt: null,
      expiresAt: new Date(Date.now() + 10 * 60 * 1000),
      attempts: 0,
      codeHash: bcryptHashedCode,
    });
    prismaMock.otpCode.update.mockResolvedValueOnce({});
    prismaMock.user.findUnique.mockResolvedValueOnce({
      id: 'u-1',
      fullName: 'R',
      email: 'r@x.com',
      role: 'OWNER',
    });
    prismaMock.passwordResetToken.create.mockResolvedValueOnce({});

    const res = await request(app).post('/api/auth/otp/verify').send({
      identifier: 'r@x.com',
      code: '123456',
      purpose: 'forgotPassword',
    });

    expect(res.status).toBe(200);
    expect(res.body.token).toBeDefined();
    expect(prismaMock.passwordResetToken.create).toHaveBeenCalled();
  });

  it('wrong code → 400 + attempts incremented', async () => {
    prismaMock.otpCode.findFirst.mockResolvedValueOnce({
      id: 'otp-1',
      identifier: 'r@x.com',
      purpose: 'login',
      consumedAt: null,
      expiresAt: new Date(Date.now() + 10 * 60 * 1000),
      attempts: 0,
      codeHash: bcryptHashedCode,
    });
    prismaMock.otpCode.update.mockResolvedValueOnce({});

    const res = await request(app).post('/api/auth/otp/verify').send({
      identifier: 'r@x.com',
      code: 'wrong1',
      purpose: 'login',
    });

    expect(res.status).toBe(400);
    expect(prismaMock.otpCode.update).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          attempts: { increment: 1 },
        }),
      }),
    );
  });

  it('no OTP exists → 410', async () => {
    prismaMock.otpCode.findFirst.mockResolvedValueOnce(null);

    const res = await request(app).post('/api/auth/otp/verify').send({
      identifier: 'r@x.com',
      code: '123456',
      purpose: 'login',
    });

    expect(res.status).toBe(410);
  });

  it('expired OTP → 410', async () => {
    prismaMock.otpCode.findFirst.mockResolvedValueOnce({
      id: 'otp-1',
      identifier: 'r@x.com',
      purpose: 'login',
      consumedAt: null,
      expiresAt: new Date(Date.now() - 1000),
      attempts: 0,
      codeHash: bcryptHashedCode,
    });

    const res = await request(app).post('/api/auth/otp/verify').send({
      identifier: 'r@x.com',
      code: '123456',
      purpose: 'login',
    });

    expect(res.status).toBe(410);
  });

  it('5+ attempts → 410 (locked out)', async () => {
    prismaMock.otpCode.findFirst.mockResolvedValueOnce({
      id: 'otp-1',
      identifier: 'r@x.com',
      purpose: 'login',
      consumedAt: null,
      expiresAt: new Date(Date.now() + 10 * 60 * 1000),
      attempts: 5,
      codeHash: bcryptHashedCode,
    });

    const res = await request(app).post('/api/auth/otp/verify').send({
      identifier: 'r@x.com',
      code: '123456',
      purpose: 'login',
    });

    expect(res.status).toBe(410);
  });

  it('missing fields → 400', async () => {
    const res = await request(app)
      .post('/api/auth/otp/verify')
      .send({ identifier: 'r@x.com' });

    expect(res.status).toBe(400);
  });
});

// ─────────────────────────────────────────────────────────────────────
// POST /api/profile/role — changeRole flow (mounted via profileRoutes)
// ─────────────────────────────────────────────────────────────────────
describe('POST /api/profile/role', () => {
  it('Owner → Freelancer → 200', async () => {
    const token = signToken({ id: 'u-1', role: 'OWNER' });
    prismaMock.user.findUnique.mockResolvedValueOnce({ role: 'OWNER' });
    prismaMock.user.update.mockResolvedValueOnce({
      id: 'u-1',
      email: 'r@x.com',
      fullName: 'R',
      role: 'FREELANCER',
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    const res = await request(app)
      .post('/api/profile/role')
      .set('Authorization', `Bearer ${token}`)
      .send({ newRole: 'FREELANCER' });

    expect(res.status).toBe(200);
    expect(res.body.user.role).toBe('freelancer');
  });

  it('Targeting MANAGER role → 403', async () => {
    const token = signToken({ role: 'OWNER' });
    const res = await request(app)
      .post('/api/profile/role')
      .set('Authorization', `Bearer ${token}`)
      .send({ newRole: 'MANAGER' });

    expect(res.status).toBe(403);
  });

  it('Targeting ADMIN role → 403', async () => {
    const token = signToken({ role: 'OWNER' });
    const res = await request(app)
      .post('/api/profile/role')
      .set('Authorization', `Bearer ${token}`)
      .send({ newRole: 'ADMIN' });

    expect(res.status).toBe(403);
  });

  it('Caller currently MANAGER → 403', async () => {
    const token = signToken({ id: 'mgr-1', role: 'MANAGER' });
    prismaMock.user.findUnique.mockResolvedValueOnce({ role: 'MANAGER' });

    const res = await request(app)
      .post('/api/profile/role')
      .set('Authorization', `Bearer ${token}`)
      .send({ newRole: 'OWNER' });

    expect(res.status).toBe(403);
  });

  it('Invalid newRole → 400', async () => {
    const token = signToken({ role: 'OWNER' });
    const res = await request(app)
      .post('/api/profile/role')
      .set('Authorization', `Bearer ${token}`)
      .send({ newRole: 'BANANA' });

    expect(res.status).toBe(400);
  });

  it('User not found → 404', async () => {
    const token = signToken({ id: 'ghost', role: 'OWNER' });
    prismaMock.user.findUnique.mockResolvedValueOnce(null);

    const res = await request(app)
      .post('/api/profile/role')
      .set('Authorization', `Bearer ${token}`)
      .send({ newRole: 'FREELANCER' });

    expect(res.status).toBe(404);
  });
});

// ─────────────────────────────────────────────────────────────────────
// POST /api/auth/accept-invite — happy path with team membership
// ─────────────────────────────────────────────────────────────────────
describe('POST /api/auth/accept-invite — happy path', () => {
  it('valid invite + valid creds → 201 with session', async () => {
    prismaMock.teamInviteCode.findUnique.mockResolvedValueOnce({
      id: 'inv-1',
      code: '123456',
      ownerId: 'owner-1',
      role: 'MANAGER',
      consumedAt: null,
      expiresAt: new Date(Date.now() + 60 * 60 * 1000),
    });
    prismaMock.user.findUnique.mockResolvedValueOnce(null); // no duplicate

    // $transaction is wired to call the callback with the mock client
    prismaMock.user.create.mockResolvedValueOnce({
      id: 'u-new',
      email: 'm@x.com',
      fullName: 'M',
      role: 'MANAGER',
      ownerId: 'owner-1',
      createdAt: new Date(),
      updatedAt: new Date(),
    });
    prismaMock.teamInviteCode.update.mockResolvedValueOnce({});
    prismaMock.teamMembership.create.mockResolvedValueOnce({});

    const res = await request(app).post('/api/auth/accept-invite').send({
      code: '123456',
      fullName: 'M',
      email: 'm@x.com',
      password: 'secret123',
    });

    expect(res.status).toBe(201);
    expect(res.body.token).toBeDefined();
  });

  it('invalid code → 404', async () => {
    prismaMock.teamInviteCode.findUnique.mockResolvedValueOnce(null);

    const res = await request(app).post('/api/auth/accept-invite').send({
      code: '999999',
      fullName: 'M',
      email: 'm@x.com',
      password: 'secret123',
    });

    expect(res.status).toBe(404);
  });

  it('consumed code → 410', async () => {
    prismaMock.teamInviteCode.findUnique.mockResolvedValueOnce({
      id: 'inv-1',
      code: '123456',
      ownerId: 'owner-1',
      role: 'MANAGER',
      consumedAt: new Date(),
      expiresAt: new Date(Date.now() + 60 * 60 * 1000),
    });

    const res = await request(app).post('/api/auth/accept-invite').send({
      code: '123456',
      fullName: 'M',
      email: 'm@x.com',
      password: 'secret123',
    });

    expect(res.status).toBe(410);
  });

  it('duplicate email → 409', async () => {
    prismaMock.teamInviteCode.findUnique.mockResolvedValueOnce({
      id: 'inv-1',
      code: '123456',
      ownerId: 'owner-1',
      role: 'MANAGER',
      consumedAt: null,
      expiresAt: new Date(Date.now() + 60 * 60 * 1000),
    });
    prismaMock.user.findUnique.mockResolvedValueOnce({
      id: 'old',
      email: 'm@x.com',
    });

    const res = await request(app).post('/api/auth/accept-invite').send({
      code: '123456',
      fullName: 'M',
      email: 'm@x.com',
      password: 'secret123',
    });

    expect(res.status).toBe(409);
  });

  it('missing fullName → 400', async () => {
    const res = await request(app).post('/api/auth/accept-invite').send({
      code: '123456',
      email: 'm@x.com',
      password: 'secret123',
    });

    expect(res.status).toBe(400);
  });

  it('weak password → 400', async () => {
    const res = await request(app).post('/api/auth/accept-invite').send({
      code: '123456',
      fullName: 'M',
      email: 'm@x.com',
      password: 'short',
    });

    expect(res.status).toBe(400);
  });
});
