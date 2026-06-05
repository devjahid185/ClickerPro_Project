// src/routes/authRoutes.js
//
// Public auth endpoints (login / register / forgot / OTP / accept-invite)।
// Authenticated endpoints (logout / change role / delete account) authMiddleware
// দিয়ে guard করা।

const express = require('express');
const router = express.Router();

const auth = require('../controllers/authController');
const { authenticate } = require('../middleware/authMiddleware');

// ── Public
router.post('/register', auth.register);
router.post('/login', auth.login);
router.post('/forgot', auth.forgotPassword);
router.post('/reset', auth.resetPassword);
router.post('/otp/request', auth.requestOtp);
router.post('/otp/verify', auth.verifyOtp);
router.post('/accept-invite', auth.acceptInvite);

module.exports = router;
