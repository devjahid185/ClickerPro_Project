const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/paymentController');
const { authenticate } = require('../middleware/authMiddleware');

// সব রুট সুরক্ষিত থাকবে (টোকেন লাগবে)
router.post('/', authenticate, paymentController.recordPayment);        // নতুন পেমেন্ট রেকর্ড
router.get('/event/:eventId', authenticate, paymentController.getEventPayments); // ইভেন্ট পেমেন্ট দেখা
router.get('/earnings', authenticate, paymentController.getEarnings);     // মোট আয় দেখা

module.exports = router;
