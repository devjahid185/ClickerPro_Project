const express = require('express');
const router = express.Router();
const searchController = require('../controllers/searchController');
const { authenticate } = require('../middleware/authMiddleware');

// সার্চ এন্ডপয়েন্ট (শুধুমাত্র লগইন করা ইউজার সার্চ করতে পারবে)
router.get('/global', authenticate, searchController.globalSearch);

module.exports = router;
