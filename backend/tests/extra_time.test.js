// tests/extra_time.test.js
//
// Extra-time endpoints — role-gated update with team-membership escape
// hatch + numeric validation + simple read।

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
// POST /api/extra-time/update
// ─────────────────────────────────────────────────────────────────────
describe('POST /api/extra-time/update', () => {
  it('Owner of the event → 200 + updates extraHours', async () => {
    const token = signToken({ id: 'owner-1', role: 'OWNER' });

    prismaMock.event.findUnique.mockResolvedValueOnce({
      id: 'evt-1',
      ownerId: 'owner-1',
    });
    prismaMock.event.update.mockResolvedValueOnce({
      id: 'evt-1',
      extraHours: 2.5,
    });

    const res = await request(app)
      .post('/api/extra-time/update')
      .set('Authorization', `Bearer ${token}`)
      .send({ eventId: 'evt-1', hours: 2.5 });

    expect(res.status).toBe(200);
    expect(res.body.data).toMatchObject({ eventId: 'evt-1', extraHours: 2.5 });

    expect(prismaMock.event.update).toHaveBeenCalledWith({
      where: { id: 'evt-1' },
      data: { extraHours: 2.5 },
    });
  });

  it('Manager of the same studio → 200 (team-membership escape)', async () => {
    const token = signToken({ id: 'mgr-1', role: 'MANAGER' });

    prismaMock.event.findUnique.mockResolvedValueOnce({
      id: 'evt-1',
      ownerId: 'owner-1',
    });
    prismaMock.teamMembership.findFirst.mockResolvedValueOnce({
      id: 'tm-1',
      userId: 'mgr-1',
      ownerId: 'owner-1',
    });
    prismaMock.event.update.mockResolvedValueOnce({
      id: 'evt-1',
      extraHours: 1,
    });

    const res = await request(app)
      .post('/api/extra-time/update')
      .set('Authorization', `Bearer ${token}`)
      .send({ eventId: 'evt-1', hours: 1 });

    expect(res.status).toBe(200);
  });

  it('Manager NOT in team → 403', async () => {
    const token = signToken({ id: 'attacker', role: 'MANAGER' });

    prismaMock.event.findUnique.mockResolvedValueOnce({
      id: 'evt-1',
      ownerId: 'owner-1',
    });
    prismaMock.teamMembership.findFirst.mockResolvedValueOnce(null);

    const res = await request(app)
      .post('/api/extra-time/update')
      .set('Authorization', `Bearer ${token}`)
      .send({ eventId: 'evt-1', hours: 1 });

    expect(res.status).toBe(403);
    expect(prismaMock.event.update).not.toHaveBeenCalled();
  });

  it('FREELANCER → 403 (role gate)', async () => {
    const token = signToken({ role: 'FREELANCER' });
    const res = await request(app)
      .post('/api/extra-time/update')
      .set('Authorization', `Bearer ${token}`)
      .send({ eventId: 'evt-1', hours: 1 });

    expect(res.status).toBe(403);
    expect(prismaMock.event.findUnique).not.toHaveBeenCalled();
  });

  it('negative hours → 400', async () => {
    const token = signToken({ role: 'OWNER' });
    const res = await request(app)
      .post('/api/extra-time/update')
      .set('Authorization', `Bearer ${token}`)
      .send({ eventId: 'evt-1', hours: -2 });

    expect(res.status).toBe(400);
  });

  it('NaN hours → 400', async () => {
    const token = signToken({ role: 'OWNER' });
    const res = await request(app)
      .post('/api/extra-time/update')
      .set('Authorization', `Bearer ${token}`)
      .send({ eventId: 'evt-1', hours: 'not-a-number' });

    expect(res.status).toBe(400);
  });

  it('event missing → 404', async () => {
    const token = signToken({ role: 'OWNER' });
    prismaMock.event.findUnique.mockResolvedValueOnce(null);

    const res = await request(app)
      .post('/api/extra-time/update')
      .set('Authorization', `Bearer ${token}`)
      .send({ eventId: 'nope', hours: 1 });

    expect(res.status).toBe(404);
  });
});

// ─────────────────────────────────────────────────────────────────────
// GET /api/extra-time/:eventId
// ─────────────────────────────────────────────────────────────────────
describe('GET /api/extra-time/:eventId', () => {
  it('returns minimal projection', async () => {
    const token = signToken();
    prismaMock.event.findUnique.mockResolvedValueOnce({
      id: 'evt-1',
      title: 'Karim Wedding',
      extraHours: 2.5,
    });

    const res = await request(app)
      .get('/api/extra-time/evt-1')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.data).toEqual({
      id: 'evt-1',
      title: 'Karim Wedding',
      extraHours: 2.5,
    });

    expect(prismaMock.event.findUnique).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'evt-1' },
        select: { id: true, title: true, extraHours: true },
      }),
    );
  });

  it('event missing → 404', async () => {
    const token = signToken();
    prismaMock.event.findUnique.mockResolvedValueOnce(null);

    const res = await request(app)
      .get('/api/extra-time/nope')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(404);
  });
});

// ─────────────────────────────────────────────────────────────────────
// Error paths
// ─────────────────────────────────────────────────────────────────────
describe('Extra-time — error paths', () => {
  it('updateExtraTime → 500 on Prisma error', async () => {
    const token = signToken({ role: 'OWNER' });
    prismaMock.event.findUnique.mockRejectedValueOnce(new Error('boom'));

    const res = await request(app)
      .post('/api/extra-time/update')
      .set('Authorization', `Bearer ${token}`)
      .send({ eventId: 'e1', hours: 1 });

    expect(res.status).toBe(500);
  });

  it('getExtraTime → 500 on Prisma error', async () => {
    const token = signToken();
    prismaMock.event.findUnique.mockRejectedValueOnce(new Error('boom'));

    const res = await request(app)
      .get('/api/extra-time/e1')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(500);
  });
});
