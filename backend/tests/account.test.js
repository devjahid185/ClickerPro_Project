// tests/account.test.js
//
// Account endpoints — 7-day-grace deletion, undo, data export।  All three
// hit `authController.requestDeleteAccount / cancelDeleteAccount /
// requestDataExport` via the /api/account router।

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
// POST /api/account/delete-request
// ─────────────────────────────────────────────────────────────────────
describe('POST /api/account/delete-request', () => {
  it('stamps deletedAt 7 days into the future', async () => {
    const token = signToken({ id: 'user-1' });

    const before = Date.now();
    prismaMock.user.update.mockImplementationOnce(async (args) => ({
      id: 'user-1',
      deletedAt: args.data.deletedAt,
    }));

    const res = await request(app)
      .post('/api/account/delete-request')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.deletedAt).toMatch(/T/); // ISO 8601 string

    // user.update called against the right id and 7-day window
    const arg = prismaMock.user.update.mock.calls[0][0];
    expect(arg.where).toEqual({ id: 'user-1' });
    const deltaMs = arg.data.deletedAt.getTime() - before;
    const sevenDaysMs = 7 * 24 * 60 * 60 * 1000;
    // allow ~5s slack to account for test runtime
    expect(deltaMs).toBeGreaterThanOrEqual(sevenDaysMs - 5_000);
    expect(deltaMs).toBeLessThanOrEqual(sevenDaysMs + 5_000);
  });

  it('Authorization missing → 401', async () => {
    const res = await request(app).post('/api/account/delete-request');
    expect(res.status).toBe(401);
    expect(prismaMock.user.update).not.toHaveBeenCalled();
  });
});

// ─────────────────────────────────────────────────────────────────────
// POST /api/account/cancel-delete
// ─────────────────────────────────────────────────────────────────────
describe('POST /api/account/cancel-delete', () => {
  it('clears deletedAt and returns user envelope', async () => {
    const token = signToken({ id: 'user-1' });

    prismaMock.user.update.mockResolvedValueOnce({
      id: 'user-1',
      email: 'r@x.com',
      fullName: 'R',
      role: 'OWNER',
      deletedAt: null,
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    const res = await request(app)
      .post('/api/account/cancel-delete')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.user).toMatchObject({
      id: 'user-1',
      email: 'r@x.com',
      role: 'owner', // denormalized lowercase wire format
    });
    expect(res.body.user.deletedAt).toBeNull();

    expect(prismaMock.user.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'user-1' },
        data: { deletedAt: null },
      }),
    );
  });
});

// ─────────────────────────────────────────────────────────────────────
// POST /api/account/export
// ─────────────────────────────────────────────────────────────────────
describe('POST /api/account/export', () => {
  it('returns 202 + stub downloadUrl carrying the userId', async () => {
    const token = signToken({ id: 'user-1' });

    const res = await request(app)
      .post('/api/account/export')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(202);
    expect(res.body.downloadUrl).toMatch(
      /^https:\/\/clickerpro\.app\/exports\/coming-soon\?userId=user-1$/,
    );
  });

  it('Authorization missing → 401', async () => {
    const res = await request(app).post('/api/account/export');
    expect(res.status).toBe(401);
  });
});
