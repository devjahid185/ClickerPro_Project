// tests/gear.test.js
//
// Gear endpoints — add / list / delete with cross-tenant 403।  Also
// covers the brand→serial column mapping documented in the controller।

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
// POST /api/gear/add
// ─────────────────────────────────────────────────────────────────────
describe('POST /api/gear/add', () => {
  it('valid payload → 201 + brand→serial mapped', async () => {
    const token = signToken({ id: 'owner-1' });

    prismaMock.gearItem.create.mockResolvedValueOnce({
      id: 'gear-1',
      name: 'Sony A7 IV',
      serial: 'Sony', // brand mapped here
      category: 'Camera',
      condition: 'Good',
      value: 250000,
      ownerId: 'owner-1',
      createdAt: new Date('2025-01-01'),
    });

    const res = await request(app)
      .post('/api/gear/add')
      .set('Authorization', `Bearer ${token}`)
      .send({
        name: 'Sony A7 IV',
        brand: 'Sony',
        category: 'Camera',
        condition: 'Good',
        value: '250000',
      });

    expect(res.status).toBe(201);
    expect(res.body.gear).toMatchObject({
      id: 'gear-1',
      brand: 'Sony', // exposed back as brand
      category: 'Camera',
      value: 250000,
    });

    const data = prismaMock.gearItem.create.mock.calls[0][0].data;
    expect(data.serial).toBe('Sony'); // brand stored in serial column
    expect(data.value).toBe(250000); // parseFloat applied
    expect(data.ownerId).toBe('owner-1');
  });

  it('missing name → 400', async () => {
    const token = signToken();
    const res = await request(app)
      .post('/api/gear/add')
      .set('Authorization', `Bearer ${token}`)
      .send({ brand: 'X' });

    expect(res.status).toBe(400);
    expect(prismaMock.gearItem.create).not.toHaveBeenCalled();
  });

  it('blank name → 400', async () => {
    const token = signToken();
    const res = await request(app)
      .post('/api/gear/add')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: '   ' });

    expect(res.status).toBe(400);
  });

  it('Authorization missing → 401', async () => {
    const res = await request(app).post('/api/gear/add').send({});
    expect(res.status).toBe(401);
  });
});

// ─────────────────────────────────────────────────────────────────────
// GET /api/gear/my-gear
// ─────────────────────────────────────────────────────────────────────
describe('GET /api/gear/my-gear', () => {
  it('returns owner-scoped descending list', async () => {
    const token = signToken({ id: 'owner-1' });
    prismaMock.gearItem.findMany.mockResolvedValueOnce([
      {
        id: 'g1',
        name: 'Sony A7 IV',
        serial: 'Sony',
        category: 'Camera',
        value: 250000,
        createdAt: new Date(),
      },
    ]);

    const res = await request(app)
      .get('/api/gear/my-gear')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.count).toBe(1);
    expect(res.body.gear[0].brand).toBe('Sony'); // serial→brand mapped on read

    expect(prismaMock.gearItem.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { ownerId: 'owner-1' },
        orderBy: { createdAt: 'desc' },
      }),
    );
  });
});

// ─────────────────────────────────────────────────────────────────────
// DELETE /api/gear/:id
// ─────────────────────────────────────────────────────────────────────
describe('DELETE /api/gear/:id', () => {
  it('owner match → 200 + deletes row', async () => {
    const token = signToken({ id: 'owner-1' });

    prismaMock.gearItem.findUnique.mockResolvedValueOnce({
      id: 'gear-1',
      ownerId: 'owner-1',
    });
    prismaMock.gearItem.delete.mockResolvedValueOnce({ id: 'gear-1' });

    const res = await request(app)
      .delete('/api/gear/gear-1')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(prismaMock.gearItem.delete).toHaveBeenCalledWith({
      where: { id: 'gear-1' },
    });
  });

  it('cross-tenant → 403', async () => {
    const token = signToken({ id: 'attacker' });
    prismaMock.gearItem.findUnique.mockResolvedValueOnce({
      id: 'gear-1',
      ownerId: 'owner-1',
    });

    const res = await request(app)
      .delete('/api/gear/gear-1')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(403);
    expect(prismaMock.gearItem.delete).not.toHaveBeenCalled();
  });

  it('not found → 404', async () => {
    const token = signToken();
    prismaMock.gearItem.findUnique.mockResolvedValueOnce(null);

    const res = await request(app)
      .delete('/api/gear/nope')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(404);
  });
});
