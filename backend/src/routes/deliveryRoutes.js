const express = require('express');
const router = express.Router();
const deliveryController = require('../controllers/deliveryController');
const { authenticate } = require('../middleware/authMiddleware');

router.post('/update', authenticate, deliveryController.updateDelivery);
router.get('/delivered', authenticate, deliveryController.getDeliveredEvents);

module.exports = router;
