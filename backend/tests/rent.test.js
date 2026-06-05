// tests/rent.test.js
//
// Rent endpoints — record / history / status update।  Covers IN/OUT
// direction enum, returnBy date coercion, and gear-join shape on history।

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
// POST /api/rent/record
// ─────────────────────────────────────────────────────────────────────
describe('POST /api/rent/record', () => {
  const validPayload = {
    direction: 'OUT',
    counterpartyName: 'Friend Studio',
    counterpartyPhone: '0170...',
    amount: '1500',
    returnBy: '2025-12-15',
  };

  it('valid payload → 201 + status defaults to ACTIVE', async () => {
    const token = signToken({ id: 'owner-1' });

    prismaMock.rentRecord.create.mockResolvedValueOnce({
      id: 'rent-1',
      ...validPayload,
      amount: 1500,
      ownerId: 'owner-1',
      status: 'ACTIVE',
    });

    const res = await request(app)
      .post('/api/rent/record')
      .set('Authorization', `Bearer ${token}`)
      .send(validPayload);

    expect(res.status).toBe(201);
    expect(res.body.record.status).toBe('ACTIVE');

    const data = prismaMock.rentRecord.create.mock.calls[0][0].data;
    expect(data.amount).toBe(1500); // parseFloat applied
    expect(typeof data.amount).toBe('number');
    expect(data.returnBy).toBeInstanceOf(Date);
    expect(data.ownerId).toBe('owner-1');
    expect(data.status).toBe('ACTIVE');
  });

  it('returnBy null / missing handled gracefully', async () => {
    const token = signToken();
    prismaMock.rentRecord.create.mockResolvedValueOnce({});

    await request(app)
      .post('/api/rent/record')
      .set('Authorization', `Bearer ${token}`)
      .send({
        direction: 'IN',
        counterpartyName: 'Vendor',
        amount: 0,
      });

    const data = prismaMock.rentRecord.create.mock.calls[0][0].data;
    expect(data.returnBy).toBeNull();
    expect(data.amount).toBe(0);
  });

  it('missing direction → 400', async () => {
    const token = signToken();
    const res = await request(app)
      .post('/api/rent/record')
      .set('Authorization', `Bearer ${token}`)
      .send({ counterpartyName: 'X' });

    expect(res.status).toBe(400);
  });

  it('missing counterpartyName → 400', async () => {
    const token = signToken();
    const res = await request(app)
      .post('/api/rent/record')
      .set('Authorization', `Bearer ${token}`)
      .send({ direction: 'OUT' });

    expect(res.status).toBe(400);
  });
});

// ─────────────────────────────────────────────────────────────────────
// GET /api/rent/history
// ─────────────────────────────────────────────────────────────────────
describe('GET /api/rent/history', () => {
  it('returns owner-scoped history with gear info joined', async () => {
    const token = signToken({ id: 'owner-1' });
    prismaMock.rentRecord.findMany.mockResolvedValueOnce([
      {
        id: 'r1',
        direction: 'OUT',
        counterpartyName: 'X',
        amount: 1000,
        gear: { id: 'g1', name: 'Sony A7' },
      },
    ]);

    const res = await request(app)
      .get('/api/rent/history')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.count).toBe(1);
    expect(res.body.history[0].gear.name).toBe('Sony A7');

    expect(prismaMock.rentRecord.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { ownerId: 'owner-1' },
        include: { gear: true },
        orderBy: { createdAt: 'desc' },
      }),
    );
  });
});

// ─────────────────────────────────────────────────────────────────────
// PATCH /api/rent/status/:id
// ─────────────────────────────────────────────────────────────────────
describe('PATCH /api/rent/status/:id', () => {
  it('RETURNED with actualReturnDate → 200', async () => {
    const token = signToken();
    prismaMock.rentRecord.update.mockResolvedValueOnce({
      id: 'r1',
      status: 'RETURNED',
    });

    const res = await request(app)
      .patch('/api/rent/status/r1')
      .set('Authorization', `Bearer ${token}`)
      .send({ status: 'RETURNED', actualReturnDate: '2025-11-30' });

    expect(res.status).toBe(200);

    const arg = prismaMock.rentRecord.update.mock.calls[0][0];
    expect(arg.where).toEqual({ id: 'r1' });
    expect(arg.data.status).toBe('RETURNED');
    expect(arg.data.actualReturnDate).toBeInstanceOf(Date);
  });

  it('OVERDUE without actualReturnDate → 200 + null date', async () => {
    const token = signToken();
    prismaMock.rentRecord.update.mockResolvedValueOnce({});

    await request(app)
      .patch('/api/rent/status/r1')
      .set('Authorization', `Bearer ${token}`)
      .send({ status: 'OVERDUE' });

    const arg = prismaMock.rentRecord.update.mock.calls[0][0];
    expect(arg.data.status).toBe('OVERDUE');
    expect(arg.data.actualReturnDate).toBeNull();
  });
});

// ─────────────────────────────────────────────────────────────────────
// Error paths
// ─────────────────────────────────────────────────────────────────────
describe('Rent — error paths', () => {
  it('createRentRecord → 500 on Prisma error', async () => {
    const token = signToken();
    prismaMock.rentRecord.create.mockRejectedValueOnce(new Error('boom'));

    const res = await request(app)
      .post('/api/rent/record')
      .set('Authorization', `Bearer ${token}`)
      .send({
        direction: 'OUT',
        counterpartyName: 'X',
        amount: 100,
      });

    expect(res.status).toBe(500);
  });

  it('getRentHistory → 500 on Prisma error', async () => {
    const token = signToken();
    prismaMock.rentRecord.findMany.mockRejectedValueOnce(new Error('boom'));

    const res = await request(app)
      .get('/api/rent/history')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(500);
  });

  it('updateRentStatus → 500 on Prisma error', async () => {
    const token = signToken();
    prismaMock.rentRecord.update.mockRejectedValueOnce(new Error('boom'));

    const res = await request(app)
      .patch('/api/rent/status/r1')
      .set('Authorization', `Bearer ${token}`)
      .send({ status: 'RETURNED' });

    expect(res.status).toBe(500);
  });
});
