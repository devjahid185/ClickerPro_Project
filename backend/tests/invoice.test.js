// tests/invoice.test.js
//
// Invoice endpoints — VAT calculation, status derivation, owner-scoped
// auth।  Heavy focus on numeric correctness because invoice math directly
// surfaces in client-facing PDFs।

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
// POST /api/invoices/generate
// ─────────────────────────────────────────────────────────────────────
describe('POST /api/invoices/generate', () => {
  it('VAT enabled → vatAmount, totalAmount, balanceDue calculated correctly', async () => {
    const token = signToken({ id: 'owner-1', role: 'OWNER' });

    prismaMock.event.findUnique.mockResolvedValueOnce({
      id: 'evt-1',
      ownerId: 'owner-1',
      owner: {
        id: 'owner-1',
        vatEnabled: true,
        vatPercentage: 15,
        language: 'bn',
      },
    });

    // Capture the final upsert payload to assert math
    prismaMock.invoice.upsert.mockImplementationOnce(async (args) => ({
      id: 'inv-1',
      ...args.create,
    }));

    const res = await request(app)
      .post('/api/invoices/generate')
      .set('Authorization', `Bearer ${token}`)
      .send({ eventId: 'evt-1', subtotal: 10000, amountPaid: 5000 });

    expect(res.status).toBe(200);
    expect(res.body.data).toMatchObject({
      subtotal: 10000,
      vatAmount: 1500, // 15% of 10000
      totalAmount: 11500, // subtotal + VAT
      amountPaid: 5000,
      balanceDue: 6500, // total - paid
      status: 'Partial', // partial pay → Partial
      language: 'bn', // pulled from owner
    });

    expect(res.body.data.invoiceNumber).toMatch(/^CP-\d{4}-\d{4}$/);
  });

  it('VAT disabled → vatAmount = 0, status="Paid" if fully paid', async () => {
    const token = signToken({ id: 'owner-1', role: 'OWNER' });

    prismaMock.event.findUnique.mockResolvedValueOnce({
      id: 'evt-1',
      ownerId: 'owner-1',
      owner: { vatEnabled: false, vatPercentage: 15, language: 'en' },
    });
    prismaMock.invoice.upsert.mockImplementationOnce(async (args) => args.create);

    const res = await request(app)
      .post('/api/invoices/generate')
      .set('Authorization', `Bearer ${token}`)
      .send({ eventId: 'evt-1', subtotal: 5000, amountPaid: 5000 });

    expect(res.status).toBe(200);
    expect(res.body.data).toMatchObject({
      vatAmount: 0,
      totalAmount: 5000,
      balanceDue: 0,
      status: 'Paid',
    });
  });

  it('amountPaid = 0 → status="Due"', async () => {
    const token = signToken({ role: 'BOTH' });

    prismaMock.event.findUnique.mockResolvedValueOnce({
      id: 'evt-1',
      owner: { vatEnabled: false, language: 'en' },
    });
    prismaMock.invoice.upsert.mockImplementationOnce(async (args) => args.create);

    const res = await request(app)
      .post('/api/invoices/generate')
      .set('Authorization', `Bearer ${token}`)
      .send({ eventId: 'evt-1', subtotal: 1000, amountPaid: 0 });

    expect(res.status).toBe(200);
    expect(res.body.data.status).toBe('Due');
  });

  it('FREELANCER role → 403', async () => {
    const token = signToken({ role: 'FREELANCER' });
    const res = await request(app)
      .post('/api/invoices/generate')
      .set('Authorization', `Bearer ${token}`)
      .send({ eventId: 'evt-1', subtotal: 100, amountPaid: 0 });

    expect(res.status).toBe(403);
    expect(prismaMock.invoice.upsert).not.toHaveBeenCalled();
  });

  it('missing fields → 400', async () => {
    const token = signToken({ role: 'OWNER' });
    const res = await request(app)
      .post('/api/invoices/generate')
      .set('Authorization', `Bearer ${token}`)
      .send({ eventId: 'evt-1' });

    expect(res.status).toBe(400);
  });

  it('event not found → 404', async () => {
    const token = signToken({ role: 'OWNER' });
    prismaMock.event.findUnique.mockResolvedValueOnce(null);

    const res = await request(app)
      .post('/api/invoices/generate')
      .set('Authorization', `Bearer ${token}`)
      .send({ eventId: 'nope', subtotal: 100, amountPaid: 0 });

    expect(res.status).toBe(404);
  });
});

// ─────────────────────────────────────────────────────────────────────
// GET /api/invoices/event/:id
// ─────────────────────────────────────────────────────────────────────
describe('GET /api/invoices/event/:id', () => {
  it('invoice exists → 200 + invoice with event/client/owner included', async () => {
    const token = signToken();

    prismaMock.invoice.findUnique.mockResolvedValueOnce({
      id: 'inv-1',
      eventId: 'evt-1',
      totalAmount: 11500,
      event: {
        id: 'evt-1',
        title: 'Karim Wedding',
        client: { id: 'cli-1', name: 'Karim' },
        owner: { id: 'owner-1', businessName: 'Studio Karim' },
      },
    });

    const res = await request(app)
      .get('/api/invoices/event/evt-1')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.data).toMatchObject({
      id: 'inv-1',
      event: expect.objectContaining({
        client: expect.objectContaining({ name: 'Karim' }),
      }),
    });

    expect(prismaMock.invoice.findUnique).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { eventId: 'evt-1' },
      }),
    );
  });

  it('invoice not found → 404', async () => {
    const token = signToken();
    prismaMock.invoice.findUnique.mockResolvedValueOnce(null);

    const res = await request(app)
      .get('/api/invoices/event/nope')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(404);
  });
});
