const express = require('express');
const router = express.Router();
const extraTimeController = require('../controllers/extraTimeController');
const { authenticate } = require('../middleware/authMiddleware');

// এক্সট্রা টাইম আপডেট এবং দেখা (SURELY SECURE)
router.post('/update', authenticate, extraTimeController.updateExtraTime);
router.get('/:eventId', authenticate, extraTimeController.getExtraTime);

module.exports = router;
