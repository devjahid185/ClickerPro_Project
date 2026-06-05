// scripts/seedFeatures.js
//
// Seeds the FeatureFlag registry. Every gateable feature starts with
// requiresPro = false (free for everyone), matching today's "all features
// free" policy. Admins later flip individual flags to paid from the panel.
//
// Idempotent: upserts by key, never downgrades an admin's manual change.
// Run: node scripts/seedFeatures.js

const prisma = require('../src/lib/prisma');

const FEATURES = [
  { key: 'reminders', label: 'Reminders', description: 'Payment / delivery / feedback reminders per booking' },
  { key: 'pdf_export', label: 'PDF Export', description: 'Export invoices, reports & sheets as PDF' },
  { key: 'waitlist', label: 'Waitlist', description: 'Manage prospective clients on a waitlist' },
  { key: 'analytics', label: 'Analytics & Reports', description: 'Earnings, cash flow & business reports' },
  { key: 'team', label: 'Team Management', description: 'Add team members & assign them to bookings' },
  { key: 'public_booking', label: 'Public Booking Link', description: 'Shareable public booking form' },
  { key: 'gear_rent', label: 'Gear & Rentals', description: 'Track gear inventory and rentals' },
  { key: 'delivery_checklist', label: 'Delivery Checklist', description: 'Step-by-step delivery checklist per booking' },
];

async function main() {
  for (const f of FEATURES) {
    await prisma.featureFlag.upsert({
      where: { key: f.key },
      update: { label: f.label, description: f.description }, // keep requiresPro as-is
      create: { ...f, requiresPro: false },
    });
    console.log(`✓ ${f.key}`);
  }
  console.log(`\nSeeded ${FEATURES.length} feature flags (all free).`);
}

main()
  .catch((e) => {
    console.error('Seed features failed:', e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
