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

function monthLabel(m: string) {
  const [, mm] = m.split('-');
  return ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][Number(mm)] || m;
}

function greeting() {
  const h = new Date().getHours();
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}

function todayStr() {
  return new Date().toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric', year: 'numeric' });
}

type KpiCard = {
  label: string;
  key: keyof Stats;
  icon: string;
  color: string;
  bg: string;
  divisor?: number;
  prefix?: string;
  suffix?: string;
};

const KPI_CARDS: KpiCard[] = [
  { label: 'Total Users',       key: 'totalUsers',        icon: '👥', color: 'var(--orange)', bg: 'var(--orange-lt)' },
  { label: 'Businesses',        key: 'owners',            icon: '🏢', color: 'var(--purple)', bg: 'var(--purple-lt)' },
  { label: 'Freelancers',       key: 'freelancers',       icon: '🎯', color: 'var(--blue)',   bg: 'var(--blue-lt)'   },
  { label: 'Total Bookings',    key: 'totalBookings',     icon: '📅', color: 'var(--teal)',   bg: 'var(--teal-lt)'   },
  { label: 'Clients',           key: 'totalClients',      icon: '🙍', color: 'var(--green)',  bg: 'var(--green-lt)'  },
  { label: 'Revenue',           key: 'totalRevenueMinor', icon: '💰', color: 'var(--gold)',   bg: 'var(--gold-lt)',   divisor: 100, prefix: '৳' },
  { label: 'Live Broadcasts',   key: 'activeBroadcasts',  icon: '📢', color: 'var(--orange)', bg: 'var(--orange-lt)' },
  { label: 'Open Tickets',      key: 'openTickets',       icon: '🎫', color: 'var(--red)',    bg: 'var(--red-lt)'    },
];

const STATUS_COLOR: Record<string, string> = {
  PENDING:      '#d6a84c',
  CONFIRMED:    '#14b8a6',
  IN_PROGRESS:  '#ff6b00',
  SHOT_COMPLETE:'#14b8a6',
  DELIVERED:    '#16a34a',
  COMPLETED:    '#16a34a',
  CANCELLED:    '#dc2626',
};

const MEDAL_COLORS = ['#FFD700', '#C0C0C0', '#CD7F32'];

export default function Dashboard() {
  const [stats, setStats] = useState<Stats | null>(null);
  const [analytics, setAnalytics] = useState<Analytics | null>(null);
  const [err, setErr] = useState('');

  useEffect(() => {
    api<{ data: Stats }>('/api/admin/stats')
      .then((r) => setStats(r.data))
      .catch((e) => setErr(e.message));
    api<{ data: Analytics }>('/api/admin/analytics')
      .then((r) => setAnalytics(r.data))
      .catch(() => {});
  }, []);

  const totalStatusCount = analytics?.statusBreakdown.reduce((s, x) => s + x.count, 0) || 1;

  return (
    <Shell>
      {/* ── Header ── */}
      <div className="dash-header">
        <div>
          <div className="dash-greeting">{greeting()}, Admin 👋</div>
          <div className="dash-date">{todayStr()}</div>
        </div>
        <div className="dash-live">
          <div className="dash-live-dot" />
          Live data
        </div>
      </div>

      {err && <div className="error" style={{ marginBottom: 20 }}>{err}</div>}

      {/* ── KPI Cards ── */}
      {stats ? (
        <div className="cards" style={{ marginBottom: 28 }}>
          {KPI_CARDS.map((c) => {
            let raw = stats[c.key] as number;
            let display: string;
            if (c.divisor) {
              display = `${c.prefix || ''}${(raw / c.divisor).toLocaleString('en', { maximumFractionDigits: 0 })}`;
            } else {
              display = `${c.prefix || ''}${raw.toLocaleString()}${c.suffix || ''}`;
            }
            return (
              <div className="card" key={c.key}>
                <div className="card-accent" style={{ background: c.color }} />
                <div className="card-icon" style={{ background: c.bg }}>
                  {c.icon}
                </div>
                <div className="label">{c.label}</div>
                <div className="value" style={{ color: c.color }}>{display}</div>
              </div>
            );
          })}
        </div>
      ) : (
        !err && (
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(190px,1fr))', gap: 16, marginBottom: 28 }}>
            {Array.from({ length: 8 }).map((_, i) => (
              <div key={i} className="card" style={{ height: 110, background: 'linear-gradient(90deg,#f1f5f9 25%,#e2e8f0 50%,#f1f5f9 75%)', backgroundSize: '200% 100%', animation: 'shimmer 1.5s infinite' }} />
            ))}
          </div>
        )
      )}

      {/* ── Charts row ── */}
      {analytics && (
        <>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 20, marginBottom: 20 }}>
            {/* Signups */}
            <div className="panel">
              <div className="panel-header">
                <span className="panel-title">New Signups</span>
                <span className="badge orange">6 months</span>
              </div>
              <div className="panel-body">
                <BarChart
                  data={analytics.signups.map((s) => ({ label: monthLabel(s.month), value: s.count }))}
                  color="var(--orange)"
                  height={130}
                />
              </div>
            </div>

            {/* Bookings */}
            <div className="panel">
              <div className="panel-header">
                <span className="panel-title">Booking Volume</span>
                <span className="badge teal">6 months</span>
              </div>
              <div className="panel-body">
                <BarChart
                  data={analytics.bookings.map((b) => ({ label: monthLabel(b.month), value: b.count }))}
                  color="var(--teal)"
                  height={130}
                />
              </div>
            </div>
          </div>

          {/* ── Bottom row ── */}
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 20 }}>
            {/* Booking status breakdown */}
            <div className="panel">
              <div className="panel-header">
                <span className="panel-title">Booking Status</span>
                <span className="badge gray">{totalStatusCount} total</span>
              </div>
              <div className="panel-body" style={{ paddingTop: 10 }}>
                {analytics.statusBreakdown.length === 0 && (
                  <p className="muted">No bookings yet</p>
                )}
                {analytics.statusBreakdown.map((s) => {
                  const pct = Math.round((s.count / totalStatusCount) * 100);
                  const color = STATUS_COLOR[s.status] || 'var(--film-muted)';
                  return (
                    <div key={s.status} style={{ marginBottom: 14 }}>
                      <div className="row" style={{ marginBottom: 6 }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                          <div style={{ width: 8, height: 8, borderRadius: '50%', background: color, flexShrink: 0 }} />
                          <span style={{ fontSize: 13, fontWeight: 500, color: 'var(--film-dim)' }}>
                            {s.status.replace('_', ' ')}
                          </span>
                        </div>
                        <div className="spacer" />
                        <span style={{ fontSize: 13, fontWeight: 700 }}>{s.count}</span>
                        <span className="muted" style={{ fontSize: 12, minWidth: 34, textAlign: 'right' }}>{pct}%</span>
                      </div>
                      <div className="status-bar">
                        <div className="status-bar-fill" style={{ width: `${pct}%`, background: color }} />
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>

            {/* Top studios */}
            <div className="panel">
              <div className="panel-header">
                <span className="panel-title">Top Businesses</span>
                <span className="badge gold">by bookings</span>
              </div>
              <div className="panel-body" style={{ paddingTop: 10 }}>
                {analytics.topStudios.length === 0 && (
                  <p className="muted">No data yet</p>
                )}
                {analytics.topStudios.map((s, i) => (
                  <div key={s.ownerId} className="row" style={{ marginBottom: i < analytics.topStudios.length - 1 ? 14 : 0 }}>
                    <div
                      className="rank-medal"
                      style={{
                        background: i < 3 ? MEDAL_COLORS[i] : 'var(--surface-2)',
                        color: i < 3 ? '#000' : 'var(--film-muted)',
                      }}
                    >
                      {i + 1}
                    </div>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ fontWeight: 600, fontSize: 13.5, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                        {s.name}
                      </div>
                    </div>
                    <span className="badge orange">{s.bookings} bk</span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </>
      )}

      <style>{`
        @keyframes shimmer {
          0%   { background-position: 200% 0; }
          100% { background-position: -200% 0; }
        }
      `}</style>
    </Shell>
  );
}
