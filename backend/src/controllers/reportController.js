const prisma = require('../lib/prisma');

// Yearly Summary Logic
const getYearlySummary = async (req, res) => {
  try {
    const { year } = req.query; 
    const ownerId = req.user.id; 

    if (!year) {
      return res.status(400).json({ message: "দয়া করে বছর উল্লেখ করুন (e.g. ?year=2026)" });
    }

    const startDate = new Date(`${year}-01-01T00:00:00.000Z`);
    const endDate = new Date(`${year}-12-31T23:59:59.999Z`);

    const totalRevenue = await prisma.payment.aggregate({
      where: {
        event: { ownerId: ownerId },
        date: { gte: startDate, lte: endDate }
      },
      _sum: { amount: true }
    });

    const totalExpenses = await prisma.expense.aggregate({
      where: {
        ownerId: ownerId,
        date: { gte: startDate, lte: endDate }
      },
      _sum: { amount: true }
    });

    const totalPayouts = await prisma.assignment.aggregate({
      where: {
        event: {
          ownerId: ownerId,
          date: { gte: startDate, lte: endDate }
        }
      },
      _sum: { payoutAmount: true }
    });

    const revenue = totalRevenue._sum.amount || 0;
    const expense = totalExpenses._sum.amount || 0;
    const payouts = totalPayouts._sum.payoutAmount || 0;
    const netProfit = revenue - (expense + payouts);

    return res.status(200).json({
      year,
      summary: {
        totalRevenue: revenue,
        totalExpenses: expense,
        totalFreelancerPayouts: payouts,
        netProfit: netProfit
      }
    });
  } catch (error) {
    console.error("Error in getYearlySummary:", error);
    res.status(500).json({ message: "সার্ভারে সমস্যা হয়েছে।" });
  }
};

// Team Performance Logic
const getTeamPerformance = async (req, res) => {
  try {
    const ownerId = req.user.id;
    const { year } = req.query;

    const startDate = year ? new Date(`${year}-01-01T00:00:00.000Z`) : new Date("2000-01-01");
    const endDate = year ? new Date(`${year}-12-31T23:59:59.999Z`) : new Date();

    const teamMembers = await prisma.teamMembership.findMany({
      where: { ownerId: ownerId },
      include: { user: true }
    });

    const performanceList = await Promise.all(
      teamMembers.map(async (member) => {
        const userId = member.userId;

        const eventsCount = await prisma.assignment.count({
          where: {
            userId: userId,
            event: {
              ownerId: ownerId,
              date: { gte: startDate, lte: endDate }
            }
          }
        });

        const totalEarned = await prisma.assignment.aggregate({
          where: {
            userId: userId,
            event: {
              ownerId: ownerId,
              date: { gte: startDate, lte: endDate }
            }
          },
          _sum: { payoutAmount: true }
        });

        const reeditCount = await prisma.reEditRequest.count({
          where: {
            editorId: userId,
            status: { not: "COMPLETED" }
          }
        });

        return {
          userId: userId,
          name: member.user.fullName,
          role: member.role,
          totalEvents: eventsCount,
          totalEarnings: totalEarned._sum.payoutAmount || 0,
          pendingReEdits: reeditCount,
          performanceScore: (eventsCount * 10) - (reeditCount * 5)
        };
      })
    );

    const sortedList = performanceList.sort((a, b) => b.performanceScore - a.performanceScore);

    return res.status(200).json({
      period: year || "All Time",
      teamPerformance: sortedList
    });
  } catch (error) {
    console.error("Error in getTeamPerformance:", error);
    res.status(500).json({ message: "পারফরম্যান্স রিপোর্ট তৈরি করতে সমস্যা হয়েছে।" });
  }
};

// ✅ এক্সপোর্ট সেকশন (এখানেই ভুল হওয়ার সম্ভাবনা থাকে)
module.exports = {
  getYearlySummary,
  getTeamPerformance
};
