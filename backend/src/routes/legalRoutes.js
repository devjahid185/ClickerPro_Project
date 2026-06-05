// src/routes/legalRoutes.js

const express = require('express');
const router = express.Router();

const legal = require('../controllers/legalController');
const { authenticate } = require('../middleware/authMiddleware');

// Public — reading privacy/terms doesn't need a token
router.get('/privacy', legal.getPrivacy);
router.get('/terms', legal.getTerms);

// Authenticated — recording consent
router.post('/consent', authenticate, legal.recordConsent);

module.exports = router;
