'use client';

import { useEffect, useState, useCallback } from 'react';
import Shell from '@/components/Shell';
import { api, downloadFile } from '@/lib/api';

type Payment = {
  id: string; amount: number; kind: string; method: string;
  transactionId: string | null; date: string; note: string | null;
  event: {
    title: string;
    owner: { fullName: string; businessName: string | null } | null;
    client: { name: string } | null;
  } | null;
};

export default function PaymentsPage() {
  const [items, setItems] = useState<Payment[]>([]);
  const [total, setTotal] = useState(0);
  const [totalAmount, setTotalAmount] = useState(0);
  const [err, setErr] = useState('');

  const load = useCallback(async () => {
    setErr('');
    try {
      const r = await api<{ data: Payment[]; total: number; totalAmount: number }>('/api/admin/payments');
      setItems(r.data); setTotal(r.total); setTotalAmount(r.totalAmount);
    } catch (e: any) { setErr(e.message); }
  }, []);
  useEffect(() => { load(); }, [load]);

  return (
    <Shell>
      <div className="row" style={{ marginBottom: 8 }}>
        <div>
          <h1 className="page-title">Payments</h1>
          <p className="page-sub" style={{ margin: 0 }}>{total} payments · ৳{totalAmount.toLocaleString()} total</p>
        </div>
        <div className="spacer" />
        <button className="btn secondary" onClick={() => downloadFile('/api/admin/export/payments.csv', 'payments.csv').catch((e) => alert(e.message))}>
          ⬇ Export CSV
        </button>
      </div>
      <div style={{ height: 16 }} />
      {err && <div className="error">{err}</div>}
      <div className="panel">
        <table>
          <thead><tr><th>Date</th><th>Amount</th><th>Kind</th><th>Method</th><th>Booking</th><th>Studio</th></tr></thead>
          <tbody>
            {items.map((p) => (
              <tr key={p.id}>
                <td className="muted">{new Date(p.date).toLocaleDateString()}</td>
                <td><strong>৳{p.amount.toLocaleString()}</strong></td>
                <td><span className="badge teal">{p.kind}</span></td>
                <td>{p.method}</td>
                <td>{p.event?.title || '—'}</td>
                <td>{p.event?.owner?.businessName || p.event?.owner?.fullName || '—'}</td>
              </tr>
            ))}
            {items.length === 0 && <tr><td colSpan={6} className="empty">No payments</td></tr>}
          </tbody>
        </table>
      </div>
      <p className="muted" style={{ marginTop: 16 }}>
        💡 Grant PRO to a user manually (after off-platform payment) from the <strong>Users</strong> page → Make PRO.
      </p>
    </Shell>
  );
}
