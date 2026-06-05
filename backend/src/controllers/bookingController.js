const prisma = require('../lib/prisma');

// =============================================
// নতুন Booking তৈরি করার ফাংশন
// POST /bookings
// =============================================
exports.createBooking = async (req, res) => {
  try {
    // body থেকে সব field বের করে নিন
    const {
      title,          // event-এর নাম (যেমন: "Karim's Wedding")
      eventType,      // event-এর ধরন (wedding/holud/birthday/corporate/preWedding/other)
      date,           // event-এর তারিখ
      startTime,      // শুরুর সময় (যেমন: "10:00")
      endTime,        // শেষের সময়
      venue,          // স্থান (schema-তে venue, location না!)
      outdoor,        // outdoor shoot কি না (true/false)
      packageId,      // কোন package
      brideName,      // wedding হলে
      groomName,      // wedding হলে
      chiefId,        // chief photographer কে
      chiefHours,     // কত ঘণ্টা coverage
      hidePaymentFromTeam,  // payment hide করবে কি না (Owner-এর জন্য)
      clientRequirements,   // client কী চায় (photo edit, print, album)
      notes           // বাড়তি note
    } = req.body;

    // App ফর্ম থেকে হয় existing clientId আসে, নয়তো নতুন client-এর
    // name/phone আসে। দুটোর যেকোনোটাই গ্রহণযোগ্য।
    let { clientId } = req.body;
    const clientName = (req.body.clientName || '').trim();
    const clientPhone = (req.body.clientPhone || '').trim();

    // The Flutter client sends enum names in lowercase ("day"/"night"/"both"),
    // but the Prisma `Shift` enum is uppercase (DAY/NIGHT/BOTH). Normalise so
    // an offline-synced booking doesn't blow up with a Prisma enum error.
    const VALID_SHIFTS = ['DAY', 'NIGHT', 'BOTH'];
    const rawShift = (req.body.shift || 'DAY').toString().toUpperCase();
    const shift = VALID_SHIFTS.includes(rawShift) ? rawShift : 'DAY';

    const ownerId = req.user.id;

    // বাধ্যতামূলক field check — venue ঐচ্ছিক (পরে যোগ করা যায়),
    // client হয় id নয়তো নাম দিয়ে দিতে হবে।
    if (!title || !date) {
      return res.status(400).json({
        success: false,
        message: "টাইটেল এবং তারিখ বাধ্যতামূলক।"
      });
    }
    if (!clientId && !clientName) {
      return res.status(400).json({
        success: false,
        message: "ক্লায়েন্ট আইডি অথবা ক্লায়েন্টের নাম দিতে হবে।"
      });
    }

    // তারিখ validation
    const eventDate = new Date(date);
    if (isNaN(eventDate)) {
      return res.status(400).json({
        success: false,
        message: "তারিখের ফরম্যাট সঠিক নয় (YYYY-MM-DD)।"
      });
    }

    // client resolve. The app may send:
    //   • a server clientId (online flow), OR
    //   • a LOCAL uuid clientId that doesn't exist on the server yet
    //     (offline-first booking synced via the outbox), plus clientName/phone.
    // So: if the given clientId exists, use it; otherwise fall back to
    // find-or-create from name/phone. Never hard-fail when we can recover.
    let resolvedClient = null;
    if (clientId) {
      resolvedClient = await prisma.client.findUnique({
        where: { id: clientId }
      });
    }
    if (!resolvedClient) {
      // Find-or-create from the typed name/phone under this owner.
      if (clientPhone) {
        resolvedClient = await prisma.client.findFirst({
          where: { ownerId, phone: clientPhone }
        });
      }
      if (!resolvedClient && !clientName && !clientPhone) {
        return res.status(400).json({
          success: false,
          message: "ক্লায়েন্টের নাম অথবা ফোন দিতে হবে।"
        });
      }
      resolvedClient ??= await prisma.client.create({
        data: {
          name: clientName || 'Unnamed client',
          phone: clientPhone || '',
          ownerId
        }
      });
    }
    clientId = resolvedClient.id;

    // 🚨 Distribution toggle check — multi-booking allow করবে কি না
    // Owner-এর settings থেকে দেখুন
    const owner = await prisma.user.findUnique({
      where: { id: ownerId },
      select: { distributionOn: true, role: true }
    });

    // যদি Owner/Both হয় এবং distribution OFF, তাহলে same date+shift এ আরেক booking আছে কিনা check
    if ((owner.role === 'OWNER' || owner.role === 'BOTH') && !owner.distributionOn) {
      const conflict = await prisma.event.findFirst({
        where: {
          ownerId: ownerId,
          date: eventDate,
          shift: shift || 'DAY',
          status: { notIn: ['CANCELLED'] }
        }
      });
      
      if (conflict) {
        return res.status(409).json({ 
          success: false, 
          message: "এই date ও shift-এ আরেকটা booking আছে। Distribution চালু করুন অথবা ভিন্ন slot দিন।",
          conflictBookingId: conflict.id
        });
      }
    }

    // FREELANCER-দের জন্য সবসময় strict — multi booking allowed না
    if (owner.role === 'FREELANCER') {
      const conflict = await prisma.event.findFirst({
        where: {
          ownerId: ownerId,
          date: eventDate,
          shift: shift || 'DAY',
          status: { notIn: ['CANCELLED'] }
        }
      });
      
      if (conflict) {
        return res.status(409).json({ 
          success: false, 
          message: "এই date ও shift-এ আপনার আরেকটা booking আছে।" 
        });
      }
    }

    // database-এ booking তৈরি করুন
    const booking = await prisma.event.create({
      data: {
        title,
        type: eventType || 'other',                       // Prisma-র type field — Flutter eventType থেকে ম্যাপ
        date: eventDate,
        venue: venue || '',                               // schema NOT NULL — খালি হলে '' দিই
        clientId,
        ownerId,
        creatorId: ownerId,                               // কে তৈরি করেছে
        status: 'PENDING',
        ...(startTime !== undefined && { startTime }),
        ...(endTime !== undefined && { endTime }),
        ...(shift !== undefined && { shift }),
        ...(outdoor !== undefined && { outdoor }),
        ...(packageId !== undefined && { packageId }),
        ...(brideName !== undefined && { brideName }),
        ...(groomName !== undefined && { groomName }),
        ...(chiefId !== undefined && { chiefId }),
        ...(chiefHours !== undefined && { chiefHours }),
        ...(hidePaymentFromTeam !== undefined && { hidePaymentFromTeam }),
        ...(clientRequirements !== undefined && { clientRequirements }),
        ...(notes !== undefined && { notes }),
      },
      // client-এর info সহ return করুন
      include: {
        client: { select: { id: true, name: true, phone: true } },
        package: true
      }
    });

    // Status history-এ entry যোগ করুন (CCTV footage)
    await prisma.statusHistory.create({
      data: {
        eventId: booking.id,
        toStatus: 'PENDING',
        changeType: 'CREATED',
        changedBy: ownerId,
        note: 'Booking created'
      }
    });

    res.status(201).json({ 
      success: true, 
      message: "স্মার্ট বুকিং সফল হয়েছে!", 
      event: booking 
    });
  } catch (error) {
    res.status(500).json({ 
      success: false, 
      message: "বুকিং এরর", 
      error: error.message 
    });
  }
};

// =============================================
// নির্দিষ্ট Booking-এর ডিটেলস (সম্পর্কিত data সহ)
// GET /bookings/:id
// =============================================
exports.getBookingById = async (req, res) => {
  try {
    const { id } = req.params;
    const ownerId = req.user.id;

    const event = await prisma.event.findFirst({
      where: { id, ownerId },
      include: {
        client: true,
        package: true,
        assignments: {
          include: { user: { select: { id: true, fullName: true, email: true } } }
        },
        payments: true,
        statusHistory: { orderBy: { changedAt: 'asc' } },
        progress: true,
      }
    });

    if (!event) {
      return res.status(404).json({ success: false, message: "Booking খুঁজে পাওয়া যায়নি।" });
    }

    // আলাদা করে ReEditRequest আনতে হবে (Event-এর সাথে direct relation নেই)
    const reEditRequests = await prisma.reEditRequest.findMany({
      where: { eventId: id },
      orderBy: { round: 'asc' }
    }).catch(() => []);

    res.json({
      success: true,
      event,
      client: event.client || null,
      assignments: event.assignments || [],
      payments: event.payments || [],
      package: event.package || null,
      statusHistory: event.statusHistory || [],
      reEditRequests: reEditRequests,
      taskProgress: event.progress || [],
    });
  } catch (error) {
    res.status(500).json({ success: false, message: "ডিটেলস আনতে সমস্যা হয়েছে", error: error.message });
  }
};

// =============================================
// Booking আপডেট
// PATCH /bookings/:id
// =============================================
exports.updateBooking = async (req, res) => {
  try {
    const { id } = req.params;
    const ownerId = req.user.id;
    const { title, date, startTime, endTime, shift, venue, outdoor,
            clientId, packageId, brideName, groomName, chiefId, chiefHours,
            hidePaymentFromTeam, clientRequirements, notes, driveLink,
            eventType } = req.body;

    const event = await prisma.event.findFirst({
      where: { id, ownerId }
    });

    if (!event) {
      return res.status(404).json({ success: false, message: "Booking খুঁজে পাওয়া যায়নি।" });
    }

    const updated = await prisma.event.update({
      where: { id },
      data: {
        ...(title !== undefined && { title }),
        ...(eventType !== undefined && { type: eventType }),
        ...(date !== undefined && { date: new Date(date) }),
        ...(startTime !== undefined && { startTime }),
        ...(endTime !== undefined && { endTime }),
        ...(shift !== undefined && { shift }),
        ...(venue !== undefined && { venue }),
        ...(outdoor !== undefined && { outdoor }),
        ...(clientId !== undefined && { clientId }),
        ...(packageId !== undefined && { packageId }),
        ...(brideName !== undefined && { brideName }),
        ...(groomName !== undefined && { groomName }),
        ...(chiefId !== undefined && { chiefId }),
        ...(chiefHours !== undefined && { chiefHours }),
        ...(hidePaymentFromTeam !== undefined && { hidePaymentFromTeam }),
        ...(clientRequirements !== undefined && { clientRequirements }),
        ...(notes !== undefined && { notes }),
        ...(driveLink !== undefined && { driveLink }),
      },
      include: {
        client: { select: { id: true, name: true, phone: true } },
        package: true
      }
    });

    res.json({ success: true, message: "Booking আপডেট করা হয়েছে!", event: updated });
  } catch (error) {
    res.status(500).json({ success: false, message: "আপডেট এরর", error: error.message });
  }
};

// =============================================
// সব Booking দেখানো
// GET /bookings
// =============================================
exports.getAllBookings = async (req, res) => {
  try {
    const ownerId = req.user.id;
    const bookings = await prisma.event.findMany({
      where: { ownerId: ownerId },
      include: { 
        client: true, 
        package: true,
        assignments: {
          include: {
            user: { select: { id: true, fullName: true } }
          }
        }
      },
      orderBy: { date: 'asc' },
    });
    res.json({ success: true, count: bookings.length, items: bookings, total: bookings.length, page: 0 });
  } catch (error) {
    res.status(500).json({ success: false, message: "লিস্ট আনতে সমস্যা হয়েছে", error: error.message });
  }
};

// =============================================
// Booking status আপডেট (পুরোনো simple version)
// PATCH /bookings/:id/status
// 
// ⚠️ পরে এটাকে আরো advanced version দিয়ে replace করব
// (state machine, validation, history সহ)
// =============================================
exports.updateBookingStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;
    const ownerId = req.user.id;

    // আগের status কী ছিল সেটা জানুন
    const currentEvent = await prisma.event.findUnique({
      where: { id }
    });

    if (!currentEvent) {
      return res.status(404).json({ success: false, message: "Booking খুঁজে পাওয়া যায়নি" });
    }

    // update করুন
    await prisma.event.updateMany({
      where: { id: id, ownerId: ownerId },
      data: { 
        status: status,
        statusUpdatedAt: new Date(),
        statusUpdatedBy: ownerId
      },
    });

    // history-এ entry যোগ করুন
    await prisma.statusHistory.create({
      data: {
        eventId: id,
        fromStatus: currentEvent.status,
        toStatus: status,
        changeType: status === 'CANCELLED' ? 'CANCELLED' : 'CONFIRMED',
        changedBy: ownerId,
      }
    });

    res.json({ success: true, message: "স্ট্যাটাস আপডেট করা হয়েছে!" });
  } catch (error) {
    res.status(500).json({ success: false, message: "আপডেট এরর", error: error.message });
  }
};