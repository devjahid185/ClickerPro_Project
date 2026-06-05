const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/authMiddleware');
const statusController = require('../controllers/statusController');

/**
 * নোট: app.js এ অলরেডি /bookings মাউন্ট করা আছে, 
 * তাই এখানে শুধু বাকি অংশটুকু লেখা হয়েছে।
 */

// ১. স্ট্যাটাস পরিবর্তন (PATCH) - যেমন: PENDING -> CONFIRMED
router.patch('/:id/status', authenticate, statusController.updateStatus);

// ২. বুকিংয়ের পুরো ইতিহাস দেখা (GET)
router.get('/:id/history', authenticate, statusController.getHistory);

// ৩. বুকিং দ্রুত বাতিল করা (POST)
router.post('/:id/cancel', authenticate, statusController.cancelBooking);

module.exports = router;