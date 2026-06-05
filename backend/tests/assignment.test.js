// tests/assignment.test.js
//
// Assignment endpoints — assign / event-staff / my-work / remove।

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
// POST /api/assignments
// ─────────────────────────────────────────────────────────────────────
describe('POST /api/assignments', () => {
  const validPayload = {
    eventId: 'evt-1',
    userId:  'staff-1',
    role:    'Chief Photographer',
  };

  it('event owner match হলে 201 + assignment', async () => {
    const token = signToken({ id: 'owner-1', role: 'OWNER' });

    prismaMock.event.findFirst.mockResolvedValueOnce({
      id: 'evt-1',
      ownerId: 'owner-1',
    });
    prismaMock.assignment.create.mockResolvedValueOnce({
      id: 'asn-1',
      ...validPayload,
    });

    const res = await request(app)
      .post('/api/assignments')
      .set('Authorization', `Bearer ${token}`)
      .send(validPayload);

    expect(res.status).toBe(201);
    expect(res.body.assignment).toMatchObject({ id: 'asn-1' });

    expect(prismaMock.event.findFirst).toHaveBeenCalledWith({
      where: { id: 'evt-1', ownerId: 'owner-1' },
    });
    expect(prismaMock.assignment.create).toHaveBeenCalledWith({
      data: validPayload,
    });
  });

  it('event অন্য owner-এর হলে 404 (cross-tenant block)', async () => {
    const token = signToken({ id: 'attacker' });

    prismaMock.event.findFirst.mockResolvedValueOnce(null);

    const res = await request(app)
      .post('/api/assignments')
      .set('Authorization', `Bearer ${token}`)
      .send(validPayload);

    expect(res.status).toBe(404);
    expect(prismaMock.assignment.create).not.toHaveBeenCalled();
  });

  it('eventId / userId / role missing → 400', async () => {
    const token = signToken();
    const res = await request(app)
      .post('/api/assignments')
      .set('Authorization', `Bearer ${token}`)
      .send({ eventId: 'evt-1' });

    expect(res.status).toBe(400);
  });
});

// ─────────────────────────────────────────────────────────────────────
// GET /api/assignments/event/:eventId
// ─────────────────────────────────────────────────────────────────────
describe('GET /api/assignments/event/:eventId', () => {
  it('event-এর staff list ফেরত দেয়, user info সহ', async () => {
    const token = signToken();
    prismaMock.assignment.findMany.mockResolvedValueOnce([
      {
        id: 'asn-1',
        userId: 'staff-1',
        role: 'Chief',
        user: { fullName: 'Karim', email: 'k@x.com', role: 'FREELANCER' },
      },
    ]);

    const res = await request(app)
      .get('/api/assignments/event/evt-1')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.data[0].user.fullName).toBe('Karim');

    expect(prismaMock.assignment.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { eventId: 'evt-1' },
        include: expect.objectContaining({
          user: { select: { fullName: true, email: true, role: true } },
        }),
      }),
    );
  });
});

// ─────────────────────────────────────────────────────────────────────
// GET /api/assignments/me
// ─────────────────────────────────────────────────────────────────────
describe('GET /api/assignments/me', () => {
  it('caller-এর own assignments newest-first', async () => {
    const token = signToken({ id: 'staff-1', role: 'FREELANCER' });
    prismaMock.assignment.findMany.mockResolvedValueOnce([
      {
        id: 'asn-2',
        eventId: 'evt-2',
        event: { title: 'B', date: new Date(), location: 'Dhaka', status: 'CONFIRMED' },
      },
    ]);

    const res = await request(app)
      .get('/api/assignments/me')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(prismaMock.assignment.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { userId: 'staff-1' },
        orderBy: { createdAt: 'desc' },
      }),
    );
  });
});

// ─────────────────────────────────────────────────────────────────────
// DELETE /api/assignments/:id
// ─────────────────────────────────────────────────────────────────────
describe('DELETE /api/assignments/:id', () => {
  it('assignment delete হলে 200', async () => {
    const token = signToken();
    prismaMock.assignment.delete.mockResolvedValueOnce({ id: 'asn-1' });

    const res = await request(app)
      .delete('/api/assignments/asn-1')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(prismaMock.assignment.delete).toHaveBeenCalledWith({
      where: { id: 'asn-1' },
    });
  });

  it('Prisma fail হলে 500', async () => {
    const token = signToken();
    prismaMock.assignment.delete.mockRejectedValueOnce(new Error('boom'));

    const res = await request(app)
      .delete('/api/assignments/asn-bad')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(500);
  });
});

// ─────────────────────────────────────────────────────────────────────
// Error paths
// ─────────────────────────────────────────────────────────────────────
describe('Assignment — error paths', () => {
  it('assignUser → 500 on Prisma error', async () => {
    const token = signToken({ role: 'OWNER' });
    prismaMock.event.findFirst.mockRejectedValueOnce(new Error('boom'));

    const res = await request(app)
      .post('/api/assignments')
      .set('Authorization', `Bearer ${token}`)
      .send({ eventId: 'e1', userId: 'u1', role: 'Chief' });

    expect(res.status).toBe(500);
  });

  it('getEventStaff → 500 on Prisma error', async () => {
    const token = signToken();
    prismaMock.assignment.findMany.mockRejectedValueOnce(new Error('boom'));

    const res = await request(app)
      .get('/api/assignments/event/e1')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(500);
  });

  it('getMyAssignments → 500 on Prisma error', async () => {
    const token = signToken();
    prismaMock.assignment.findMany.mockRejectedValueOnce(new Error('boom'));

    const res = await request(app)
      .get('/api/assignments/me')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(500);
  });
});
