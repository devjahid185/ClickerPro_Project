# Clicker Pro — Backend

[![Backend CI](../../actions/workflows/backend-ci.yml/badge.svg)](../../actions/workflows/backend-ci.yml)
[![codecov](https://codecov.io/gh/OWNER/REPO/branch/main/graph/badge.svg?flag=backend)](https://codecov.io/gh/OWNER/REPO)

Node.js + Express 5 + Prisma 5 + PostgreSQL API for the Clicker Pro
photography & event management app.

## Quick start

```bash
npm install
npx prisma generate
npm run dev          # http://localhost:5000
```

## Test

```bash
npm test                # 250 supertest integration smoke tests, ~2s
npm run test:coverage   # same suite + coverage report + threshold gate
npm run test:watch
```

The test suite mocks Prisma at the module boundary, so you can run it
without a Postgres instance. See `tests/README.md` for details on how
to add new tests.

### Coverage thresholds

CI fails the build if coverage drops below the floors configured in
`package.json` → `jest.coverageThreshold`. Global floors track project-wide
totals; per-path floors guard the controllers that have dedicated test
suites.

| Scope                                       | Stmt | Br | Fn  | Ln |
| ------------------------------------------- | ---- | -- | --- | -- |
| Global (whole project, after exclusions)    | 85   | 75 | 95  | 85 |
| `middleware/authMiddleware.js`              | 100  | 100| 100 | 100|
| `controllers/clientController.js`           | 95   | 95 | 100 | 95 |
| `controllers/statusController.js`           | 95   | 90 | 100 | 95 |
| `controllers/legalController.js`            | 95   | 80 | 100 | 95 |
| `controllers/teamController.js`             | 90   | 80 | 100 | 95 |
| `controllers/gearController.js`             | 95   | 60 | 100 | 95 |
| `controllers/authController.js`             | 90   | 80 | 90  | 90 |
| `controllers/bookingController.js`          | 85   | 60 | 100 | 85 |
| `controllers/assignmentController.js`       | 85   | 90 | 100 | 85 |
| `controllers/invoiceController.js`          | 85   | 90 | 100 | 85 |
| `controllers/reportController.js`           | 85   | 90 | 100 | 85 |
| `controllers/searchController.js`           | 85   | 70 | 100 | 85 |
| `controllers/extraTimeController.js`        | 85   | 90 | 100 | 85 |
| `controllers/profileController.js`          | 80   | 55 | 100 | 95 |
| `controllers/expenseController.js`          | 80   | 90 | 100 | 80 |
| `controllers/packageController.js`          | 80   | 90 | 100 | 80 |
| `controllers/paymentController.js`          | 80   | 90 | 100 | 80 |
| `controllers/deliveryController.js`         | 80   | 90 | 100 | 80 |
| `controllers/reeditController.js`           | 80   | 90 | 100 | 80 |
| `controllers/rentController.js`             | 80   | 90 | 100 | 80 |
| `controllers/notificationController.js`     | 80   | 90 | 100 | 80 |
| `controllers/supportController.js`          | 80   | 90 | 100 | 80 |
| `controllers/taskController.js`             | 80   | 90 | 100 | 80 |
| `controllers/clientBookingController.js`    | 80   | 90 | 100 | 80 |
| `controllers/broadcastController.js`        | 75   | 90 | 100 | 75 |
| `controllers/chatController.js`             | 75   | 90 | 100 | 75 |

## Codecov

Each push uploads `coverage/lcov.info` to Codecov via
`codecov/codecov-action@v4`. Project-level threshold mirrors the local
Jest gate (74% statements with 1% breathing room); patch-level
threshold for diffs is 80%. See `codecov.yml` for the full config.

To enable PR comments and the badge above:

1. Sign in at <https://codecov.io> with the GitHub account that owns
   the repo and grant access to it.
2. For private repos, copy the upload token into a repo secret named
   `CODECOV_TOKEN`. Public repos can skip this — `codecov-action`
   falls back to tokenless upload.
3. Replace `OWNER/REPO` in the badge URL with the actual GitHub
   `org/repo` slug.

## Layout

```
backend/
├── app.js                  # Express entry — exports `app`, listens only when run directly
├── prisma/schema.prisma    # PostgreSQL schema (User, Client, Event, Payment, ...)
├── src/
│   ├── controllers/        # Route handlers (25 modules)
│   ├── routes/             # Express routers (26 modules)
│   ├── middleware/         # auth, error
│   └── lib/                # prisma client, response helpers, role normalization
└── tests/                  # Jest + supertest smoke suite
```

## Scripts

| Command                  | Purpose                            |
| ------------------------ | ---------------------------------- |
| `npm start`              | Production launch (`node app.js`)  |
| `npm run dev`            | nodemon hot-reload                 |
| `npm test`               | Run full Jest suite                |
| `npm run prisma:migrate` | Apply migrations to local DB       |
| `npm run prisma:studio`  | Browse the DB visually             |

## Environment

`backend/.env` (not committed):

```
DATABASE_URL=postgresql://user:pass@localhost:5432/clicker_pro
JWT_SECRET=replace-me-in-prod
PORT=5000
```

CI sets a placeholder `DATABASE_URL` only because `prisma generate`
reads it; the test suite never connects.
