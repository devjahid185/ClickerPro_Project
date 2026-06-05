// tests/reedit.test.js
//
// Re-edit request endpoints — create / update status / list।  Tests the
// role-gated security model: only Owner/Both can create, only the
// assigned editor or Owner/Both can update, role-specific list scoping।

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
// POST /api/reedits
// ─────────────────────────────────────────────────────────────────────
describe('POST /api/reedits', () => {
  const validPayload = {
    eventId: 'evt-1',
    editorId: 'staff-1',
    deliverable: 'Photos',
    notes: 'Re-color the wedding album',
    deadline: '2025-12-31',
  };

  it('Owner valid payload → 201 with round=1 + status=PENDING', async () => {
    const token = signToken({ id: 'owner-1', role: 'OWNER' });

    prismaMock.event.findUnique.mockResolvedValueOnce({ id: 'evt-1' });
    prismaMock.reEditRequest.create.mockResolvedValueOnce({
      id: 'rr-1',
      ...validPayload,
      requestedBy: 'owner-1',
      round: 1,
      status: 'PENDING',
    });

    const res = await request(app)
      .post('/api/reedits')
      .set('Authorization', `Bearer ${token}`)
      .send(validPayload);

    expect(res.status).toBe(201);
    expect(res.body.data.round).toBe(1);
    expect(res.body.data.status).toBe('PENDING');

    const data = prismaMock.reEditRequest.create.mock.calls[0][0].data;
    expect(data).toMatchObject({
      eventId: 'evt-1',
      requestedBy: 'owner-1',
      editorId: 'staff-1',
      round: 1,
      status: 'PENDING',
    });
    // deadline coerced from string to Date
    expect(data.deadline).toBeInstanceOf(Date);
  });

  it('FREELANCER cannot create → 403', async () => {
    const token = signToken({ role: 'FREELANCER' });
    const res = await request(app)
      .post('/api/reedits')
      .set('Authorization', `Bearer ${token}`)
      .send(validPayload);

    expect(res.status).toBe(403);
    expect(prismaMock.reEditRequest.create).not.toHaveBeenCalled();
  });

  it('event missing → 404', async () => {
    const token = signToken({ role: 'OWNER' });
    prismaMock.event.findUnique.mockResolvedValueOnce(null);

    const res = await request(app)
      .post('/api/reedits')
      .set('Authorization', `Bearer ${token}`)
      .send(validPayload);

    expect(res.status).toBe(404);
  });
});

// ─────────────────────────────────────────────────────────────────────
// PATCH /api/reedits/:id/status
// ─────────────────────────────────────────────────────────────────────
describe('PATCH /api/reedits/:id/status', () => {
  it('assigned editor can update status → 200', async () => {
    const token = signToken({ id: 'staff-1', role: 'FREELANCER' });

    prismaMock.reEditRequest.findUnique.mockResolvedValueOnce({
      id: 'rr-1',
      editorId: 'staff-1',
      notes: 'Original notes',
    });
    prismaMock.reEditRequest.update.mockResolvedValueOnce({
      id: 'rr-1',
      status: 'IN_PROGRESS',
    });

    const res = await request(app)
      .patch('/api/reedits/rr-1/status')
      .set('Authorization', `Bearer ${token}`)
      .send({ status: 'IN_PROGRESS', note: 'Started today' });

    expect(res.status).toBe(200);

    const arg = prismaMock.reEditRequest.update.mock.calls[0][0];
    expect(arg.where).toEqual({ id: 'rr-1' });
    expect(arg.data.status).toBe('IN_PROGRESS');
    // note appended to existing notes
    expect(arg.data.notes).toContain('Started today');
    expect(arg.data.notes).toContain('Original notes');
  });

  it('Owner can update someone else\'s assigned request → 200', async () => {
    const token = signToken({ id: 'owner-1', role: 'OWNER' });

    prismaMock.reEditRequest.findUnique.mockResolvedValueOnce({
      id: 'rr-1',
      editorId: 'someone-else',
      notes: 'Existing',
    });
    prismaMock.reEditRequest.update.mockResolvedValueOnce({});

    const res = await request(app)
      .patch('/api/reedits/rr-1/status')
      .set('Authorization', `Bearer ${token}`)
      .send({ status: 'DONE' });

    expect(res.status).toBe(200);
  });

  it('FREELANCER not assigned → 403', async () => {
    const token = signToken({ id: 'attacker', role: 'FREELANCER' });

    prismaMock.reEditRequest.findUnique.mockResolvedValueOnce({
      id: 'rr-1',
      editorId: 'someone-else',
    });

    const res = await request(app)
      .patch('/api/reedits/rr-1/status')
      .set('Authorization', `Bearer ${token}`)
      .send({ status: 'DONE' });

    expect(res.status).toBe(403);
    expect(prismaMock.reEditRequest.update).not.toHaveBeenCalled();
  });

  it('request missing → 404', async () => {
    const token = signToken({ role: 'OWNER' });
    prismaMock.reEditRequest.findUnique.mockResolvedValueOnce(null);

    const res = await request(app)
      .patch('/api/reedits/nope/status')
      .set('Authorization', `Bearer ${token}`)
      .send({ status: 'DONE' });

    expect(res.status).toBe(404);
  });
});

// ─────────────────────────────────────────────────────────────────────
// GET /api/reedits/my-requests
// ─────────────────────────────────────────────────────────────────────
describe('GET /api/reedits/my-requests', () => {
  it('Owner sees requests they created (requestedBy filter)', async () => {
    const token = signToken({ id: 'owner-1', role: 'OWNER' });
    prismaMock.reEditRequest.findMany.mockResolvedValueOnce([
      { id: 'rr-1', requestedBy: 'owner-1' },
    ]);

    const res = await request(app)
      .get('/api/reedits/my-requests')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(prismaMock.reEditRequest.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { requestedBy: 'owner-1' },
        orderBy: { id: 'desc' },
      }),
    );
  });

  it('FREELANCER sees requests assigned to them (editorId filter)', async () => {
    const token = signToken({ id: 'staff-1', role: 'FREELANCER' });
    prismaMock.reEditRequest.findMany.mockResolvedValueOnce([
      { id: 'rr-1', editorId: 'staff-1' },
    ]);

    const res = await request(app)
      .get('/api/reedits/my-requests')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(prismaMock.reEditRequest.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { editorId: 'staff-1' },
        orderBy: { id: 'desc' },
      }),
    );
  });
});

// ─────────────────────────────────────────────────────────────────────
// Error paths
// ─────────────────────────────────────────────────────────────────────
describe('Re-edit — error paths', () => {
  it('createReeditRequest → 500 on Prisma error', async () => {
    const token = signToken({ role: 'OWNER' });
    prismaMock.event.findUnique.mockRejectedValueOnce(new Error('boom'));

    const res = await request(app)
      .post('/api/reedits')
      .set('Authorization', `Bearer ${token}`)
      .send({
        eventId: 'evt-1',
        editorId: 'staff-1',
        deliverable: 'Photos',
        notes: 'X',
      });

    expect(res.status).toBe(500);
  });

  it('updateReeditStatus → 500 on Prisma error', async () => {
    const token = signToken();
    prismaMock.reEditRequest.findUnique.mockRejectedValueOnce(
      new Error('boom'),
    );

    const res = await request(app)
      .patch('/api/reedits/r1/status')
      .set('Authorization', `Bearer ${token}`)
      .send({ status: 'DONE' });

    expect(res.status).toBe(500);
  });

  it('getMyReeditRequests → 500 on Prisma error', async () => {
    const token = signToken();
    prismaMock.reEditRequest.findMany.mockRejectedValueOnce(new Error('boom'));

    const res = await request(app)
      .get('/api/reedits/my-requests')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(500);
  });
});
