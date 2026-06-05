const express = require('express');
const router = express.Router();
const clientBookingController = require('../controllers/clientBookingController');
const { authenticate } = require('../middleware/authMiddleware');

// পাবলিক এন্ডপয়েন্ট: ক্লায়েন্ট এখানে সাবমিট করবে (কোন লগইন লাগবে না)
router.post('/submit', clientBookingController.submitBooking);

// প্রটেক্টেড এন্ডপয়েন্ট: শুধুমাত্র ওনার বা ম্যানেজার দেখতে পারবেন
router.get('/requests', authenticate, clientBookingController.getPendingRequests);
router.post('/generate-token', authenticate, clientBookingController.generateBookingToken);

module.exports = router;
