const prisma = require('../lib/prisma');

// ১. নতুন প্যাকেজ তৈরি করা (Create Package)
exports.createPackage = async (req, res) => {
  try {
    const { name, price } = req.body;

    if (!name || !price) {
      return res.status(400).json({ success: false, message: "প্যাকেজের নাম এবং দাম দেওয়া বাধ্যতামূলক।" });
    }

    const packageItem = await prisma.package.create({
      data: {
        name,
        price: parseFloat(price),
      },
    });

    res.status(201).json({ success: true, message: "প্যাকেজ সফলভাবে তৈরি হয়েছে!", packageItem });
  } catch (error) {
    console.error("Package Error:", error);
    res.status(500).json({ success: false, message: "প্যাকেজ সেভ করতে সমস্যা হয়েছে", error: error.message });
  }
};

// ২. সব প্যাকেজের লিস্ট দেখা (Get All Packages)
exports.getAllPackages = async (req, res) => {
  try {
    const packages = await prisma.package.findMany({
      orderBy: { price: 'asc' },
    });

    res.json({ success: true, count: packages.length, data: packages });
  } catch (error) {
    res.status(500).json({ success: false, message: "প্যাকেজ লিস্ট আনতে সমস্যা হয়েছে" });
  }
};

// ৩. নির্দিষ্ট প্যাকেজ আপডেট করা (Update Package)
exports.updatePackage = async (req, res) => {
  try {
    const { id } = req.params;
    const updatedPackage = await prisma.package.update({
      where: { id: id },
      data: req.body,
    });

    res.json({ success: true, message: "প্যাকেজ আপডেট করা হয়েছে!", updatedPackage });
  } catch (error) {
    res.status(500).json({ success: false, message: "আপডেট করতে সমস্যা হয়েছে" });
  }
};

// ৪. প্যাকেজ ডিলিট করা (Delete Package)
exports.deletePackage = async (req, res) => {
  try {
    const { id } = req.params;
    await prisma.package.delete({
      where: { id: id },
    });
    res.json({ success: true, message: "প্যাকেজটি সফলভাবে রিমুভ করা হয়েছে!" });
  } catch (error) {
    res.status(500).json({ success: false, message: "ডিলিট করতে সমস্যা হয়েছে" });
  }
};
