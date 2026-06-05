// tests/task.test.js
//
// Task progress endpoints — assignment-gated upsert, owner-only event
// progress aggregation।  Validates 0–100 range guard and the composite
// `eventId_userId` upsert key contract।

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
// PATCH /api/tasks/progress
// ─────────────────────────────────────────────────────────────────────
describe('PATCH /api/tasks/progress', () => {
  it('assigned user 0–100 → 200 + upsert with composite key', async () => {
    const token = signToken({ id: 'staff-1' });

    prismaMock.assignment.findFirst.mockResolvedValueOnce({
      id: 'asn-1',
      eventId: 'evt-1',
      userId: 'staff-1',
    });
    prismaMock.taskProgress.upsert.mockResolvedValueOnce({
      id: 'tp-1',
      eventId: 'evt-1',
      userId: 'staff-1',
      percentage: 60,
      note: 'half done',
    });

    const res = await request(app)
      .patch('/api/tasks/progress')
      .set('Authorization', `Bearer ${token}`)
      .send({ eventId: 'evt-1', percentage: 60, note: 'half done' });

    expect(res.status).toBe(200);
    expect(res.body.data.percentage).toBe(60);

    const arg = prismaMock.taskProgress.upsert.mock.calls[0][0];
    expect(arg.where).toEqual({
      eventId_userId: { eventId: 'evt-1', userId: 'staff-1' },
    });
    expect(arg.update).toMatchObject({ percentage: 60, note: 'half done' });
    expect(arg.create).toMatchObject({
      eventId: 'evt-1',
      userId: 'staff-1',
      percentage: 60,
      note: 'half done',
    });
  });

  it('not assigned → 403', async () => {
    const token = signToken({ id: 'attacker' });
    prismaMock.assignment.findFirst.mockResolvedValueOnce(null);

    const res = await request(app)
      .patch('/api/tasks/progress')
      .set('Authorization', `Bearer ${token}`)
      .send({ eventId: 'evt-1', percentage: 50 });

    expect(res.status).toBe(403);
    expect(prismaMock.taskProgress.upsert).not.toHaveBeenCalled();
  });

  it('percentage missing → 400', async () => {
    const token = signToken();
    const res = await request(app)
      .patch('/api/tasks/progress')
      .set('Authorization', `Bearer ${token}`)
      .send({ eventId: 'evt-1' });

    expect(res.status).toBe(400);
    expect(prismaMock.assignment.findFirst).not.toHaveBeenCalled();
  });

  it('percentage > 100 → 400', async () => {
    const token = signToken();
    const res = await request(app)
      .patch('/api/tasks/progress')
      .set('Authorization', `Bearer ${token}`)
      .send({ eventId: 'evt-1', percentage: 150 });

    expect(res.status).toBe(400);
  });

  it('percentage < 0 → 400', async () => {
    const token = signToken();
    const res = await request(app)
      .patch('/api/tasks/progress')
      .set('Authorization', `Bearer ${token}`)
      .send({ eventId: 'evt-1', percentage: -10 });

    expect(res.status).toBe(400);
  });
});

// ─────────────────────────────────────────────────────────────────────
// GET /api/tasks/event/:id
// ─────────────────────────────────────────────────────────────────────
describe('GET /api/tasks/event/:id', () => {
  it('Owner → 200 + per-user list with user info joined', async () => {
    const token = signToken({ role: 'OWNER' });
    prismaMock.taskProgress.findMany.mockResolvedValueOnce([
      {
        id: 'tp-1',
        eventId: 'evt-1',
        userId: 'staff-1',
        percentage: 80,
        user: { fullName: 'Karim', email: 'k@x.com' },
      },
    ]);

    const res = await request(app)
      .get('/api/tasks/event/evt-1')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.count).toBe(1);
    expect(res.body.data[0].user.fullName).toBe('Karim');

    expect(prismaMock.taskProgress.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { eventId: 'evt-1' },
        include: { user: { select: { fullName: true, email: true } } },
      }),
    );
  });

  it('FREELANCER → 403', async () => {
    const token = signToken({ role: 'FREELANCER' });
    const res = await request(app)
      .get('/api/tasks/event/evt-1')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(403);
    expect(prismaMock.taskProgress.findMany).not.toHaveBeenCalled();
  });

  it('MANAGER → 403', async () => {
    const token = signToken({ role: 'MANAGER' });
    const res = await request(app)
      .get('/api/tasks/event/evt-1')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(403);
  });
});

// ─────────────────────────────────────────────────────────────────────
// Error paths
// ─────────────────────────────────────────────────────────────────────
describe('Task — error paths', () => {
  it('updateProgress → 500 on Prisma error', async () => {
    const token = signToken();
    prismaMock.assignment.findFirst.mockRejectedValueOnce(new Error('boom'));

    const res = await request(app)
      .patch('/api/tasks/progress')
      .set('Authorization', `Bearer ${token}`)
      .send({ eventId: 'e1', percentage: 50 });

    expect(res.status).toBe(500);
  });

  it('getEventProgress → 500 on Prisma error', async () => {
    const token = signToken({ role: 'OWNER' });
    prismaMock.taskProgress.findMany.mockRejectedValueOnce(new Error('boom'));

    const res = await request(app)
      .get('/api/tasks/event/e1')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(500);
  });
});
