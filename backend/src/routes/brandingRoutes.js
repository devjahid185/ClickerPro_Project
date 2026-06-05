const express = require('express');
const router = express.Router();
const settings = require('../controllers/settingsController');

// Public — app reads theme/branding/social without auth.
router.get('/', settings.getPublicBranding);

module.exports = router;
