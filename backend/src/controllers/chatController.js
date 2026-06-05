const prisma = require('../lib/prisma');

// ১. ওনারের জন্য অটোমেটিক টিম গ্রুপ তৈরি করা
exports.createTeamGroup = async (req, res) => {
    try {
        const userId = req.user.id;
        const user = await prisma.user.findUnique({ where: { id: userId } });

        const groupName = `${user.fullName}'s Team Chat`;

        const group = await prisma.chatGroup.create({
            data: {
                name: groupName,
                ownerId: userId
            }
        });

        res.json({ success: true, data: group });
    } catch (error) {
        console.error("Create Group Error:", error);
        res.status(500).json({ success: false, message: "গ্রুপ তৈরি করতে সমস্যা হয়েছে।" });
    }
};

// ২. মেসেজ পাঠানো
exports.sendMessage = async (req, res) => {
    try {
        const { groupId, text } = req.body;
        const senderId = req.user.id;

        const message = await prisma.chatMessage.create({
            data: {
                groupId: groupId,
                senderId: senderId,
                text: text
            }
        });

        res.status(201).json({ success: true, data: message });
    } catch (error) {
        console.error("Send Message Error:", error);
        res.status(500).json({ success: false, message: "মেসেজ পাঠাতে সমস্যা হয়েছে।" });
    }
};

// ৩. গ্রুপ চ্যাটের মেসেজ হিস্ট্রি দেখা
exports.getMessages = async (req, res) => {
    try {
        const { groupId } = req.params;

        const messages = await prisma.chatMessage.findMany({
            where: { groupId: groupId },
            include: {
                sender: {
                    select: { fullName: true, role: true } // প্রেরকের নাম এবং রোল দেখাবে
                }
            },
            orderBy: { sentAt: 'asc' } // পুরনো মেসেজ আগে আসবে
        });

        res.json({ success: true, data: messages });
    } catch (error) {
        console.error("Get Messages Error:", error);
        res.status(500).json({ success: false, message: "মেসেজ লোড করতে সমস্যা হয়েছে।" });
    }
};

// ৪. ওনারের নিজস্ব গ্রুপটি খুঁজে বের করা
exports.getMyTeamGroup = async (req, res) => {
    try {
        const userId = req.user.id;
        const group = await prisma.chatGroup.findFirst({
            where: { ownerId: userId }
        });

        if (!group) {
            return res.status(404).json({ success: false, message: "কোনো টিম গ্রুপ পাওয়া যায়নি।" });
        }

        res.json({ success: true, data: group });
    } catch (error) {
        res.status(500).json({ success: false, message: "গ্রুপ খুঁজতে সমস্যা হয়েছে।" });
    }
};
