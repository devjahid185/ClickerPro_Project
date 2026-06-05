// tests/payment.test.js
//
// Payment endpoints — record / event-history / earnings aggregate।

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
// POST /api/payments
// ─────────────────────────────────────────────────────────────────────
describe('POST /api/payments', () => {
  const validPayload = {
    eventId:     'evt-1',
    amount:      5000,
    kind:        'ADVANCE',
    method:      'BKASH',
    recipientId: 'owner-1',
  };

  it('valid payload → 201 + payment record', async () => {
    const token = signToken({ id: 'owner-1', role: 'OWNER' });

    prismaMock.payment.create.mockResolvedValueOnce({
      id: 'pay-1',
      ...validPayload,
      date: new Date(),
    });

    const res = await request(app)
      .post('/api/payments')
      .set('Authorization', `Bearer ${token}`)
      .send(validPayload);

    expect(res.status).toBe(201);
    expect(res.body.payment).toMatchObject({ id: 'pay-1', kind: 'ADVANCE' });

    // amount-কে numeric ই বসেছে কিনা confirm করি
    expect(prismaMock.payment.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          eventId: 'evt-1',
          amount: 5000, // parseFloat applied
          kind: 'ADVANCE',
        }),
      }),
    );
  });

  it('amount string আসলে parseFloat করে save হয়', async () => {
    const token = signToken();
    prismaMock.payment.create.mockResolvedValueOnce({ id: 'pay-2' });

    await request(app)
      .post('/api/payments')
      .set('Authorization', `Bearer ${token}`)
      .send({ ...validPayload, amount: '7500.50' });

    const arg = prismaMock.payment.create.mock.calls[0][0].data;
    expect(arg.amount).toBe(7500.5);
    expect(typeof arg.amount).toBe('number');
  });

  it('eventId missing হলে 400', async () => {
    const token = signToken();
    const res = await request(app)
      .post('/api/payments')
      .set('Authorization', `Bearer ${token}`)
      .send({ amount: 100, kind: 'ADVANCE' });

    expect(res.status).toBe(400);
    expect(prismaMock.payment.create).not.toHaveBeenCalled();
  });

  it('Authorization missing → 401', async () => {
    const res = await request(app).post('/api/payments').send(validPayload);
    expect(res.status).toBe(401);
  });
});

// ─────────────────────────────────────────────────────────────────────
// GET /api/payments/event/:eventId
// ─────────────────────────────────────────────────────────────────────
describe('GET /api/payments/event/:eventId', () => {
  it('event-এর payments descending date-order এ ফেরত দেয়', async () => {
    const token = signToken();
    prismaMock.payment.findMany.mockResolvedValueOnce([
      { id: 'pay-2', amount: 3000, date: new Date('2025-02-01') },
      { id: 'pay-1', amount: 5000, date: new Date('2025-01-15') },
    ]);

    const res = await request(app)
      .get('/api/payments/event/evt-1')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.count).toBe(2);
    expect(prismaMock.payment.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { eventId: 'evt-1' },
        orderBy: { date: 'desc' },
      }),
    );
  });
});

// ─────────────────────────────────────────────────────────────────────
// GET /api/payments/earnings
// ─────────────────────────────────────────────────────────────────────
describe('GET /api/payments/earnings', () => {
  it('owner-এর recipient sum aggregate ফেরত দেয়', async () => {
    const token = signToken({ id: 'owner-1' });
    prismaMock.payment.aggregate.mockResolvedValueOnce({
      _sum: { amount: 125_000 },
    });

    const res = await request(app)
      .get('/api/payments/earnings')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body).toEqual({
      success: true,
      totalEarnings: 125_000,
      currency: 'BDT',
    });

    expect(prismaMock.payment.aggregate).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { recipientId: 'owner-1' },
        _sum: { amount: true },
      }),
    );
  });

  it('aggregate null হলে 0 ফেরত', async () => {
    const token = signToken();
    prismaMock.payment.aggregate.mockResolvedValueOnce({
      _sum: { amount: null },
    });

    const res = await request(app)
      .get('/api/payments/earnings')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.totalEarnings).toBe(0);
  });
});

// ─────────────────────────────────────────────────────────────────────
// Error paths
// ─────────────────────────────────────────────────────────────────────
describe('Payment — error paths', () => {
  it('recordPayment → 500 on Prisma error', async () => {
    const token = signToken();
    prismaMock.payment.create.mockRejectedValueOnce(new Error('boom'));

    const res = await request(app)
      .post('/api/payments')
      .set('Authorization', `Bearer ${token}`)
      .send({
        eventId: 'e1',
        amount: 100,
        kind: 'ADVANCE',
      });

    expect(res.status).toBe(500);
  });

  it('getEventPayments → 500 on Prisma error', async () => {
    const token = signToken();
    prismaMock.payment.findMany.mockRejectedValueOnce(new Error('boom'));

    const res = await request(app)
      .get('/api/payments/event/e1')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(500);
  });

  it('getEarnings → 500 on Prisma error', async () => {
    const token = signToken();
    prismaMock.payment.aggregate.mockRejectedValueOnce(new Error('boom'));

    const res = await request(app)
      .get('/api/payments/earnings')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(500);
  });
});
