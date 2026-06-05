// src/lib/roles.js
//
// Flutter app lowercase role পাঠায় (owner / freelancer / both / manager / admin)।
// Prisma schema uppercase enum expect করে (OWNER / FREELANCER / ...)।
// এই helper দুটো convention এর মাঝে translate করে।

const VALID_ROLES = ['OWNER', 'FREELANCER', 'BOTH', 'MANAGER', 'ADMIN'];
const SELF_REGISTRABLE = ['OWNER', 'FREELANCER', 'BOTH'];

function normalizeRole(input) {
  if (!input) return null;
  const upper = String(input).trim().toUpperCase();
  return VALID_ROLES.includes(upper) ? upper : null;
}

function denormalizeRole(role) {
  // wire format ছোট হাতের — Flutter এ যেমন আসে তেমন ফিরে যায়
  return role ? String(role).toLowerCase() : null;
}

function isSelfRegistrable(role) {
  return SELF_REGISTRABLE.includes(role);
}

module.exports = {
  VALID_ROLES,
  SELF_REGISTRABLE,
  normalizeRole,
  denormalizeRole,
  isSelfRegistrable,
};
