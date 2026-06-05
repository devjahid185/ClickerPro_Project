// tests/team.test.js
//
// Team / Membership endpoints — invite generation, listing, legacy add,
// my-companies, member listing (Manager scoping), member removal।

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
// POST /api/team/invite  (6-digit code, 24h)
// ─────────────────────────────────────────────────────────────────────
describe('POST /api/team/invite', () => {
  it('Owner → 201 with 6-digit code + ~24h expiresAt', async () => {
    const token = signToken({ id: 'owner-1', role: 'OWNER' });

    prismaMock.teamInviteCode.findUnique.mockResolvedValueOnce(null); // no collision
    prismaMock.teamInviteCode.upsert.mockResolvedValueOnce({});

    const before = Date.now();
    const res = await request(app)
      .post('/api/team/invite')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(201);
    expect(res.body.code).toMatch(/^\d{6}$/);

    const expiresAt = new Date(res.body.expiresAt).getTime();
    const dayMs = 24 * 60 * 60 * 1000;
    expect(expiresAt - before).toBeGreaterThanOrEqual(dayMs - 5_000);
    expect(expiresAt - before).toBeLessThanOrEqual(dayMs + 5_000);

    // upsert called with role MANAGER + 24h expiry
    const arg = prismaMock.teamInviteCode.upsert.mock.calls[0][0];
    expect(arg.create).toMatchObject({
      ownerId: 'owner-1',
      role: 'MANAGER',
    });
  });

  it('FREELANCER → 403', async () => {
    const token = signToken({ role: 'FREELANCER' });
    const res = await request(app)
      .post('/api/team/invite')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(403);
    expect(prismaMock.teamInviteCode.upsert).not.toHaveBeenCalled();
  });
});

// ─────────────────────────────────────────────────────────────────────
// GET /api/team/invites
// ─────────────────────────────────────────────────────────────────────
describe('GET /api/team/invites', () => {
  it('Owner-scoped descending list, max 20', async () => {
    const token = signToken({ id: 'owner-1', role: 'OWNER' });

    prismaMock.teamInviteCode.findMany.mockResolvedValueOnce([
      {
        code: '123456',
        expiresAt: new Date('2025-12-31'),
        consumedAt: null,
        role: 'MANAGER',
      },
    ]);

    const res = await request(app)
      .get('/api/team/invites')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.invites[0]).toMatchObject({
      code: '123456',
      role: 'manager', // lowercased on the wire
      consumedAt: null,
    });

    expect(prismaMock.teamInviteCode.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { ownerId: 'owner-1' },
        orderBy: { createdAt: 'desc' },
        take: 20,
      }),
    );
  });

  it('FREELANCER → 403', async () => {
    const token = signToken({ role: 'FREELANCER' });
    const res = await request(app)
      .get('/api/team/invites')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(403);
  });
});

// ─────────────────────────────────────────────────────────────────────
// POST /api/team/invite-by-email  (legacy direct add)
// ─────────────────────────────────────────────────────────────────────
describe('POST /api/team/invite-by-email', () => {
  it('Owner adds existing user → 201 + membership', async () => {
    const token = signToken({ id: 'owner-1', role: 'OWNER' });

    prismaMock.user.findUnique.mockResolvedValueOnce({
      id: 'staff-1',
      email: 'k@x.com',
    });
    prismaMock.teamMembership.findUnique.mockResolvedValueOnce(null);
    prismaMock.teamMembership.create.mockResolvedValueOnce({
      id: 'tm-1',
      userId: 'staff-1',
      ownerId: 'owner-1',
      role: 'FREELANCER',
      user: { id: 'staff-1', fullName: 'K', email: 'k@x.com', phone: null },
    });

    const res = await request(app)
      .post('/api/team/invite-by-email')
      .set('Authorization', `Bearer ${token}`)
      .send({ email: 'k@x.com', role: 'freelancer' });

    expect(res.status).toBe(201);
    expect(res.body.membership.user.email).toBe('k@x.com');

    expect(prismaMock.teamMembership.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          userId: 'staff-1',
          ownerId: 'owner-1',
          role: 'FREELANCER', // uppercased
        }),
      }),
    );
  });

  it('email not registered → 404', async () => {
    const token = signToken({ role: 'OWNER' });
    prismaMock.user.findUnique.mockResolvedValueOnce(null);

    const res = await request(app)
      .post('/api/team/invite-by-email')
      .set('Authorization', `Bearer ${token}`)
      .send({ email: 'no@x.com' });

    expect(res.status).toBe(404);
  });

  it('self-invite → 400', async () => {
    const token = signToken({ id: 'owner-1', role: 'OWNER' });
    prismaMock.user.findUnique.mockResolvedValueOnce({
      id: 'owner-1',
      email: 'me@x.com',
    });

    const res = await request(app)
      .post('/api/team/invite-by-email')
      .set('Authorization', `Bearer ${token}`)
      .send({ email: 'me@x.com' });

    expect(res.status).toBe(400);
  });

  it('already a member → 409', async () => {
    const token = signToken({ id: 'owner-1', role: 'OWNER' });
    prismaMock.user.findUnique.mockResolvedValueOnce({
      id: 'staff-1',
      email: 'k@x.com',
    });
    prismaMock.teamMembership.findUnique.mockResolvedValueOnce({
      id: 'tm-existing',
    });

    const res = await request(app)
      .post('/api/team/invite-by-email')
      .set('Authorization', `Bearer ${token}`)
      .send({ email: 'k@x.com' });

    expect(res.status).toBe(409);
  });

  it('email missing → 400', async () => {
    const token = signToken({ role: 'OWNER' });
    const res = await request(app)
      .post('/api/team/invite-by-email')
      .set('Authorization', `Bearer ${token}`)
      .send({});

    expect(res.status).toBe(400);
  });
});

// ─────────────────────────────────────────────────────────────────────
// GET /api/team/my-companies
// ─────────────────────────────────────────────────────────────────────
describe('GET /api/team/my-companies', () => {
  it('returns memberships with owner info joined', async () => {
    const token = signToken({ id: 'staff-1' });
    prismaMock.teamMembership.findMany.mockResolvedValueOnce([
      {
        id: 'tm-1',
        userId: 'staff-1',
        ownerId: 'owner-1',
        owner: {
          id: 'owner-1',
          fullName: 'O',
          email: 'o@x.com',
          businessName: 'O Studio',
          logoUrl: null,
        },
      },
    ]);

    const res = await request(app)
      .get('/api/team/my-companies')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.count).toBe(1);
    expect(res.body.companies[0].owner.businessName).toBe('O Studio');

    expect(prismaMock.teamMembership.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { userId: 'staff-1' },
      }),
    );
  });
});

// ─────────────────────────────────────────────────────────────────────
// GET /api/team/members  (Owner / Both / Manager)
// ─────────────────────────────────────────────────────────────────────
describe('GET /api/team/members', () => {
  it('Owner sees own studio members', async () => {
    const token = signToken({ id: 'owner-1', role: 'OWNER' });
    prismaMock.teamMembership.findMany.mockResolvedValueOnce([
      {
        id: 'tm-1',
        user: {
          id: 'staff-1',
          fullName: 'K',
          email: 'k@x.com',
          phone: null,
          role: 'FREELANCER',
          avatarUrl: null,
        },
      },
    ]);

    const res = await request(app)
      .get('/api/team/members')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.members).toHaveLength(1);

    expect(prismaMock.teamMembership.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ where: { ownerId: 'owner-1' } }),
    );
  });

  it('Manager sees members of their studio (via ownerId lookup)', async () => {
    const token = signToken({ id: 'mgr-1', role: 'MANAGER' });
    prismaMock.user.findUnique.mockResolvedValueOnce({ ownerId: 'owner-1' });
    prismaMock.teamMembership.findMany.mockResolvedValueOnce([]);

    const res = await request(app)
      .get('/api/team/members')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);

    expect(prismaMock.teamMembership.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ where: { ownerId: 'owner-1' } }),
    );
  });

  it('FREELANCER → 403', async () => {
    const token = signToken({ role: 'FREELANCER' });
    const res = await request(app)
      .get('/api/team/members')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(403);
  });
});

// ─────────────────────────────────────────────────────────────────────
// DELETE /api/team/members/:userId
// ─────────────────────────────────────────────────────────────────────
describe('DELETE /api/team/members/:userId', () => {
  it('Owner removes member → 200', async () => {
    const token = signToken({ id: 'owner-1', role: 'OWNER' });
    prismaMock.teamMembership.deleteMany.mockResolvedValueOnce({ count: 1 });

    const res = await request(app)
      .delete('/api/team/members/staff-1')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(prismaMock.teamMembership.deleteMany).toHaveBeenCalledWith({
      where: { userId: 'staff-1', ownerId: 'owner-1' },
    });
  });

  it('membership not found → 404', async () => {
    const token = signToken({ role: 'OWNER' });
    prismaMock.teamMembership.deleteMany.mockResolvedValueOnce({ count: 0 });

    const res = await request(app)
      .delete('/api/team/members/no-such')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(404);
  });

  it('FREELANCER → 403', async () => {
    const token = signToken({ role: 'FREELANCER' });
    const res = await request(app)
      .delete('/api/team/members/staff-1')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(403);
    expect(prismaMock.teamMembership.deleteMany).not.toHaveBeenCalled();
  });
});
