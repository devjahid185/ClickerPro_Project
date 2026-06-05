const express = require('express');
const router = express.Router();
const chatController = require('../controllers/chatController');
const { authenticate } = require('../middleware/authMiddleware');

// গ্রুপ ম্যানেজমেন্ট
router.post('/create-group', authenticate, chatController.createTeamGroup);
router.get('/my-group', authenticate, chatController.getMyTeamGroup);

// মেসেজিং
router.post('/send', authenticate, chatController.sendMessage);
router.get('/messages/:groupId', authenticate, chatController.getMessages);

module.exports = router;
