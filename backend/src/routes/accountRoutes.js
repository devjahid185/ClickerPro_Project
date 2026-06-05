// src/routes/accountRoutes.js
//
// Account-level actions Flutter expects: 7-day-grace deletion, undo, data export।

const express = require('express');
const router = express.Router();

const auth = require('../controllers/authController');
const { authenticate } = require('../middleware/authMiddleware');

router.use(authenticate);

router.post('/delete-request', auth.requestDeleteAccount);
router.post('/cancel-delete', auth.cancelDeleteAccount);
router.post('/export', auth.requestDataExport);

module.exports = router;
