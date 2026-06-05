const express = require('express');
const router = express.Router();
const packageController = require('../controllers/packageController');
const { authenticate } = require('../middleware/authMiddleware');

router.post('/', authenticate, packageController.createPackage);
router.get('/', authenticate, packageController.getAllPackages);
router.put('/:id', authenticate, packageController.updatePackage);
router.delete('/:id', authenticate, packageController.deletePackage);

module.exports = router; // এই লাইনটি খুব জরুরি!
