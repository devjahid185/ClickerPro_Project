const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/authMiddleware');
const taskController = require('../controllers/taskController');

// ১. প্রগ্রেস আপডেট করা (PATCH)
// URL: /tasks/progress
router.patch('/progress', authenticate, taskController.updateProgress);

// ২. ইভেন্টের প্রগ্রেস রিপোর্ট দেখা (GET)
// URL: /tasks/event/:id
router.get('/event/:id', authenticate, taskController.getEventProgress);

module.exports = router;
