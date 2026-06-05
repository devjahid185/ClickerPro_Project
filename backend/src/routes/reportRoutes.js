const express = require('express');
const router = express.Router();
const reportController = require('../controllers/reportController');
const { authenticate } = require('../middleware/authMiddleware'); // এখন এটি কাজ করবে

// রাউটগুলো সেট করা
router.get('/yearly-summary', authenticate, reportController.getYearlySummary);
router.get('/team-performance', authenticate, reportController.getTeamPerformance);

module.exports = router;
