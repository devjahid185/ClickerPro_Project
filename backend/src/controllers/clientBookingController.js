const prisma = require('../lib/prisma');
const notificationController = require('./notificationController');

// ১. ক্লায়েন্ট যখন বুকিং ফর্ম সাবমিট করবে
exports.submitBooking = async (req, res) => {
    try {
        const { 
            ownerToken, 
            clientName, 
            clientPhone, 
            clientEmail, 
            clientAddress,
            eventType, 
            eventDate, 
            eventShift, 
            venue, 
            notes 
        } = req.body;

        const owner = await prisma.user.findUnique({
            where: { publicBookingToken: ownerToken }
        });

        if (!owner) {
            return res.status(404).json({ 
                success: false, 
                message: "ভুল বুকিং লিঙ্ক! দয়া করে সঠিক লিঙ্ক ব্যবহার করুন।" 
            });
        }

        let client = await prisma.client.findFirst({
            where: { phone: clientPhone }
        });

        if (!client) {
            client = await prisma.client.create({
                data: {
                    ownerId: owner.id,
                    name: clientName,
                    phone: clientPhone,
                    email: clientEmail,
                    address: clientAddress,
                }
            });
        }

        const event = await prisma.event.create({
            data: {
                title: `${clientName} - ${eventType}`,
                type: eventType,         // ✅ এখন ডাটাবেসে এই ঘরটি আছে
                ownerId: owner.id,
                creatorId: owner.id,
                clientId: client.id,
                date: new Date(eventDate),
                shift: eventShift,
                venue: venue,
                notes: notes,
                status: 'PENDING', 
            }
        });

        await notificationController.sendNotification(
            owner.id, 
            'OPERATIONS', 
            `নতুন বুকিং রিকোয়েস্ট! ${clientName} ${eventDate} তারিখের জন্য রিকোয়েস্ট পাঠিয়েছেন।`, 
            `/bookings/${event.id}`
        );

        res.status(201).json({ 
            success: true, 
            message: "আপনার বুকিং রিকোয়েস্টটি সফলভাবে পাঠানো হয়েছে।" 
        });

    } catch (error) {
        console.error("Error in submitBooking:", error);
        res.status(500).json({ success: false, message: "সার্ভারে সমস্যা হয়েছে, আবার চেষ্টা করুন।" });
    }
};

exports.getPendingRequests = async (req, res) => {
    try {
        const ownerId = req.user.id; 
        const requests = await prisma.event.findMany({
            where: { ownerId: ownerId, status: 'PENDING' },
            include: { client: true },
            orderBy: { createdAt: 'desc' }
        });
        res.json({ success: true, data: requests });
    } catch (error) {
        res.status(500).json({ success: false, message: "রিকোয়েস্ট লিস্ট লোড করতে সমস্যা হয়েছে।" });
    }
};

exports.generateBookingToken = async (req, res) => {
    try {
        const userId = req.user.id;
        const token = `CP-${Math.random().toString(36).substring(2, 15).toUpperCase()}`;
        await prisma.user.update({
            where: { id: userId },
            data: { publicBookingToken: token }
        });
        res.json({ success: true, token: token, link: `https://clickerpro.app/book/${token}` });
    } catch (error) {
        res.status(500).json({ success: false, message: "টোকেন জেনারেট করা সম্ভব হয়নি।" });
    }
};
