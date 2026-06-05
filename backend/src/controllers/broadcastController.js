const prisma = require('../lib/prisma');

/**
 * @desc    নতুন একটি ঘোষণা বা নোটিশ তৈরি করা
 * @route   POST /broadcasts
 * @access  Private (Owner, Both Only)
 */
exports.createAnnouncement = async (req, res) => {
    try {
        const { title, content, imageUrl, buttonLabel, link, priority, type } = req.body;
        const { role } = req.user;

        // ১. পারমিশন চেক: শুধুমাত্র ওনার বা অ্যাডমিন নোটিশ দিতে পারবে
        if (role !== 'OWNER' && role !== 'BOTH') {
            return res.status(403).json({ success: false, message: "আপনার ঘোষণা দেওয়ার অনুমতি নেই।" });
        }

        // ২. ডাটাবেসে সেভ করা
        const announcement = await prisma.broadcast.create({
            data: {
                title: title,
                content: content,
                imageUrl: imageUrl || null,
                buttonLabel: buttonLabel || null,
                link: link || null,
                priority: priority || 'Normal', // Normal, Important, Emergency
                type: type || 'Announcement',   // Announcement, Update, etc.
                status: 'ACTIVE',               // ডিফল্টভাবে অ্যাক্টিভ থাকবে
                displayDuration: 10,             // ১০ দিন পর্যন্ত দেখাবে
            }
        });

        return res.status(201).json({ 
            success: true, 
            message: "ঘোষণাটি সফলভাবে নোটিশ বোর্ডে দেওয়া হয়েছে।", 
            data: announcement 
        });

    } catch (error) {
        console.error("Create Broadcast Error:", error);
        return res.status(500).json({ success: false, message: "নোটিশ তৈরি করতে সমস্যা হয়েছে।" });
    }
};

/**
 * @desc    সকল সক্রিয় নোটিশগুলো দেখা
 * @route   GET /broadcasts
 * @access  Private
 */
exports.getAnnouncements = async (req, res) => {
    try {
        // শুধু ACTIVE স্ট্যাটাসে থাকা নোটিশগুলোই ইউজাররা দেখতে পাবে
        const all = await prisma.broadcast.findMany({
            where: {
                status: 'ACTIVE'
            },
            orderBy: {
                createdAt: 'desc' // নতুন নোটিশ আগে দেখাবে
            }
        });

        // Audience targeting: a broadcast with `targetAudience.roles` is only
        // shown to users whose role is in that list. No targeting = everyone.
        const role = (req.user && req.user.role ? req.user.role : '').toUpperCase();
        const announcements = all.filter((b) => {
            const ta = b.targetAudience;
            if (!ta || !Array.isArray(ta.roles) || ta.roles.length === 0) return true;
            return ta.roles.map((r) => String(r).toUpperCase()).includes(role);
        });

        return res.status(200).json({
            success: true,
            count: announcements.length,
            data: announcements
        });
    } catch (error) {
        console.error("Get Broadcasts Error:", error);
        return res.status(500).json({ success: false, message: "নোটিশগুলো লোড করতে সমস্যা হয়েছে।" });
    }
};

/**
 * @desc    পুরানো বা অপ্রয়োজনীয় নোটিশ ডিলিট করা
 * @route   DELETE /broadcasts/:id
 * @access  Private (Owner, Both Only)
 */
exports.deleteAnnouncement = async (req, res) => {
    try {
        const { id } = req.params;
        const { role } = req.user;

        if (role !== 'OWNER' && role !== 'BOTH') {
            return res.status(403).json({ success: false, message: "আপনার নোটিশ ডিলিট করার অনুমতি নেই।" });
        }

        await prisma.broadcast.delete({
            where: { id: id }
        });

        return res.status(200).json({ 
            success: true, 
            message: "নোটিশটি সফলভাবে সরিয়ে ফেলা হয়েছে।" 
        });
    } catch (error) {
        console.error("Delete Broadcast Error:", error);
        return res.status(500).json({ success: false, message: "নোটিশ ডিলিট করতে সমস্যা হয়েছে।" });
    }
};
