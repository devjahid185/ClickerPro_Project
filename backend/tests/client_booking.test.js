// tests/client_booking.test.js
//
// Public client booking flow — submit (no auth), pending-requests list
// (auth), and token generation (auth)।  Tests cover the
// "phone-already-exists → reuse client" branch, the new-client branch,
// and notification side-effect dispatch।

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
// POST /api/client-booking/submit  (public, no auth header)
// ─────────────────────────────────────────────────────────────────────
describe('POST /api/client-booking/submit', () => {
  const validPayload = {
    ownerToken:    'CP-XYZ123',
    clientName:    'Karim',
    clientPhone:   '01700000001',
    clientEmail:   'karim@example.com',
    eventType:     'Wedding',
    eventDate:     '2025-12-15',
    eventShift:    'DAY',
    venue:         'Sonargaon',
    notes:         'Special requirements',
  };

  it('valid token + new client → 201, creates client + event, fires notification', async () => {
    prismaMock.user.findUnique.mockResolvedValueOnce({
      id: 'owner-1',
      publicBookingToken: 'CP-XYZ123',
    });
    prismaMock.client.findFirst.mockResolvedValueOnce(null); // no existing
    prismaMock.client.create.mockResolvedValueOnce({
      id: 'cli-new',
      name: 'Karim',
    });
    prismaMock.event.create.mockResolvedValueOnce({
      id: 'evt-new',
      title: 'Karim - Wedding',
      ownerId: 'owner-1',
      status: 'PENDING',
    });
    prismaMock.notification.create.mockResolvedValueOnce({});

    const res = await request(app)
      .post('/api/client-booking/submit')
      .send(validPayload);

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);

    // client.create called with owner's ownerId
    expect(prismaMock.client.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          ownerId: 'owner-1',
          name: 'Karim',
          phone: '01700000001',
        }),
      }),
    );
    // event.create called with status PENDING + tied to new client
    const eventArg = prismaMock.event.create.mock.calls[0][0].data;
    expect(eventArg).toMatchObject({
      ownerId: 'owner-1',
      clientId: 'cli-new',
      status: 'PENDING',
      type: 'Wedding',
      shift: 'DAY',
    });
    // notification fired (side effect)
    expect(prismaMock.notification.create).toHaveBeenCalled();
  });

  it('phone already exists → reuses client, no client.create', async () => {
    prismaMock.user.findUnique.mockResolvedValueOnce({
      id: 'owner-1',
      publicBookingToken: 'CP-XYZ123',
    });
    prismaMock.client.findFirst.mockResolvedValueOnce({
      id: 'cli-existing',
      phone: '01700000001',
    });
    prismaMock.event.create.mockResolvedValueOnce({ id: 'evt-new' });
    prismaMock.notification.create.mockResolvedValueOnce({});

    const res = await request(app)
      .post('/api/client-booking/submit')
      .send(validPayload);

    expect(res.status).toBe(201);
    expect(prismaMock.client.create).not.toHaveBeenCalled();

    const eventArg = prismaMock.event.create.mock.calls[0][0].data;
    expect(eventArg.clientId).toBe('cli-existing');
  });

  it('invalid ownerToken → 404', async () => {
    prismaMock.user.findUnique.mockResolvedValueOnce(null);

    const res = await request(app)
      .post('/api/client-booking/submit')
      .send(validPayload);

    expect(res.status).toBe(404);
    expect(prismaMock.event.create).not.toHaveBeenCalled();
  });
});

// ─────────────────────────────────────────────────────────────────────
// GET /api/client-booking/requests  (auth required)
// ─────────────────────────────────────────────────────────────────────
describe('GET /api/client-booking/requests', () => {
  it('owner-scoped PENDING events with client info, newest first', async () => {
    const token = signToken({ id: 'owner-1' });
    prismaMock.event.findMany.mockResolvedValueOnce([
      {
        id: 'evt-1',
        title: 'Karim - Wedding',
        client: { id: 'cli-1', name: 'Karim' },
      },
    ]);

    const res = await request(app)
      .get('/api/client-booking/requests')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.data[0].client.name).toBe('Karim');

    expect(prismaMock.event.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { ownerId: 'owner-1', status: 'PENDING' },
        include: { client: true },
        orderBy: { createdAt: 'desc' },
      }),
    );
  });

  it('Authorization missing → 401', async () => {
    const res = await request(app).get('/api/client-booking/requests');
    expect(res.status).toBe(401);
  });
});

// ─────────────────────────────────────────────────────────────────────
// POST /api/client-booking/generate-token  (auth required)
// ─────────────────────────────────────────────────────────────────────
describe('POST /api/client-booking/generate-token', () => {
  it('issues a CP-prefixed token + booking link', async () => {
    const token = signToken({ id: 'owner-1' });
    prismaMock.user.update.mockResolvedValueOnce({
      id: 'owner-1',
      publicBookingToken: 'CP-XYZ123ABC',
    });

    const res = await request(app)
      .post('/api/client-booking/generate-token')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.token).toMatch(/^CP-/);
    expect(res.body.link).toMatch(
      /^https:\/\/clickerpro\.app\/book\/CP-/,
    );

    // user.update called with the generated token
    const arg = prismaMock.user.update.mock.calls[0][0];
    expect(arg.where).toEqual({ id: 'owner-1' });
    expect(arg.data.publicBookingToken).toMatch(/^CP-/);
  });
});

// ─────────────────────────────────────────────────────────────────────
// Error paths
// ─────────────────────────────────────────────────────────────────────
describe('clientBooking — error paths', () => {
  it('submit → 500 on Prisma error', async () => {
    prismaMock.user.findUnique.mockRejectedValueOnce(new Error('boom'));

    const res = await request(app)
      .post('/api/client-booking/submit')
      .send({
        ownerToken: 'CP-XYZ123',
        clientName: 'Karim',
        clientPhone: '01700000001',
        eventType: 'Wedding',
        eventDate: '2025-12-15',
        eventShift: 'DAY',
        venue: 'Sonargaon',
      });

    expect(res.status).toBe(500);
  });

  it('getPendingRequests → 500 on Prisma error', async () => {
    const token = signToken();
    prismaMock.event.findMany.mockRejectedValueOnce(new Error('boom'));

    const res = await request(app)
      .get('/api/client-booking/requests')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(500);
  });

  it('generateBookingToken → 500 on Prisma error', async () => {
    const token = signToken();
    prismaMock.user.update.mockRejectedValueOnce(new Error('boom'));

    const res = await request(app)
      .post('/api/client-booking/generate-token')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(500);
  });
});
