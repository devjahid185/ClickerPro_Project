// src/routes/gearRoutes.js
//
// Both legacy paths (/api/gear/*) and new profile paths (/api/profile/gear)
// are wired — Flutter uses the profile path; old clients keep working.

const express = require('express');
const router = express.Router();

const gear = require('../controllers/gearController');
const { authenticate } = require('../middleware/authMiddleware');

router.use(authenticate);

router.post('/add', gear.addGear);
router.get('/my-gear', gear.getMyGear);
router.delete('/:id', gear.deleteGear);

module.exports = router;
