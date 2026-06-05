const express = require('express');
const router = express.Router();
const reminderController = require('../controllers/reminderController');
const { authenticate } = require('../middleware/authMiddleware');

router.get('/', authenticate, reminderController.getReminders); // সব রিমাইন্ডার
router.post('/', authenticate, reminderController.createReminder); // নতুন
router.patch('/:id', authenticate, reminderController.updateReminder); // আপডেট
router.delete('/:id', authenticate, reminderController.deleteReminder); // মুছে ফেলা

module.exports = router;
