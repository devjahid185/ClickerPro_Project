// tests/support.test.js
//
// Support endpoints — ticket create (auth required), ticket list, FAQ
// list (public)।

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
// POST /api/support/ticket
// ─────────────────────────────────────────────────────────────────────
describe('POST /api/support/ticket', () => {
  it('valid payload → 201 + status defaults to OPEN, priority NORMAL', async () => {
    const token = signToken({ id: 'user-1' });

    prismaMock.supportTicket.create.mockResolvedValueOnce({
      id: 't-1',
      userId: 'user-1',
      subject: 'Cannot login',
      message: 'I tried multiple times',
      priority: 'NORMAL',
      status: 'OPEN',
    });

    const res = await request(app)
      .post('/api/support/ticket')
      .set('Authorization', `Bearer ${token}`)
      .send({ subject: 'Cannot login', message: 'I tried multiple times' });

    expect(res.status).toBe(201);
    expect(res.body.ticket).toMatchObject({
      status: 'OPEN',
      priority: 'NORMAL',
    });

    const data = prismaMock.supportTicket.create.mock.calls[0][0].data;
    expect(data).toMatchObject({
      userId: 'user-1',
      subject: 'Cannot login',
      message: 'I tried multiple times',
      priority: 'NORMAL',
      status: 'OPEN',
    });
  });

  it('explicit priority overrides default', async () => {
    const token = signToken();
    prismaMock.supportTicket.create.mockResolvedValueOnce({});

    await request(app)
      .post('/api/support/ticket')
      .set('Authorization', `Bearer ${token}`)
      .send({ subject: 'Urgent', message: 'Critical', priority: 'HIGH' });

    const data = prismaMock.supportTicket.create.mock.calls[0][0].data;
    expect(data.priority).toBe('HIGH');
  });

  it('missing subject → 400', async () => {
    const token = signToken();
    const res = await request(app)
      .post('/api/support/ticket')
      .set('Authorization', `Bearer ${token}`)
      .send({ message: 'X' });

    expect(res.status).toBe(400);
  });

  it('missing message → 400', async () => {
    const token = signToken();
    const res = await request(app)
      .post('/api/support/ticket')
      .set('Authorization', `Bearer ${token}`)
      .send({ subject: 'X' });

    expect(res.status).toBe(400);
  });

  it('Authorization missing → 401', async () => {
    const res = await request(app).post('/api/support/ticket').send({});
    expect(res.status).toBe(401);
  });
});

// ─────────────────────────────────────────────────────────────────────
// GET /api/support/tickets  (auth required)
// ─────────────────────────────────────────────────────────────────────
describe('GET /api/support/tickets', () => {
  it('returns descending list', async () => {
    const token = signToken();
    prismaMock.supportTicket.findMany.mockResolvedValueOnce([
      { id: 't-2', createdAt: new Date('2025-02-01') },
      { id: 't-1', createdAt: new Date('2025-01-01') },
    ]);

    const res = await request(app)
      .get('/api/support/tickets')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.count).toBe(2);

    expect(prismaMock.supportTicket.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ orderBy: { createdAt: 'desc' } }),
    );
  });
});

// ─────────────────────────────────────────────────────────────────────
// GET /api/support/faqs  (public, no auth)
// ─────────────────────────────────────────────────────────────────────
describe('GET /api/support/faqs', () => {
  it('public — returns sorted by order asc', async () => {
    prismaMock.fAQ.findMany.mockResolvedValueOnce([
      { id: 'f1', question: 'Q1', answer: 'A1', order: 1 },
      { id: 'f2', question: 'Q2', answer: 'A2', order: 2 },
    ]);

    const res = await request(app).get('/api/support/faqs'); // no auth header

    expect(res.status).toBe(200);
    expect(res.body.count).toBe(2);
    expect(prismaMock.fAQ.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ orderBy: { order: 'asc' } }),
    );
  });
});

// ─────────────────────────────────────────────────────────────────────
// Error paths
// ─────────────────────────────────────────────────────────────────────
describe('Support — error paths', () => {
  it('createTicket → 500 on Prisma error', async () => {
    const token = signToken();
    prismaMock.supportTicket.create.mockRejectedValueOnce(new Error('boom'));

    const res = await request(app)
      .post('/api/support/ticket')
      .set('Authorization', `Bearer ${token}`)
      .send({ subject: 'X', message: 'Y' });

    expect(res.status).toBe(500);
  });

  it('getAllTickets → 500 on Prisma error', async () => {
    const token = signToken();
    prismaMock.supportTicket.findMany.mockRejectedValueOnce(new Error('boom'));

    const res = await request(app)
      .get('/api/support/tickets')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(500);
  });

  it('getFAQs → 500 on Prisma error', async () => {
    prismaMock.fAQ.findMany.mockRejectedValueOnce(new Error('boom'));

    const res = await request(app).get('/api/support/faqs');

    expect(res.status).toBe(500);
  });
});
