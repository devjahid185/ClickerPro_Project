# Deploying the Clicker Pro API

The API is a stateless Node/Express + Prisma app backed by PostgreSQL. It reads
config from env vars (`DATABASE_URL`, `JWT_SECRET`, optional `PORT`/`HOST`) and
binds `0.0.0.0:$PORT`, so it runs unchanged on any container or Node host.

## Option A — Render (one click, free tier)

1. Push this repo to GitHub.
2. Render → **New → Blueprint** → select the repo. It reads [`render.yaml`](render.yaml),
   provisions a free Postgres DB, wires `DATABASE_URL`, and generates `JWT_SECRET`.
3. First deploy runs `npm ci` (→ `prisma generate`) then `npm run start:prod`
   (→ `prisma migrate deploy` then `node app.js`).
4. Note the service URL, e.g. `https://clicker-pro-api.onrender.com`.

## Option B — Docker (Railway / Fly.io / Cloud Run / any host)

```bash
docker build -t clicker-pro-api .
docker run -p 5000:5000 \
  -e DATABASE_URL="postgresql://USER:PASS@HOST:5432/clicker_pro" \
  -e JWT_SECRET="$(node -e "console.log(require('crypto').randomBytes(48).toString('hex'))")" \
  clicker-pro-api
```

The image applies pending migrations on boot (`start:prod`) and exposes `5000`.

## Option C — Bare Node host

```bash
npm ci                 # runs prisma generate via postinstall
npm run migrate:deploy # apply migrations to the production DB
npm start              # node app.js
```

## Required environment variables

See [`.env.example`](.env.example):

| Var            | Required | Notes                                            |
| -------------- | -------- | ------------------------------------------------ |
| `DATABASE_URL` | yes      | PostgreSQL connection string                     |
| `JWT_SECRET`   | yes      | long random string; rotate to invalidate tokens  |
| `PORT`         | no       | defaults to `5000`                               |
| `HOST`         | no       | defaults to `0.0.0.0`                             |

Health check: `GET /health` → `{ "status": "ok" }`.

## After deploy — point the Flutter app at it

The app reads `API_BASE_URL` from `clicker_pro/.env`
(see [`app_config.dart`](../clicker_pro/lib/core/env/app_config.dart)).
Set it to the deployed URL and rebuild the release APK:

```
# clicker_pro/.env
API_BASE_URL=https://clicker-pro-api.onrender.com
```

```bash
cd clicker_pro
flutter build apk --release
```

No more `adb reverse` needed once the app talks to the hosted API.
