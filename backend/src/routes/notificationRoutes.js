const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notificationController');
const { authenticate } = require('../middleware/authMiddleware');

// নটিফিকেশন পাঠানো (Internal/Admin use)
router.post('/send', notificationController.handleNotificationRequest);

// ইউজারের নিজের নটিফিকেশন দেখা
router.get('/', authenticate, notificationController.getUserNotifications);

// নটিফিকেশন Read হিসেবে মার্ক করা
router.patch('/read', authenticate, notificationController.markAsRead);

module.exports = router;
