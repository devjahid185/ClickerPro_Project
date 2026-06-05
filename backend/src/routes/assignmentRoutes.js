const express = require('express');
const router = express.Router();
const assignmentController = require('../controllers/assignmentController');
const { authenticate } = require('../middleware/authMiddleware');

// সব রুট সুরক্ষিত থাকবে
router.post('/', authenticate, assignmentController.assignUser);         // অ্যাসাইন করা
router.get('/event/:eventId', authenticate, assignmentController.getEventStaff); // ইভেন্টের স্টাফ দেখা
router.get('/me', authenticate, assignmentController.getMyAssignments);  // নিজের কাজ দেখা
router.delete('/:id', authenticate, assignmentController.removeAssignment); // রিমুভ করা

module.exports = router;
