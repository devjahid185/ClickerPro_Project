const prisma = require('../lib/prisma');

// ১. ইভেন্টে মেম্বার অ্যাসাইন করা (Assign User to Event)
exports.assignUser = async (req, res) => {
  try {
    const { eventId, userId, role } = req.body;
    const ownerId = req.user.id;

    if (!eventId || !userId || !role) {
      return res.status(400).json({ success: false, message: "ইভেন্ট আইডি, ইউজার আইডি এবং রোল দেওয়া বাধ্যতামূলক।" });
    }

    // প্রথমে চেক করা যে এই ইভেন্টটি কি এই Owner-এর কি না
    const event = await prisma.event.findFirst({
      where: { id: eventId, ownerId: ownerId },
    });

    if (!event) {
      return res.status(404).json({ success: false, message: "ইভেন্টটি খুঁজে পাওয়া যায়নি অথবা আপনার অ্যাক্সেস নেই।" });
    }

    // অ্যাসাইনমেন্ট তৈরি করা
    const assignment = await prisma.assignment.create({
      data: {
        eventId: eventId,
        userId: userId,
        role: role, // যেমন: 'Chief Photographer' বা 'Drone Pilot'
      },
    });

    res.status(201).json({ success: true, message: "টিম মেম্বার সফলভাবে অ্যাসাইন করা হয়েছে!", assignment });
  } catch (error) {
    console.error("Assignment Error:", error);
    res.status(500).json({ success: false, message: "অ্যাসাইন করার সময় সমস্যা হয়েছে", error: error.message });
  }
};

// ২. নির্দিষ্ট ইভেন্টের সব স্টাফ দেখা (Get Event Staff)
exports.getEventStaff = async (req, res) => {
  try {
    const { eventId } = req.params;
    
    const assignments = await prisma.assignment.findMany({
      where: { eventId: eventId },
      include: { 
        user: { select: { fullName: true, email: true, role: true } } 
      },
    });

    res.json({ success: true, data: assignments });
  } catch (error) {
    res.status(500).json({ success: false, message: "স্টাফ লিস্ট আনতে সমস্যা হয়েছে" });
  }
};

// ৩. আমার নিজের সব অ্যাসাইনমেন্ট দেখা (My Assignments - Freelancer View)
exports.getMyAssignments = async (req, res) => {
  try {
    const userId = req.user.id;

    const myWork = await prisma.assignment.findMany({
      where: { userId: userId },
      include: { 
        event: { 
          select: { title: true, date: true, location: true, status: true } 
        } 
      },
      orderBy: { createdAt: 'desc' },
    });

    res.json({ success: true, data: myWork });
  } catch (error) {
    res.status(500).json({ success: false, message: "আপনার অ্যাসাইনমেন্ট লিস্ট আনতে সমস্যা হয়েছে" });
  }
};

// ৪. অ্যাসাইনমেন্ট বাতিল করা (Remove Assignment)
exports.removeAssignment = async (req, res) => {
  try {
    const { id } = req.params;
    await prisma.assignment.delete({
      where: { id: id },
    });
    res.json({ success: true, message: "অ্যাসাইনমেন্টটি সফলভাবে রিমুভ করা হয়েছে!" });
  } catch (error) {
    res.status(500).json({ success: false, message: "রিমুভ করার সময় সমস্যা হয়েছে" });
  }
};
