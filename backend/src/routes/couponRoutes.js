const express = require('express');
const router = express.Router();
const coupons = require('../controllers/couponController');
const { authenticate } = require('../middleware/authMiddleware');

// Authenticated app users redeem a code (e.g. for PRO days).
router.post('/redeem', authenticate, coupons.redeemCoupon);

module.exports = router;
