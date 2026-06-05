// scripts/seedAdmin.js
//
// Creates (or promotes) the first ADMIN account. ADMIN is NOT
// self-registrable via /api/auth/register, so the very first admin must
// be bootstrapped here.
//
// Usage:
//   node scripts/seedAdmin.js admin@clickerpro.app StrongPass123 "Super Admin"
//
// If the email already exists, it is promoted to ADMIN (password unchanged
// unless you pass a new one).

const prisma = require('../src/lib/prisma');
const bcrypt = require('bcryptjs');

async function main() {
  const [, , emailArg, passwordArg, ...nameParts] = process.argv;
  const email = emailArg || 'admin@clickerpro.app';
  const password = passwordArg || 'Admin123!';
  const fullName = nameParts.join(' ') || 'Super Admin';

  const existing = await prisma.user.findUnique({ where: { email } });

  if (existing) {
    const updated = await prisma.user.update({
      where: { email },
      data: { role: 'ADMIN', deletedAt: null },
    });
    console.log(`✓ Promoted existing user to ADMIN: ${updated.email}`);
  } else {
    const hashed = await bcrypt.hash(password, 10);
    const user = await prisma.user.create({
      data: { email, password: hashed, fullName, role: 'ADMIN' },
    });
    console.log(`✓ Created ADMIN: ${user.email}`);
    console.log(`  Password: ${password}`);
  }
}

main()
  .catch((e) => {
    console.error('Seed admin failed:', e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
