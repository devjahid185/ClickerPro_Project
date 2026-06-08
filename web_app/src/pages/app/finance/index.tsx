import { useEffect, useState, FormEvent } from 'react';
import Link from 'next/link';
import AppShell from '@/components/AppShell';
import { api } from '@/lib/api';
import { tk } from '@/lib/format';


const PERIODS = ['This Month', 'Last Month', 'Last 3 Months', 'This Year'];
const MONTHS_LABELS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const CAT_COLORS: Record<string, string> = { Travel: 'var(--blue)', Food: 'var(--green)', Gear: 'var(--orange)', Print: 'var(--purple)', Phone: 'var(--teal)', Other: 'var(--film-muted)' };

export default function FinancePage() {
  const [payments, setPayments] = useState<any[]>([]);
  const [expenses, setExpenses] = useState<any[]>([]);
  const [bookings, setBookings] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [period, setPeriod] = useState('This Month');
  const [studioTab, setStudioTab] = useState<'studio' | 'freelancer'>('studio');
  const [payReqForm, setPayReqForm] = useState({ amount: '', method: 'BKASH', note: '' });
  const [payReqSubmitting, setPayReqSubmitting] = useState(false);
  const [payReqMsg, setPayReqMsg] = useState('');

  useEffect(() => {
    Promise.all([
      api<any>('/api/payments').catch(() => []),
      api<any>('/api/expenses').catch(() => []),
      api<any>('/api/bookings?limit=500').catch(() => []),
    ])
      .then(([p, e, b]) => {
        setPayments(Array.isArray(p) ? p : p?.data ?? []);
        setExpenses(Array.isArray(e) ? e : e?.data ?? []);
        setBookings(Array.isArray(b) ? b : b?.data ?? []);
      })
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, []);

  const now = new Date();

  const getRange = () => {
    const end = new Date(now);
    const start = new Date(now);
    if (period === 'This Month') { start.setDate(1); }
    else if (period === 'Last Month') { start.setMonth(now.getMonth() - 1, 1); end.setDate(0); }
    else if (period === 'Last 3 Months') { start.setMonth(now.getMonth() - 2, 1); }
    else { start.setMonth(0, 1); }
    return { start: start.toISOString().split('T')[0], end: end.toISOString().split('T')[0] };
  };

  const { start, end } = getRange();
  const inRange = (d: string) => { const ds = (d || '').split('T')[0]; return ds >= start && ds <= end; };

  const filteredPayments = payments.filter((p) => inRange(p.createdAt || p.paid_at || p.date));
  const filteredExpenses = expenses.filter((e) => inRange(e.date || e.createdAt));

  const income = filteredPayments.filter((p) => p.kind !== 'PAYOUT').reduce((s, p) => s + (Number(p.amount) || 0), 0);
  const totalExpenses = filteredExpenses.reduce((s, e) => s + (Number(e.amount) || 0), 0);
  const netProfit = income - totalExpenses;

  // Studio tab
  const booked = bookings.reduce((s, b) => s + (Number(b.price) || 0), 0);
  const collected = payments.filter((p) => ['ADVANCE', 'DUE'].includes(p.kind)).reduce((s, p) => s + (Number(p.amount) || 0), 0);
  const totalDue = booked - collected;

  // Client dues
  const dueByClient: Record<string, { name: string; bookingId: string | number; due: number }[]> = {};
  bookings.forEach((b) => {
    const price = Number(b.price) || 0;
    const paid = payments.filter((p) => (p.bookingId === b.id || p.eventId === b.id || p.event_id === b.id) && ['ADVANCE', 'DUE'].includes(p.kind)).reduce((s, p) => s + (Number(p.amount) || 0), 0);
    const due = price - paid;
    if (due > 0) {
      const name = b.clientName || b.client_name || b.client?.name || 'Unknown';
      if (!dueByClient[name]) dueByClient[name] = [];
      dueByClient[name].push({ name, bookingId: b.id, due });
    }
  });

  // 6 month chart
  const months6: { label: string; income: number; expenses: number }[] = [];
  for (let i = 5; i >= 0; i--) {
    const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
    const prefix = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
    const inc = payments.filter((p) => p.kind !== 'PAYOUT' && (p.createdAt || p.paid_at || '').startsWith(prefix)).reduce((s, p) => s + (Number(p.amount) || 0), 0);
    const exp = expenses.filter((e) => (e.date || e.createdAt || '').startsWith(prefix)).reduce((s, e) => s + (Number(e.amount) || 0), 0);
    months6.push({ label: `${MONTHS_LABELS[d.getMonth()]} ${String(d.getFullYear()).slice(2)}`, income: inc, expenses: exp });
  }
  const maxBar = Math.max(...months6.map((m) => Math.max(m.income, m.expenses)), 1);

  // Category breakdown
  const catBreakdown: Record<string, number> = {};
  filteredExpenses.forEach((e) => {
    catBreakdown[e.category || 'Other'] = (catBreakdown[e.category || 'Other'] || 0) + (Number(e.amount) || 0);
  });
  const maxCat = Math.max(...Object.values(catBreakdown), 1);

  // Freelancer
  const myPayouts = payments.filter((p) => p.kind === 'PAYOUT');
  const myReceived = myPayouts.filter((p) => p.paid).reduce((s, p) => s + (Number(p.amount) || 0), 0);
  const myPending = myPayouts.filter((p) => !p.paid).reduce((s, p) => s + (Number(p.amount) || 0), 0);
  const myExpenses = filteredExpenses.reduce((s, e) => s + (Number(e.amount) || 0), 0);

  const handlePayRequest = async (e: FormEvent) => {
    e.preventDefault();
    if (!payReqForm.amount) return;
    setPayReqSubmitting(true); setPayReqMsg('');
    try {
      await api('/api/payments/request', { method: 'POST', body: { amount: Number(payReqForm.amount), method: payReqForm.method, note: payReqForm.note } });
      setPayReqMsg('Payment request submitted successfully.');
      setPayReqForm({ amount: '', method: 'BKASH', note: '' });
    } catch (e: any) { setPayReqMsg(e.message); }
    finally { setPayReqSubmitting(false); }
  };

  return (
    <AppShell>
      <div style={{ padding: 24 }}>
        <div className="toolbar" style={{ marginBottom: 16 }}>
          <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 24 }}>Finance</div>
          <span className="spacer" />
          <button className="btn ghost sm" onClick={() => window.print()}>Export PDF</button>
        </div>

        {error && <div className="error" style={{ marginBottom: 12 }}>{error}</div>}

        {/* Period */}
        <div className="chip-row" style={{ marginBottom: 20 }}>
          {PERIODS.map((p) => (
            <button key={p} className={`chip${period === p ? ' active' : ''}`} onClick={() => setPeriod(p)}>{p}</button>
          ))}
        </div>

        {/* Hero Cards */}
        <div className="cards cards-3" style={{ marginBottom: 20 }}>
          <div className="card" style={{ textAlign: 'center' }}>
            <div className="muted text-sm" style={{ marginBottom: 6 }}>Total Income</div>
            {loading ? <div className="shimmer" style={{ height: 36, width: '80%', margin: '0 auto' }} /> : (
              <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 34, color: 'var(--green)' }}>{tk(income)}</div>
            )}
          </div>
          <div className="card" style={{ textAlign: 'center' }}>
            <div className="muted text-sm" style={{ marginBottom: 6 }}>Total Expenses</div>
            {loading ? <div className="shimmer" style={{ height: 36, width: '80%', margin: '0 auto' }} /> : (
              <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 34, color: 'var(--red)' }}>{tk(totalExpenses)}</div>
            )}
          </div>
          <div className="card" style={{ textAlign: 'center' }}>
            <div className="muted text-sm" style={{ marginBottom: 6 }}>Net Profit</div>
            {loading ? <div className="shimmer" style={{ height: 36, width: '80%', margin: '0 auto' }} /> : (
              <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 34, color: netProfit >= 0 ? 'var(--green)' : 'var(--red)' }}>{tk(netProfit)}</div>
            )}
          </div>
        </div>

        {/* Tabs */}
        <div className="tabs" style={{ marginBottom: 20 }}>
          <button className={`tab${studioTab === 'studio' ? ' active' : ''}`} onClick={() => setStudioTab('studio')}>Business</button>
          <button className={`tab${studioTab === 'freelancer' ? ' active' : ''}`} onClick={() => setStudioTab('freelancer')}>Freelancer</button>
        </div>

        {studioTab === 'studio' && (
          <>
            <div className="cards cards-3" style={{ marginBottom: 20 }}>
              <div className="card" style={{ textAlign: 'center' }}>
                <div className="muted text-sm">Total Booked</div>
                <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 28, color: 'var(--blue)' }}>{tk(booked)}</div>
              </div>
              <div className="card" style={{ textAlign: 'center' }}>
                <div className="muted text-sm">Collected</div>
                <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 28, color: 'var(--green)' }}>{tk(collected)}</div>
              </div>
              <div className="card" style={{ textAlign: 'center' }}>
                <div className="muted text-sm">Due</div>
                <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 28, color: 'var(--red)' }}>{tk(Math.max(0, totalDue))}</div>
              </div>
            </div>

            {/* Client Dues */}
            {Object.keys(dueByClient).length > 0 && (
              <div className="panel" style={{ marginBottom: 20 }}>
                <div className="panel-header"><span className="panel-title">Client Dues</span></div>
                <div className="panel-body">
                  {Object.entries(dueByClient).map(([name, items]) => (
                    <div key={name}>
                      {items.map((item, i) => (
                        <div key={i} className="row" style={{ padding: '10px 0', borderBottom: '1px solid var(--surface-3)', gap: 12 }}>
                          <div style={{ flex: 1 }}>
                            <div style={{ fontWeight: 600 }}>{name}</div>
                            <div className="muted text-sm">Booking #{String(item.bookingId).slice(0, 8)}</div>
                          </div>
                          <div style={{ color: 'var(--red)', fontFamily: 'Bebas Neue, sans-serif', fontSize: 22 }}>{tk(item.due)}</div>
                          <Link href={`/app/bookings/${item.bookingId}`} className="btn ghost xs">View</Link>
                        </div>
                      ))}
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* 6 Month Chart */}
            <div className="panel" style={{ marginBottom: 20 }}>
              <div className="panel-header"><span className="panel-title">6-Month Overview</span></div>
              <div className="panel-body">
                <div className="bar-chart">
                  {months6.map((m) => (
                    <div key={m.label} className="bar-chart-col">
                      <div style={{ display: 'flex', gap: 4, alignItems: 'flex-end', height: 100 }}>
                        <div style={{ width: 16, height: `${(m.income / maxBar) * 100}%`, background: 'var(--green)', borderRadius: '3px 3px 0 0', minHeight: 2 }} title={`Income: ${tk(m.income)}`} />
                        <div style={{ width: 16, height: `${(m.expenses / maxBar) * 100}%`, background: 'var(--red)', borderRadius: '3px 3px 0 0', minHeight: 2 }} title={`Expenses: ${tk(m.expenses)}`} />
                      </div>
                      <div className="muted" style={{ fontSize: 10, marginTop: 6, fontFamily: 'JetBrains Mono, monospace' }}>{m.label}</div>
                    </div>
                  ))}
                </div>
              </div>
            </div>

            {/* Expense Category Breakdown */}
            <div className="panel">
              <div className="panel-header"><span className="panel-title">Expense Breakdown</span></div>
              <div className="panel-body">
                {Object.entries(catBreakdown).length === 0 && <div className="empty">No expenses in this period.</div>}
                {Object.entries(catBreakdown).sort((a, b) => b[1] - a[1]).map(([cat, total]) => (
                  <div key={cat} style={{ marginBottom: 12 }}>
                    <div className="row" style={{ justifyContent: 'space-between', marginBottom: 4 }}>
                      <span className="text-sm" style={{ fontWeight: 600 }}>{cat}</span>
                      <span className="muted text-sm">{tk(total)}</span>
                    </div>
                    <div style={{ background: 'var(--surface-3)', borderRadius: 4, height: 6 }}>
                      <div style={{ width: `${(total / maxCat) * 100}%`, height: '100%', background: CAT_COLORS[cat] || 'var(--film-muted)', borderRadius: 4 }} />
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </>
        )}

        {studioTab === 'freelancer' && (
          <>
            <div className="cards cards-4" style={{ marginBottom: 20 }}>
              {[
                { label: 'Received', value: myReceived, color: 'var(--green)' },
                { label: 'Pending', value: myPending, color: 'var(--gold)' },
                { label: 'My Expenses', value: myExpenses, color: 'var(--red)' },
                { label: 'Net', value: myReceived - myExpenses, color: myReceived - myExpenses >= 0 ? 'var(--green)' : 'var(--red)' },
              ].map((k) => (
                <div key={k.label} className="card" style={{ textAlign: 'center' }}>
                  <div className="muted text-sm" style={{ marginBottom: 6 }}>{k.label}</div>
                  <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 26, color: k.color }}>{tk(k.value)}</div>
                </div>
              ))}
            </div>

            <div className="card" style={{ marginBottom: 20 }}>
              <div className="muted text-sm" style={{ marginBottom: 12 }}>Request Payment from Company</div>
              {payReqMsg && <div className={payReqMsg.includes('success') ? 'success-msg' : 'error'} style={{ marginBottom: 10 }}>{payReqMsg}</div>}
              <form onSubmit={handlePayRequest}>
                <div className="form-grid">
                  <div className="field"><label>Amount (৳)</label><input type="number" className="field" required value={payReqForm.amount} onChange={(e) => setPayReqForm({ ...payReqForm, amount: e.target.value })} placeholder="0" /></div>
                  <div className="field">
                    <label>Method</label>
                    <select className="field" value={payReqForm.method} onChange={(e) => setPayReqForm({ ...payReqForm, method: e.target.value })}>
                      {['BKASH', 'NAGAD', 'BANK', 'CASH'].map((m) => <option key={m}>{m}</option>)}
                    </select>
                  </div>
                  <div className="field" style={{ gridColumn: '1/-1' }}><label>Note</label><input className="field" value={payReqForm.note} onChange={(e) => setPayReqForm({ ...payReqForm, note: e.target.value })} placeholder="Optional note" /></div>
                </div>
                <button type="submit" className="btn sm" style={{ marginTop: 12, background: 'var(--orange)', color: '#000' }} disabled={payReqSubmitting}>{payReqSubmitting ? 'Submitting...' : 'Request Payment'}</button>
              </form>
            </div>
          </>
        )}
      </div>

      <style>{`
        @media print {
          .app-sidebar, .toolbar, .chip-row, .tabs { display: none !important; }
          .app-main { margin: 0 !important; }
        }
      `}</style>
    </AppShell>
  );
}
