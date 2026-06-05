// src/lib/prisma.js
//
// একটিমাত্র PrismaClient instance — পুরো অ্যাপের সব controller এটাই import করবে।
// (প্রতি controller-এ `new PrismaClient()` করলে connection leak হয়, তাই এটা ব্যবহার করুন।)

const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient({
  log: process.env.NODE_ENV === 'production'
    ? ['warn', 'error']
    : ['warn', 'error'],
});

// graceful shutdown — Node process বন্ধ হলে DB connection ঠিকঠাক বন্ধ করবে
process.on('beforeExit', async () => {
  await prisma.$disconnect();
});

module.exports = prisma;
