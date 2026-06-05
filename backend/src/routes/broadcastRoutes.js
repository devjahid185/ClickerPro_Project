const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/authMiddleware');
const broadcastController = require('../controllers/broadcastController');

// ১. নতুন নোটিশ তৈরি করা (POST)
router.post('/', authenticate, broadcastController.createAnnouncement);

// ২. সকল নোটিশ দেখা (GET)
router.get('/', authenticate, broadcastController.getAnnouncements);

// ৩. নোটিশ ডিলিট করা (DELETE)
router.delete('/:id', authenticate, broadcastController.deleteAnnouncement);

module.exports = router;
