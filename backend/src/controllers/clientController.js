const prisma = require('../lib/prisma');

// ১. নতুন ক্লায়েন্ট তৈরি করা (Create Client)
exports.createClient = async (req, res) => {
  try {
    const { name, email, phone, address } = req.body;
    const ownerId = req.user.id; // টোকেন থেকে পাওয়া Owner-এর আইডি

    if (!name || !phone) {
      return res.status(400).json({ success: false, message: "নাম এবং ফোন নম্বর দেওয়া বাধ্যতামূলক।" });
    }

    const client = await prisma.client.create({
      data: {
        name,
        email,
        phone,
        address,
        ownerId: ownerId, // এই ক্লায়েন্টটি কোন Owner-এর অধীনে তা সেভ হবে
      },
    });

    res.status(201).json({ success: true, message: "ক্লায়েন্ট সফলভাবে সেভ করা হয়েছে!", client });
  } catch (error) {
    console.error("Create Client Error:", error);
    res.status(500).json({ success: false, message: "ক্লায়েন্ট সেভ করার সময় সমস্যা হয়েছে", error: error.message });
  }
};

// ২. সব ক্লায়েন্টের লিস্ট দেখা (Get All Clients)
exports.getAllClients = async (req, res) => {
  try {
    const ownerId = req.user.id;
    const clients = await prisma.client.findMany({
      where: { ownerId: ownerId }, // শুধুমাত্র এই Owner-এর ক্লায়েন্টদের দেখাবে
      orderBy: { createdAt: 'desc' },
    });

    res.json({ success: true, count: clients.length, items: clients });
  } catch (error) {
    res.status(500).json({ success: false, message: "ক্লায়েন্ট লিস্ট আনতে সমস্যা হয়েছে" });
  }
};

// ৩. নির্দিষ্ট একজন ক্লায়েন্টের ডিটেইলস দেখা (Get Client By ID)
exports.getClientById = async (req, res) => {
  try {
    const { id } = req.params;
    const ownerId = req.user.id;

    const client = await prisma.client.findFirst({
      where: { id: id, ownerId: ownerId },
    });

    if (!client) {
      return res.status(404).json({ success: false, message: "ক্লায়েন্ট খুঁজে পাওয়া যায়নি।" });
    }

    res.json({ success: true, client });
  } catch (error) {
    res.status(500).json({ success: false, message: "তথ্য আনতে সমস্যা হয়েছে" });
  }
};

// ৪. ক্লায়েন্টের তথ্য আপডেট করা (Update Client)
exports.updateClient = async (req, res) => {
  try {
    const { id } = req.params;
    const ownerId = req.user.id;

    const updatedClient = await prisma.client.update({
      where: { id },
      data: req.body,
    });

    res.json({ success: true, message: "ক্লায়েন্টের তথ্য আপডেট করা হয়েছে!", client: updatedClient });
  } catch (error) {
    res.status(500).json({ success: false, message: "আপডেট করার সময় সমস্যা হয়েছে" });
  }
};

// ৫. ফোন নম্বর দিয়ে ক্লায়েন্ট খোঁজা (Phone prefix search)
exports.searchClientsByPhone = async (req, res) => {
  try {
    const ownerId = req.user.id;
    const phone = req.query.phone || '';

    const clients = await prisma.client.findMany({
      where: {
        ownerId: ownerId,
        phone: { contains: phone },
      },
      orderBy: { name: 'asc' },
      take: 20,
    });

    res.json({ success: true, items: clients });
  } catch (error) {
    res.status(500).json({ success: false, message: "সার্চ করতে সমস্যা হয়েছে" });
  }
};
