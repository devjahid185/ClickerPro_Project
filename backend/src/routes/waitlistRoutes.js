const express = require('express');
const router = express.Router();
const waitlistController = require('../controllers/waitlistController');
const { authenticate } = require('../middleware/authMiddleware');

router.get('/', authenticate, waitlistController.getWaitlist); // সব এন্ট্রি
router.post('/', authenticate, waitlistController.createWaitlist); // নতুন এন্ট্রি
router.patch('/:id', authenticate, waitlistController.updateWaitlist); // আপডেট
router.delete('/:id', authenticate, waitlistController.deleteWaitlist); // মুছে ফেলা

module.exports = router;
