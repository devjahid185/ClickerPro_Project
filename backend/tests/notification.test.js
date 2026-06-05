// tests/notification.test.js
//
// Notification endpoints — direct send (internal/admin), user list, mark
// read।  POST /send is currently un-authenticated by route config — we
// document that fact explicitly so a future regression toward "no auth"
// is loud, not silent।

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
// POST /api/notifications/send  (no auth — internal use)
// ─────────────────────────────────────────────────────────────────────
describe('POST /api/notifications/send', () => {
  it('valid payload → 201 + persists notification row with read=false', async () => {
    prismaMock.notification.create.mockResolvedValueOnce({
      id: 'notif-1',
      userId: 'user-1',
      category: 'booking',
      message: 'New booking received',
      read: false,
    });

    const res = await request(app).post('/api/notifications/send').send({
      userId: 'user-1',
      category: 'booking',
      message: 'New booking received',
      deeplink: '/booking/evt-1',
    });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);

    expect(prismaMock.notification.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          userId: 'user-1',
          category: 'booking',
          message: 'New booking received',
          deeplink: '/booking/evt-1',
          read: false,
        }),
      }),
    );
  });

  it('missing userId → 400', async () => {
    const res = await request(app)
      .post('/api/notifications/send')
      .send({ category: 'wish', message: 'happy birthday' });

    expect(res.status).toBe(400);
    expect(prismaMock.notification.create).not.toHaveBeenCalled();
  });

  it('Prisma error → 500 (handler suppresses error stack)', async () => {
    prismaMock.notification.create.mockRejectedValueOnce(new Error('boom'));

    const res = await request(app).post('/api/notifications/send').send({
      userId: 'u1',
      category: 'announcement',
      message: 'maintenance',
    });

    expect(res.status).toBe(500);
  });
});

// ─────────────────────────────────────────────────────────────────────
// GET /api/notifications
// ─────────────────────────────────────────────────────────────────────
describe('GET /api/notifications', () => {
  it('owner-scoped descending list', async () => {
    const token = signToken({ id: 'user-1' });

    prismaMock.notification.findMany.mockResolvedValueOnce([
      { id: 'n2', sentAt: new Date('2025-02-01'), read: false },
      { id: 'n1', sentAt: new Date('2025-01-15'), read: true },
    ]);

    const res = await request(app)
      .get('/api/notifications')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.data).toHaveLength(2);

    expect(prismaMock.notification.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { userId: 'user-1' },
        orderBy: { sentAt: 'desc' },
      }),
    );
  });

  it('Authorization missing → 401', async () => {
    const res = await request(app).get('/api/notifications');
    expect(res.status).toBe(401);
  });
});

// ─────────────────────────────────────────────────────────────────────
// PATCH /api/notifications/read
// ─────────────────────────────────────────────────────────────────────
describe('PATCH /api/notifications/read', () => {
  it('marks the row read=true', async () => {
    const token = signToken();
    prismaMock.notification.update.mockResolvedValueOnce({
      id: 'n1',
      read: true,
    });

    const res = await request(app)
      .patch('/api/notifications/read')
      .set('Authorization', `Bearer ${token}`)
      .send({ notificationId: 'n1' });

    expect(res.status).toBe(200);
    expect(prismaMock.notification.update).toHaveBeenCalledWith({
      where: { id: 'n1' },
      data: { read: true },
    });
  });
});

// ─────────────────────────────────────────────────────────────────────
// Error paths
// ─────────────────────────────────────────────────────────────────────
describe('Notification — error paths', () => {
  it('getUserNotifications → 500 on Prisma error', async () => {
    const token = signToken();
    prismaMock.notification.findMany.mockRejectedValueOnce(new Error('boom'));

    const res = await request(app)
      .get('/api/notifications')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(500);
  });

  it('markAsRead → 500 on Prisma error', async () => {
    const token = signToken();
    prismaMock.notification.update.mockRejectedValueOnce(new Error('boom'));

    const res = await request(app)
      .patch('/api/notifications/read')
      .set('Authorization', `Bearer ${token}`)
      .send({ notificationId: 'n1' });

    expect(res.status).toBe(500);
  });
});
