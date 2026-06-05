const prisma = require('../lib/prisma');

/**
 * @desc    কাজের প্রগ্রেস আপডেট করা (যেমন: ২০% কাজ শেষ)
 * @route   PATCH /tasks/progress
 * @access  Private (Freelancer, Owner, Both)
 */
exports.updateProgress = async (req, res) => {
    try {
        const { eventId, percentage, note } = req.body;
        const userId = req.user.id;

        // ১. ইনপুট ভ্যালিডেশন: পার্সেন্টেজ দেওয়া হয়েছে কি না?
        if (percentage === undefined) {
            return res.status(400).json({ 
                success: false, 
                message: "অনুগ্রহ করে কাজের পার্সেন্টেজ (percentage) প্রদান করুন।" 
            });
        }

        // ২. ভ্যালিডেশন: পার্সেন্টেজ কি ০ থেকে ১০০ এর মধ্যে?
        if (percentage < 0 || percentage > 100) {
            return res.status(400).json({ 
                success: false, 
                message: "পার্সেন্টেজ অবশ্যই ০ থেকে ১০০ এর মধ্যে হতে হবে।" 
            });
        }

        // ৩. সিকিউরিটি চেক: এই ইউজার কি এই ইভেন্টের জন্য অ্যাসাইন করা আছে?
        // যদি ইউজার অ্যাসাইন করা না থাকে, তবে সে প্রগ্রেস আপডেট করতে পারবে না।
        const assignment = await prisma.assignment.findFirst({
            where: { 
                eventId: eventId, 
                userId: userId 
            }
        });

        if (!assignment) {
            return res.status(403).json({ 
                success: false, 
                message: "আপনি এই ইভেন্টের জন্য নিযুক্ত নন, তাই প্রগ্রেস আপডেট করতে পারবেন না।" 
            });
        }

        // ৪. প্রগ্রেস আপডেট করা (Upsert)
        // Upsert মানে: যদি ডাটা থাকে তবে আপডেট করো, না থাকলে নতুন তৈরি করো।
        const progress = await prisma.taskProgress.upsert({
            where: {
                eventId_userId: { 
                    eventId: eventId, 
                    userId: userId 
                }
            },
            update: {
                percentage,
                note,
            },
            create: {
                eventId,
                userId,
                percentage,
                note,
            }
        });

        return res.status(200).json({ 
            success: true, 
            message: "কাজের প্রগ্রেস সফলভাবে আপডেট করা হয়েছে।", 
            data: progress 
        });

    } catch (error) {
        console.error("Update Progress Error:", error);
        return res.status(500).json({ 
            success: false, 
            message: "প্রগ্রেস আপডেট করতে সার্ভারে সমস্যা হয়েছে।" 
        });
    }
};

/**
 * @desc    একটি ইভেন্টের সকল স্টাফদের প্রগ্রেস রিপোর্ট দেখা
 * @route   GET /tasks/event/:id
 * @access  Private (Owner, Both Only)
 */
exports.getEventProgress = async (req, res) => {
    try {
        const { id } = req.params;
        const { role } = req.user;

        // সিকিউরিটি: শুধুমাত্র ওনার বা অ্যাডমিন রিপোর্ট দেখতে পারবে
        if (role !== 'OWNER' && role !== 'BOTH') {
            return res.status(403).json({ 
                success: false, 
                message: "শুধুমাত্র ওনার বা অ্যাডমিন প্রগ্রেস রিপোর্ট দেখতে পারবেন।" 
            });
        }

        // ওই ইভেন্টের সব স্টাফদের প্রগ্রেস লিস্ট আনা
        const progressList = await prisma.taskProgress.findMany({
            where: { eventId: id },
            include: {
                user: { 
                    select: { fullName: true, email: true } // ইউজারের নাম ও ইমেইল নেওয়া হচ্ছে
                }
            }
        });

        return res.status(200).json({ 
            success: true, 
            count: progressList.length,
            data: progressList 
        });
    } catch (error) {
        console.error("Get Progress Error:", error);
        return res.status(500).json({ 
            success: false, 
            message: "প্রগ্রেস রিপোর্ট লোড করতে সমস্যা হয়েছে।" 
        });
    }
};
