// tests/device_token.test.js
//
// Device-token registry — register / unregister / list।  Covers:
//   • happy path with platform validation
//   • upsert on (userId, token) composite key
//   • token / platform validation guards
//   • DELETE 404 on unknown token
//   • DELETE 200 on owned token
//   • listMyDevices owner-scoping with descending lastSeenAt

const request = require('supertest');

const { buildApp, signToken, prismaMock } = require('./helpers/testApp');

let app;
beforeAll(() => {
  app = buildApp();
});

beforeEach(() => {
  prismaMock.reset();
});

describe('POST /api/devices/register', () => {
  const validPayload = {
    token: 'fcm-token-aaaaa-bbbbb-ccccc',
    platform: 'android',
    appVersion: '1.2.3',
    language: 'bn',
  };

  it('valid payload → 201 + upsert with composite key', async () => {
    const token = signToken({ id: 'u-1' });
    prismaMock.deviceToken.upsert.mockResolvedValueOnce({
      id: 'dt-1',
      platform: 'android',
      appVersion: '1.2.3',
      language: 'bn',
    });

    const res = await request(app)
      .post('/api/devices/register')
      .set('Authorization', `Bearer ${token}`)
      .send(validPayload);

    expect(res.status).toBe(201);
    expect(res.body.device).toMatchObject({ id: 'dt-1', platform: 'android' });

    const arg = prismaMock.deviceToken.upsert.mock.calls[0][0];
    expect(arg.where).toEqual({
      userId_token: { userId: 'u-1', token: validPayload.token },
    });
    expect(arg.create).toMatchObject({
      userId: 'u-1',
      token: validPayload.token,
      platform: 'android',
      appVersion: '1.2.3',
      language: 'bn',
    });
  });

  it('iOS platform accepted', async () => {
    const token = signToken();
    prismaMock.deviceToken.upsert.mockResolvedValueOnce({});

    const res = await request(app)
      .post('/api/devices/register')
      .set('Authorization', `Bearer ${token}`)
      .send({ ...validPayload, platform: 'ios' });

    expect(res.status).toBe(201);
  });

  it('web platform accepted', async () => {
    const token = signToken();
    prismaMock.deviceToken.upsert.mockResolvedValueOnce({});

    const res = await request(app)
      .post('/api/devices/register')
      .set('Authorization', `Bearer ${token}`)
      .send({ ...validPayload, platform: 'web' });

    expect(res.status).toBe(201);
  });

  it('missing token → 400', async () => {
    const token = signToken();
    const res = await request(app)
      .post('/api/devices/register')
      .set('Authorization', `Bearer ${token}`)
      .send({ platform: 'android' });

    expect(res.status).toBe(400);
    expect(prismaMock.deviceToken.upsert).not.toHaveBeenCalled();
  });

  it('token too short → 400', async () => {
    const token = signToken();
    const res = await request(app)
      .post('/api/devices/register')
      .set('Authorization', `Bearer ${token}`)
      .send({ token: 'abc', platform: 'android' });

    expect(res.status).toBe(400);
  });

  it('invalid platform → 400', async () => {
    const token = signToken();
    const res = await request(app)
      .post('/api/devices/register')
      .set('Authorization', `Bearer ${token}`)
      .send({ token: validPayload.token, platform: 'symbian' });

    expect(res.status).toBe(400);
  });

  it('missing platform → 400', async () => {
    const token = signToken();
    const res = await request(app)
      .post('/api/devices/register')
      .set('Authorization', `Bearer ${token}`)
      .send({ token: validPayload.token });

    expect(res.status).toBe(400);
  });

  it('Authorization missing → 401', async () => {
    const res = await request(app)
      .post('/api/devices/register')
      .send(validPayload);
    expect(res.status).toBe(401);
  });

  it('Prisma error → 500', async () => {
    const token = signToken();
    prismaMock.deviceToken.upsert.mockRejectedValueOnce(new Error('boom'));

    const res = await request(app)
      .post('/api/devices/register')
      .set('Authorization', `Bearer ${token}`)
      .send(validPayload);

    expect(res.status).toBe(500);
  });
});

describe('DELETE /api/devices/:token', () => {
  it('owned token → 200', async () => {
    const token = signToken({ id: 'u-1' });
    prismaMock.deviceToken.deleteMany.mockResolvedValueOnce({ count: 1 });

    const res = await request(app)
      .delete('/api/devices/some-fcm-token')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(prismaMock.deviceToken.deleteMany).toHaveBeenCalledWith({
      where: { userId: 'u-1', token: 'some-fcm-token' },
    });
  });

  it('unknown token → 404', async () => {
    const token = signToken();
    prismaMock.deviceToken.deleteMany.mockResolvedValueOnce({ count: 0 });

    const res = await request(app)
      .delete('/api/devices/no-such-token')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(404);
  });

  it('Prisma error → 500', async () => {
    const token = signToken();
    prismaMock.deviceToken.deleteMany.mockRejectedValueOnce(new Error('x'));

    const res = await request(app)
      .delete('/api/devices/x')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(500);
  });
});

describe('GET /api/devices/me', () => {
  it('owner-scoped descending lastSeenAt list', async () => {
    const token = signToken({ id: 'u-1' });
    prismaMock.deviceToken.findMany.mockResolvedValueOnce([
      {
        id: 'dt-1',
        platform: 'android',
        appVersion: '1.2.3',
        language: 'bn',
        createdAt: new Date('2025-01-01'),
        lastSeenAt: new Date('2025-02-01'),
      },
    ]);

    const res = await request(app)
      .get('/api/devices/me')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.count).toBe(1);
    expect(res.body.devices[0].platform).toBe('android');

    expect(prismaMock.deviceToken.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { userId: 'u-1' },
        orderBy: { lastSeenAt: 'desc' },
      }),
    );
  });

  it('Prisma error → 500', async () => {
    const token = signToken();
    prismaMock.deviceToken.findMany.mockRejectedValueOnce(new Error('x'));

    const res = await request(app)
      .get('/api/devices/me')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(500);
  });
});
