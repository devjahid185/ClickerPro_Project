const prisma = require('../lib/prisma');

/**
 * MOD-34: Extra Time Management
 * এই কন্ট্রোলারটি ইভেন্টের অতিরিক্ত কাজের সময় আপডেট এবং ট্র্যাক করে।
 * শুধুমাত্র ওনার এবং ম্যানেজার এই তথ্য পরিবর্তন করতে পারবেন।
 */

// ১. এক্সট্রা টাইম আপডেট করা (SURELY SECURE)
exports.updateExtraTime = async (req, res) => {
    try {
        const { eventId, hours } = req.body;
        const userId = req.user.id;
        const userRole = req.user.role;

        // 🛡️ সিকিউরিটি চেক ১: শুধুমাত্র OWNER, BOTH অথবা MANAGER এক্সট্রা টাইম বসাতে পারবে
        const allowedRoles = ['OWNER', 'BOTH', 'MANAGER'];
        if (!allowedRoles.includes(userRole)) {
            return res.status(403).json({ 
                success: false, 
                message: "আপনার এই তথ্য পরিবর্তন করার অনুমতি নেই। শুধুমাত্র ওনার বা ম্যানেজার এটি করতে পারেন।" 
            });
        }

        // 🛡️ ইনপুট ভ্যালিডেশন: ঘণ্টা অবশ্যই একটি পজিটিভ নাম্বার হতে হবে
        if (hours === undefined || isNaN(hours) || hours < 0) {
            return res.status(400).json({ 
                success: false, 
                message: "অনুগ্রহ করে সঠিক ঘণ্টার পরিমাণ দিন (০ এর বেশি নাম্বার হতে হবে)।" 
            });
        }

        // ইভেন্টটি ডাটাবেসে আছে কি না চেক করা
        const event = await prisma.event.findUnique({
            where: { id: eventId }
        });

        if (!event) {
            return res.status(404).json({ success: false, message: "ইভেন্টটি খুঁজে পাওয়া যায়নি।" });
        }

        // 🛡️ সিকিউরিটি চেক ২: ইউজার কি ওই ইভেন্টের ওনার বা ওই ওনারের টিমের সদস্য?
        if (event.ownerId !== userId) {
            // যদি ইউজার ম্যানেজার হয়, তবে চেক করে দেখব সে ওই ওনারের টিমে আছে কি না
            const isTeamMember = await prisma.teamMembership.findFirst({
                where: {
                    userId: userId,
                    ownerId: event.ownerId
                }
            });

            if (!isTeamMember) {
                return res.status(403).json({ 
                    success: false, 
                    message: "আপনি এই ইভেন্টের এক্সট্রা টাইম আপডেট করার অনুমতিপ্রাপ্ত নন।" 
                });
            }
        }

        // ডাটাবেসে এক্সট্রা আওয়ার আপডেট করা
        const updatedEvent = await prisma.event.update({
            where: { id: eventId },
            data: { extraHours: parseFloat(hours) }
        });

        res.json({ 
            success: true, 
            message: "অতিরিক্ত সময় সফলভাবে আপডেট করা হয়েছে।", 
            data: { 
                eventId: updatedEvent.id,
                extraHours: updatedEvent.extraHours 
            }
        });

    } catch (error) {
        console.error("Extra Time Update Error:", error);
        res.status(500).json({ success: false, message: "সার্ভারে সমস্যা হয়েছে, আবার চেষ্টা করুন।" });
    }
};

// ২. ইভেন্টের বর্তমান এক্সট্রা টাইম দেখা
exports.getExtraTime = async (req, res) => {
    try {
        const { eventId } = req.params;

        const event = await prisma.event.findUnique({
            where: { id: eventId },
            select: { 
                id: true,
                title: true, 
                extraHours: true 
            }
        });

        if (!event) {
            return res.status(404).json({ success: false, message: "ইভেন্টটি পাওয়া যায়নি।" });
        }

        res.json({ success: true, data: event });
    } catch (error) {
        console.error("Get Extra Time Error:", error);
        res.status(500).json({ success: false, message: "তথ্য লোড করতে সমস্যা হয়েছে।" });
    }
};
