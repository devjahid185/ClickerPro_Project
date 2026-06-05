const prisma = require('../lib/prisma');

// ১. রেন্ট রেকর্ড তৈরি (ভাড়া দেওয়া বা নেওয়া)
exports.createRentRecord = async (req, res) => {
  try {
    const { direction, counterpartyName, counterpartyPhone, amount, returnBy, gearItemId } = req.body;
    const ownerId = req.user.id;

    if (!direction || !counterpartyName) {
      return res.status(400).json({ error: "Direction (IN/OUT) এবং নাম অবশ্যই দিতে হবে" });
    }

    const record = await prisma.rentRecord.create({
      data: {
        direction, // "IN" মানে বাইরে থেকে ভাড়া নেওয়া, "OUT" মানে অন্যকে ভাড়া দেওয়া
        counterpartyName,
        counterpartyPhone,
        amount: parseFloat(amount) || 0,
        returnBy: returnBy ? new Date(returnBy) : null,
        gearItemId,
        ownerId: ownerId,
        status: "ACTIVE"
      }
    });

    res.status(201).json({ message: "রেন্ট রেকর্ড সফলভাবে তৈরি হয়েছে", record });
  } catch (error) {
    res.status(500).json({ error: "রেকর্ড তৈরি করতে সমস্যা হয়েছে" });
  }
};

// ২. রেন্ট হিস্ট্রি দেখা
exports.getRentHistory = async (req, res) => {
  try {
    const history = await prisma.rentRecord.findMany({
      where: { ownerId: req.user.id },
      include: { gear: true }, // সাথে গিয়ারের নামও দেখাবে
      orderBy: { createdAt: 'desc' }
    });
    res.status(200).json({ count: history.length, history });
  } catch (error) {
    res.status(500).json({ error: "হিস্ট্রি আনতে সমস্যা হয়েছে" });
  }
};

// ৩. গিয়ার ফেরত নেওয়া (Status Update)
exports.updateRentStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, actualReturnDate } = req.body;

    const updated = await prisma.rentRecord.update({
      where: { id: id },
      data: { 
        status: status, // "RETURNED" বা "OVERDUE"
        actualReturnDate: actualReturnDate ? new Date(actualReturnDate) : null 
      }
    });

    res.status(200).json({ message: "রেন্ট স্ট্যাটাস আপডেট করা হয়েছে", updated });
  } catch (error) {
    res.status(500).json({ error: "আপডেট করতে সমস্যা হয়েছে" });
  }
};
