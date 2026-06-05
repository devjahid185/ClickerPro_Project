const prisma = require('../lib/prisma');

exports.globalSearch = async (req, res) => {
    try {
        // কুয়েরি থেকে সব ফিল্টার নেওয়া হচ্ছে
        const { q, status, type, startDate, endDate } = req.query; 
        const userId = req.user.id;

        // যদি সার্চ বক্সে কিছু লেখা না থাকে এবং কোনো ফিল্টারও না থাকে, তবে এরর দেবে
        if (!q && !status && !type && !startDate) {
            return res.status(400).json({ 
                success: false, 
                message: "অনুগ্রহ করে কিছু লিখে সার্চ করুন অথবা ফিল্টার ব্যবহার করুন।" 
            });
        }

        // --- ১. ক্লায়েন্ট সার্চ ফিল্টার তৈরি ---
        const clientFilter = {
            ownerId: userId,
            where: {
                OR: [
                    { name: { contains: q || '', mode: 'insensitive' } },
                    { phone: { contains: q || '', mode: 'insensitive' } },
                ]
            }
        };

        // --- ২. ইভেন্ট সার্চ ফিল্টার তৈরি (Advanced) ---
        const eventWhere = {
            ownerId: userId,
            AND: [] // এখানে সব শর্ত জমা হবে
        };

        // যদি নাম বা ভেন্যু দিয়ে সার্চ করে
        if (q) {
            eventWhere.AND.push({
                OR: [
                    { title: { contains: q, mode: 'insensitive' } },
                    { venue: { contains: q, mode: 'insensitive' } },
                ]
            });
        }

        // যদি স্ট্যাটাস দিয়ে ফিল্টার করে (যেমন: PENDING)
        if (status) {
            eventWhere.AND.push({ status: status });
        }

        // যদি ইভেন্ট টাইপ দিয়ে ফিল্টার করে (যেমন: Wedding)
        if (type) {
            eventWhere.AND.push({ type: type });
        }

        // যদি তারিখের রেঞ্জ দেওয়া হয় (startDate এবং endDate)
        if (startDate && endDate) {
            eventWhere.AND.push({
                date: {
                    gte: new Date(startDate), // Greater than or equal to
                    lte: new Date(endDate)    // Less than or equal to
                }
            });
        }

        // এবার সব জায়গায় একসাথে সার্চ করা হবে
        const [clients, events, users, packages] = await Promise.all([
            prisma.client.findMany({
                where: {
                    OR: [
                        { name: { contains: q || '', mode: 'insensitive' } },
                        { phone: { contains: q || '', mode: 'insensitive' } },
                    ],
                    ownerId: userId
                }
            }),
            prisma.event.findMany({
                where: eventWhere
            }),
            prisma.user.findMany({
                where: { fullName: { contains: q || '', mode: 'insensitive' } }
            }),
            prisma.package.findMany({
                where: {
                    name: { contains: q || '', mode: 'insensitive' },
                    ownerId: userId
                }
            })
        ]);

        res.json({
            success: true,
            filters: { q, status, type, startDate, endDate },
            results: {
                clients: clients,
                events: events,
                teamMembers: users,
                packages: packages
            },
            summary: {
                totalClients: clients.length,
                totalEvents: events.length,
                totalMembers: users.length,
                totalPackages: packages.length
            }
        });

    } catch (error) {
        console.error("Advanced Search Error:", error);
        res.status(500).json({ 
            success: false, 
            message: "সার্চ ফিল্টারিং করতে সমস্যা হয়েছে।" 
        });
    }
};
