const prisma = require('../lib/prisma');

const VALID_TYPE = ['PAYMENT', 'DELIVERY', 'FEEDBACK'];
const VALID_CHANNEL = ['WHATSAPP', 'SMS'];

const norm = (val, valid, fallback) => {
  const up = (val || '').toString().toUpperCase();
  return valid.includes(up) ? up : fallback;
};

// সব রিমাইন্ডার দেখা (owner-scoped)
exports.getReminders = async (req, res) => {
  try {
    const ownerId = req.user.id;
    const reminders = await prisma.reminder.findMany({
      where: { ownerId },
      orderBy: { scheduledDate: 'asc' },
    });
    res.json({ success: true, count: reminders.length, data: reminders });
  } catch (error) {
    console.error('Reminder list error:', error);
    res
      .status(500)
      .json({ success: false, message: 'রিমাইন্ডার আনতে সমস্যা হয়েছে' });
  }
};

// নতুন রিমাইন্ডার যোগ করা
exports.createReminder = async (req, res) => {
  try {
    const ownerId = req.user.id;
    const { bookingId, type, scheduledDate, sent, channel } = req.body;

    if (!bookingId || !scheduledDate) {
      return res.status(400).json({
        success: false,
        message: 'bookingId এবং scheduledDate দেওয়া বাধ্যতামূলক।',
      });
    }

    const reminder = await prisma.reminder.create({
      data: {
        ownerId,
        bookingId,
        type: norm(type, VALID_TYPE, 'PAYMENT'),
        scheduledDate: new Date(scheduledDate),
        sent: sent === true,
        channel: norm(channel, VALID_CHANNEL, 'WHATSAPP'),
      },
    });

    res.status(201).json({ success: true, data: reminder });
  } catch (error) {
    console.error('Reminder create error:', error);
    res
      .status(500)
      .json({ success: false, message: 'রিমাইন্ডার যোগ করতে সমস্যা হয়েছে' });
  }
};

// রিমাইন্ডার আপডেট — owner-scoped
exports.updateReminder = async (req, res) => {
  try {
    const ownerId = req.user.id;
    const { id } = req.params;
    const { bookingId, type, scheduledDate, sent, channel } = req.body;

    const existing = await prisma.reminder.findFirst({ where: { id, ownerId } });
    if (!existing) {
      return res
        .status(404)
        .json({ success: false, message: 'রিমাইন্ডার খুঁজে পাওয়া যায়নি।' });
    }

    const data = {};
    if (bookingId !== undefined) data.bookingId = bookingId;
    if (type !== undefined) data.type = norm(type, VALID_TYPE, existing.type);
    if (scheduledDate !== undefined) data.scheduledDate = new Date(scheduledDate);
    if (sent !== undefined) data.sent = sent === true;
    if (channel !== undefined)
      data.channel = norm(channel, VALID_CHANNEL, existing.channel);

    const reminder = await prisma.reminder.update({ where: { id }, data });
    res.json({ success: true, data: reminder });
  } catch (error) {
    console.error('Reminder update error:', error);
    res
      .status(500)
      .json({ success: false, message: 'রিমাইন্ডার আপডেট করতে সমস্যা হয়েছে' });
  }
};

// রিমাইন্ডার মুছে ফেলা — owner-scoped
exports.deleteReminder = async (req, res) => {
  try {
    const ownerId = req.user.id;
    const { id } = req.params;

    const existing = await prisma.reminder.findFirst({ where: { id, ownerId } });
    if (!existing) {
      return res
        .status(404)
        .json({ success: false, message: 'রিমাইন্ডার খুঁজে পাওয়া যায়নি।' });
    }

    await prisma.reminder.delete({ where: { id } });
    res.json({ success: true, message: 'মুছে ফেলা হয়েছে।' });
  } catch (error) {
    console.error('Reminder delete error:', error);
    res.status(500).json({ success: false, message: 'মুছতে সমস্যা হয়েছে' });
  }
};
