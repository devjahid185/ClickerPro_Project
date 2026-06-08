// Shared API domain types for the ClickerPro admin panel.
//
// These mirror the admin API JSON shapes (camelCase, as produced by
// AdminController's mappers). Import these instead of `any` so backend
// shape changes surface at compile time.

export type UserRole = 'OWNER' | 'FREELANCER' | 'BOTH' | 'MANAGER' | 'ADMIN';
export type Plan = 'FREE' | 'PRO';

export interface AdminUser {
  id: string;
  email: string;
  fullName: string;
  phone: string | null;
  role: UserRole;
  plan: Plan;
  planExpiresAt: string | null;
  businessName: string | null;
  totalEvents: number;
  totalRevenueMinor?: number;
  deletedAt: string | null;
  createdAt: string;
}

export interface AdminStats {
  totalUsers: number;
  owners: number;
  freelancers: number;
  admins: number;
  totalBookings: number;
  totalClients: number;
  activeBroadcasts: number;
  openTickets: number;
  totalRevenueMinor: number;
}

export interface AdminBooking {
  id: string;
  title: string;
  type: string;
  date: string;
  status: string;
  venue: string;
  client: { name: string } | null;
  owner: { id: string; fullName: string; businessName: string | null } | null;
}

export interface AdminPayment {
  id: string;
  amount: number;
  kind: string;
  method: string;
  transactionId: string | null;
  date: string;
  note: string | null;
  event: {
    title: string;
    owner: { fullName: string; businessName: string | null } | null;
    client: { name: string } | null;
  } | null;
}

export interface ApiEnvelope<T> { data: T; total?: number; totalAmount?: number; }
