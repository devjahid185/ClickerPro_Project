// tests/legal.test.js
//
// Legal endpoints — privacy / terms (public), consent record (auth)।
// Tests both DB-hit and fallback-text paths।

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
// GET /api/legal/privacy  (public)
// ─────────────────────────────────────────────────────────────────────
describe('GET /api/legal/privacy', () => {
  it('DB row found → returns its body + version', async () => {
    prismaMock.legalDocument.findUnique.mockResolvedValueOnce({
      kind: 'privacy',
      language: 'en',
      version: '2025.1',
      body: 'Custom privacy text from DB',
    });

    const res = await request(app).get('/api/legal/privacy?lang=en');

    expect(res.status).toBe(200);
    expect(res.body).toEqual({
      version: '2025.1',
      body: 'Custom privacy text from DB',
    });

    expect(prismaMock.legalDocument.findUnique).toHaveBeenCalledWith({
      where: { kind_language: { kind: 'privacy', language: 'en' } },
    });
  });

  it('DB row missing → falls back to baked-in EN text', async () => {
    prismaMock.legalDocument.findUnique.mockResolvedValueOnce(null);

    const res = await request(app).get('/api/legal/privacy?lang=en');

    expect(res.status).toBe(200);
    expect(res.body.version).toMatch(/^fallback-/);
    expect(res.body.body).toMatch(/Clicker Pro respects your privacy/);
  });

  it('lang=bn → returns Bengali fallback text', async () => {
    prismaMock.legalDocument.findUnique.mockResolvedValueOnce(null);

    const res = await request(app).get('/api/legal/privacy?lang=bn');

    expect(res.status).toBe(200);
    expect(res.body.body).toMatch(/গোপনীয়তাকে সম্মান করে/);
  });

  it('no lang param → defaults to en', async () => {
    prismaMock.legalDocument.findUnique.mockResolvedValueOnce(null);

    const res = await request(app).get('/api/legal/privacy');

    expect(res.status).toBe(200);
    expect(prismaMock.legalDocument.findUnique).toHaveBeenCalledWith({
      where: { kind_language: { kind: 'privacy', language: 'en' } },
    });
  });
});

// ─────────────────────────────────────────────────────────────────────
// GET /api/legal/terms  (public)
// ─────────────────────────────────────────────────────────────────────
describe('GET /api/legal/terms', () => {
  it('returns Bengali fallback when no DB row', async () => {
    prismaMock.legalDocument.findUnique.mockResolvedValueOnce(null);

    const res = await request(app).get('/api/legal/terms?lang=bn');

    expect(res.status).toBe(200);
    expect(res.body.body).toMatch(/Clicker Pro ব্যবহার করে/);
  });
});

// ─────────────────────────────────────────────────────────────────────
// POST /api/legal/consent  (auth)
// ─────────────────────────────────────────────────────────────────────
describe('POST /api/legal/consent', () => {
  it('valid version → stamps consent into notificationPrefs JSON', async () => {
    const token = signToken({ id: 'user-1' });

    prismaMock.user.findUnique.mockResolvedValueOnce({
      notificationPrefs: { booking: true },
    });
    prismaMock.user.update.mockResolvedValueOnce({});

    const res = await request(app)
      .post('/api/legal/consent')
      .set('Authorization', `Bearer ${token}`)
      .send({ version: '2025.1' });

    expect(res.status).toBe(200);

    const arg = prismaMock.user.update.mock.calls[0][0];
    expect(arg.where).toEqual({ id: 'user-1' });
    expect(arg.data.notificationPrefs).toMatchObject({
      booking: true, // existing pref preserved
      legalConsent: expect.objectContaining({
        version: '2025.1',
        at: expect.any(String),
      }),
    });
  });

  it('missing version → 400', async () => {
    const token = signToken();
    const res = await request(app)
      .post('/api/legal/consent')
      .set('Authorization', `Bearer ${token}`)
      .send({});

    expect(res.status).toBe(400);
    expect(prismaMock.user.update).not.toHaveBeenCalled();
  });

  it('Authorization missing → 401', async () => {
    const res = await request(app)
      .post('/api/legal/consent')
      .send({ version: '2025.1' });

    expect(res.status).toBe(401);
  });
});
