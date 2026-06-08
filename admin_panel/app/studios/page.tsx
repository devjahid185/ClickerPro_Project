'use client';

import { useEffect, useState, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import Shell from '@/components/Shell';
import { api } from '@/lib/api';

type Studio = {
  id: string;
  email: string;
  fullName: string;
  businessName: string | null;
  businessAddress: string | null;
  phone: string | null;
  plan: string;
  totalEvents: number;
  totalClients: number;
  totalRevenueMinor: number;
  deletedAt: string | null;
  createdAt: string;
};

export default function StudiosPage() {
  const router = useRouter();
  const [studios, setStudios] = useState<Studio[]>([]);
  const [total, setTotal] = useState(0);
  const [search, setSearch] = useState('');
  const [err, setErr] = useState('');

  const load = useCallback(async () => {
    setErr('');
    const params = new URLSearchParams({ role: 'OWNER' });
    if (search) params.set('search', search);
    try {
      const r = await api<{ data: Studio[]; total: number }>(`/api/admin/users?${params}`);
      setStudios(r.data);
      setTotal(r.total);
    } catch (e: any) {
      setErr(e.message);
    }
  }, [search]);

  useEffect(() => {
    const t = setTimeout(load, 300);
    return () => clearTimeout(t);
  }, [load]);

  const totalRevenue = studios.reduce((s, st) => s + (st.totalRevenueMinor || 0), 0);

  return (
    <Shell>
      <h1 className="page-title">Businesses</h1>
      <p className="page-sub">{total} registered businesses · ৳{(totalRevenue / 100).toLocaleString()} total revenue</p>

      <div className="toolbar">
        <input
          placeholder="Search business name, owner, email…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
        <div className="spacer" />
      </div>

      {err && <div className="error">{err}</div>}

      <div className="panel">
        <table>
          <thead>
            <tr>
              <th>Business / Owner</th>
              <th>Contact</th>
              <th>Plan</th>
              <th>Bookings</th>
              <th>Clients</th>
              <th>Revenue</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {studios.map((s) => (
              <tr key={s.id} style={{ cursor: 'pointer' }} onClick={() => router.push(`/users/${s.id}`)}>
                <td>
                  <strong style={{ color: 'var(--orange)' }}>{s.businessName || s.fullName}</strong>
                  <div className="muted">{s.fullName}</div>
                </td>
                <td>
                  <div>{s.email}</div>
                  {s.phone && <div className="muted">{s.phone}</div>}
                </td>
                <td>
                  <span className={`badge ${s.plan === 'PRO' ? 'gold' : 'gray'}`}>{s.plan}</span>
                </td>
                <td>{s.totalEvents}</td>
                <td>{s.totalClients}</td>
                <td>৳{((s.totalRevenueMinor || 0) / 100).toLocaleString()}</td>
                <td>
                  {s.deletedAt ? (
                    <span className="badge red">Suspended</span>
                  ) : (
                    <span className="badge green">Active</span>
                  )}
                </td>
              </tr>
            ))}
            {studios.length === 0 && (
              <tr><td colSpan={7} className="empty">No businesses found</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </Shell>
  );
}
