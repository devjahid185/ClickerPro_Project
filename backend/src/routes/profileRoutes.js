// src/routes/profileRoutes.js
//
// Profile + Role + Account-deletion + Data-export endpoints।
// সব endpoint authenticated — middleware প্রথমেই apply।

const express = require('express');
const router = express.Router();

const profile = require('../controllers/profileController');
const auth = require('../controllers/authController');
const gear = require('../controllers/gearController');
const { authenticate } = require('../middleware/authMiddleware');

router.use(authenticate);

// ── Read / Update profile (Flutter PATCH ব্যবহার করে — PUT ও support করি)
router.get('/', profile.getProfile);
router.patch('/', profile.updateProfile);
router.put('/', profile.updateProfile);

// ── Lifetime stats
router.get('/stats', profile.getLifetimeStats);

// ── Settings (language, distribution, notif prefs)
router.patch('/settings', profile.updateSettings);

// ── VAT (Owner / Both only)
router.patch('/vat', profile.updateVatSettings);

// ── Change role (auth controller — DB transaction)
router.post('/role', auth.changeRole);

// ── Gear (Flutter addGear / removeGear hit /api/profile/gear)
router.get('/gear', gear.getMyGear);
router.post('/gear', gear.addGear);
router.delete('/gear/:id', gear.deleteGear);

module.exports = router;
