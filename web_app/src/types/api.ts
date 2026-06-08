// Shared API domain types for the ClickerPro web app.
//
// These mirror the backend JSON shapes (snake_case as returned by Laravel /
// the API Resources). Import these instead of using `any` so a backend field
// rename surfaces as a TypeScript error rather than a silent runtime bug.
//
// Note: fields are intentionally permissive (optional) where the API may omit
// them, matching the current defensive access patterns in the pages.

export type BookingStatus =
  | 'PENDING' | 'CONFIRMED' | 'IN_PROGRESS' | 'SHOT_COMPLETE'
  | 'DELIVERED' | 'COMPLETED' | 'CANCELLED';

export type Shift = 'DAY' | 'NIGHT' | 'BOTH';

export type PaymentKind = 'ADVANCE' | 'DUE' | 'EXTRA' | 'PAYOUT';
export type PaymentMethod = 'CASH' | 'BKASH' | 'NAGAD' | 'BANK' | 'CARD' | 'OTHER';

export interface Client {
  id: number;
  owner_id?: number;
  name: string;
  phone?: string | null;
  email?: string | null;
  notes?: string | null;
  dob?: string | null;
  anniversary?: string | null;
  created_at?: string;
}

export interface Booking {
  id: number;
  owner_id?: number;
  client_id?: number | null;
  package_id?: number | null;
  title: string;
  event_type?: string | null;
  date: string;
  venue?: string | null;
  shift: Shift;
  status: BookingStatus;
  price?: number | string | null;
  advance_paid?: number | string | null;
  due_amount?: number | string | null;
  notes?: string | null;
  internal_notes?: string | null;
  // Flattened convenience fields from BookingResource:
  client_name?: string | null;
  client_phone?: string | null;
  client?: Client | null;
  created_at?: string;
  updated_at?: string;
  // camelCase aliases the UI accesses defensively (may be absent at runtime;
  // declared so existing `b.eventType || b.event_type` fallbacks type-check).
  eventType?: string | null;
  clientName?: string | null;
  clientPhone?: string | null;
  advance?: number | string | null;
}

export interface Payment {
  id: number;
  event_id: number;
  amount: number | string;
  kind: PaymentKind;
  method: PaymentMethod;
  note?: string | null;
  paid_at?: string | null;
  created_at?: string;
  event?: { id: number; title: string; client?: Client | null } | null;
}

export interface Invoice {
  id: number;
  event_id: number;
  owner_id?: number;
  subtotal: number | string;
  tax_rate?: number | string;
  tax_amount?: number | string;
  total: number | string;
  status: 'DRAFT' | 'SENT' | 'PAID' | 'OVERDUE';
  notes?: string | null;
  language?: string;
  created_at?: string;
  event?: Booking | null;
}

export interface Expense {
  id: number;
  owner_id?: number;
  event_id?: number | null;
  title: string;
  amount: number | string;
  category: string;
  note?: string | null;
  date: string;
}

// Laravel wraps single/many results as { data: ... }.
export interface ApiEnvelope<T> { data: T; total?: number; }

/** Unwrap an API response that may be raw, or wrapped in { data }. */
export function unwrap<T>(res: unknown): T {
  if (res && typeof res === 'object' && 'data' in (res as Record<string, unknown>)) {
    return (res as { data: T }).data;
  }
  return res as T;
}

/** Unwrap to an array, tolerating raw arrays or { data: [...] }. */
export function unwrapList<T>(res: unknown): T[] {
  if (Array.isArray(res)) return res as T[];
  const data = (res as { data?: unknown })?.data;
  return Array.isArray(data) ? (data as T[]) : [];
}
