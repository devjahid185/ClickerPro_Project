// tests/profile.test.js
//
// Profile endpoints — get / patch / settings / VAT / lifetime stats।
// Covers Flutter's `name` ↔ `fullName` field aliasing, the
// `bankDetails` string→object coercion, role-gated VAT updates, and
// the empty-body 400 guard।

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
// GET /api/profile
// ─────────────────────────────────────────────────────────────────────
describe('GET /api/profile', () => {
  it('returns presentUser-shaped record', async () => {
    const token = signToken({ id: 'user-1' });

    prismaMock.user.findUnique.mockResolvedValueOnce({
      id: 'user-1',
      email: 'r@x.com',
      fullName: 'R',
      role: 'OWNER',
      businessName: 'R Studio',
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    const res = await request(app)
      .get('/api/profile')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.user).toMatchObject({
      id: 'user-1',
      email: 'r@x.com',
      role: 'owner', // denormalized lowercase
      companyName: 'R Studio', // businessName → companyName on the wire
    });
  });

  it('user missing → 404', async () => {
    const token = signToken();
    prismaMock.user.findUnique.mockResolvedValueOnce(null);

    const res = await request(app)
      .get('/api/profile')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(404);
  });

  it('Authorization missing → 401', async () => {
    const res = await request(app).get('/api/profile');
    expect(res.status).toBe(401);
  });
});

// ─────────────────────────────────────────────────────────────────────
// PATCH /api/profile  (Flutter sends `name`, legacy `fullName` ও support করি)
// ─────────────────────────────────────────────────────────────────────
describe('PATCH /api/profile', () => {
  it('name aliased to fullName, companyName aliased to businessName', async () => {
    const token = signToken({ id: 'user-1' });
    prismaMock.user.update.mockResolvedValueOnce({
      id: 'user-1',
      email: 'r@x.com',
      fullName: 'New Name',
      businessName: 'New Studio',
      role: 'OWNER',
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    const res = await request(app)
      .patch('/api/profile')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'New Name', companyName: 'New Studio' });

    expect(res.status).toBe(200);

    const data = prismaMock.user.update.mock.calls[0][0].data;
    expect(data).toMatchObject({
      fullName: 'New Name',
      businessName: 'New Studio',
    });
  });

  it('bankDetails as string → wrapped as { raw: string }', async () => {
    const token = signToken();
    prismaMock.user.update.mockResolvedValueOnce({
      id: 'user-1',
      email: 'r@x.com',
      fullName: 'R',
      role: 'OWNER',
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    await request(app)
      .patch('/api/profile')
      .set('Authorization', `Bearer ${token}`)
      .send({ bankDetails: 'Account: 1234, Branch: Dhaka' });

    const data = prismaMock.user.update.mock.calls[0][0].data;
    expect(data.bankDetails).toEqual({ raw: 'Account: 1234, Branch: Dhaka' });
  });

  it('bankDetails as object → passed through verbatim', async () => {
    const token = signToken();
    prismaMock.user.update.mockResolvedValueOnce({
      id: 'user-1',
      email: 'r@x.com',
      fullName: 'R',
      role: 'OWNER',
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    await request(app)
      .patch('/api/profile')
      .set('Authorization', `Bearer ${token}`)
      .send({ bankDetails: { account: '1234', branch: 'Dhaka' } });

    const data = prismaMock.user.update.mock.calls[0][0].data;
    expect(data.bankDetails).toEqual({ account: '1234', branch: 'Dhaka' });
  });

  it('empty body → 400', async () => {
    const token = signToken();
    const res = await request(app)
      .patch('/api/profile')
      .set('Authorization', `Bearer ${token}`)
      .send({});

    expect(res.status).toBe(400);
    expect(prismaMock.user.update).not.toHaveBeenCalled();
  });
});

// ─────────────────────────────────────────────────────────────────────
// PATCH /api/profile/settings
// ─────────────────────────────────────────────────────────────────────
describe('PATCH /api/profile/settings', () => {
  it('valid distributionOn + language → 200', async () => {
    const token = signToken({ id: 'user-1' });
    prismaMock.user.update.mockResolvedValueOnce({
      distributionOn: true,
      language: 'bn',
      notificationPrefs: { booking: true },
    });

    const res = await request(app)
      .patch('/api/profile/settings')
      .set('Authorization', `Bearer ${token}`)
      .send({ distributionOn: true, language: 'bn' });

    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({
      distributionOn: true,
      language: 'bn',
    });

    const data = prismaMock.user.update.mock.calls[0][0].data;
    expect(data.distributionOn).toBe(true);
    expect(data.language).toBe('bn');
  });

  it('language other than en/bn → 400', async () => {
    const token = signToken();
    const res = await request(app)
      .patch('/api/profile/settings')
      .set('Authorization', `Bearer ${token}`)
      .send({ language: 'fr' });

    expect(res.status).toBe(400);
    expect(prismaMock.user.update).not.toHaveBeenCalled();
  });

  it('empty body → 400', async () => {
    const token = signToken();
    const res = await request(app)
      .patch('/api/profile/settings')
      .set('Authorization', `Bearer ${token}`)
      .send({});

    expect(res.status).toBe(400);
  });
});

// ─────────────────────────────────────────────────────────────────────
// PATCH /api/profile/vat  (Owner / Both only)
// ─────────────────────────────────────────────────────────────────────
describe('PATCH /api/profile/vat', () => {
  it('Owner valid → 200', async () => {
    const token = signToken({ id: 'user-1', role: 'OWNER' });
    prismaMock.user.findUnique.mockResolvedValueOnce({ role: 'OWNER' });
    prismaMock.user.update.mockResolvedValueOnce({
      vatEnabled: true,
      vatPercentage: 15,
      vatBin: 'BIN-123',
    });

    const res = await request(app)
      .patch('/api/profile/vat')
      .set('Authorization', `Bearer ${token}`)
      .send({ vatEnabled: true, vatPercentage: 15, vatBin: 'BIN-123' });

    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({
      vatEnabled: true,
      vatPercentage: 15,
      vatBin: 'BIN-123',
    });
  });

  it('FREELANCER → 403', async () => {
    const token = signToken({ role: 'FREELANCER' });
    prismaMock.user.findUnique.mockResolvedValueOnce({ role: 'FREELANCER' });

    const res = await request(app)
      .patch('/api/profile/vat')
      .set('Authorization', `Bearer ${token}`)
      .send({ vatEnabled: true });

    expect(res.status).toBe(403);
    expect(prismaMock.user.update).not.toHaveBeenCalled();
  });

  it('vatPercentage out of 0-100 range → 400', async () => {
    const token = signToken({ role: 'OWNER' });
    prismaMock.user.findUnique.mockResolvedValueOnce({ role: 'OWNER' });

    const res = await request(app)
      .patch('/api/profile/vat')
      .set('Authorization', `Bearer ${token}`)
      .send({ vatPercentage: 150 });

    expect(res.status).toBe(400);
  });
});

// ─────────────────────────────────────────────────────────────────────
// GET /api/profile/stats
// ─────────────────────────────────────────────────────────────────────
describe('GET /api/profile/stats', () => {
  it('returns lifetime stats with null-safety on empty fields', async () => {
    const token = signToken();
    prismaMock.user.findUnique.mockResolvedValueOnce({
      totalEvents: null,
      totalRevenueMinor: null,
      totalClients: null,
      statsRefreshedAt: null,
    });

    const res = await request(app)
      .get('/api/profile/stats')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body).toEqual({
      totalEvents: 0,
      totalRevenueMinor: 0,
      totalClients: 0,
      statsRefreshedAt: null,
    });
  });

  it('returns ISO-string for statsRefreshedAt when set', async () => {
    const token = signToken();
    const refreshed = new Date('2025-01-01T00:00:00.000Z');
    prismaMock.user.findUnique.mockResolvedValueOnce({
      totalEvents: 5,
      totalRevenueMinor: 100_000,
      totalClients: 3,
      statsRefreshedAt: refreshed,
    });

    const res = await request(app)
      .get('/api/profile/stats')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body).toEqual({
      totalEvents: 5,
      totalRevenueMinor: 100_000,
      totalClients: 3,
      statsRefreshedAt: '2025-01-01T00:00:00.000Z',
    });
  });
});
