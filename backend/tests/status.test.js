// tests/status.test.js
//
// Status state-machine + history + cancel — statusController smoke।
//
// Note on routing: app.js দু'বার /api/bookings মাউন্ট করেছে — প্রথমে
// bookingRoutes (যেটায় PATCH /:id/status আছে), তারপর statusRoutes (যেটায়
// GET /:id/history ও POST /:id/cancel আছে)।  Express first-match-wins
// করে, তাই PATCH path আসলে bookingController.updateBookingStatus এ যায় —
// এটা booking.test.js-এ already covered।  এই suite-এ আমরা GET history ও
// POST cancel এই দুটোই test করি।

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
// GET /api/bookings/:id/history
// ─────────────────────────────────────────────────────────────────────
describe('GET /api/bookings/:id/history', () => {
  it('booking-এর full history descending order এ ফেরত দেয়', async () => {
    const token = signToken({ id: 'owner-1', role: 'OWNER' });

    prismaMock.statusHistory.findMany.mockResolvedValueOnce([
      {
        id: 'h2',
        eventId: 'evt-1',
        fromStatus: 'PENDING',
        toStatus: 'CONFIRMED',
        changeType: 'CONFIRMED',
        changedAt: new Date('2025-01-02'),
        note: 'Approved',
        changedBy: { fullName: 'Owner Bhai', role: 'OWNER' },
      },
      {
        id: 'h1',
        eventId: 'evt-1',
        fromStatus: null,
        toStatus: 'PENDING',
        changeType: 'CREATED',
        changedAt: new Date('2025-01-01'),
        note: 'Booking created',
        changedBy: { fullName: 'Owner Bhai', role: 'OWNER' },
      },
    ]);

    const res = await request(app)
      .get('/api/bookings/evt-1/history')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toHaveLength(2);
    expect(res.body.data[0].toStatus).toBe('CONFIRMED');

    expect(prismaMock.statusHistory.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { eventId: 'evt-1' },
        orderBy: { changedAt: 'desc' },
      }),
    );
  });

  it('history empty হলে 404', async () => {
    const token = signToken();
    prismaMock.statusHistory.findMany.mockResolvedValueOnce([]);

    const res = await request(app)
      .get('/api/bookings/no-such/history')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(404);
    expect(res.body.success).toBe(false);
  });
});

// ─────────────────────────────────────────────────────────────────────
// POST /api/bookings/:id/cancel
// ─────────────────────────────────────────────────────────────────────
describe('POST /api/bookings/:id/cancel', () => {
  it('Owner কে allow করে — booking cancel + history record', async () => {
    const token = signToken({ id: 'owner-1', role: 'OWNER' });

    prismaMock.event.findUnique.mockResolvedValueOnce({
      id: 'evt-1',
      status: 'PENDING',
    });
    prismaMock.event.update.mockResolvedValueOnce({});
    prismaMock.statusHistory.create.mockResolvedValueOnce({});

    const res = await request(app)
      .post('/api/bookings/evt-1/cancel')
      .set('Authorization', `Bearer ${token}`)
      .send({ cancellationReason: 'Client requested reschedule' });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);

    expect(prismaMock.event.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'evt-1' },
        data: expect.objectContaining({
          status: 'CANCELLED',
          cancellationReason: 'Client requested reschedule',
          cancelledBy: 'owner-1',
        }),
      }),
    );

    expect(prismaMock.statusHistory.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          eventId: 'evt-1',
          fromStatus: 'PENDING',
          toStatus: 'CANCELLED',
          changeType: 'CANCELLED',
        }),
      }),
    );
  });

  it('FREELANCER cancel করতে পারে না — 403', async () => {
    const token = signToken({ id: 'free-1', role: 'FREELANCER' });

    const res = await request(app)
      .post('/api/bookings/evt-1/cancel')
      .set('Authorization', `Bearer ${token}`)
      .send({ cancellationReason: 'nope' });

    expect(res.status).toBe(403);
    expect(prismaMock.event.update).not.toHaveBeenCalled();
  });

  it('booking না থাকলে 404', async () => {
    const token = signToken({ role: 'OWNER' });
    prismaMock.event.findUnique.mockResolvedValueOnce(null);

    const res = await request(app)
      .post('/api/bookings/missing/cancel')
      .set('Authorization', `Bearer ${token}`)
      .send({});

    expect(res.status).toBe(404);
  });
});

// ─────────────────────────────────────────────────────────────────────
// PATCH /api/bookings/:id/status — statusController state machine
//
// NOTE on routing: app.js mounts bookingRoutes BEFORE statusRoutes on
// /api/bookings, so PATCH /:id/status hits bookingController (the simple
// update, already covered in booking.test.js)।  To exercise the rich
// state-machine in statusController we point Express at the second
// registration via a manually-mounted Express subapp।  This proves the
// state-machine logic in isolation and covers the previously-missed
// branches (forward transition gate, role gate, business rules)।

const express = require('express');
const statusRoutes = require('../src/routes/statusRoutes');
const errorMiddleware = require('../src/middleware/errorMiddleware');

function buildStatusOnlyApp() {
  const sub = express();
  sub.use(express.json());
  // Mount JUST the statusRoutes so PATCH /:id/status resolves to
  // statusController.updateStatus (not booking's simple variant)।
  sub.use('/api/bookings', statusRoutes);
  sub.use(errorMiddleware);
  return sub;
}

describe('statusController.updateStatus — state machine', () => {
  let sm;
  beforeAll(() => {
    sm = buildStatusOnlyApp();
  });

  it('PENDING → CONFIRMED with assignments → 200', async () => {
    const token = signToken({ id: 'owner-1', role: 'OWNER' });
    prismaMock.event.findUnique.mockResolvedValueOnce({
      id: 'evt-1',
      status: 'PENDING',
      assignments: [{ id: 'a1', userId: 'u1' }],
    });
    prismaMock.event.update.mockResolvedValueOnce({
      id: 'evt-1',
      status: 'CONFIRMED',
    });
    prismaMock.statusHistory.create.mockResolvedValueOnce({});

    const res = await request(sm)
      .patch('/api/bookings/evt-1/status')
      .set('Authorization', `Bearer ${token}`)
      .send({ toStatus: 'CONFIRMED', note: 'Approved' });

    expect(res.status).toBe(200);
    expect(prismaMock.statusHistory.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          fromStatus: 'PENDING',
          toStatus: 'CONFIRMED',
          note: 'Approved',
        }),
      }),
    );
  });

  it('CONFIRMED with NO assignments → 400 (business rule)', async () => {
    const token = signToken({ role: 'OWNER' });
    prismaMock.event.findUnique.mockResolvedValueOnce({
      id: 'evt-1',
      status: 'PENDING',
      assignments: [], // ← business rule violation
    });

    const res = await request(sm)
      .patch('/api/bookings/evt-1/status')
      .set('Authorization', `Bearer ${token}`)
      .send({ toStatus: 'CONFIRMED' });

    expect(res.status).toBe(400);
    expect(res.body.message).toMatch(/স্টাফ/);
  });

  it('SHOT_COMPLETE → DELIVERED without driveLink → 400', async () => {
    const token = signToken({ role: 'OWNER' });
    prismaMock.event.findUnique.mockResolvedValueOnce({
      id: 'evt-1',
      status: 'SHOT_COMPLETE',
      assignments: [{ id: 'a1', userId: 'u1' }],
      driveLink: null,
    });

    const res = await request(sm)
      .patch('/api/bookings/evt-1/status')
      .set('Authorization', `Bearer ${token}`)
      .send({ toStatus: 'DELIVERED' });

    expect(res.status).toBe(400);
    expect(res.body.message).toMatch(/Drive Link|ড্রাইভ/);
  });

  it('Invalid transition (PENDING → DELIVERED) → 400', async () => {
    const token = signToken({ role: 'OWNER' });
    prismaMock.event.findUnique.mockResolvedValueOnce({
      id: 'evt-1',
      status: 'PENDING',
      assignments: [],
    });

    const res = await request(sm)
      .patch('/api/bookings/evt-1/status')
      .set('Authorization', `Bearer ${token}`)
      .send({ toStatus: 'DELIVERED' });

    expect(res.status).toBe(400);
    expect(res.body.message).toMatch(/অবৈধ|invalid/i);
  });

  it('FREELANCER assigned + SHOT_COMPLETE → DELIVERED → 200', async () => {
    const token = signToken({ id: 'staff-1', role: 'FREELANCER' });
    prismaMock.event.findUnique.mockResolvedValueOnce({
      id: 'evt-1',
      status: 'SHOT_COMPLETE',
      assignments: [{ id: 'a1', userId: 'staff-1' }],
      driveLink: 'https://drive.google.com/x',
    });
    prismaMock.event.update.mockResolvedValueOnce({});
    prismaMock.statusHistory.create.mockResolvedValueOnce({});

    const res = await request(sm)
      .patch('/api/bookings/evt-1/status')
      .set('Authorization', `Bearer ${token}`)
      .send({ toStatus: 'DELIVERED' });

    expect(res.status).toBe(200);
  });

  it('FREELANCER trying CONFIRMED → 403', async () => {
    const token = signToken({ id: 'staff-1', role: 'FREELANCER' });
    prismaMock.event.findUnique.mockResolvedValueOnce({
      id: 'evt-1',
      status: 'PENDING',
      assignments: [{ id: 'a1', userId: 'staff-1' }],
    });

    const res = await request(sm)
      .patch('/api/bookings/evt-1/status')
      .set('Authorization', `Bearer ${token}`)
      .send({ toStatus: 'CONFIRMED' });

    expect(res.status).toBe(403);
  });

  it('FREELANCER NOT assigned + SHOT_COMPLETE → DELIVERED → 403', async () => {
    const token = signToken({ id: 'attacker', role: 'FREELANCER' });
    prismaMock.event.findUnique.mockResolvedValueOnce({
      id: 'evt-1',
      status: 'SHOT_COMPLETE',
      assignments: [{ id: 'a1', userId: 'someone-else' }],
      driveLink: 'https://x',
    });

    const res = await request(sm)
      .patch('/api/bookings/evt-1/status')
      .set('Authorization', `Bearer ${token}`)
      .send({ toStatus: 'DELIVERED' });

    expect(res.status).toBe(403);
  });

  it('Missing toStatus → 400', async () => {
    const token = signToken({ role: 'OWNER' });
    const res = await request(sm)
      .patch('/api/bookings/evt-1/status')
      .set('Authorization', `Bearer ${token}`)
      .send({});

    expect(res.status).toBe(400);
  });

  it('Event not found → 404', async () => {
    const token = signToken({ role: 'OWNER' });
    prismaMock.event.findUnique.mockResolvedValueOnce(null);

    const res = await request(sm)
      .patch('/api/bookings/nope/status')
      .set('Authorization', `Bearer ${token}`)
      .send({ toStatus: 'CONFIRMED' });

    expect(res.status).toBe(404);
  });

  it('Prisma error during update → 500', async () => {
    const token = signToken({ role: 'OWNER' });
    prismaMock.event.findUnique.mockRejectedValueOnce(new Error('boom'));

    const res = await request(sm)
      .patch('/api/bookings/evt-1/status')
      .set('Authorization', `Bearer ${token}`)
      .send({ toStatus: 'CONFIRMED' });

    expect(res.status).toBe(500);
  });
});

// ─────────────────────────────────────────────────────────────────────
// statusController.getHistory — error path
// ─────────────────────────────────────────────────────────────────────
describe('GET /api/bookings/:id/history — error path', () => {
  it('Prisma error → 500', async () => {
    const token = signToken();
    prismaMock.statusHistory.findMany.mockRejectedValueOnce(new Error('x'));

    const res = await request(app)
      .get('/api/bookings/evt-1/history')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(500);
  });
});

// ─────────────────────────────────────────────────────────────────────
// statusController.cancelBooking — error path
// ─────────────────────────────────────────────────────────────────────
describe('POST /api/bookings/:id/cancel — error path', () => {
  it('Prisma error → 500', async () => {
    const token = signToken({ role: 'OWNER' });
    prismaMock.event.findUnique.mockRejectedValueOnce(new Error('x'));

    const res = await request(app)
      .post('/api/bookings/evt-1/cancel')
      .set('Authorization', `Bearer ${token}`)
      .send({});

    expect(res.status).toBe(500);
  });
});
