// tests/helpers/testApp.js
//
// Test rig: Prisma client টাকে jest.mock দিয়ে in-memory stub-এ রিপ্লেস করি,
// তারপর `app.js` লোড করি।  ফলে কোনো real DB connection লাগে না, কিন্তু পুরো
// Express stack (auth middleware → controller → error middleware) সত্যিকারের
// মতো trip হয়।
//
// ব্যবহার:
//   const { buildApp, signToken, prismaMock } = require('./helpers/testApp');
//   beforeEach(() => prismaMock.reset());
//   const app = buildApp();
//   await request(app).get('/api/bookings').set('Authorization', `Bearer ${token}`);

const path = require('path');
const jwt = require('jsonwebtoken');

// ─────────────────────────────────────────────────────────────────────
// 1. Prisma mock — controller-গুলো `require('../lib/prisma')` করে, সবাই
//    এই একটাই reference পায়, তাই jest.mock দিয়ে replace করাই যথেষ্ট।
//
//    NOTE: Jest `jest.mock()` factory-কে file-top-এ hoist করে, ফলে
//    factory-এর ভেতর শুধু `mock`-prefix নামের closure variable allow করে।
//    সেজন্য নাম `mockPrismaInstance` রাখা হয়েছে; বাইরে আমরা সেটা
//    `prismaMock` হিসেবে এক্সপোজ করি।
// ─────────────────────────────────────────────────────────────────────

const mockPrismaInstance = {
  client:        { findUnique: jest.fn(), findMany: jest.fn(), findFirst: jest.fn(), create: jest.fn(), update: jest.fn(), updateMany: jest.fn() },
  user:          { findUnique: jest.fn(), findMany: jest.fn(), findFirst: jest.fn(), create: jest.fn(), update: jest.fn(), updateMany: jest.fn() },
  event:         {
    create:     jest.fn(),
    findFirst:  jest.fn(),
    findUnique: jest.fn(),
    findMany:   jest.fn(),
    update:     jest.fn(),
    updateMany: jest.fn(),
  },
  statusHistory:      { create: jest.fn(), findMany: jest.fn() },
  assignment:         { findMany: jest.fn(), findFirst: jest.fn(), create: jest.fn(), delete: jest.fn(), aggregate: jest.fn(), count: jest.fn() },
  payment:            { create: jest.fn(), findMany: jest.fn(), aggregate: jest.fn() },
  invoice:            { upsert: jest.fn(), findUnique: jest.fn() },
  expense:            { create: jest.fn(), findMany: jest.fn(), aggregate: jest.fn() },
  reEditRequest:      { create: jest.fn(), findUnique: jest.fn(), findMany: jest.fn(), update: jest.fn(), count: jest.fn() },
  package:            { create: jest.fn(), findMany: jest.fn(), update: jest.fn(), delete: jest.fn() },
  notification:       { create: jest.fn(), findMany: jest.fn(), update: jest.fn() },
  gearItem:           { create: jest.fn(), findMany: jest.fn(), findUnique: jest.fn(), delete: jest.fn() },
  rentRecord:         { create: jest.fn(), findMany: jest.fn(), update: jest.fn() },
  teamMembership:     { create: jest.fn(), findMany: jest.fn(), findFirst: jest.fn(), findUnique: jest.fn(), deleteMany: jest.fn() },
  broadcast:          { create: jest.fn(), findMany: jest.fn(), delete: jest.fn() },
  chatGroup:          { create: jest.fn(), findFirst: jest.fn() },
  chatMessage:        { create: jest.fn(), findMany: jest.fn() },
  supportTicket:      { create: jest.fn(), findMany: jest.fn() },
  fAQ:                { findMany: jest.fn() },
  taskProgress:       { upsert: jest.fn(), findMany: jest.fn() },
  deviceToken:        { upsert: jest.fn(), deleteMany: jest.fn(), findMany: jest.fn() },
  otpCode:            { count: jest.fn(), create: jest.fn(), findFirst: jest.fn(), update: jest.fn(), updateMany: jest.fn() },
  passwordResetToken: { create: jest.fn(), findUnique: jest.fn(), update: jest.fn() },
  teamInviteCode:     { findUnique: jest.fn(), update: jest.fn(), upsert: jest.fn(), findMany: jest.fn(), create: jest.fn() },
  legalDocument:      { findUnique: jest.fn() },
  // `prisma.$transaction([...])` — array পেলে Promise.all-এর মতো resolve করি
  // (callback fn পেলে সরাসরি call করি, যাতে authController এর tx callback
  //  pattern-ও কাজ করে)।
  $transaction: jest.fn(async (arg) => {
    if (typeof arg === 'function') {
      return arg(mockPrismaInstance);
    }
    return Promise.all(arg);
  }),
  $disconnect:   jest.fn(),
  // helper — সব mock এর implementation/calls clear করে
  reset() {
    for (const model of Object.values(this)) {
      if (model && typeof model === 'object') {
        for (const fn of Object.values(model)) {
          if (typeof fn === 'function' && typeof fn.mockReset === 'function') {
            fn.mockReset();
          }
        }
      }
    }
    // $transaction-এর default behaviour প্রতিটি reset-এর পর restore করি
    this.$transaction.mockImplementation(async (arg) => {
      if (typeof arg === 'function') {
        return arg(mockPrismaInstance);
      }
      return Promise.all(arg);
    });
  },
};

// jest module registry-তে inject — `require('../lib/prisma')` এ এই object-ই
// মিলবে।  factory-তে শুধু `mock`-prefix variable reference করা যাবে এবং
// path string-ও literal হতে হয় (`jest.mock` hoisted হয় বলে)।
jest.mock('../../src/lib/prisma', () => mockPrismaInstance);

// ─────────────────────────────────────────────────────────────────────
// 2. Helpers
// ─────────────────────────────────────────────────────────────────────

const JWT_SECRET =
  process.env.JWT_SECRET || 'ClickerPro_Super_Secret_Key_12345';

/**
 * Test-এর জন্য signed JWT।  authMiddleware এই-ই decode করে `req.user`
 * তৈরি করবে।
 */
function signToken({ id = 'user-1', role = 'OWNER' } = {}) {
  return jwt.sign({ id, role }, JWT_SECRET, { expiresIn: '1h' });
}

/**
 * Express app fresh-load করে।  test-এর মাঝে কোনো module state lingering
 * হলে এই helper দিয়ে clear করা যায়।
 */
function buildApp() {
  const appPath = path.resolve(__dirname, '..', '..', 'app.js');
  // require cache পরিষ্কার করে দিচ্ছি — স্ট্যাটিক env override দরকার হলে কাজে লাগবে
  delete require.cache[require.resolve(appPath)];
  return require(appPath);
}

module.exports = {
  buildApp,
  signToken,
  prismaMock: mockPrismaInstance,
};
