const prisma = require('../lib/prisma');

// ১. নতুন সাপোর্ট টিকিট তৈরি করা (User side)
// এন্ডপয়েন্ট: POST /support/ticket
exports.createTicket = async (req, res) => {
  try {
    const { subject, message, priority, screenshot } = req.body;
    const userId = req.user.id; 

    if (!subject || !message) {
      return res.status(400).json({ 
        error: "বিষয় (subject) এবং বিস্তারিত মেসেজ (message) দেওয়া আবশ্যক।" 
      });
    }

    const ticket = await prisma.supportTicket.create({
      data: {
        userId,
        subject,
        message,
        priority: priority || "NORMAL", 
        screenshot,
        status: "OPEN"
      }
    });

    res.status(201).json({ 
      message: "আপনার রিপোর্টটি সফলভাবে পাঠানো হয়েছে। আমরা দ্রুত যোগাযোগ করব।", 
      ticket 
    });
  } catch (error) {
    res.status(500).json({ error: "রিপোর্ট পাঠাতে সমস্যা হয়েছে: " + error.message });
  }
};

// ২. সব টিকিট দেখা (Owner/Admin side)
// এন্ডপয়েন্ট: GET /support/tickets
exports.getAllTickets = async (req, res) => {
  try {
    const tickets = await prisma.supportTicket.findMany({
      orderBy: { createdAt: 'desc' }
    });
    res.status(200).json({ 
      count: tickets.length, 
      tickets 
    });
  } catch (error) {
    res.status(500).json({ error: "টিকিট লিস্ট আনতে সমস্যা হয়েছে: " + error.message });
  }
};

// ৩. FAQ (সাধারণ প্রশ্ন ও উত্তর) লিস্ট দেখা
// এন্ডপয়েন্ট: GET /support/faqs
exports.getFAQs = async (req, res) => {
  try {
    const faqs = await prisma.fAQ.findMany({
      orderBy: { order: 'asc' }
    });
    res.status(200).json({ 
      count: faqs.length,
      faqs 
    });
  } catch (error) {
    res.status(500).json({ error: "FAQ লিস্ট আনতে সমস্যা হয়েছে: " + error.message });
  }
};
