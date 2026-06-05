const prisma = require('../lib/prisma');

// ১. পেমেন্ট রেকর্ড করা (Record Payment)
exports.recordPayment = async (req, res) => {
  try {
    const { eventId, amount, kind, method, transactionId, recipientId, payerId, note } = req.body;

    if (!eventId || !amount || !kind) {
      return res.status(400).json({ success: false, message: "ইভেন্ট আইডি, পরিমাণ এবং পেমেন্ট টাইপ (kind) দেওয়া বাধ্যতামূলক।" });
    }

    const payment = await prisma.payment.create({
      data: {
        eventId,
        amount: parseFloat(amount),
        kind, // 'ADVANCE', 'DUE', 'EXTRA' অথবা 'PAYOUT'
        method, // 'CASH', 'BKASH', 'BANK', 'CARD'
        transactionId,
        recipientId,
        payerId,
        note,
      },
    });

    res.status(201).json({ success: true, message: "পেমেন্ট সফলভাবে রেকর্ড করা হয়েছে!", payment });
  } catch (error) {
    console.error("Payment Error:", error);
    res.status(500).json({ success: false, message: "পেমেন্ট সেভ করতে সমস্যা হয়েছে", error: error.message });
  }
};

// ২. একটি নির্দিষ্ট ইভেন্টের সব পেমেন্ট হিস্ট্রি দেখা (Event Payment History)
exports.getEventPayments = async (req, res) => {
  try {
    const { eventId } = req.params;

    const payments = await prisma.payment.findMany({
      where: { eventId: eventId },
      orderBy: { date: 'desc' },
    });

    res.json({ success: true, count: payments.length, data: payments });
  } catch (error) {
    res.status(500).json({ success: false, message: "পেমেন্ট লিস্ট আনতে সমস্যা হয়েছে" });
  }
};

// ৩. ওনারের মোট আয় দেখা (Total Earnings)
exports.getEarnings = async (req, res) => {
  try {
    const ownerId = req.user.id;

    // শুধুমাত্র সেই পেমেন্টগুলো যোগ করবে যেখানে recipientId হলো ওনার
    const total = await prisma.payment.aggregate({
      where: { recipientId: ownerId },
      _sum: { amount: true },
    });

    res.json({ 
      success: true, 
      totalEarnings: total._sum.amount || 0,
      currency: "BDT" 
    });
  } catch (error) {
    res.status(500).json({ success: false, message: "আয়ের হিসাব আনতে সমস্যা হয়েছে" });
  }
};
