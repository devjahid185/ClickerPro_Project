const express = require('express');
const router = express.Router();
const supportController = require('../controllers/supportController');
const { authenticate } = require('../middleware/authMiddleware');

// ১. টিকিট তৈরি (ইউজারকে লগইন থাকতে হবে)
router.post('/ticket', authenticate, supportController.createTicket);

// ২. সব টিকিট দেখা (শুধুমাত্র মালিক বা এডমিন লগইন করে দেখবে)
router.get('/tickets', authenticate, supportController.getAllTickets);

// ৩. FAQ দেখা (লগইন ছাড়াই সবাই দেখতে পারবে)
router.get('/faqs', supportController.getFAQs);

module.exports = router;
