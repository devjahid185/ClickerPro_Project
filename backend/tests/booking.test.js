// tests/booking.test.js
//
// Bookings module — supertest integration smoke।  Prisma mocked, JWT real,
// পুরো Express stack live।  Goal: route wiring, validation, status state-
// machine, error envelope shape — সব পরীক্ষা করা।

const request = require('supertest');

const { buildApp, signToken, prismaMock } = require('./helpers/testApp');

// সব test-এ একই app instance ব্যবহার করব — supertest এটা accept করে।
let app;
beforeAll(() => {
  app = buildApp();
});

beforeEach(() => {
  prismaMock.reset();
});

// ─────────────────────────────────────────────────────────────────────
// Auth — 401 গুলো প্রথমে যাচাই, যাতে guard ঠিকমতো wired তা নিশ্চিত হই।
// ─────────────────────────────────────────────────────────────────────
describe('GET /api/bookings — auth guard', () => {
  it('Authorization header না থাকলে 401', async () => {
    const res = await request(app).get('/api/bookings');
    expect(res.status).toBe(401);
    expect(res.body.message).toMatch(/token/i);
  });

  it('invalid token হলে 401', async () => {
    const res = await request(app)
      .get('/api/bookings')
      .set('Authorization', 'Bearer this.is.not.a.real.jwt');
    expect(res.status).toBe(401);
    expect(res.body.message).toMatch(/সঠিক|valid/i);
  });
});

// ─────────────────────────────────────────────────────────────────────
// GET /api/bookings — owner-scoped list
// ─────────────────────────────────────────────────────────────────────
describe('GET /api/bookings', () => {
  it('owner-এর bookings list ফেরত দেয়', async () => {
    const token = signToken({ id: 'owner-1', role: 'OWNER' });

    prismaMock.event.findMany.mockResolvedValueOnce([
      {
        id: 'evt-1',
        title: 'Karim Wedding',
        date: new Date('2025-12-01'),
        venue: 'Dhaka Club',
        status: 'PENDING',
        ownerId: 'owner-1',
        clientId: 'cli-1',
        client: { id: 'cli-1', name: 'Karim', phone: '0170...' },
        package: null,
        assignments: [],
      },
    ]);

    const res = await request(app)
      .get('/api/bookings')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({
      success: true,
      count: 1,
      data: expect.any(Array),
    });
    expect(res.body.data[0]).toMatchObject({
      id: 'evt-1',
      title: 'Karim Wedding',
    });

    // Prisma call-টা ownerId দিয়ে scope হয়েছে কি না — নিশ্চিত করি
    expect(prismaMock.event.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ where: { ownerId: 'owner-1' } }),
    );
  });

  it('Prisma exception হলে 500 + error envelope', async () => {
    const token = signToken();
    prismaMock.event.findMany.mockRejectedValueOnce(new Error('boom'));

    const res = await request(app)
      .get('/api/bookings')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(500);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toMatch(/সমস্যা/);
  });
});

// ─────────────────────────────────────────────────────────────────────
// POST /api/bookings — creation
// ─────────────────────────────────────────────────────────────────────
describe('POST /api/bookings', () => {
  const validPayload = {
    title:    'Rahim Wedding',
    date:     '2025-12-15',
    startTime:'10:00',
    endTime:  '18:00',
    shift:    'DAY',
    venue:    'Sonargaon Hotel',
    clientId: 'cli-42',
  };

  it('সব required field থাকলে 201 + booking ফেরত আসে', async () => {
    const token = signToken({ id: 'owner-1', role: 'OWNER' });

    prismaMock.client.findUnique.mockResolvedValueOnce({ id: 'cli-42' });
    prismaMock.user.findUnique.mockResolvedValueOnce({
      role: 'OWNER',
      distributionOn: true, // conflict check skip
    });
    prismaMock.event.create.mockResolvedValueOnce({
      id: 'evt-new',
      ...validPayload,
      status: 'PENDING',
      ownerId: 'owner-1',
      client: { id: 'cli-42', name: 'Rahim', phone: '019...' },
      package: null,
    });
    prismaMock.statusHistory.create.mockResolvedValueOnce({});

    const res = await request(app)
      .post('/api/bookings')
      .set('Authorization', `Bearer ${token}`)
      .send(validPayload);

    expect(res.status).toBe(201);
    expect(res.body).toMatchObject({
      success: true,
      booking: expect.objectContaining({ id: 'evt-new', status: 'PENDING' }),
    });

    // Status history-তে CREATED entry গেছে কি না verify
    expect(prismaMock.statusHistory.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          eventId:    'evt-new',
          toStatus:   'PENDING',
          changeType: 'CREATED',
        }),
      }),
    );
  });

  it('required field missing হলে 400', async () => {
    const token = signToken();
    const res = await request(app)
      .post('/api/bookings')
      .set('Authorization', `Bearer ${token}`)
      .send({ title: 'Onek Tukro', date: '2025-12-01' }); // venue + clientId missing

    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toMatch(/বাধ্যতামূলক/);
  });

  it('invalid date format হলে 400', async () => {
    const token = signToken();
    prismaMock.client.findUnique.mockResolvedValueOnce({ id: 'cli-42' });

    const res = await request(app)
      .post('/api/bookings')
      .set('Authorization', `Bearer ${token}`)
      .send({ ...validPayload, date: 'not-a-date' });

    expect(res.status).toBe(400);
    expect(res.body.message).toMatch(/তারিখ|date/i);
  });

  it('client না থাকলে 404', async () => {
    const token = signToken();
    prismaMock.client.findUnique.mockResolvedValueOnce(null);

    const res = await request(app)
      .post('/api/bookings')
      .set('Authorization', `Bearer ${token}`)
      .send(validPayload);

    expect(res.status).toBe(404);
    expect(res.body.message).toMatch(/client/i);
  });

  it('distribution OFF এবং একই date+shift এ booking থাকলে 409', async () => {
    const token = signToken({ id: 'owner-1', role: 'OWNER' });

    prismaMock.client.findUnique.mockResolvedValueOnce({ id: 'cli-42' });
    prismaMock.user.findUnique.mockResolvedValueOnce({
      role: 'OWNER',
      distributionOn: false,
    });
    prismaMock.event.findFirst.mockResolvedValueOnce({
      id: 'evt-existing',
    });

    const res = await request(app)
      .post('/api/bookings')
      .set('Authorization', `Bearer ${token}`)
      .send(validPayload);

    expect(res.status).toBe(409);
    expect(res.body).toMatchObject({
      success: false,
      conflictBookingId: 'evt-existing',
    });

    // event create হয়নি confirm
    expect(prismaMock.event.create).not.toHaveBeenCalled();
  });
});

// ─────────────────────────────────────────────────────────────────────
// PATCH /api/bookings/:id/status — state machine
// (statusController is mounted second on /api/bookings, তাই PATCH এ
// সেটাই hit হবে — বুকিং কন্ট্রোলারের রিউট prefix `/` এর কাছে আসে আগে,
// কিন্তু `/:id/status` দুটোতেই define আছে। Express routing first-match
// wins, তাই `bookingController.updateBookingStatus` আগে hit করবে।)
// ─────────────────────────────────────────────────────────────────────
describe('PATCH /api/bookings/:id/status', () => {
  it('booking exists ও owner ম্যাচ করলে status update হয়', async () => {
    const token = signToken({ id: 'owner-1', role: 'OWNER' });

    prismaMock.event.findUnique.mockResolvedValueOnce({
      id: 'evt-1',
      status: 'PENDING',
    });
    prismaMock.event.updateMany.mockResolvedValueOnce({ count: 1 });
    prismaMock.statusHistory.create.mockResolvedValueOnce({});

    const res = await request(app)
      .patch('/api/bookings/evt-1/status')
      .set('Authorization', `Bearer ${token}`)
      .send({ status: 'CONFIRMED' });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);

    expect(prismaMock.statusHistory.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          fromStatus: 'PENDING',
          toStatus:   'CONFIRMED',
        }),
      }),
    );
  });

  it('booking না থাকলে 404', async () => {
    const token = signToken();
    prismaMock.event.findUnique.mockResolvedValueOnce(null);

    const res = await request(app)
      .patch('/api/bookings/missing-id/status')
      .set('Authorization', `Bearer ${token}`)
      .send({ status: 'CONFIRMED' });

    expect(res.status).toBe(404);
    expect(res.body.message).toMatch(/পাওয়া যায়নি|not found/i);
  });
});

// ─────────────────────────────────────────────────────────────────────
// /health — liveness probe
// ─────────────────────────────────────────────────────────────────────
describe('GET /health', () => {
  it('always returns ok', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ status: 'ok' });
  });
});
