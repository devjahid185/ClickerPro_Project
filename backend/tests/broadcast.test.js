// tests/broadcast.test.js
//
// Broadcast / announcement endpoints — role-gated create + delete, public
// active list।  Validates default `priority`, `type`, `status` field
// fallback behaviour and the displayDuration default 10।

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
// POST /api/broadcasts
// ─────────────────────────────────────────────────────────────────────
describe('POST /api/broadcasts', () => {
  it('Owner valid payload → 201 + defaults applied', async () => {
    const token = signToken({ role: 'OWNER' });

    prismaMock.broadcast.create.mockResolvedValueOnce({
      id: 'bc-1',
      title: 'Maintenance',
      content: 'Down at 2am',
      priority: 'Normal',
      type: 'Announcement',
      status: 'ACTIVE',
      displayDuration: 10,
    });

    const res = await request(app)
      .post('/api/broadcasts')
      .set('Authorization', `Bearer ${token}`)
      .send({ title: 'Maintenance', content: 'Down at 2am' });

    expect(res.status).toBe(201);
    expect(res.body.data).toMatchObject({
      status: 'ACTIVE',
      priority: 'Normal',
      type: 'Announcement',
      displayDuration: 10,
    });

    const data = prismaMock.broadcast.create.mock.calls[0][0].data;
    expect(data).toMatchObject({
      title: 'Maintenance',
      priority: 'Normal',
      type: 'Announcement',
      status: 'ACTIVE',
      displayDuration: 10,
    });
  });

  it('explicit priority/type override defaults', async () => {
    const token = signToken({ role: 'BOTH' });
    prismaMock.broadcast.create.mockResolvedValueOnce({});

    await request(app)
      .post('/api/broadcasts')
      .set('Authorization', `Bearer ${token}`)
      .send({
        title: 'Outage',
        content: 'Critical',
        priority: 'Emergency',
        type: 'Update',
      });

    const data = prismaMock.broadcast.create.mock.calls[0][0].data;
    expect(data.priority).toBe('Emergency');
    expect(data.type).toBe('Update');
  });

  it('FREELANCER → 403', async () => {
    const token = signToken({ role: 'FREELANCER' });
    const res = await request(app)
      .post('/api/broadcasts')
      .set('Authorization', `Bearer ${token}`)
      .send({ title: 'X', content: 'Y' });

    expect(res.status).toBe(403);
    expect(prismaMock.broadcast.create).not.toHaveBeenCalled();
  });

  it('MANAGER → 403', async () => {
    const token = signToken({ role: 'MANAGER' });
    const res = await request(app)
      .post('/api/broadcasts')
      .set('Authorization', `Bearer ${token}`)
      .send({ title: 'X', content: 'Y' });

    expect(res.status).toBe(403);
  });
});

// ─────────────────────────────────────────────────────────────────────
// GET /api/broadcasts
// ─────────────────────────────────────────────────────────────────────
describe('GET /api/broadcasts', () => {
  it('returns ACTIVE broadcasts newest-first', async () => {
    const token = signToken();
    prismaMock.broadcast.findMany.mockResolvedValueOnce([
      { id: 'b2', title: 'New', status: 'ACTIVE', createdAt: new Date('2025-02-01') },
      { id: 'b1', title: 'Old', status: 'ACTIVE', createdAt: new Date('2025-01-01') },
    ]);

    const res = await request(app)
      .get('/api/broadcasts')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.count).toBe(2);

    expect(prismaMock.broadcast.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { status: 'ACTIVE' },
        orderBy: { createdAt: 'desc' },
      }),
    );
  });
});

// ─────────────────────────────────────────────────────────────────────
// DELETE /api/broadcasts/:id
// ─────────────────────────────────────────────────────────────────────
describe('DELETE /api/broadcasts/:id', () => {
  it('Owner → 200 + delete called', async () => {
    const token = signToken({ role: 'OWNER' });
    prismaMock.broadcast.delete.mockResolvedValueOnce({ id: 'b1' });

    const res = await request(app)
      .delete('/api/broadcasts/b1')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(prismaMock.broadcast.delete).toHaveBeenCalledWith({ where: { id: 'b1' } });
  });

  it('FREELANCER cannot delete → 403', async () => {
    const token = signToken({ role: 'FREELANCER' });
    const res = await request(app)
      .delete('/api/broadcasts/b1')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(403);
    expect(prismaMock.broadcast.delete).not.toHaveBeenCalled();
  });
});

// ─────────────────────────────────────────────────────────────────────
// Error paths — Prisma exceptions trigger 500 envelopes
// ─────────────────────────────────────────────────────────────────────
describe('Broadcast — error paths', () => {
  it('POST → 500 on Prisma error', async () => {
    const token = signToken({ role: 'OWNER' });
    prismaMock.broadcast.create.mockRejectedValueOnce(new Error('boom'));

    const res = await request(app)
      .post('/api/broadcasts')
      .set('Authorization', `Bearer ${token}`)
      .send({ title: 'X', content: 'Y' });

    expect(res.status).toBe(500);
  });

  it('GET → 500 on Prisma error', async () => {
    const token = signToken();
    prismaMock.broadcast.findMany.mockRejectedValueOnce(new Error('boom'));

    const res = await request(app)
      .get('/api/broadcasts')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(500);
  });

  it('DELETE → 500 on Prisma error', async () => {
    const token = signToken({ role: 'OWNER' });
    prismaMock.broadcast.delete.mockRejectedValueOnce(new Error('boom'));

    const res = await request(app)
      .delete('/api/broadcasts/b1')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(500);
  });
});
