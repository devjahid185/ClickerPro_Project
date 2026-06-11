'use client';

import { useEffect, useState, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import Shell from '@/components/Shell';
import { api, downloadFile } from '@/lib/api';

type Booking = {
  id: string;
  title: string;
  type: string;
  date: string;
  status: string;
  venue: string;
  client: { name: string } | null;
  owner: { id: string; fullName: string; businessName: string | null } | null;
};

const STATUSES = [
  'PENDING', 'CONFIRMED', 'IN_PROGRESS', 'SHOT_COMPLETE', 'DELIVERED', 'COMPLETED', 'CANCELLED',
];

function statusBadge(s: string) {
  const map: Record<string, string> = {
    PENDING: 'gold',
    CONFIRMED: 'teal',
    IN_PROGRESS: 'orange',
    SHOT_COMPLETE: 'teal',
    DELIVERED: 'green',
    COMPLETED: 'green',
    CANCELLED: 'red',
  };
  return <span className={`badge ${map[s] || 'gray'}`}>{s}</span>;
}

export default function BookingsPage() {
  const router = useRouter();
  const [items, setItems] = useState<Booking[]>([]);
  const [total, setTotal] = useState(0);
  const [search, setSearch] = useState('');
  const [status, setStatus] = useState('');
  const [err, setErr] = useState('');

  const load = useCallback(async () => {
    setErr('');
    const params = new URLSearchParams();
    if (search) params.set('search', search);
    if (status) params.set('status', status);
    try {
      const r = await api<{ data: Booking[]; total: number }>(`/api/admin/bookings?${params}`);
      setItems(r.data);
      setTotal(r.total);
    } catch (e: any) {
      setErr(e.message);
    }
  }, [search, status]);

  useEffect(() => {
    const t = setTimeout(load, 300);
    return () => clearTimeout(t);
  }, [load]);

  return (
    <Shell>
      <h1 className="page-title">Bookings</h1>
      <p className="page-sub">{total} bookings across all businesses</p>

      <div className="toolbar">
        <input
          placeholder="Search title, venue, client, owner…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
        <select value={status} onChange={(e) => setStatus(e.target.value)}>
          <option value="">All statuses</option>
          {STATUSES.map((s) => <option key={s} value={s}>{s}</option>)}
        </select>
        <div className="spacer" />
        <button
          className="btn secondary"
          onClick={() => downloadFile('/api/admin/export/bookings.csv', 'bookings.csv').catch((e) => alert(e.message))}
        >
          ⬇ Export CSV
        </button>
      </div>

      {err && <div className="error">{err}</div>}

      <div className="panel">
        <table>
          <thead>
            <tr>
              <th>Booking</th>
              <th>Business / Owner</th>
              <th>Client</th>
              <th>Date</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {items.map((b) => (
              <tr key={b.id}>
                <td><strong>{b.title}</strong><div className="muted">{b.type} · {b.venue}</div></td>
                <td>
                  {b.owner ? (
                    <span
                      onClick={() => router.push(`/users/${b.owner!.id}`)}
                      style={{ cursor: 'pointer', color: 'var(--orange)', fontWeight: 600 }}
                    >
                      {b.owner?.businessName || b.owner?.fullName || '—'}
                    </span>
                  ) : '—'}
                </td>
                <td>{b.client?.name || '—'}</td>
                <td>{new Date(b.date).toLocaleDateString()}</td>
                <td>{statusBadge(b.status)}</td>
              </tr>
            ))}
            {items.length === 0 && (
              <tr><td colSpan={5} className="empty">No bookings found</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </Shell>
  );
}
