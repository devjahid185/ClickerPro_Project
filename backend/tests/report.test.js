// tests/report.test.js
//
// Report endpoints — yearly summary aggregate + team performance with
// composite per-user count + sum + reedit pending count + ranking score।

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
// GET /api/reports/yearly-summary
// ─────────────────────────────────────────────────────────────────────
describe('GET /api/reports/yearly-summary', () => {
  it('aggregates revenue / expense / payouts and computes netProfit', async () => {
    const token = signToken({ id: 'owner-1' });

    prismaMock.payment.aggregate.mockResolvedValueOnce({
      _sum: { amount: 500_000 },
    });
    prismaMock.expense.aggregate.mockResolvedValueOnce({
      _sum: { amount: 80_000 },
    });
    prismaMock.assignment.aggregate.mockResolvedValueOnce({
      _sum: { payoutAmount: 120_000 },
    });

    const res = await request(app)
      .get('/api/reports/yearly-summary?year=2025')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({
      year: '2025',
      summary: {
        totalRevenue: 500_000,
        totalExpenses: 80_000,
        totalFreelancerPayouts: 120_000,
        // 500k − (80k + 120k) = 300k
        netProfit: 300_000,
      },
    });

    // Date range scoping check on payment.aggregate
    const payArg = prismaMock.payment.aggregate.mock.calls[0][0];
    expect(payArg.where.event).toEqual({ ownerId: 'owner-1' });
    expect(payArg.where.date.gte).toBeInstanceOf(Date);
    expect(payArg.where.date.lte).toBeInstanceOf(Date);
  });

  it('null aggregates → coerced to 0', async () => {
    const token = signToken();
    prismaMock.payment.aggregate.mockResolvedValueOnce({ _sum: { amount: null } });
    prismaMock.expense.aggregate.mockResolvedValueOnce({ _sum: { amount: null } });
    prismaMock.assignment.aggregate.mockResolvedValueOnce({
      _sum: { payoutAmount: null },
    });

    const res = await request(app)
      .get('/api/reports/yearly-summary?year=2025')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.summary).toEqual({
      totalRevenue: 0,
      totalExpenses: 0,
      totalFreelancerPayouts: 0,
      netProfit: 0,
    });
  });

  it('missing ?year → 400', async () => {
    const token = signToken();
    const res = await request(app)
      .get('/api/reports/yearly-summary')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(400);
    expect(prismaMock.payment.aggregate).not.toHaveBeenCalled();
  });

  it('Authorization missing → 401', async () => {
    const res = await request(app).get('/api/reports/yearly-summary?year=2025');
    expect(res.status).toBe(401);
  });
});

// ─────────────────────────────────────────────────────────────────────
// GET /api/reports/team-performance
// ─────────────────────────────────────────────────────────────────────
describe('GET /api/reports/team-performance', () => {
  it('per-member ranking sorted by performanceScore desc', async () => {
    const token = signToken({ id: 'owner-1' });

    prismaMock.teamMembership.findMany.mockResolvedValueOnce([
      { userId: 'u1', role: 'FREELANCER', user: { fullName: 'Alice' } },
      { userId: 'u2', role: 'MANAGER', user: { fullName: 'Bob' } },
    ]);

    // Each user gets 3 prisma calls in order: count, aggregate, count
    // Alice: 5 events, 50k earned, 0 reedits ⇒ score = 5*10 - 0*5 = 50
    // Bob:   2 events, 10k earned, 1 reedit  ⇒ score = 2*10 - 1*5 = 15
    prismaMock.assignment.count
      .mockResolvedValueOnce(5)
      .mockResolvedValueOnce(2);
    prismaMock.assignment.aggregate
      .mockResolvedValueOnce({ _sum: { payoutAmount: 50_000 } })
      .mockResolvedValueOnce({ _sum: { payoutAmount: 10_000 } });
    prismaMock.reEditRequest.count
      .mockResolvedValueOnce(0)
      .mockResolvedValueOnce(1);

    const res = await request(app)
      .get('/api/reports/team-performance?year=2025')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.period).toBe('2025');
    expect(res.body.teamPerformance).toHaveLength(2);
    expect(res.body.teamPerformance[0]).toMatchObject({
      name: 'Alice',
      totalEvents: 5,
      totalEarnings: 50_000,
      pendingReEdits: 0,
      performanceScore: 50,
    });
    expect(res.body.teamPerformance[1]).toMatchObject({
      name: 'Bob',
      performanceScore: 15,
    });

    // Owner-scoping on team list
    expect(prismaMock.teamMembership.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ where: { ownerId: 'owner-1' } }),
    );
  });

  it('no year → period = "All Time"', async () => {
    const token = signToken();
    prismaMock.teamMembership.findMany.mockResolvedValueOnce([]);

    const res = await request(app)
      .get('/api/reports/team-performance')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.period).toBe('All Time');
    expect(res.body.teamPerformance).toEqual([]);
  });
});

// ─────────────────────────────────────────────────────────────────────
// Error paths
// ─────────────────────────────────────────────────────────────────────
describe('Report — error paths', () => {
  it('yearly-summary → 500 on Prisma error', async () => {
    const token = signToken();
    prismaMock.payment.aggregate.mockRejectedValueOnce(new Error('boom'));

    const res = await request(app)
      .get('/api/reports/yearly-summary?year=2025')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(500);
  });

  it('team-performance → 500 on Prisma error', async () => {
    const token = signToken();
    prismaMock.teamMembership.findMany.mockRejectedValueOnce(new Error('boom'));

    const res = await request(app)
      .get('/api/reports/team-performance?year=2025')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(500);
  });
});
