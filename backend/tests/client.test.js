// tests/client.test.js
//
// Clients CRUD smoke — auth guard + owner scoping ঠিকঠাক ঘুরছে কি না।

const request = require('supertest');

const { buildApp, signToken, prismaMock } = require('./helpers/testApp');

let app;
beforeAll(() => {
  app = buildApp();
});

beforeEach(() => {
  prismaMock.reset();
});

describe('POST /api/clients', () => {
  it('name + phone থাকলে 201 + record return', async () => {
    const token = signToken({ id: 'owner-1', role: 'OWNER' });

    prismaMock.client.create.mockResolvedValueOnce({
      id: 'cli-new',
      name: 'Karim',
      phone: '0170...',
      ownerId: 'owner-1',
    });

    const res = await request(app)
      .post('/api/clients')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'Karim', phone: '0170...', email: 'k@example.com' });

    expect(res.status).toBe(201);
    expect(res.body).toMatchObject({
      success: true,
      client: expect.objectContaining({ id: 'cli-new', ownerId: 'owner-1' }),
    });

    expect(prismaMock.client.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          name: 'Karim',
          phone: '0170...',
          ownerId: 'owner-1',
        }),
      }),
    );
  });

  it('name বা phone missing হলে 400', async () => {
    const token = signToken();
    const res = await request(app)
      .post('/api/clients')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'Onlyname' });

    expect(res.status).toBe(400);
    expect(prismaMock.client.create).not.toHaveBeenCalled();
  });

  it('Authorization missing হলে 401', async () => {
    const res = await request(app).post('/api/clients').send({});
    expect(res.status).toBe(401);
  });
});

describe('GET /api/clients', () => {
  it('owner-এর clients ফেরত দেয়', async () => {
    const token = signToken({ id: 'owner-1', role: 'OWNER' });

    prismaMock.client.findMany.mockResolvedValueOnce([
      { id: 'cli-1', name: 'A', phone: '01...', ownerId: 'owner-1' },
      { id: 'cli-2', name: 'B', phone: '02...', ownerId: 'owner-1' },
    ]);

    const res = await request(app)
      .get('/api/clients')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.count).toBe(2);
    expect(prismaMock.client.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ where: { ownerId: 'owner-1' } }),
    );
  });
});

describe('GET /api/clients/:id', () => {
  it('match হলে 200 + body data', async () => {
    const token = signToken({ id: 'owner-1' });
    prismaMock.client.findFirst.mockResolvedValueOnce({
      id: 'cli-1',
      name: 'Karim',
    });

    const res = await request(app)
      .get('/api/clients/cli-1')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.data.id).toBe('cli-1');
    expect(prismaMock.client.findFirst).toHaveBeenCalledWith({
      where: { id: 'cli-1', ownerId: 'owner-1' },
    });
  });

  it('match না হলে 404', async () => {
    const token = signToken();
    prismaMock.client.findFirst.mockResolvedValueOnce(null);

    const res = await request(app)
      .get('/api/clients/no-such')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(404);
  });
});

// ─────────────────────────────────────────────────────────────────────
// GET /api/clients/:id — error path
// ─────────────────────────────────────────────────────────────────────
describe('GET /api/clients/:id — error path', () => {
  it('Prisma error → 500', async () => {
    const token = signToken();
    prismaMock.client.findFirst.mockRejectedValueOnce(new Error('boom'));

    const res = await request(app)
      .get('/api/clients/x')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(500);
  });
});

// ─────────────────────────────────────────────────────────────────────
// PUT /api/clients/:id  — update flow
// ─────────────────────────────────────────────────────────────────────
describe('PUT /api/clients/:id', () => {
  it('owner-scoped updateMany passes body verbatim', async () => {
    const token = signToken({ id: 'owner-1' });
    prismaMock.client.updateMany.mockResolvedValueOnce({ count: 1 });

    const res = await request(app)
      .put('/api/clients/cli-1')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'Karim Updated', phone: '0170...new' });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);

    expect(prismaMock.client.updateMany).toHaveBeenCalledWith({
      where: { id: 'cli-1', ownerId: 'owner-1' },
      data: { name: 'Karim Updated', phone: '0170...new' },
    });
  });

  it('Prisma error → 500', async () => {
    const token = signToken();
    prismaMock.client.updateMany.mockRejectedValueOnce(new Error('boom'));

    const res = await request(app)
      .put('/api/clients/cli-1')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'X' });

    expect(res.status).toBe(500);
  });

  it('Authorization missing → 401', async () => {
    const res = await request(app).put('/api/clients/cli-1').send({});
    expect(res.status).toBe(401);
    expect(prismaMock.client.updateMany).not.toHaveBeenCalled();
  });
});

// ─────────────────────────────────────────────────────────────────────
// GET /api/clients — error path
// ─────────────────────────────────────────────────────────────────────
describe('GET /api/clients — error path', () => {
  it('Prisma error → 500', async () => {
    const token = signToken();
    prismaMock.client.findMany.mockRejectedValueOnce(new Error('boom'));

    const res = await request(app)
      .get('/api/clients')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(500);
  });
});

// ─────────────────────────────────────────────────────────────────────
// POST /api/clients — error path
// ─────────────────────────────────────────────────────────────────────
describe('POST /api/clients — error path', () => {
  it('Prisma error → 500 + error envelope', async () => {
    const token = signToken();
    prismaMock.client.create.mockRejectedValueOnce(new Error('boom'));

    const res = await request(app)
      .post('/api/clients')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'X', phone: '01700' });

    expect(res.status).toBe(500);
    expect(res.body.success).toBe(false);
  });
});
