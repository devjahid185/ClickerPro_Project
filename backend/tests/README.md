# Backend Tests

Jest + supertest based integration smoke suite. No real database — Prisma is
mocked at module level, so the entire Express stack (auth → controller →
error middleware) is exercised without spinning up Postgres.

## Running

```bash
npm test          # one-shot
npm run test:watch
```

## Layout

```
tests/
├── helpers/
│   └── testApp.js        # Prisma mock + JWT helper + buildApp()
├── booking.test.js       # /api/bookings smoke (12 tests)
└── README.md
```

## Writing a new test

```js
const request = require('supertest');
const { buildApp, signToken, prismaMock } = require('./helpers/testApp');

let app;
beforeAll(() => { app = buildApp(); });
beforeEach(() => prismaMock.reset());

it('does the thing', async () => {
  const token = signToken({ id: 'owner-1', role: 'OWNER' });

  prismaMock.event.findMany.mockResolvedValueOnce([/* ... */]);

  const res = await request(app)
    .get('/api/bookings')
    .set('Authorization', `Bearer ${token}`);

  expect(res.status).toBe(200);
});
```

## Why mock Prisma?

* No Postgres installation required for CI / local laptops
* Tests run in ~1 second instead of ~30 seconds
* We're testing route wiring, validation, status transitions, and error
  envelopes — not Prisma itself

For future contract-level tests against a real DB, add a separate
`tests/integration/` folder gated behind `RUN_DB_TESTS=1` and use a
disposable Postgres container.
