const prisma = require('../lib/prisma');

/**
 * STATUS TRANSITION MAP
 * এটি হলো আমাদের অ্যাপের "ট্রাফিক সিগন্যাল"। 
 * এখানে নির্দিষ্ট করা আছে কোন স্ট্যাটাস থেকে কোন স্ট্যাটাসে যাওয়া সম্ভব।
 * এটি পরিবর্তন করলে পুরো অ্যাপের ওয়ার্কফ্লো বদলে যাবে।
 */
const STATUS_WORKFLOW = {
    'PENDING': ['CONFIRMED', 'CANCELLED'],
    'CONFIRMED': ['IN_PROGRESS', 'CANCELLED'],
    'IN_PROGRESS': ['SHOT_COMPLETE', 'CANCELLED'],
    'SHOT_COMPLETE': ['DELIVERED', 'CANCELLED'],
    'DELIVERED': ['COMPLETED'],
    'COMPLETED': [], // Terminal State: আর কোনো পরিবর্তন সম্ভব নয়
    'CANCELLED': [], // Terminal State: আর কোনো পরিবর্তন সম্ভব নয়
};

/**
 * @desc    বুকিংয়ের স্ট্যাটাস আপডেট করা
 * @route   PATCH /bookings/:id/status
 * @access  Private (Owner, Both, Freelancer)
 */
exports.updateStatus = async (req, res) => {
    try {
        const { id } = req.params;
        const { toStatus, note } = req.body;
        const { id: userId, role: userRole } = req.user;

        // ১. ইনপুট ভ্যালিডেশন: toStatus দেওয়া হয়েছে কি না?
        if (!toStatus) {
            return res.status(400).json({ success: false, message: "অনুগ্রহ করে নতুন স্ট্যাটাস (toStatus) প্রদান করুন।" });
        }

        // ২. বুকিং অস্তিত্ব চেক এবং সাথে সাথে অ্যাসাইনমেন্ট ডাটা নিয়ে আসা
        const event = await prisma.event.findUnique({
            where: { id },
            include: { assignments: true }
        });

        if (!event) {
            return res.status(404).json({ success: false, message: "বুকিংটি খুঁজে পাওয়া যায়নি।" });
        }

        const fromStatus = event.status;

        // ৩. স্টেট মেশিন ভ্যালিডেশন: এই পরিবর্তনটি কি বৈধ?
        const allowedTransitions = STATUS_WORKFLOW[fromStatus] || [];
        if (!allowedTransitions.includes(toStatus)) {
            return res.status(400).json({ 
                success: false, 
                message: `অবৈধ ট্রানজিশন! ${fromStatus} থেকে সরাসরি ${toStatus}-এ যাওয়া সম্ভব নয়।` 
            });
        }

        // ৪. রোল ভিত্তিক পারমিশন চেক (Role-Based Access Control)
        if (userRole === 'FREELANCER') {
            // ফ্রিল্যান্সার শুধু SHOT_COMPLETE -> DELIVERED করতে পারবে, যদি সে অ্যাসাইন করা থাকে
            if (!(fromStatus === 'SHOT_COMPLETE' && toStatus === 'DELIVERED')) {
                return res.status(403).json({ success: false, message: "ফ্রিল্যান্সার হিসেবে আপনি শুধুমাত্র 'শট কমপ্লিট' থেকে 'ডেলিভারি' স্ট্যাটাসে নিতে পারেন।" });
            }
            
            const isAssigned = event.assignments.some(a => a.userId === userId);
            if (!isAssigned) {
                return res.status(403).json({ success: false, message: "আপনি এই ইভেন্টের জন্য নিযুক্ত নন, তাই স্ট্যাটাস পরিবর্তন করতে পারবেন না।" });
            }
        }

        // ৫. বিজনেস রুলস (Strict Constraints)
        
        // নিয়ম ক: CONFIRMED করতে হলে অন্তত ১ জন স্টাফ অ্যাসাইন থাকতে হবে
        if (toStatus === 'CONFIRMED' && event.assignments.length === 0) {
            return res.status(400).json({ success: false, message: "বুকিং কনফার্ম করার আগে দয়া করে অন্তত একজনকে স্টাফ হিসেবে অ্যাসাইন করুন।" });
        }

        // নিয়ম খ: DELIVERED করতে হলে ড্রাইভ লিঙ্ক থাকতে হবে
        if (toStatus === 'DELIVERED' && !event.driveLink) {
            return res.status(400).json({ success: false, message: "ডেলিভারি স্ট্যাটাসে নিতে হলে আগে ড্রাইভ লিঙ্ক (Drive Link) আপডেট করুন।" });
        }

        // ৬. ডাটাবেস আপডেট (Atomic Transaction)
        // আমরা এখানে prisma.$transaction ব্যবহার করতে পারি যদি আরও জটিল কাজ থাকতো, তবে সাধারণ update-ই যথেষ্ট।
        const updatedEvent = await prisma.event.update({
            where: { id },
            data: {
                status: toStatus,
                statusUpdatedAt: new Date(),
                statusUpdatedBy: userId,
            }
        });

        // ৭. অডিট ট্রেইল (Status History) তৈরি করা
        await prisma.statusHistory.create({
            data: {
                eventId: id,
                fromStatus: fromStatus,
                toStatus: toStatus,
                changedBy: userId,
                changedAt: new Date(),
                note: note || "No note provided",
                changeType: toStatus === 'CANCELLED' ? 'CANCELLED' : 'CONFIRMED', // এটি Enum এর সাথে মিল রেখে সেট করা
            }
        });

        return res.status(200).json({ 
            success: true, 
            message: `বুকিং সফলভাবে ${toStatus} স্ট্যাটাসে আপডেট হয়েছে।`, 
            data: updatedEvent 
        });

    } catch (error) {
        console.error("Status Update Error:", error);
        return res.status(500).json({ success: false, message: "সার্ভারে অভ্যন্তরীণ সমস্যা হয়েছে। দয়া করে পরে চেষ্টা করুন।" });
    }
};

/**
 * @desc    বুকিংয়ের সম্পূর্ণ স্ট্যাটাস হিস্ট্রি দেখা
 * @route   GET /bookings/:id/history
 * @access  Private
 */
exports.getHistory = async (req, res) => {
    try {
        const { id } = req.params;

        const history = await prisma.statusHistory.findMany({
            where: { eventId: id },
            orderBy: { changedAt: 'desc' },
            include: {
                changedBy: {
                    select: { fullName: true, role: true } // কে পরিবর্তন করেছে তার নাম ও রোল
                }
            }
        });

        if (!history || history.length === 0) {
            return res.status(404).json({ success: false, message: "এই বুকিংয়ের কোনো হিস্ট্রি পাওয়া যায়নি।" });
        }

        return res.status(200).json({ success: true, data: history });
    } catch (error) {
        console.error("Get History Error:", error);
        return res.status(500).json({ success: false, message: "হিস্ট্রি লোড করতে সমস্যা হয়েছে।" });
    }
};

/**
 * @desc    বুকিং সম্পূর্ণ বাতিল করা
 * @route   POST /bookings/:id/cancel
 * @access  Private (Owner, Both Only)
 */
exports.cancelBooking = async (req, res) => {
    try {
        const { id } = req.params;
        const { cancellationReason } = req.body;
        const { id: userId, role: userRole } = req.user;

        // ১. পারমিশন চেক: শুধুমাত্র Owner বা Both রোল যাদের, তারা ক্যান্সেল করতে পারবে
        if (userRole !== 'OWNER' && userRole !== 'BOTH') {
            return res.status(403).json({ success: false, message: "বুকিং বাতিল করার অনুমতি শুধুমাত্র অ্যাডমিন বা ওনারের আছে।" });
        }

        const event = await prisma.event.findUnique({ where: { id } });
        if (!event) {
            return res.status(404).json({ success: false, message: "বুকিংটি খুঁজে পাওয়া যায়নি।" });
        }

        const fromStatus = event.status;

        // ২. ইভেন্ট আপডেট (Cancellation Metadata)
        await prisma.event.update({
            where: { id },
            data: {
                status: 'CANCELLED',
                cancellationReason: cancellationReason,
                cancelledAt: new Date(),
                cancelledBy: userId,
            }
        });

        // ৩. হিস্ট্রিতে রেকর্ড রাখা
        await prisma.statusHistory.create({
            data: {
                eventId: id,
                fromStatus: fromStatus,
                toStatus: 'CANCELLED',
                changedBy: userId,
                changedAt: new Date(),
                note: cancellationReason || "Cancelled by owner",
                changeType: 'CANCELLED',
            }
        });

        return res.status(200).json({ 
            success: true, 
            message: "বুকিংটি সফলভাবে বাতিল করা হয়েছে এবং রেকর্ড সংরক্ষণ করা হয়েছে।" 
        });

    } catch (error) {
        console.error("Cancel Booking Error:", error);
        return res.status(500).json({ success: false, message: "বুকিং বাতিল করতে সমস্যা হয়েছে।" });
    }
};
