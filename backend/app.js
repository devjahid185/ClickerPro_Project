// app.js
//
// Clicker Pro — Backend entry point।  Express + Prisma।
// সব routes এই ফাইল-এ register হয় এবং সর্বশেষে error middleware।
//
// dev: `npm run dev`   prod: `node app.js`

require('dotenv').config();

const express = require('express');
const cors = require('cors');
const morgan = require('morgan');

const app = express();

// ─── Middleware ────────────────────────────────────────────────────
app.use(cors());                      // open CORS — Flutter web / mobile সব pass হবে
app.use(express.json({ limit: '2mb' }));
if (process.env.NODE_ENV !== 'test') {
  // dev / prod উভয়েই access log
  app.use(morgan('dev'));
}

// ─── Health check (always available) ──────────────────────────────
app.get('/', (_req, res) =>
  res.json({
    name: 'Clicker Pro API',
    version: '1.0.0',
    time: new Date().toISOString(),
    status: 'ok',
  }),
);
app.get('/health', (_req, res) => res.json({ status: 'ok' }));

// ─── Routes ────────────────────────────────────────────────────────
const authRoutes          = require('./src/routes/authRoutes');
const accountRoutes       = require('./src/routes/accountRoutes');
const legalRoutes         = require('./src/routes/legalRoutes');
const profileRoutes       = require('./src/routes/profileRoutes');
const teamRoutes          = require('./src/routes/teamRoutes');
const clientRoutes        = require('./src/routes/clientRoutes');
const bookingRoutes       = require('./src/routes/bookingRoutes');
const assignmentRoutes    = require('./src/routes/assignmentRoutes');
const paymentRoutes       = require('./src/routes/paymentRoutes');
const invoiceRoutes       = require('./src/routes/invoiceRoutes');
const packageRoutes       = require('./src/routes/packageRoutes');
const deliveryRoutes      = require('./src/routes/deliveryRoutes');
const expenseRoutes       = require('./src/routes/expenseRoutes');
const statusRoutes        = require('./src/routes/statusRoutes');
const notificationRoutes  = require('./src/routes/notificationRoutes');
const broadcastRoutes     = require('./src/routes/broadcastRoutes');
const taskRoutes          = require('./src/routes/taskRoutes');
const reeditRoutes        = require('./src/routes/reeditRoutes');
const clientBookingRoutes = require('./src/routes/clientBookingRoutes');
const searchRoutes        = require('./src/routes/searchRoutes');
const chatRoutes          = require('./src/routes/chatRoutes');
const extraTimeRoutes     = require('./src/routes/extraTimeRoutes');
const reportRoutes        = require('./src/routes/reportRoutes');
const gearRoutes          = require('./src/routes/gearRoutes');
const rentRoutes          = require('./src/routes/rentRoutes');
const supportRoutes       = require('./src/routes/supportRoutes');
const deviceTokenRoutes   = require('./src/routes/deviceTokenRoutes');
const waitlistRoutes      = require('./src/routes/waitlistRoutes');
const reminderRoutes      = require('./src/routes/reminderRoutes');
const auditLogRoutes      = require('./src/routes/auditLogRoutes');
const adminRoutes         = require('./src/routes/adminRoutes');
const entitlementRoutes   = require('./src/routes/entitlementRoutes');
const couponRoutes        = require('./src/routes/couponRoutes');
const brandingRoutes      = require('./src/routes/brandingRoutes');
const path                = require('path');

app.use('/api/auth',           authRoutes);
app.use('/api/account',        accountRoutes);
app.use('/api/legal',          legalRoutes);
app.use('/api/profile',        profileRoutes);
app.use('/api/team',           teamRoutes);
app.use('/api/clients',        clientRoutes);
app.use('/api/assignments',    assignmentRoutes);
app.use('/api/payments',       paymentRoutes);
app.use('/api/invoices',       invoiceRoutes);
app.use('/api/packages',       packageRoutes);
app.use('/api/delivery',       deliveryRoutes);
app.use('/api/expenses',       expenseRoutes);
app.use('/api/notifications',  notificationRoutes);
app.use('/api/broadcasts',     broadcastRoutes);
app.use('/api/tasks',          taskRoutes);
app.use('/api/reedits',        reeditRoutes);
app.use('/api/client-booking', clientBookingRoutes);
app.use('/api/extra-time',     extraTimeRoutes);
app.use('/api/reports',        reportRoutes);
app.use('/api/gear',           gearRoutes);
app.use('/api/rent',           rentRoutes);
app.use('/api/support',        supportRoutes);
app.use('/api/devices',        deviceTokenRoutes);
app.use('/api/bookings',       bookingRoutes);
app.use('/api/bookings',       statusRoutes);
app.use('/api/search',         searchRoutes);
app.use('/api/chat',           chatRoutes);
app.use('/api/waitlist',       waitlistRoutes);
app.use('/api/reminders',      reminderRoutes);
app.use('/api/audit-logs',     auditLogRoutes);
app.use('/api/admin',          adminRoutes);
app.use('/api/entitlements',   entitlementRoutes);
app.use('/api/coupons',        couponRoutes);
app.use('/api/branding',       brandingRoutes);
app.use('/uploads',            express.static(path.join(__dirname, 'uploads')));

// ─── 404 ───────────────────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ message: `Route পাওয়া যায়নি: ${req.method} ${req.url}` });
});

// ─── Error handler (last) ──────────────────────────────────────────
app.use(require('./src/middleware/errorMiddleware'));

// ─── Server boot ───────────────────────────────────────────────────
// `node app.js` দিয়ে চালালে listen করবে, কিন্তু supertest / jest থেকে
// `require('./app')` করলে শুধু express instance return করবে — পোর্ট দখল
// করবে না।  Test runner চাইলে নিজের ephemeral server তোলে।
if (require.main === module) {
  const PORT = process.env.PORT || 5000;
  const HOST = process.env.HOST || '0.0.0.0';

  const server = app.listen(PORT, HOST, () => {
    /* eslint-disable no-console */
    console.log('\n────────────────────────────────────────────');
    console.log(`🚀  Clicker Pro API listening on http://${HOST}:${PORT}`);
    console.log('────────────────────────────────────────────');
    console.log(`   Auth        →  /api/auth`);
    console.log(`   Profile     →  /api/profile`);
    console.log(`   Account     →  /api/account`);
    console.log(`   Legal       →  /api/legal`);
    console.log(`   Team        →  /api/team`);
    console.log(`   Bookings    →  /api/bookings`);
    console.log(`   Payments    →  /api/payments`);
    console.log(`   Invoices    →  /api/invoices`);
    console.log(`   Reports     →  /api/reports`);
    console.log(`   Gear / Rent →  /api/gear, /api/rent`);
    console.log('────────────────────────────────────────────\n');
  });

  // Graceful shutdown
  const shutdown = (signal) => {
    console.log(`\n${signal} received — shutting down gracefully...`);
    server.close(() => process.exit(0));
    setTimeout(() => process.exit(1), 10_000).unref();
  };
  process.on('SIGINT',  () => shutdown('SIGINT'));
  process.on('SIGTERM', () => shutdown('SIGTERM'));
}

module.exports = app;
