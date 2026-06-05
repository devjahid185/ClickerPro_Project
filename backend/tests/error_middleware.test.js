// tests/error_middleware.test.js
//
// Unit-tests for the centralized error middleware।  Mounts a tiny
// Express app with a single route that throws synthetic errors so the
// middleware's mapping logic (Prisma error codes → 4xx, JSON parse →
// 400, fallback → 500) is exercised in isolation।

const express = require('express');
const request = require('supertest');

const errorMiddleware = require('../src/middleware/errorMiddleware');

function buildApp(error) {
  const app = express();
  app.use(express.json());
  app.get('/throw', (_req, _res, next) => next(error));
  app.use(errorMiddleware);
  return app;
}

describe('errorMiddleware', () => {
  // Suppress noisy console.error from the middleware itself
  beforeAll(() => {
    jest.spyOn(console, 'error').mockImplementation(() => {});
  });

  it('Prisma P2002 (unique constraint) → 409 with target', async () => {
    const err = Object.assign(new Error('Unique violation'), {
      code: 'P2002',
      meta: { target: ['email'] },
    });

    const res = await request(buildApp(err)).get('/throw');

    expect(res.status).toBe(409);
    expect(res.body.message).toContain('email');
  });

  it('Prisma P2002 with no meta target → still 409', async () => {
    const err = Object.assign(new Error('Unique violation'), {
      code: 'P2002',
    });

    const res = await request(buildApp(err)).get('/throw');

    expect(res.status).toBe(409);
  });

  it('Prisma P2025 (record not found) → 404', async () => {
    const err = Object.assign(new Error('No record'), { code: 'P2025' });

    const res = await request(buildApp(err)).get('/throw');

    expect(res.status).toBe(404);
  });

  it('Prisma P2003 (foreign key violation) → 400', async () => {
    const err = Object.assign(new Error('FK violation'), { code: 'P2003' });

    const res = await request(buildApp(err)).get('/throw');

    expect(res.status).toBe(400);
  });

  it('SyntaxError on bad JSON body → 400', async () => {
    const err = Object.assign(new SyntaxError('Unexpected token'), {
      type: 'entity.parse.failed',
    });

    const res = await request(buildApp(err)).get('/throw');

    expect(res.status).toBe(400);
  });

  it('Custom statusCode → forwarded', async () => {
    const err = Object.assign(new Error('Forbidden'), { statusCode: 403 });

    const res = await request(buildApp(err)).get('/throw');

    expect(res.status).toBe(403);
    expect(res.body.message).toBe('Forbidden');
  });

  it('Custom .status → forwarded', async () => {
    const err = Object.assign(new Error('Teapot'), { status: 418 });

    const res = await request(buildApp(err)).get('/throw');

    expect(res.status).toBe(418);
  });

  it('Generic error → 500 + message field', async () => {
    const err = new Error('Boom');

    const res = await request(buildApp(err)).get('/throw');

    expect(res.status).toBe(500);
    expect(res.body.message).toBe('Boom');
  });

  it('Generic error with no message → fallback', async () => {
    const err = {};

    const res = await request(buildApp(err)).get('/throw');

    expect(res.status).toBe(500);
    expect(res.body.message).toBe('Internal Server Error');
  });
});
