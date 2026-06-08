'use client';

import { useEffect, useState } from 'react';
import Shell from '@/components/Shell';
import BarChart from '@/components/BarChart';
import { api } from '@/lib/api';

type Analytics = {
  signups: { month: string; count: number }[];
  bookings: { month: string; count: number }[];
  statusBreakdown: { status: string; count: number }[];
  topStudios: { ownerId: string; name: string; bookings: number }[];
};

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

function monthLabel(m: string) {
  const [, mm] = m.split('-');
  return ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][Number(mm)] || m;
}

const STATUS_COLOR: Record<string, string> = {
  PENDING: 'gold',
  CONFIRMED: 'teal',
  IN_PROGRESS: 'orange',
  SHOT_COMPLETE: 'teal',
  DELIVERED: 'green',
  COMPLETED: 'green',
  CANCELLED: 'red',
};

export default function AnalyticsPage() {
  const [analytics, setAnalytics] = useState<Analytics | null>(null);
  const [stats, setStats] = useState<Stats | null>(null);
  const [err, setErr] = useState('');

  useEffect(() => {
    api<{ data: Analytics }>('/api/admin/analytics')
      .then((r) => setAnalytics(r.data))
      .catch((e) => setErr(e.message));
    api<{ data: Stats }>('/api/admin/stats')
      .then((r) => setStats(r.data))
      .catch(() => {});
  }, []);

  const totalSignups = analytics?.signups.reduce((s, m) => s + m.count, 0) || 0;
  const totalNewBookings = analytics?.bookings.reduce((s, m) => s + m.count, 0) || 0;

  return (
    <Shell>
      <h1 className="page-title">Analytics</h1>
      <p className="page-sub">Platform-wide growth and activity metrics</p>

      {err && <div className="error">{err}</div>}

      {stats && (
        <div className="cards" style={{ marginBottom: 28 }}>
          <div className="card">
            <div className="label">Total users</div>
            <div className="value">{stats.totalUsers}</div>
          </div>
          <div className="card">
            <div className="label">Businesses (owners)</div>
            <div className="value">{stats.owners}</div>
          </div>
          <div className="card">
            <div className="label">Freelancers</div>
            <div className="value">{stats.freelancers}</div>
          </div>
          <div className="card">
            <div className="label">Total bookings</div>
            <div className="value">{stats.totalBookings}</div>
          </div>
          <div className="card">
            <div className="label">Clients</div>
            <div className="value">{stats.totalClients}</div>
          </div>
          <div className="card">
            <div className="label">Open tickets</div>
            <div className="value">{stats.openTickets}</div>
          </div>
        </div>
      )}

      {analytics ? (
        <>
          {/* Growth charts */}
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 20, marginBottom: 20 }}>
            <div className="panel" style={{ padding: 20 }}>
              <div className="row" style={{ marginBottom: 12 }}>
                <h3>New signups (6 mo)</h3>
                <div className="spacer" />
                <span className="badge orange">{totalSignups} total</span>
              </div>
              <BarChart
                data={analytics.signups.map((s) => ({ label: monthLabel(s.month), value: s.count }))}
                color="var(--orange)"
              />
            </div>
            <div className="panel" style={{ padding: 20 }}>
              <div className="row" style={{ marginBottom: 12 }}>
                <h3>New bookings (6 mo)</h3>
                <div className="spacer" />
                <span className="badge teal">{totalNewBookings} total</span>
              </div>
              <BarChart
                data={analytics.bookings.map((b) => ({ label: monthLabel(b.month), value: b.count }))}
                color="var(--teal)"
              />
            </div>
          </div>

          {/* Status breakdown + top studios */}
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 20 }}>
            <div className="panel" style={{ padding: 20 }}>
              <h3 style={{ marginBottom: 16 }}>Booking status breakdown</h3>
              {analytics.statusBreakdown.map((s) => {
                const total = analytics.statusBreakdown.reduce((sum, x) => sum + x.count, 0);
                const pct = total > 0 ? Math.round((s.count / total) * 100) : 0;
                return (
                  <div key={s.status} style={{ marginBottom: 12 }}>
                    <div className="row" style={{ marginBottom: 4 }}>
                      <span className={`badge ${STATUS_COLOR[s.status] || 'gray'}`} style={{ minWidth: 120 }}>
                        {s.status.replace('_', ' ')}
                      </span>
                      <div className="spacer" />
                      <strong>{s.count}</strong>
                      <span className="muted" style={{ marginLeft: 8 }}>{pct}%</span>
                    </div>
                    <div style={{ background: 'var(--border)', borderRadius: 4, height: 4 }}>
                      <div style={{ background: `var(--${STATUS_COLOR[s.status] === 'gold' ? 'gold' : STATUS_COLOR[s.status] === 'teal' ? 'teal' : STATUS_COLOR[s.status] === 'orange' ? 'orange' : STATUS_COLOR[s.status] === 'green' ? 'green' : 'film-muted'})`, width: `${pct}%`, height: 4, borderRadius: 4 }} />
                    </div>
                  </div>
                );
              })}
            </div>

            <div className="panel" style={{ padding: 20 }}>
              <h3 style={{ marginBottom: 16 }}>Top businesses by bookings</h3>
              {analytics.topStudios.length === 0 && (
                <p className="muted">No data yet</p>
              )}
              {analytics.topStudios.map((s, i) => (
                <div key={s.ownerId} className="row" style={{ marginBottom: 12 }}>
                  <div style={{
                    width: 28, height: 28, borderRadius: '50%',
                    background: i === 0 ? '#ffd700' : i === 1 ? '#c0c0c0' : i === 2 ? '#cd7f32' : 'var(--border)',
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    fontSize: 12, fontWeight: 800, color: i < 3 ? '#000' : 'var(--film-dim)',
                    flexShrink: 0,
                  }}>
                    {i + 1}
                  </div>
                  <div style={{ flex: 1 }}>
                    <div style={{ fontWeight: 600 }}>{s.name}</div>
                  </div>
                  <span className="badge orange">{s.bookings} bookings</span>
                </div>
              ))}
            </div>
          </div>
        </>
      ) : (
        !err && <p className="muted">Loading analytics…</p>
      )}
    </Shell>
  );
}
