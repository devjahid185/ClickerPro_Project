const prisma = require('../lib/prisma');

/**
 * এই ফাংশনটি মূলত ডাটাবেসে নটিফিকেশন সেভ করার কাজ করে।
 * এটি অন্য যেকোনো কন্ট্রোলার থেকে কল করা যাবে।
 */
async function createNotificationInDB(userId, category, message, deeplink = null) {
    try {
        return await prisma.notification.create({
            data: {
                userId: userId,
                category: category,
                message: message,
                deeplink: deeplink,
                read: false
            }
        });
    } catch (error) {
        console.error("Database Notification Error:", error);
        throw error;
    }
}

// ১. যখন অন্য কন্ট্রোলার (যেমন clientBookingController) থেকে কল করা হয়
exports.sendNotification = async (userId, category, message, deeplink) => {
    try {
        await createNotificationInDB(userId, category, message, deeplink);
        return { success: true };
    } catch (error) {
        console.error("Send Notification Helper Error:", error);
        return { success: false, error };
    }
};

// ২. যখন সরাসরি API রাউট (/notifications/send) থেকে কল করা হয়
exports.handleNotificationRequest = async (req, res) => {
    try {
        const { userId, category, message, deeplink } = req.body;

        if (!userId || !category || !message) {
            return res.status(400).json({ 
                success: false, 
                message: "userId, category এবং message অবশ্যই দিতে হবে।" 
            });
        }

        await createNotificationInDB(userId, category, message, deeplink);

        res.status(201).json({ 
            success: true, 
            message: "নটিফিকেশন সফলভাবে পাঠানো হয়েছে।" 
        });
    } catch (error) {
        console.error("Handle Notification Request Error:", error);
        res.status(500).json({ success: false, message: "নটিফিকেশন পাঠাতে সমস্যা হয়েছে।" });
    }
};

// ৩. ইউজার তার নিজের নটিফিকেশন লিস্ট দেখবে
exports.getUserNotifications = async (req, res) => {
    try {
        const userId = req.user.id;
        const notifications = await prisma.notification.findMany({
            where: { userId: userId },
            orderBy: { sentAt: 'desc' }
        });
        res.json({ success: true, data: notifications });
    } catch (error) {
        res.status(500).json({ success: false, message: "নটিফিকেশন লোড করতে সমস্যা হয়েছে।" });
    }
};

// ৪. নটিফিকেশন পড়া হয়েছে (Read) হিসেবে মার্ক করা
exports.markAsRead = async (req, res) => {
    try {
        const { notificationId } = req.body;
        const userId = req.user.id;

        await prisma.notification.update({
            where: { id: notificationId },
            data: { read: true }
        });

        res.json({ success: true, message: "নটিফিকেশনটি পড়া হয়েছে হিসেবে মার্ক করা হয়েছে।" });
    } catch (error) {
        res.status(500).json({ success: false, message: "আপডেট করতে সমস্যা হয়েছে।" });
    }
};
