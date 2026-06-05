const prisma = require('../lib/prisma');

/**
 * @desc    নতুন রি-এডিট রিকোয়েস্ট তৈরি করা (Owner/Both only)
 * @route   POST /reedits
 * @access  Private (Owner, Both)
 */
exports.createReeditRequest = async (req, res) => {
    try {
        const { eventId, editorId, deliverable, notes, deadline } = req.body;
        const { role } = req.user;

        // ১. পারমিশন চেক: শুধুমাত্র ওনার বা অ্যাডমিন রি-এডিট রিকোয়েস্ট পাঠাতে পারে
        if (role !== 'OWNER' && role !== 'BOTH') {
            return res.status(403).json({ success: false, message: "আপনার রি-এডিট রিকোয়েস্ট তৈরি করার অনুমতি নেই।" });
        }

        // ২. ইভেন্ট অস্তিত্ব চেক
        const event = await prisma.event.findUnique({ where: { id: eventId } });
        if (!event) {
            return res.status(404).json({ success: false, message: "ইভেন্টটি খুঁজে পাওয়া যায়নি।" });
        }

        // ৩. রিকোয়েস্ট তৈরি করা
        const reeditRequest = await prisma.reEditRequest.create({
            data: {
                eventId,
                requestedBy: req.user.id,
                editorId,
                deliverable, // e.g., 'Photos', 'Video', 'Album'
                notes,
                round: 1,     // প্রথম রিকোয়েস্ট হলে Round 1
                status: 'PENDING',
                deadline: deadline ? new Date(deadline) : null,
            }
        });

        return res.status(201).json({ 
            success: true, 
            message: "রি-এডিট রিকোয়েস্টটি সফলভাবে পাঠানো হয়েছে।", 
            data: reeditRequest 
        });

    } catch (error) {
        console.error("Create Re-edit Error:", error);
        return res.status(500).json({ success: false, message: "রিকোয়েস্ট তৈরি করতে সমস্যা হয়েছে।" });
    }
};

/**
 * @desc    রি-এডিট রিকোয়েস্টের স্ট্যাটাস আপডেট করা (Editor/Owner)
 * @route   PATCH /reedits/:id/status
 * @access  Private
 */
exports.updateReeditStatus = async (req, res) => {
    try {
        const { id } = req.params;
        const { status, note } = req.body; // status: 'IN_PROGRESS', 'DONE'
        const userId = req.user.id;

        const request = await prisma.reEditRequest.findUnique({ where: { id } });
        if (!request) {
            return res.status(404).json({ success: false, message: "রিকোয়েস্টটি পাওয়া যায়নি।" });
        }

        // সিকিউরিটি: শুধুমাত্র নির্দিষ্ট এডিটর বা ওনার স্ট্যাটাস আপডেট করতে পারবে
        if (userId !== request.editorId && req.user.role !== 'OWNER' && req.user.role !== 'BOTH') {
            return res.status(403).json({ success: false, message: "আপনার এই রিকোয়েস্ট আপডেট করার অনুমতি নেই।" });
        }

        const updatedRequest = await prisma.reEditRequest.update({
            where: { id },
            data: { 
                status, 
                notes: note ? `${request.notes}\n\nUpdate: ${note}` : undefined 
            }
        });

        return res.status(200).json({ 
            success: true, 
            message: "স্ট্যাটাস সফলভাবে আপডেট করা হয়েছে।", 
            data: updatedRequest 
        });
    } catch (error) {
        console.error("Update Re-edit Error:", error);
        return res.status(500).json({ success: false, message: "আপডেট করতে সমস্যা হয়েছে।" });
    }
};

/**
 * @desc    ইউজারের সব রি-এডিট রিকোয়েস্ট দেখা
 * @route   GET /reedits/my-requests
 * @access  Private
 */
exports.getMyReeditRequests = async (req, res) => {
    try {
        const userId = req.user.id;
        const role = req.user.role;

        let requests;
        if (role === 'OWNER' || role === 'BOTH') {
            // ওনার তার তৈরি করা সব রিকোয়েস্ট দেখবে
            requests = await prisma.reEditRequest.findMany({
                where: { requestedBy: userId },
                orderBy: { id: 'desc' }
            });
        } else {
            // ফ্রিল্যান্সার/এডিটর তাকে পাঠানো রিকোয়েস্টগুলো দেখবে
            requests = await prisma.reEditRequest.findMany({
                where: { editorId: userId },
                orderBy: { id: 'desc' }
            });
        }

        return res.status(200).json({ success: true, data: requests });
    } catch (error) {
        return res.status(500).json({ success: false, message: "রিকোয়েস্ট লোড করতে সমস্যা হয়েছে।" });
    }
};
