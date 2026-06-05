const express = require('express');
const router = express.Router();
const expenseController = require('../controllers/expenseController');
const { authenticate } = require('../middleware/authMiddleware');

router.post('/', authenticate, expenseController.createExpense);     // খরচ রেকর্ড
router.get('/', authenticate, expenseController.getExpenses);       // সব খরচ দেখা
router.get('/profit', authenticate, expenseController.getProfitLoss); // লাভ-ক্ষতি দেখা

module.exports = router;
