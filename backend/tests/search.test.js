// tests/search.test.js
//
// Global search endpoint — owner-scoped client/event/package query, status
// + type + date-range filter wiring on event-level Prisma calls।

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
// GET /api/search/global
// ─────────────────────────────────────────────────────────────────────
describe('GET /api/search/global', () => {
  it('q only — runs four parallel searches owner-scoped', async () => {
    const token = signToken({ id: 'owner-1' });

    prismaMock.client.findMany.mockResolvedValueOnce([{ id: 'c1', name: 'Karim' }]);
    prismaMock.event.findMany.mockResolvedValueOnce([{ id: 'e1', title: 'Karim Wedding' }]);
    prismaMock.user.findMany.mockResolvedValueOnce([]);
    prismaMock.package.findMany.mockResolvedValueOnce([]);

    const res = await request(app)
      .get('/api/search/global?q=Karim')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.summary).toEqual({
      totalClients: 1,
      totalEvents: 1,
      totalMembers: 0,
      totalPackages: 0,
    });

    // client.findMany owner-scoped
    expect(prismaMock.client.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({ ownerId: 'owner-1' }),
      }),
    );
    // package.findMany owner-scoped
    expect(prismaMock.package.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({ ownerId: 'owner-1' }),
      }),
    );
  });

  it('status + type + date-range filters added to event.where.AND', async () => {
    const token = signToken({ id: 'owner-1' });

    prismaMock.client.findMany.mockResolvedValueOnce([]);
    prismaMock.event.findMany.mockResolvedValueOnce([]);
    prismaMock.user.findMany.mockResolvedValueOnce([]);
    prismaMock.package.findMany.mockResolvedValueOnce([]);

    await request(app)
      .get(
        '/api/search/global?q=wedding&status=PENDING&type=Wedding&startDate=2025-01-01&endDate=2025-12-31',
      )
      .set('Authorization', `Bearer ${token}`);

    const eventCall = prismaMock.event.findMany.mock.calls[0][0];
    expect(eventCall.where.ownerId).toBe('owner-1');

    const andClauses = eventCall.where.AND;
    expect(andClauses).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ status: 'PENDING' }),
        expect.objectContaining({ type: 'Wedding' }),
        expect.objectContaining({
          date: expect.objectContaining({
            gte: expect.any(Date),
            lte: expect.any(Date),
          }),
        }),
      ]),
    );
  });

  it('no q and no filter → 400', async () => {
    const token = signToken();
    const res = await request(app)
      .get('/api/search/global')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(400);
    expect(prismaMock.event.findMany).not.toHaveBeenCalled();
  });

  it('Authorization missing → 401', async () => {
    const res = await request(app).get('/api/search/global?q=anything');
    expect(res.status).toBe(401);
  });
});
