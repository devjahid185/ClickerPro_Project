const express = require('express');
const router = express.Router();
const bookingController = require('../controllers/bookingController');
const assignmentController = require('../controllers/assignmentController');
const { authenticate } = require('../middleware/authMiddleware');

// ─── Booking CRUD ─────────────────────────────────────────────────
router.post('/', authenticate, bookingController.createBooking);
router.get('/', authenticate, bookingController.getAllBookings);
router.get('/:id', authenticate, bookingController.getBookingById);
router.patch('/:id', authenticate, bookingController.updateBooking);
router.patch('/:id/status', authenticate, bookingController.updateBookingStatus);

// ─── Nested Assignment routes (Flutter calls these) ────────────────
// POST /api/bookings/:eventId/assignments
router.post('/:eventId/assignments', authenticate, async (req, res) => {
  // Merge the URL param into the body so the existing controller works
  req.body.eventId = req.params.eventId;
  return assignmentController.assignUser(req, res);
});

// PATCH /api/bookings/:eventId/assignments/:assignmentId
router.patch('/:eventId/assignments/:assignmentId', authenticate, async (req, res) => {
  try {
    const prisma = require('../lib/prisma');
    const { assignmentId } = req.params;
    const { userId, role, payout, notes } = req.body;

    const updated = await prisma.assignment.update({
      where: { id: assignmentId },
      data: {
        ...(userId !== undefined && { userId }),
        ...(role !== undefined && { role }),
        ...(payout !== undefined && { payoutAmount: payout }),
        ...(notes !== undefined && { notes }),
      }
    });

    res.json({ success: true, message: "Assignment আপডেট করা হয়েছে!", assignment: updated });
  } catch (error) {
    res.status(500).json({ success: false, message: "Assignment আপডেট এরর", error: error.message });
  }
});

// DELETE /api/bookings/:eventId/assignments/:assignmentId
router.delete('/:eventId/assignments/:assignmentId', authenticate, async (req, res) => {
  try {
    const prisma = require('../lib/prisma');
    const { assignmentId } = req.params;
    await prisma.assignment.delete({ where: { id: assignmentId } });
    res.json({ success: true, message: "Assignment রিমুভ করা হয়েছে!" });
  } catch (error) {
    res.status(500).json({ success: false, message: "Assignment রিমুভ এরর", error: error.message });
  }
});

module.exports = router;
