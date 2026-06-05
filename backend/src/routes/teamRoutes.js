// src/routes/teamRoutes.js

const express = require('express');
const router = express.Router();

const team = require('../controllers/teamController');
const { authenticate } = require('../middleware/authMiddleware');

router.use(authenticate);

// 6-digit invite code (Manager onboarding)
router.post('/invite', team.generateInvite);
router.get('/invites', team.listInvites);

// Direct add by email (legacy)
router.post('/invite-by-email', team.inviteMember);

// Membership listings
router.get('/my-companies', team.getMyCompanies);
router.get('/members', team.listMembers);
router.delete('/members/:userId', team.removeMember);

module.exports = router;
