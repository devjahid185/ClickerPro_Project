// src/lib/userPresenter.js
//
// Database থেকে আসা User row কে Flutter app যে shape এ expect করে সেই
// JSON এ rূপান্তর করে।  সব auth/profile endpoint একই presenter ব্যবহার করবে
// যাতে field naming সর্বত্র consistent থাকে।

const { denormalizeRole } = require('./roles');

function presentUser(user) {
  if (!user) return null;
  return {
    id: user.id,
    remoteId: user.id,
    name: user.fullName || '',
    email: user.email || '',
    phone: user.phone || null,
    whatsapp: user.whatsapp || null,
    role: denormalizeRole(user.role),
    avatarUrl: user.avatarUrl || null,
    bio: user.bio || null,
    specialization: user.specialization || null,
    vatBin: user.vatBin || null,
    studioAddress: user.businessAddress || null,
    companyName: user.businessName || null,
    bkash: user.bkash || null,
    bankDetails: user.bankDetails ? JSON.stringify(user.bankDetails) : null,
    signatureUrl: user.signatureUrl || null,
    logoUrl: user.logoUrl || null,
    ownerId: user.ownerId || null,
    deletedAt: user.deletedAt ? user.deletedAt.toISOString() : null,
    // Lifetime stats — Phase 2 এ live values আসবে; এখন zero placeholders
    totalEvents: user.totalEvents ?? 0,
    totalRevenueMinor: user.totalRevenueMinor ?? 0,
    totalClients: user.totalClients ?? 0,
    statsRefreshedAt: user.statsRefreshedAt
      ? user.statsRefreshedAt.toISOString()
      : null,
  };
}

// Profile select — getProfile / updateProfile এ ব্যবহার্য সব column
const USER_SELECT = {
  id: true,
  email: true,
  fullName: true,
  phone: true,
  whatsapp: true,
  role: true,
  ownerId: true,
  language: true,
  distributionOn: true,
  logoUrl: true,
  signatureUrl: true,
  avatarUrl: true,
  bio: true,
  specialization: true,
  bkash: true,
  businessName: true,
  businessAddress: true,
  vatEnabled: true,
  vatPercentage: true,
  vatBin: true,
  notificationPrefs: true,
  bankDetails: true,
  deletedAt: true,
  totalEvents: true,
  totalRevenueMinor: true,
  totalClients: true,
  statsRefreshedAt: true,
  createdAt: true,
  updatedAt: true,
};

module.exports = { presentUser, USER_SELECT };
