const prisma = require('../lib/prisma');

// ১. খরচ রেকর্ড করা (Record Expense)
exports.createExpense = async (req, res) => {
  try {
    const { amount, category, eventId, note } = req.body;
    const ownerId = req.user.id;

    if (!amount || !category) {
      return res.status(400).json({ success: false, message: "পরিমাণ এবং ক্যাটাগরি দেওয়া বাধ্যতামূলক।" });
    }

    const expense = await prisma.expense.create({
      data: {
        amount: parseFloat(amount),
        category,
        eventId, // optional
        ownerId,
        note,
      },
    });

    res.status(201).json({ success: true, message: "খরচ সফলভাবে রেকর্ড করা হয়েছে!", expense });
  } catch (error) {
    console.error("Expense Error:", error);
    res.status(500).json({ success: false, message: "খরচ সেভ করতে সমস্যা হয়েছে", error: error.message });
  }
};

// ২. সব খরচের লিস্ট দেখা (Get All Expenses)
exports.getExpenses = async (req, res) => {
  try {
    const ownerId = req.user.id;
    const expenses = await prisma.expense.findMany({
      where: { ownerId: ownerId },
      orderBy: { date: 'desc' },
      include: { event: { select: { title: true } } }
    });

    res.json({ success: true, count: expenses.length, data: expenses });
  } catch (error) {
    res.status(500).json({ success: false, message: "খরচের লিস্ট আনতে সমস্যা হয়েছে" });
  }
};

// ৩. নিট প্রফিট হিসাব করা (Calculate Net Profit)
exports.getProfitLoss = async (req, res) => {
  try {
    const ownerId = req.user.id;

    // মোট আয়
    const totalIncome = await prisma.payment.aggregate({
      where: { recipientId: ownerId },
      _sum: { amount: true },
    });

    // মোট খরচ
    const totalExpense = await prisma.expense.aggregate({
      where: { ownerId: ownerId },
      _sum: { amount: true },
    });

    const income = totalIncome._sum.amount || 0;
    const expense = totalExpense._sum.amount || 0;
    const profit = income - expense;

    res.json({ 
      success: true, 
      totalIncome, 
      totalExpense: expense, 
      netProfit: profit 
    });
  } catch (error) {
    res.status(500).json({ success: false, message: "লাভ-ক্ষতির হিসাব আনতে সমস্যা হয়েছে" });
  }
};
