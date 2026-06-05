const express = require('express');
const router = express.Router();
const auditLogController = require('../controllers/auditLogController');
const { authenticate } = require('../middleware/authMiddleware');

router.get('/',  authenticate, auditLogController.getAuditLogs);
router.post('/', authenticate, auditLogController.createAuditLog);

module.exports = router;
