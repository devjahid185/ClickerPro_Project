// tests/package.test.js
//
// Package endpoints — create / list / update / delete।  Smoke covers
// numeric coercion, ascending price ordering, and clean error envelope।

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
// POST /api/packages
// ─────────────────────────────────────────────────────────────────────
describe('POST /api/packages', () => {
  it('valid payload → 201 + parseFloat applied', async () => {
    const token = signToken({ role: 'OWNER' });

    prismaMock.package.create.mockResolvedValueOnce({
      id: 'pkg-1',
      name: 'Wedding Pro',
      price: 50000,
    });

    const res = await request(app)
      .post('/api/packages')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'Wedding Pro', price: '50000' });

    expect(res.status).toBe(201);
    expect(res.body.packageItem).toMatchObject({ id: 'pkg-1' });

    const data = prismaMock.package.create.mock.calls[0][0].data;
    expect(data.price).toBe(50000);
    expect(typeof data.price).toBe('number');
  });

  it('missing name → 400', async () => {
    const token = signToken();
    const res = await request(app)
      .post('/api/packages')
      .set('Authorization', `Bearer ${token}`)
      .send({ price: 1000 });

    expect(res.status).toBe(400);
    expect(prismaMock.package.create).not.toHaveBeenCalled();
  });

  it('Authorization missing → 401', async () => {
    const res = await request(app).post('/api/packages').send({});
    expect(res.status).toBe(401);
  });
});

// ─────────────────────────────────────────────────────────────────────
// GET /api/packages
// ─────────────────────────────────────────────────────────────────────
describe('GET /api/packages', () => {
  it('returns ascending-price list', async () => {
    const token = signToken();
    prismaMock.package.findMany.mockResolvedValueOnce([
      { id: 'pkg-1', name: 'Basic', price: 10000 },
      { id: 'pkg-2', name: 'Pro', price: 50000 },
    ]);

    const res = await request(app)
      .get('/api/packages')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.count).toBe(2);
    expect(prismaMock.package.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ orderBy: { price: 'asc' } }),
    );
  });
});

// ─────────────────────────────────────────────────────────────────────
// PUT /api/packages/:id
// ─────────────────────────────────────────────────────────────────────
describe('PUT /api/packages/:id', () => {
  it('passes body straight through to prisma.update', async () => {
    const token = signToken();
    prismaMock.package.update.mockResolvedValueOnce({
      id: 'pkg-1',
      name: 'Updated',
    });

    const res = await request(app)
      .put('/api/packages/pkg-1')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'Updated', price: 60000 });

    expect(res.status).toBe(200);
    expect(prismaMock.package.update).toHaveBeenCalledWith({
      where: { id: 'pkg-1' },
      data: { name: 'Updated', price: 60000 },
    });
  });
});

// ─────────────────────────────────────────────────────────────────────
// DELETE /api/packages/:id
// ─────────────────────────────────────────────────────────────────────
describe('DELETE /api/packages/:id', () => {
  it('delete → 200', async () => {
    const token = signToken();
    prismaMock.package.delete.mockResolvedValueOnce({ id: 'pkg-1' });

    const res = await request(app)
      .delete('/api/packages/pkg-1')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(prismaMock.package.delete).toHaveBeenCalledWith({
      where: { id: 'pkg-1' },
    });
  });

  it('Prisma error → 500', async () => {
    const token = signToken();
    prismaMock.package.delete.mockRejectedValueOnce(new Error('boom'));

    const res = await request(app)
      .delete('/api/packages/missing')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(500);
  });
});

// ─────────────────────────────────────────────────────────────────────
// Error paths
// ─────────────────────────────────────────────────────────────────────
describe('Package — error paths', () => {
  it('createPackage → 500 on Prisma error', async () => {
    const token = signToken();
    prismaMock.package.create.mockRejectedValueOnce(new Error('boom'));

    const res = await request(app)
      .post('/api/packages')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'X', price: 100 });

    expect(res.status).toBe(500);
  });

  it('getAllPackages → 500 on Prisma error', async () => {
    const token = signToken();
    prismaMock.package.findMany.mockRejectedValueOnce(new Error('boom'));

    const res = await request(app)
      .get('/api/packages')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(500);
  });

  it('updatePackage → 500 on Prisma error', async () => {
    const token = signToken();
    prismaMock.package.update.mockRejectedValueOnce(new Error('boom'));

    const res = await request(app)
      .put('/api/packages/p1')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'New' });

    expect(res.status).toBe(500);
  });
});
