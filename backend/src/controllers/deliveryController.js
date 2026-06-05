const prisma = require('../lib/prisma');

// ১. ডেলিভারি লিঙ্ক যোগ করা এবং স্ট্যাটাস আপডেট করা
exports.updateDelivery = async (req, res) => {
  try {
    const { eventId, driveLink, status } = req.body;
    const ownerId = req.user.id;

    if (!eventId || !driveLink) {
      return res.status(400).json({ success: false, message: "ইভেন্ট আইডি এবং ড্রাইভ লিঙ্ক দেওয়া বাধ্যতামূলক।" });
    }

    // ইভেন্টটি এই ওনারের কি না তা চেক করা
    const event = await prisma.event.findFirst({
      where: { id: eventId, ownerId: ownerId },
    });

    if (!event) {
      return res.status(404).json({ success: false, message: "ইভেন্টটি পাওয়া যায়নি।" });
    }

    // আপডেট করা
    const updatedEvent = await prisma.event.update({
      where: { id: eventId },
      data: { 
        driveLink: driveLink,
        status: status || 'DELIVERED' // ডিফল্ট হিসেবে DELIVERED করা হবে
      },
    });

    res.json({ success: true, message: "ডেলিভারি লিঙ্ক সফলভাবে যোগ করা হয়েছে!", updatedEvent });
  } catch (error) {
    console.error("Delivery Error:", error);
    res.status(500).json({ success: false, message: "লিঙ্ক সেভ করতে সমস্যা হয়েছে", error: error.message });
  }
};

// ২. ডেলিভারি করা সব ইভেন্ট দেখা
exports.getDeliveredEvents = async (req, res) => {
  try {
    const ownerId = req.user.id;
    const events = await prisma.event.findMany({
      where: { ownerId: ownerId, status: 'DELIVERED' },
      select: { title: true, driveLink: true, date: true }
    });
    res.json({ success: true, data: events });
  } catch (error) {
    res.status(500).json({ success: false, message: "লিস্ট আনতে সমস্যা হয়েছে" });
  }
};
