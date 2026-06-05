const prisma = require('../lib/prisma');

const VALID_STATUS = ['WAITING', 'CONTACTED', 'BOOKED', 'EXPIRED'];

// সব ওয়েটলিস্ট এন্ট্রি দেখা (owner-scoped)
exports.getWaitlist = async (req, res) => {
  try {
    const ownerId = req.user.id;
    const entries = await prisma.waitlist.findMany({
      where: { ownerId },
      orderBy: { preferredDate: 'desc' },
    });
    res.json({ success: true, count: entries.length, data: entries });
  } catch (error) {
    console.error('Waitlist list error:', error);
    res
      .status(500)
      .json({ success: false, message: 'ওয়েটলিস্ট আনতে সমস্যা হয়েছে' });
  }
};

// নতুন এন্ট্রি যোগ করা
exports.createWaitlist = async (req, res) => {
  try {
    const ownerId = req.user.id;
    const { clientName, phone, preferredDate, note, status } = req.body;

    if (!clientName || !phone || !preferredDate) {
      return res.status(400).json({
        success: false,
        message: 'ক্লায়েন্টের নাম, ফোন এবং পছন্দের তারিখ দেওয়া বাধ্যতামূলক।',
      });
    }

    const normalizedStatus = VALID_STATUS.includes(
      (status || '').toString().toUpperCase()
    )
      ? status.toUpperCase()
      : 'WAITING';

    const entry = await prisma.waitlist.create({
      data: {
        ownerId,
        clientName,
        phone,
        preferredDate: new Date(preferredDate),
        note: note || null,
        status: normalizedStatus,
      },
    });

    res
      .status(201)
      .json({ success: true, message: 'ওয়েটলিস্টে যোগ করা হয়েছে!', data: entry });
  } catch (error) {
    console.error('Waitlist create error:', error);
    res
      .status(500)
      .json({ success: false, message: 'ওয়েটলিস্টে যোগ করতে সমস্যা হয়েছে' });
  }
};

// এন্ট্রি আপডেট (status বদল বা তথ্য সম্পাদনা) — owner-scoped
exports.updateWaitlist = async (req, res) => {
  try {
    const ownerId = req.user.id;
    const { id } = req.params;
    const { clientName, phone, preferredDate, note, status } = req.body;

    const existing = await prisma.waitlist.findFirst({
      where: { id, ownerId },
    });
    if (!existing) {
      return res
        .status(404)
        .json({ success: false, message: 'এন্ট্রি খুঁজে পাওয়া যায়নি।' });
    }

    const data = {};
    if (clientName !== undefined) data.clientName = clientName;
    if (phone !== undefined) data.phone = phone;
    if (preferredDate !== undefined) data.preferredDate = new Date(preferredDate);
    if (note !== undefined) data.note = note;
    if (status !== undefined && VALID_STATUS.includes(status.toUpperCase())) {
      data.status = status.toUpperCase();
    }

    const entry = await prisma.waitlist.update({ where: { id }, data });
    res.json({ success: true, data: entry });
  } catch (error) {
    console.error('Waitlist update error:', error);
    res
      .status(500)
      .json({ success: false, message: 'ওয়েটলিস্ট আপডেট করতে সমস্যা হয়েছে' });
  }
};

// এন্ট্রি মুছে ফেলা — owner-scoped
exports.deleteWaitlist = async (req, res) => {
  try {
    const ownerId = req.user.id;
    const { id } = req.params;

    const existing = await prisma.waitlist.findFirst({
      where: { id, ownerId },
    });
    if (!existing) {
      return res
        .status(404)
        .json({ success: false, message: 'এন্ট্রি খুঁজে পাওয়া যায়নি।' });
    }

    await prisma.waitlist.delete({ where: { id } });
    res.json({ success: true, message: 'মুছে ফেলা হয়েছে।' });
  } catch (error) {
    console.error('Waitlist delete error:', error);
    res
      .status(500)
      .json({ success: false, message: 'মুছতে সমস্যা হয়েছে' });
  }
};
