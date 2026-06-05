// tests/expense.test.js
//
// Expense endpoints — record / list / profit-loss aggregate।  Tests cover
// numeric coercion, owner-scoping, and the income-minus-expense net
// calculation that drives the dashboard tile।

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
// POST /api/expenses
// ─────────────────────────────────────────────────────────────────────
describe('POST /api/expenses', () => {
  it('valid payload → 201 + record', async () => {
    const token = signToken({ id: 'owner-1', role: 'OWNER' });

    prismaMock.expense.create.mockResolvedValueOnce({
      id: 'exp-1',
      amount: 1500,
      category: 'Travel',
      ownerId: 'owner-1',
      note: 'Fuel',
    });

    const res = await request(app)
      .post('/api/expenses')
      .set('Authorization', `Bearer ${token}`)
      .send({ amount: 1500, category: 'Travel', note: 'Fuel' });

    expect(res.status).toBe(201);
    expect(res.body.expense).toMatchObject({ id: 'exp-1', category: 'Travel' });

    const data = prismaMock.expense.create.mock.calls[0][0].data;
    expect(data).toMatchObject({
      amount: 1500,
      ownerId: 'owner-1',
      category: 'Travel',
    });
    expect(typeof data.amount).toBe('number');
  });

  it('amount as string → parseFloat applied', async () => {
    const token = signToken();
    prismaMock.expense.create.mockResolvedValueOnce({});

    await request(app)
      .post('/api/expenses')
      .set('Authorization', `Bearer ${token}`)
      .send({ amount: '2500.75', category: 'Misc' });

    const data = prismaMock.expense.create.mock.calls[0][0].data;
    expect(data.amount).toBe(2500.75);
    expect(typeof data.amount).toBe('number');
  });

  it('missing amount → 400', async () => {
    const token = signToken();
    const res = await request(app)
      .post('/api/expenses')
      .set('Authorization', `Bearer ${token}`)
      .send({ category: 'X' });

    expect(res.status).toBe(400);
    expect(prismaMock.expense.create).not.toHaveBeenCalled();
  });

  it('Authorization missing → 401', async () => {
    const res = await request(app).post('/api/expenses').send({});
    expect(res.status).toBe(401);
  });
});

// ─────────────────────────────────────────────────────────────────────
// GET /api/expenses
// ─────────────────────────────────────────────────────────────────────
describe('GET /api/expenses', () => {
  it('owner-scoped descending date list with event title joined', async () => {
    const token = signToken({ id: 'owner-1' });
    prismaMock.expense.findMany.mockResolvedValueOnce([
      {
        id: 'exp-1',
        amount: 100,
        category: 'A',
        date: new Date('2025-02-01'),
        event: { title: 'Karim Wedding' },
      },
    ]);

    const res = await request(app)
      .get('/api/expenses')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.count).toBe(1);
    expect(res.body.data[0].event.title).toBe('Karim Wedding');

    expect(prismaMock.expense.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { ownerId: 'owner-1' },
        orderBy: { date: 'desc' },
        include: { event: { select: { title: true } } },
      }),
    );
  });
});

// ─────────────────────────────────────────────────────────────────────
// GET /api/expenses/profit
// ─────────────────────────────────────────────────────────────────────
describe('GET /api/expenses/profit', () => {
  it('returns income - expense = netProfit', async () => {
    const token = signToken({ id: 'owner-1' });
    prismaMock.payment.aggregate.mockResolvedValueOnce({
      _sum: { amount: 100_000 },
    });
    prismaMock.expense.aggregate.mockResolvedValueOnce({
      _sum: { amount: 35_000 },
    });

    const res = await request(app)
      .get('/api/expenses/profit')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({
      success: true,
      totalExpense: 35_000,
      netProfit: 65_000,
    });

    // payment aggregate scoped by recipient = owner
    expect(prismaMock.payment.aggregate).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { recipientId: 'owner-1' },
        _sum: { amount: true },
      }),
    );
    // expense aggregate scoped by owner
    expect(prismaMock.expense.aggregate).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { ownerId: 'owner-1' },
        _sum: { amount: true },
      }),
    );
  });

  it('null aggregates → coerced to 0, profit = 0', async () => {
    const token = signToken();
    prismaMock.payment.aggregate.mockResolvedValueOnce({ _sum: { amount: null } });
    prismaMock.expense.aggregate.mockResolvedValueOnce({ _sum: { amount: null } });

    const res = await request(app)
      .get('/api/expenses/profit')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.netProfit).toBe(0);
    expect(res.body.totalExpense).toBe(0);
  });
});

// ─────────────────────────────────────────────────────────────────────
// Error paths
// ─────────────────────────────────────────────────────────────────────
describe('Expense — error paths', () => {
  it('createExpense → 500 on Prisma error', async () => {
    const token = signToken();
    prismaMock.expense.create.mockRejectedValueOnce(new Error('boom'));

    const res = await request(app)
      .post('/api/expenses')
      .set('Authorization', `Bearer ${token}`)
      .send({ amount: 100, category: 'X' });

    expect(res.status).toBe(500);
  });

  it('getExpenses → 500 on Prisma error', async () => {
    const token = signToken();
    prismaMock.expense.findMany.mockRejectedValueOnce(new Error('boom'));

    const res = await request(app)
      .get('/api/expenses')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(500);
  });

  it('getProfitLoss → 500 on Prisma error', async () => {
    const token = signToken();
    prismaMock.payment.aggregate.mockRejectedValueOnce(new Error('boom'));

    const res = await request(app)
      .get('/api/expenses/profit')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(500);
  });
});
