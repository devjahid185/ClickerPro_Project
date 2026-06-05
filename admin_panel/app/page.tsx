'use client';

import { useEffect, useState } from 'react';
import Shell from '@/components/Shell';
import BarChart from '@/components/BarChart';
import { api } from '@/lib/api';

type Stats = {
  totalUsers: number;
  owners: number;
  freelancers: number;
  admins: number;
  totalBookings: number;
  totalClients: number;
  activeBroadcasts: number;
  openTickets: number;
  totalRevenueMinor: number;
};

type Analytics = {
  signups: { month: string; count: number }[];
  bookings: { month: string; count: number }[];
  statusBreakdown: { status: string; count: number }[];
  topStudios: { ownerId: string; name: string; bookings: number }[];
};

const CARDS: { key: keyof Stats; label: string }[] = [
  { key: 'totalUsers', label: 'Total Users' },
  { key: 'owners', label: 'Owners' },
  { key: 'freelancers', label: 'Freelancers' },
  { key: 'admins', label: 'Admins' },
  { key: 'totalBookings', label: 'Bookings' },
  { key: 'totalClients', label: 'Clients' },
  { key: 'activeBroadcasts', label: 'Active Broadcasts' },
  { key: 'openTickets', label: 'Open Tickets' },
];

// "2026-06" → "Jun"
function monthLabel(m: string) {
  const [, mm] = m.split('-');
  return ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][Number(mm)] || m;
}

export default function Dashboard() {
  const [stats, setStats] = useState<Stats | null>(null);
  const [analytics, setAnalytics] = useState<Analytics | null>(null);
  const [err, setErr] = useState('');

  useEffect(() => {
    api<{ data: Stats }>('/api/admin/stats').then((r) => setStats(r.data)).catch((e) => setErr(e.message));
    api<{ data: Analytics }>('/api/admin/analytics').then((r) => setAnalytics(r.data)).catch(() => {});
  }, []);

  return (
    <Shell>
      <h1 className="page-title">Dashboard</h1>
      <p className="page-sub">Platform overview at a glance</p>
      {err && <div className="error">{err}</div>}

      {stats ? (
        <div className="cards">
          {CARDS.map((c) => (
            <div className="card" key={c.key}>
              <div className="label">{c.label}</div>
              <div className="value">{stats[c.key]}</div>
            </div>
          ))}
        </div>
      ) : (
        !err && <p className="muted">Loading…</p>
      )}

      {analytics && (
        <>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 20, marginTop: 28 }}>
            <div className="panel" style={{ padding: 20 }}>
              <h3 style={{ marginBottom: 8 }}>New signups (6 mo)</h3>
              <BarChart
                data={analytics.signups.map((s) => ({ label: monthLabel(s.month), value: s.count }))}
                color="var(--orange)"
              />
            </div>
            <div className="panel" style={{ padding: 20 }}>
              <h3 style={{ marginBottom: 8 }}>Bookings (6 mo)</h3>
              <BarChart
                data={analytics.bookings.map((b) => ({ label: monthLabel(b.month), value: b.count }))}
                color="var(--teal)"
              />
            </div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 20, marginTop: 20 }}>
            <div className="panel" style={{ padding: 20 }}>
              <h3 style={{ marginBottom: 14 }}>Booking status</h3>
              {analytics.statusBreakdown.map((s) => (
                <div key={s.status} className="row" style={{ marginBottom: 8 }}>
                  <span className="badge gray" style={{ minWidth: 120 }}>{s.status}</span>
                  <div className="spacer" />
                  <strong>{s.count}</strong>
                </div>
              ))}
            </div>
            <div className="panel" style={{ padding: 20 }}>
              <h3 style={{ marginBottom: 14 }}>Top studios</h3>
              {analytics.topStudios.map((s, i) => (
                <div key={s.ownerId + i} className="row" style={{ marginBottom: 8 }}>
                  <span className="muted">{i + 1}.</span>
                  <strong>{s.name}</strong>
                  <div className="spacer" />
                  <span className="badge orange">{s.bookings} bookings</span>
                </div>
              ))}
            </div>
          </div>
        </>
      )}
    </Shell>
  );
}
