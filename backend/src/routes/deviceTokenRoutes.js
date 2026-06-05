// src/routes/deviceTokenRoutes.js

const express = require('express');
const router = express.Router();

const ctl = require('../controllers/deviceTokenController');
const { authenticate } = require('../middleware/authMiddleware');

router.use(authenticate);

router.post('/register', ctl.registerToken);
router.delete('/:token', ctl.unregisterToken);
router.get('/me', ctl.listMyDevices);

module.exports = router;
