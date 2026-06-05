const express = require('express');
const router = express.Router();
const entitlement = require('../controllers/entitlementController');
const { authenticate } = require('../middleware/authMiddleware');

router.get('/', authenticate, entitlement.getEntitlements);

module.exports = router;
