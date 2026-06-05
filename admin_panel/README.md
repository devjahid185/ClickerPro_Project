# Clicker Pro — Admin Panel

A Next.js (App Router) web app for platform administration. Talks to the same
Clicker Pro backend (`/api/admin/*`), gated by the `ADMIN` role.

## Features

- **Dashboard** — top-line counts (users by role, bookings, clients, active broadcasts, open tickets)
- **Users** — search/filter, change role, suspend/reactivate, create new accounts
- **Broadcasts** — create / archive / delete announcements shown to all app users
- **Support & FAQ** — triage support tickets (status), manage the FAQ list
- **Audit Log** — global view of every create/update/delete with actor + entity

## Architecture

- **Auth**: shared `/api/auth/login`; the panel verifies `role === 'admin'`, stores
  the JWT in `localStorage`, and attaches it as a Bearer token on every call.
  A 401 clears the token and bounces to `/login`.
- **API proxy**: `next.config.js` rewrites `/api/*` → the backend (default
  `http://localhost:5000`, override with `API_PROXY_TARGET`). Same-origin, no CORS.
- **Backend surface**: `backend/src/controllers/adminController.js` +
  `adminRoutes.js`, behind `authenticate` + `requireAdmin` (`adminMiddleware.js`).
- **Theme**: Orange Horizon Pro light palette in `app/globals.css` (mirrors the
  Flutter app).

## Running locally

```bash
# 1. Backend must be running (from backend/):
node app.js                       # http://localhost:5000

# 2. Seed the first admin (only needed once — ADMIN is not self-registrable):
node scripts/seedAdmin.js admin@clickerpro.app Admin123! "Super Admin"

# 3. Admin panel (from admin_panel/):
npm install
npm run dev                       # http://localhost:3001
```

Sign in at `http://localhost:3001/login` with the seeded admin.

## Production build

```bash
npm run build
npm run start                     # serves on :3001
# Point at a deployed API:
API_PROXY_TARGET=https://your-api.onrender.com npm run start
```

## Deploy

Deploy as any Node app (Vercel, Render, Railway). Set `API_PROXY_TARGET` to the
hosted backend URL. The panel is a trusted internal tool — restrict access at
the network/hosting layer if needed (only ADMIN tokens work regardless).
