import { useEffect, useState } from 'react';
import AppShell from '@/components/AppShell';
import { api } from '@/lib/api';
import { tk } from '@/lib/format';


const PERIODS = ['This Month', 'Last Month', 'Last 3 Months', 'This Year'];

function statusBadge(s: string) {
  const map: Record<string, string> = {
    PENDING: 'gold', CONFIRMED: 'teal', IN_PROGRESS: 'orange',
    SHOT_COMPLETE: 'blue', DELIVERED: 'purple', COMPLETED: 'green', CANCELLED: 'red',
  };
  return <span className={`badge ${map[s] || 'gray'}`}>{s.replace(/_/g, ' ')}</span>;
}

export default function ReportsPage() {
  const [bookings, setBookings] = useState<any[]>([]);
  const [payments, setPayments] = useState<any[]>([]);
  const [expenses, setExpenses] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [period, setPeriod] = useState('This Month');

  useEffect(() => {
    Promise.all([
      api<any>('/api/bookings?limit=500'),
      api<any>('/api/payments').catch(() => []),
      api<any>('/api/expenses').catch(() => []),
    ])
      .then(([b, p, e]) => {
        setBookings(Array.isArray(b) ? b : b?.data ?? []);
        setPayments(Array.isArray(p) ? p : p?.data ?? []);
        setExpenses(Array.isArray(e) ? e : e?.data ?? []);
      })
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, []);

  const now = new Date();

  const getDateRange = () => {
    const end = new Date(now);
    const start = new Date(now);
    if (period === 'This Month') { start.setDate(1); }
    else if (period === 'Last Month') { start.setMonth(now.getMonth() - 1, 1); end.setDate(0); }
    else if (period === 'Last 3 Months') { start.setMonth(now.getMonth() - 2, 1); }
    else { start.setMonth(0, 1); }
    return { start, end };
  };

  const { start, end } = getDateRange();
  const startStr = start.toISOString().split('T')[0];
  const endStr = end.toISOString().split('T')[0];

  const inRange = (d: string) => {
    const ds = (d || '').split('T')[0];
    return ds >= startStr && ds <= endStr;
  };

  const filteredPayments = payments.filter((p) => inRange(p.createdAt || p.paid_at || p.date));
  const filteredExpenses = expenses.filter((e) => inRange(e.date || e.createdAt));
  const filteredBookings = bookings.filter((b) => inRange(b.date || b.event_date));

  const totalRevenue = filteredPayments.filter((p) => p.kind !== 'PAYOUT').reduce((s, p) => s + (Number(p.amount) || 0), 0);
  const totalExpenses = filteredExpenses.reduce((s, e) => s + (Number(e.amount) || 0), 0);
  const netProfit = totalRevenue - totalExpenses;
  const completedBookings = filteredBookings.filter((b) => b.status === 'COMPLETED').length;
  const pendingBookings = filteredBookings.filter((b) => b.status === 'PENDING').length;
  const avgBookingValue = filteredBookings.length > 0 ? filteredBookings.reduce((s, b) => s + (Number(b.price) || 0), 0) / filteredBookings.length : 0;

  // Monthly breakdown (last 6 months)
  const months: { label: string; revenue: number; expenses: number; bookings: number }[] = [];
  for (let i = 5; i >= 0; i--) {
    const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
    const prefix = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
    const rev = payments.filter((p) => p.kind !== 'PAYOUT' && (p.createdAt || p.paid_at || '').startsWith(prefix)).reduce((s, p) => s + (Number(p.amount) || 0), 0);
    const exp = expenses.filter((e) => (e.date || e.createdAt || '').startsWith(prefix)).reduce((s, e) => s + (Number(e.amount) || 0), 0);
    const bk = bookings.filter((b) => (b.date || b.event_date || '').startsWith(prefix)).length;
    months.push({ label: d.toLocaleDateString('en-BD', { month: 'short', year: '2-digit' }), revenue: rev, expenses: exp, bookings: bk });
  }

  const maxBarVal = Math.max(...months.map((m) => Math.max(m.revenue, m.expenses)), 1);

  // Status breakdown
  const statusMap: Record<string, number> = {};
  filteredBookings.forEach((b) => { statusMap[b.status] = (statusMap[b.status] || 0) + 1; });
  const statusTotal = Math.max(filteredBookings.length, 1);

  // Event type breakdown
  const typeMap: Record<string, number> = {};
  filteredBookings.forEach((b) => { const t = b.eventType || b.event_type || 'Other'; typeMap[t] = (typeMap[t] || 0) + 1; });

  const exportCSV = () => {
    const headers = ['Month', 'Revenue', 'Expenses', 'Net', 'Bookings'];
    const rows = months.map((m) => [m.label, m.revenue, m.expenses, m.revenue - m.expenses, m.bookings]);
    const csv = [headers, ...rows].map((r) => r.join(',')).join('\n');
    const a = document.createElement('a');
    a.href = 'data:text/csv;charset=utf-8,' + encodeURIComponent(csv);
    a.download = 'report.csv';
    a.click();
  };

  return (
    <AppShell>
      <div style={{ padding: 24 }}>
        <div className="toolbar" style={{ marginBottom: 16 }}>
          <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 24 }}>Reports</div>
          <span className="spacer" />
          <button className="btn ghost sm" onClick={exportCSV}>Export CSV</button>
        </div>

        {error && <div className="error" style={{ marginBottom: 12 }}>{error}</div>}

        {/* Period Filter */}
        <div className="chip-row" style={{ marginBottom: 20 }}>
          {PERIODS.map((p) => (
            <button key={p} className={`chip${period === p ? ' active' : ''}`} onClick={() => setPeriod(p)}>{p}</button>
          ))}
        </div>

        {loading && <div className="shimmer" style={{ height: 400, borderRadius: 8 }} />}

        {!loading && (
          <>
            {/* KPI Cards */}
            <div className="cards cards-3" style={{ marginBottom: 20 }}>
              {[
                { label: 'Total Revenue', value: tk(totalRevenue), color: 'var(--green)' },
                { label: 'Total Expenses', value: tk(totalExpenses), color: 'var(--red)' },
                { label: 'Net Profit', value: tk(netProfit), color: netProfit >= 0 ? 'var(--green)' : 'var(--red)' },
                { label: 'Completed Bookings', value: completedBookings, color: 'var(--green)' },
                { label: 'Pending Bookings', value: pendingBookings, color: 'var(--gold)' },
                { label: 'Avg Booking Value', value: tk(avgBookingValue), color: 'var(--orange)' },
              ].map((k) => (
                <div key={k.label} className="card" style={{ textAlign: 'center' }}>
                  <div className="muted text-sm" style={{ marginBottom: 8 }}>{k.label}</div>
                  <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 28, color: k.color }}>{k.value}</div>
                </div>
              ))}
            </div>

            {/* Bar Chart */}
            <div className="panel" style={{ marginBottom: 20 }}>
              <div className="panel-header"><span className="panel-title">Revenue vs Expenses (6 Months)</span></div>
              <div className="panel-body">
                <div className="bar-chart">
                  {months.map((m) => (
                    <div key={m.label} className="bar-chart-col">
                      <div style={{ display: 'flex', gap: 4, alignItems: 'flex-end', height: 120 }}>
                        <div
                          className="bar-chart-bar"
                          style={{ width: 16, height: `${(m.revenue / maxBarVal) * 100}%`, background: 'var(--green)', minHeight: 2 }}
                          title={`Revenue: ${tk(m.revenue)}`}
                        />
                        <div
                          className="bar-chart-bar"
                          style={{ width: 16, height: `${(m.expenses / maxBarVal) * 100}%`, background: 'var(--red)', minHeight: 2 }}
                          title={`Expenses: ${tk(m.expenses)}`}
                        />
                      </div>
                      <div className="muted" style={{ fontSize: 10, marginTop: 6, fontFamily: 'JetBrains Mono, monospace' }}>{m.label}</div>
                    </div>
                  ))}
                </div>
                <div className="row" style={{ gap: 16, marginTop: 12 }}>
                  <div className="row" style={{ gap: 6 }}><div style={{ width: 12, height: 12, borderRadius: 2, background: 'var(--green)' }} /><span className="muted text-sm">Revenue</span></div>
                  <div className="row" style={{ gap: 6 }}><div style={{ width: 12, height: 12, borderRadius: 2, background: 'var(--red)' }} /><span className="muted text-sm">Expenses</span></div>
                </div>
              </div>
            </div>

            {/* Monthly Table */}
            <div className="panel" style={{ marginBottom: 20 }}>
              <div className="panel-header"><span className="panel-title">Monthly Breakdown</span></div>
              <div className="panel-body">
                <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                  <thead>
                    <tr style={{ borderBottom: '1px solid var(--surface-3)' }}>
                      {['Month', 'Revenue', 'Expenses', 'Net', 'Bookings'].map((h) => (
                        <th key={h} style={{ textAlign: 'left', padding: '8px 12px', fontSize: 11, fontFamily: 'JetBrains Mono, monospace', color: 'var(--film-muted)', textTransform: 'uppercase' }}>{h}</th>
                      ))}
                    </tr>
                  </thead>
                  <tbody>
                    {months.map((m) => (
                      <tr key={m.label} style={{ borderBottom: '1px solid var(--surface-3)' }}>
                        <td style={{ padding: '10px 12px', fontWeight: 600 }}>{m.label}</td>
                        <td style={{ padding: '10px 12px', color: 'var(--green)' }}>{tk(m.revenue)}</td>
                        <td style={{ padding: '10px 12px', color: 'var(--red)' }}>{tk(m.expenses)}</td>
                        <td style={{ padding: '10px 12px', color: m.revenue - m.expenses >= 0 ? 'var(--green)' : 'var(--red)' }}>{tk(m.revenue - m.expenses)}</td>
                        <td style={{ padding: '10px 12px' }}>{m.bookings}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 20 }}>
              {/* Booking by Status */}
              <div className="panel">
                <div className="panel-header"><span className="panel-title">By Status</span></div>
                <div className="panel-body">
                  {Object.entries(statusMap).map(([status, count]) => (
                    <div key={status} style={{ marginBottom: 12 }}>
                      <div className="row" style={{ justifyContent: 'space-between', marginBottom: 4 }}>
                        {statusBadge(status)}
                        <span className="muted text-sm">{count} ({Math.round(count / statusTotal * 100)}%)</span>
                      </div>
                      <div style={{ background: 'var(--surface-3)', borderRadius: 4, height: 6 }}>
                        <div style={{ width: `${(count / statusTotal) * 100}%`, height: '100%', background: 'var(--orange)', borderRadius: 4 }} />
                      </div>
                    </div>
                  ))}
                  {Object.keys(statusMap).length === 0 && <div className="empty">No data for period.</div>}
                </div>
              </div>

              {/* Booking by Event Type */}
              <div className="panel">
                <div className="panel-header"><span className="panel-title">By Event Type</span></div>
                <div className="panel-body">
                  {Object.entries(typeMap).sort((a, b) => b[1] - a[1]).map(([type, count]) => (
                    <div key={type} style={{ marginBottom: 12 }}>
                      <div className="row" style={{ justifyContent: 'space-between', marginBottom: 4 }}>
                        <span style={{ fontSize: 13, fontWeight: 600 }}>{type}</span>
                        <span className="muted text-sm">{count} ({Math.round(count / statusTotal * 100)}%)</span>
                      </div>
                      <div style={{ background: 'var(--surface-3)', borderRadius: 4, height: 6 }}>
                        <div style={{ width: `${(count / statusTotal) * 100}%`, height: '100%', background: 'var(--blue)', borderRadius: 4 }} />
                      </div>
                    </div>
                  ))}
                  {Object.keys(typeMap).length === 0 && <div className="empty">No data for period.</div>}
                </div>
              </div>
            </div>
          </>
        )}
      </div>
    </AppShell>
  );
}
