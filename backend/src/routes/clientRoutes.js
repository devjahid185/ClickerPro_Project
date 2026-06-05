const express = require('express');
const router = express.Router();
const clientController = require('../controllers/clientController');
const { authenticate } = require('../middleware/authMiddleware');

// সব ক্লায়েন্ট রুট সুরক্ষিত থাকবে (টোকেন লাগবেই)
router.post('/', authenticate, clientController.createClient);       // নতুন ক্লায়েন্ট তৈরি
router.get('/', authenticate, clientController.getAllClients);      // সব ক্লায়েন্ট দেখা
router.get('/search', authenticate, clientController.searchClientsByPhone); // ফোন দিয়ে খোঁজা
router.get('/:id', authenticate, clientController.getClientById);   // নির্দিষ্ট ক্লায়েন্ট দেখা
router.put('/:id', authenticate, clientController.updateClient);    // ক্লায়েন্ট আপডেট করা

module.exports = router;
