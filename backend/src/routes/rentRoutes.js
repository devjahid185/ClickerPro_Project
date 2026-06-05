const express = require('express');
const router = express.Router();
const rentController = require('../controllers/rentController');
const { authenticate } = require('../middleware/authMiddleware');

router.post('/record', authenticate, rentController.createRentRecord);
router.get('/history', authenticate, rentController.getRentHistory);
router.patch('/status/:id', authenticate, rentController.updateRentStatus);

module.exports = router;
