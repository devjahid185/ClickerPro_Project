'use client';

import { useEffect, useState, useCallback } from 'react';
import Shell from '@/components/Shell';
import BarChart from '@/components/BarChart';
import { api, downloadFile } from '@/lib/api';

type Payment = {
  id: string;
  amount: number;
  currency: string;
  method: string;
  status: string;
  paidAt: string | null;
  note: string | null;
  user: { id: string; fullName: string; email: string } | null;
  booking: { id: string; title: string } | null;
};

type PaymentsResponse = {
  data: Payment[];
  total: number;
  totalAmount: number;
};

type Analytics = {
  signups: { month: string; count: number }[];
  bookings: { month: string; count: number }[];
  statusBreakdown: { status: string; count: number }[];
  topStudios: { ownerId: string; name: string; bookings: number }[];
};

function monthLabel(m: string) {
  const [, mm] = m.split('-');
  return ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][Number(mm)] || m;
}

const METHOD_COLOR: Record<string, string> = {
  CASH: 'green',
  BKASH: 'orange',
  NAGAD: 'orange',
  BANK: 'teal',
  CARD: 'teal',
  OTHER: 'gray',
};

export default function FinancePage() {
  const [payments, setPayments] = useState<Payment[]>([]);
  const [total, setTotal] = useState(0);
  const [totalAmount, setTotalAmount] = useState(0);
  const [analytics, setAnalytics] = useState<Analytics | null>(null);
  const [search, setSearch] = useState('');
  const [method, setMethod] = useState('');
  const [err, setErr] = useState('');

  const load = useCallback(async () => {
    setErr('');
    const params = new URLSearchParams({ limit: '50' });
    if (search) params.set('search', search);
    if (method) params.set('method', method);
    try {
      const r = await api<PaymentsResponse>(`/api/admin/payments?${params}`);
      setPayments(r.data);
      setTotal(r.total);
      setTotalAmount(r.totalAmount || 0);
    } catch (e: any) {
      setErr(e.message);
    }
  }, [search, method]);

  useEffect(() => {
    const t = setTimeout(load, 300);
    return () => clearTimeout(t);
  }, [load]);

  useEffect(() => {
    api<{ data: Analytics }>('/api/admin/analytics')
      .then((r) => setAnalytics(r.data))
      .catch(() => {});
  }, []);

  const completedPayments = payments.filter((p) => p.status === 'COMPLETED');
  const pendingPayments = payments.filter((p) => p.status === 'PENDING');
  const completedTotal = completedPayments.reduce((s, p) => s + p.amount, 0);
  const pendingTotal = pendingPayments.reduce((s, p) => s + p.amount, 0);

  return (
    <Shell>
      <h1 className="page-title">Finance</h1>
      <p className="page-sub">Revenue overview and payment transactions</p>

      {err && <div className="error">{err}</div>}

      {/* KPI cards */}
      <div className="cards" style={{ marginBottom: 28 }}>
        <div className="card">
          <div className="label">Total payments</div>
          <div className="value">{total}</div>
        </div>
        <div className="card">
          <div className="label">Total collected</div>
          <div className="value" style={{ fontSize: 20 }}>৳{totalAmount.toLocaleString()}</div>
        </div>
        <div className="card">
          <div className="label">This page — paid</div>
          <div className="value" style={{ fontSize: 20, color: 'var(--green)' }}>৳{completedTotal.toLocaleString()}</div>
        </div>
        <div className="card">
          <div className="label">This page — pending</div>
          <div className="value" style={{ fontSize: 20, color: 'var(--gold)' }}>৳{pendingTotal.toLocaleString()}</div>
        </div>
      </div>

      {/* Booking trend */}
      {analytics && (
        <div className="panel" style={{ padding: 20, marginBottom: 24 }}>
          <h3 style={{ marginBottom: 12 }}>Bookings created (6 mo)</h3>
          <BarChart
            data={analytics.bookings.map((b) => ({ label: monthLabel(b.month), value: b.count }))}
            color="var(--teal)"
          />
        </div>
      )}

      {/* Filters + table */}
      <div className="toolbar">
        <input
          placeholder="Search user, booking, note…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
        <select value={method} onChange={(e) => setMethod(e.target.value)} style={{ width: 160 }}>
          <option value="">All methods</option>
          {['CASH', 'BKASH', 'NAGAD', 'BANK', 'CARD', 'OTHER'].map((m) => (
            <option key={m} value={m}>{m}</option>
          ))}
        </select>
        <div className="spacer" />
        <button
          className="btn secondary"
          onClick={() => downloadFile('/api/admin/export/payments.csv', 'payments.csv').catch((e) => alert(e.message))}
        >
          ⬇ Export CSV
        </button>
      </div>

      <div className="panel">
        <table>
          <thead>
            <tr>
              <th>User</th>
              <th>Booking</th>
              <th>Method</th>
              <th>Amount</th>
              <th>Status</th>
              <th>Date</th>
            </tr>
          </thead>
          <tbody>
            {payments.map((p) => (
              <tr key={p.id}>
                <td>
                  {p.user ? (
                    <>
                      <div style={{ fontWeight: 600 }}>{p.user.fullName}</div>
                      <div className="muted">{p.user.email}</div>
                    </>
                  ) : '—'}
                </td>
                <td>{p.booking?.title || '—'}</td>
                <td>
                  <span className={`badge ${METHOD_COLOR[p.method] || 'gray'}`}>{p.method}</span>
                </td>
                <td><strong>৳{p.amount.toLocaleString()}</strong></td>
                <td>
                  <span className={`badge ${p.status === 'COMPLETED' ? 'green' : p.status === 'PENDING' ? 'gold' : 'gray'}`}>
                    {p.status}
                  </span>
                </td>
                <td className="muted">
                  {p.paidAt ? new Date(p.paidAt).toLocaleDateString() : '—'}
                </td>
              </tr>
            ))}
            {payments.length === 0 && (
              <tr><td colSpan={6} className="empty">No payments found</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </Shell>
  );
}
