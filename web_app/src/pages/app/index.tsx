import { useEffect, useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/router';
import AppShell from '@/components/AppShell';
import { api, getUser } from '@/lib/api';
import { tk } from '@/lib/format';

const fmtDate = (d: string) =>
  new Date(d).toLocaleDateString('en-BD', { day: 'numeric', month: 'short', year: 'numeric' });

function statusBadge(s: string) {
  const map: Record<string, string> = {
    PENDING: 'gold', CONFIRMED: 'teal', IN_PROGRESS: 'orange',
    SHOT_COMPLETE: 'blue', DELIVERED: 'purple', COMPLETED: 'green', CANCELLED: 'red',
  };
  return <span className={`badge ${map[s] || 'gray'}`}>{s.replace(/_/g, ' ')}</span>;
}

export default function DashboardPage() {
  const router = useRouter();
  const user = getUser();
  const today = new Date();

  const [bookings, setBookings] = useState<any[]>([]);
  const [payments, setPayments] = useState<any[]>([]);
  const [clients, setClients] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    Promise.all([
      api<any>('/api/bookings?limit=100'),
      api<any>('/api/payments').catch(() => []),
      api<any>('/api/clients').catch(() => []),
    ])
      .then(([b, p, c]) => {
        setBookings(Array.isArray(b) ? b : b?.data ?? b?.bookings ?? []);
        setPayments(Array.isArray(p) ? p : p?.data ?? p?.payments ?? []);
        setClients(Array.isArray(c) ? c : c?.data ?? c?.clients ?? []);
      })
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, []);

  const todayStr = today.toISOString().split('T')[0];
  const in7 = new Date(today); in7.setDate(today.getDate() + 7);
  const in7Str = in7.toISOString().split('T')[0];

  const getDate = (b: any) => b.date?.split('T')[0] || b.event_date?.split('T')[0] || '';
  const getName = (b: any) => b.clientName || b.client_name || b.client?.name || '—';

  const upcoming = bookings
    .filter((b) => { const d = getDate(b); return d >= todayStr && d <= in7Str && b.status !== 'CANCELLED'; })
    .sort((a, b) => getDate(a).localeCompare(getDate(b)));

  const recent = [...bookings]
    .sort((a, b) => (b.createdAt || b.created_at || '').localeCompare(a.createdAt || a.created_at || ''))
    .slice(0, 5);

  const thisMonth = today.getMonth();
  const thisYear = today.getFullYear();

  const thisMonthRevenue = payments
    .filter((p) => {
      if (p.kind === 'PAYOUT') return false;
      const d = new Date(p.createdAt || p.paid_at || p.date || 0);
      return d.getMonth() === thisMonth && d.getFullYear() === thisYear;
    })
    .reduce((s, p) => s + (Number(p.amount) || 0), 0);

  const totalDue = bookings.reduce((s, b) => s + (Number(b.due_amount) || Number(b.dueAmount) || 0), 0);
  const todayBookings = bookings.filter((b) => getDate(b) === todayStr);
  const completed = bookings.filter((b) => b.status === 'COMPLETED').length;
  const pending = bookings.filter((b) => b.status === 'PENDING').length;

  const hour = today.getHours();
  const greeting = hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';

  const Shimmer = ({ w = '100%', h = 32 }: { w?: string; h?: number }) => (
    <div className="shimmer" style={{ width: w, height: h, borderRadius: 6 }} />
  );

  return (
    <AppShell>
      <div style={{ padding: 24 }}>
        {/* Header */}
        <div className="row" style={{ marginBottom: 24, flexWrap: 'wrap', gap: 12, alignItems: 'flex-start' }}>
          <div style={{ flex: 1 }}>
            <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 28, color: 'var(--film)', letterSpacing: '0.03em' }}>
              {greeting}, {user?.name?.split(' ')[0] || 'there'} 👋
            </div>
            <div className="muted" style={{ fontSize: 13, marginTop: 2 }}>
              {today.toLocaleDateString('en-BD', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' })}
            </div>
          </div>
          <div className="row" style={{ gap: 8 }}>
            <span className="badge orange">{user?.role || 'OWNER'}</span>
          </div>
        </div>

        {error && <div className="error" style={{ marginBottom: 16 }}>{error}</div>}

        {/* Finance Row */}
        <div className="cards cards-3" style={{ marginBottom: 20 }}>
          <div className="finance-card">
            <div className="muted text-sm" style={{ marginBottom: 6 }}>This Month Revenue</div>
            {loading ? <Shimmer h={28} /> : (
              <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 30, color: 'var(--green)' }}>{tk(thisMonthRevenue)}</div>
            )}
          </div>
          <div className="finance-card">
            <div className="muted text-sm" style={{ marginBottom: 6 }}>Total Due</div>
            {loading ? <Shimmer h={28} /> : (
              <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 30, color: 'var(--red)' }}>{tk(totalDue)}</div>
            )}
          </div>
          <div className="finance-card">
            <div className="muted text-sm" style={{ marginBottom: 6 }}>Today&apos;s Bookings</div>
            {loading ? <Shimmer h={28} /> : (
              <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 30, color: 'var(--orange)' }}>{todayBookings.length}</div>
            )}
          </div>
        </div>

        {/* KPI Cards */}
        <div className="cards cards-4" style={{ marginBottom: 20 }}>
          {[
            { label: 'Total Bookings', value: bookings.length, color: 'var(--orange)' },
            { label: 'Completed', value: completed, color: 'var(--green)' },
            { label: 'Pending', value: pending, color: 'var(--gold)' },
            { label: 'Total Clients', value: clients.length, color: 'var(--blue)' },
          ].map((k) => (
            <div key={k.label} className="card" style={{ textAlign: 'center' }}>
              <div className="muted text-sm" style={{ marginBottom: 8 }}>{k.label}</div>
              {loading ? <Shimmer w="60%" h={36} /> : (
                <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 38, color: k.color }}>{k.value}</div>
              )}
            </div>
          ))}
        </div>

        {/* Quick Actions */}
        <div className="card" style={{ marginBottom: 20 }}>
          <div className="muted text-sm" style={{ marginBottom: 12, textTransform: 'uppercase', letterSpacing: '0.08em', fontFamily: 'JetBrains Mono, monospace' }}>Quick Actions</div>
          <div className="row" style={{ gap: 10, flexWrap: 'wrap' }}>
            <button className="btn" style={{ background: 'var(--orange)', color: '#000' }} onClick={() => router.push('/app/bookings')}>+ New Booking</button>
            <button className="btn ghost" onClick={() => router.push('/app/clients')}>+ New Client</button>
            <button className="btn ghost" onClick={() => router.push('/app/finance')}>Finance</button>
            <button className="btn ghost" onClick={() => router.push('/app/reports')}>Reports</button>
          </div>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 20 }}>
          {/* Upcoming */}
          <div className="panel">
            <div className="panel-header">
              <span className="panel-title">Upcoming (Next 7 Days)</span>
              <span className="badge gray">{upcoming.length}</span>
            </div>
            <div className="panel-body">
              {loading && [...Array(3)].map((_, i) => <div key={i} className="shimmer" style={{ height: 60, borderRadius: 6, marginBottom: 8 }} />)}
              {!loading && upcoming.length === 0 && <div className="empty">No upcoming bookings</div>}
              {!loading && upcoming.map((b) => (
                <Link key={b.id} href={`/app/bookings/${b.id}`} style={{ textDecoration: 'none', display: 'block' }}>
                  <div style={{ padding: '10px 12px', background: 'var(--surface-3)', borderRadius: 6, marginBottom: 8, borderLeft: `3px solid ${b.shift === 'NIGHT' ? 'var(--purple)' : b.shift === 'BOTH' ? 'var(--orange)' : 'var(--gold)'}` }}>
                    <div className="row" style={{ justifyContent: 'space-between', marginBottom: 4 }}>
                      <span style={{ fontWeight: 600, fontSize: 14, color: 'var(--film)' }} className="truncate">{b.title || b.eventType || 'Booking'}</span>
                      <span className={`pill ${b.shift === 'NIGHT' ? 'night' : b.shift === 'BOTH' ? 'both' : 'day'}`}>{b.shift || 'DAY'}</span>
                    </div>
                    <div className="row" style={{ justifyContent: 'space-between' }}>
                      <span className="muted text-sm">{getName(b)}</span>
                      <span className="muted text-sm">{fmtDate(getDate(b))}</span>
                    </div>
                    <div style={{ marginTop: 6 }}>{statusBadge(b.status)}</div>
                  </div>
                </Link>
              ))}
            </div>
          </div>

          {/* Recent Bookings */}
          <div className="panel">
            <div className="panel-header">
              <span className="panel-title">Recent Bookings</span>
              <Link href="/app/bookings" className="btn ghost sm">View All →</Link>
            </div>
            <div className="panel-body">
              {loading && [...Array(5)].map((_, i) => <div key={i} className="shimmer" style={{ height: 44, borderRadius: 6, marginBottom: 8 }} />)}
              {!loading && recent.length === 0 && <div className="empty">No bookings yet</div>}
              {!loading && recent.map((b) => (
                <div key={b.id} className="row" style={{ padding: '10px 0', borderBottom: '1px solid var(--surface-3)', gap: 10 }}>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div className="truncate" style={{ fontSize: 13, fontWeight: 600, color: 'var(--film)' }}>{b.title || b.eventType || 'Booking'}</div>
                    <div className="muted text-sm truncate">{getName(b)} · {fmtDate(getDate(b))}</div>
                  </div>
                  <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: 4, flexShrink: 0 }}>
                    {statusBadge(b.status)}
                    <span style={{ fontSize: 12, color: 'var(--orange)' }}>{tk(Number(b.price) || 0)}</span>
                  </div>
                  <Link href={`/app/bookings/${b.id}`} className="btn ghost xs">View</Link>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </AppShell>
  );
}
