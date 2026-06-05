const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/authMiddleware');
const reeditController = require('../controllers/reeditController');

// ১. নতুন রি-এডিট রিকোয়েস্ট পাঠানো (POST)
router.post('/', authenticate, reeditController.createReeditRequest);

// ২. রিকোয়েস্টের স্ট্যাটাস আপডেট করা (PATCH)
router.patch('/:id/status', authenticate, reeditController.updateReeditStatus);

// ৩. আমার সব রিকোয়েস্ট দেখা (GET)
router.get('/my-requests', authenticate, reeditController.getMyReeditRequests);

module.exports = router;
