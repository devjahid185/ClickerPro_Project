// tests/delivery.test.js
//
// Delivery endpoints — drive link patch + delivered list view।

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
// POST /api/delivery/update
// ─────────────────────────────────────────────────────────────────────
describe('POST /api/delivery/update', () => {
  const validPayload = {
    eventId: 'evt-1',
    driveLink: 'https://drive.google.com/folders/abc',
  };

  it('valid + owner match → 200 + status defaults to DELIVERED', async () => {
    const token = signToken({ id: 'owner-1', role: 'OWNER' });

    prismaMock.event.findFirst.mockResolvedValueOnce({
      id: 'evt-1',
      ownerId: 'owner-1',
    });
    prismaMock.event.update.mockResolvedValueOnce({
      id: 'evt-1',
      driveLink: validPayload.driveLink,
      status: 'DELIVERED',
    });

    const res = await request(app)
      .post('/api/delivery/update')
      .set('Authorization', `Bearer ${token}`)
      .send(validPayload);

    expect(res.status).toBe(200);
    expect(res.body.updatedEvent.status).toBe('DELIVERED');

    expect(prismaMock.event.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'evt-1' },
        data: expect.objectContaining({
          driveLink: validPayload.driveLink,
          status: 'DELIVERED',
        }),
      }),
    );
  });

  it('explicit status param overrides default', async () => {
    const token = signToken({ id: 'owner-1' });
    prismaMock.event.findFirst.mockResolvedValueOnce({ id: 'evt-1' });
    prismaMock.event.update.mockResolvedValueOnce({});

    await request(app)
      .post('/api/delivery/update')
      .set('Authorization', `Bearer ${token}`)
      .send({ ...validPayload, status: 'COMPLETED' });

    const data = prismaMock.event.update.mock.calls[0][0].data;
    expect(data.status).toBe('COMPLETED');
  });

  it('cross-tenant → 404', async () => {
    const token = signToken({ id: 'attacker' });
    prismaMock.event.findFirst.mockResolvedValueOnce(null);

    const res = await request(app)
      .post('/api/delivery/update')
      .set('Authorization', `Bearer ${token}`)
      .send(validPayload);

    expect(res.status).toBe(404);
    expect(prismaMock.event.update).not.toHaveBeenCalled();
  });

  it('missing driveLink → 400', async () => {
    const token = signToken();
    const res = await request(app)
      .post('/api/delivery/update')
      .set('Authorization', `Bearer ${token}`)
      .send({ eventId: 'evt-1' });

    expect(res.status).toBe(400);
  });
});

// ─────────────────────────────────────────────────────────────────────
// GET /api/delivery/delivered
// ─────────────────────────────────────────────────────────────────────
describe('GET /api/delivery/delivered', () => {
  it('returns owner-scoped delivered events with minimal projection', async () => {
    const token = signToken({ id: 'owner-1' });
    prismaMock.event.findMany.mockResolvedValueOnce([
      { title: 'A', driveLink: 'http://x', date: new Date() },
    ]);

    const res = await request(app)
      .get('/api/delivery/delivered')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.data).toHaveLength(1);

    expect(prismaMock.event.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { ownerId: 'owner-1', status: 'DELIVERED' },
        select: { title: true, driveLink: true, date: true },
      }),
    );
  });
});

// ─────────────────────────────────────────────────────────────────────
// Error paths
// ─────────────────────────────────────────────────────────────────────
describe('Delivery — error paths', () => {
  it('updateDelivery → 500 on Prisma error', async () => {
    const token = signToken();
    prismaMock.event.findFirst.mockRejectedValueOnce(new Error('boom'));

    const res = await request(app)
      .post('/api/delivery/update')
      .set('Authorization', `Bearer ${token}`)
      .send({ eventId: 'evt-1', driveLink: 'https://x' });

    expect(res.status).toBe(500);
  });

  it('getDeliveredEvents → 500 on Prisma error', async () => {
    const token = signToken();
    prismaMock.event.findMany.mockRejectedValueOnce(new Error('boom'));

    const res = await request(app)
      .get('/api/delivery/delivered')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(500);
  });
});
