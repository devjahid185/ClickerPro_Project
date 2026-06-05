const prisma = require('../lib/prisma');

/**
 * @desc    ইভেন্টের জন্য প্রফেশনাল ইনভয়েস তৈরি করা (VAT সহ)
 * @route   POST /invoices/generate
 * @access  Private (Owner, Both)
 */
exports.generateInvoice = async (req, res) => {
    try {
        const { eventId, subtotal, amountPaid } = req.body;
        const { id: userId, role: userRole } = req.user;

        // ১. পারমিশন চেক: শুধুমাত্র ওনার বা অ্যাডমিন ইনভয়েস তৈরি করতে পারবে
        if (userRole !== 'OWNER' && userRole !== 'BOTH') {
            return res.status(403).json({ success: false, message: "আপনার ইনভয়েস তৈরি করার অনুমতি নেই।" });
        }

        // ২. ইনপুট ভ্যালিডেশন
        if (!eventId || subtotal === undefined || amountPaid === undefined) {
            return res.status(400).json({ success: false, message: "eventId, subtotal এবং amountPaid প্রদান করা বাধ্যতামূলক।" });
        }

        // ৩. ইভেন্ট এবং ওনারের প্রোফাইল ডাটা একসাথে আনা
        const event = await prisma.event.findUnique({
            where: { id: eventId },
            include: { 
                owner: true // ওনারের VAT সেটিংস চেক করার জন্য
            }
        });

        if (!event) {
            return res.status(404).json({ success: false, message: "ইভেন্টটি খুঁজে পাওয়া যায়নি।" });
        }

        const owner = event.owner;
        let vatAmount = 0;

        // ৪. VAT ক্যালকুলেশন লজিক
        if (owner && owner.vatEnabled) {
            vatAmount = (subtotal * owner.vatPercentage) / 100;
        }

        // ৫. ফাইনাল ক্যালকুলেশন
        const totalAmount = subtotal + vatAmount;
        const balanceDue = totalAmount - amountPaid;

        // ৬. ইনভয়েস স্ট্যাটাস নির্ধারণ
        let status = "Due";
        if (balanceDue <= 0) {
            status = "Paid";
        } else if (amountPaid > 0) {
            status = "Partial";
        }

        // ৭. ইনভয়েস নম্বর তৈরি
        const year = new Date().getFullYear();
        const randomNum = Math.floor(1000 + Math.random() * 9000);
        const invoiceNumber = `CP-${year}-${randomNum}`;

        // ৮. ডাটাবেসে ইনভয়েস সেভ করা
        // এখানে আমরা только সেই ফিল্ডগুলো ব্যবহার করছি যা আপনার schema.prisma তে আছে
        const invoice = await prisma.invoice.upsert({
            where: { eventId: eventId }, 
            update: {
                invoiceNumber,
                subtotal,
                vatAmount,
                totalAmount,
                amountPaid,
                balanceDue,
                status,
            },
            create: {
                invoiceNumber,
                eventId,
                subtotal,
                vatAmount,
                totalAmount,
                amountPaid,
                balanceDue,
                status,
                language: owner.language || 'en',
            }
        });

        return res.status(200).json({ 
            success: true, 
            message: "ইনভয়েস সফলভাবে তৈরি হয়েছে।", 
            data: invoice 
        });

    } catch (error) {
        console.error("Invoice Generation Error:", error);
        return res.status(500).json({ success: false, message: "ইনভয়েস তৈরি করতে সার্ভারে সমস্যা হয়েছে।" });
    }
};

/**
 * @desc    নির্দিষ্ট ইভেন্টের ইনভয়েস দেখা
 * @route   GET /invoices/event/:id
 * @access  Private
 */
exports.getEventInvoice = async (req, res) => {
    try {
        const { id } = req.params;

        const invoice = await prisma.invoice.findUnique({
            where: { eventId: id },
            include: {
                event: {
                    include: {
                        client: true,
                        owner: true
                    }
                }
            }
        });

        if (!invoice) {
            return res.status(404).json({ success: false, message: "এই ইভেন্টের জন্য কোনো ইনভয়েস পাওয়া যায়নি।" });
        }

        return res.status(200).json({ success: true, data: invoice });
    } catch (error) {
        console.error("Get Invoice Error:", error);
        return res.status(500).json({ success: false, message: "ইনভয়েস লোড করতে সমস্যা হয়েছে।" });
    }
};
