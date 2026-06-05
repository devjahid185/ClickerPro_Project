const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/authMiddleware');
const invoiceController = require('../controllers/invoiceController');

/**
 * ইনভয়েস রাউট কনফিগারেশন
 * এখানে আমরা কন্ট্রোলারের নতুন ফাংশনগুলোর সাথে কানেক্ট করছি
 */

// ১. নতুন ইনভয়েস তৈরি করা (VAT ক্যালকুলেশন সহ)
// POST /invoices/generate
router.post('/generate', authenticate, invoiceController.generateInvoice);

// ২. নির্দিষ্ট ইভেন্টের ইনভয়েস দেখা
// GET /invoices/event/:id
router.get('/event/:id', authenticate, invoiceController.getEventInvoice);

module.exports = router;
