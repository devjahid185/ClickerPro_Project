// src/routes/adminRoutes.js
//
// Admin-panel API surface, all under /api/admin and gated by
// authenticate + requireAdmin.

const express = require('express');
const router = express.Router();
const path = require('path');
const multer = require('multer');
const admin = require('../controllers/adminController');
const settings = require('../controllers/settingsController');
const coupons = require('../controllers/couponController');
const security = require('../controllers/securityController');
const files = require('../controllers/fileController');
const { authenticate } = require('../middleware/authMiddleware');
const requireAdmin = require('../middleware/adminMiddleware');

// Multer disk storage for the admin media library.
const upload = multer({
  storage: multer.diskStorage({
    destination: files.UPLOAD_DIR,
    filename: (req, file, cb) => {
      const safe = file.originalname.replace(/[^a-zA-Z0-9._-]/g, '_');
      cb(null, `${Date.now()}_${safe}`);
    },
  }),
  limits: { fileSize: 10 * 1024 * 1024 }, // 10 MB
});

// Every admin route requires a valid ADMIN token.
router.use(authenticate, requireAdmin);

// Settings
router.get('/settings', settings.getSettings);
router.put('/settings', settings.updateSettings);

// File manager (media library)
router.get('/files', files.listFiles);
router.post('/files', upload.single('file'), files.uploadFile);
router.delete('/files/:name', files.deleteFile);

// Coupons
router.get('/coupons', coupons.listCoupons);
router.post('/coupons', coupons.createCoupon);
router.patch('/coupons/:id', coupons.updateCoupon);
router.delete('/coupons/:id', coupons.deleteCoupon);

// Security — login activity, suspicious, IP block, 2FA
router.get('/security/login-activity', security.listLoginActivity);
router.get('/security/suspicious', security.suspicious);
router.get('/security/blocked-ips', security.listBlockedIps);
router.post('/security/blocked-ips', security.blockIp);
router.delete('/security/blocked-ips/:ip', security.unblockIp);
router.get('/security/2fa/status', security.status2fa);
router.post('/security/2fa/setup', security.setup2fa);
router.post('/security/2fa/verify', security.verify2fa);
router.post('/security/2fa/disable', security.disable2fa);

// Stats & analytics
router.get('/stats', admin.getStats);
router.get('/analytics', admin.getAnalytics);

// Users
router.get('/users', admin.listUsers);
router.get('/users/:id', admin.getUserDetail);
router.post('/users', admin.createUser);
router.patch('/users/:id/role', admin.updateUserRole);
router.patch('/users/:id/suspend', admin.setUserSuspended);
router.patch('/users/:id/plan', admin.updateUserPlan);

// Feature flags (subscription gating)
router.get('/features', admin.listFeatures);
router.patch('/features/:key', admin.updateFeature);

// Bookings overview (all studios)
router.get('/bookings', admin.listBookings);

// Payments
router.get('/payments', admin.listPayments);
router.post('/users/:id/grant-pro', admin.grantProManual);

// CSV exports
router.get('/export/users.csv', admin.exportUsers);
router.get('/export/bookings.csv', admin.exportBookings);
router.get('/export/payments.csv', admin.exportPayments);

// Broadcasts
router.get('/broadcasts', admin.listBroadcasts);
router.post('/broadcasts', admin.createBroadcast);
router.patch('/broadcasts/:id', admin.updateBroadcast);
router.delete('/broadcasts/:id', admin.deleteBroadcast);

// Support tickets
router.get('/tickets', admin.listTickets);
router.patch('/tickets/:id', admin.updateTicket);

// FAQ
router.get('/faqs', admin.listFaqs);
router.post('/faqs', admin.createFaq);
router.patch('/faqs/:id', admin.updateFaq);
router.delete('/faqs/:id', admin.deleteFaq);

// Audit log (global)
router.get('/audit', admin.listAudit);

module.exports = router;
