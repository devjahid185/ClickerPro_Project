import { useEffect, useState, FormEvent } from 'react';
import AppShell from '@/components/AppShell';
import { api } from '@/lib/api';
import { tk } from '@/lib/format';
import { Payment } from '@/types/api';

const fmtDate = (d: string) =>
  d ? new Date(d).toLocaleDateString('en-BD', { day: 'numeric', month: 'short', year: 'numeric' }) : '—';

const KINDS = ['ALL', 'ADVANCE', 'DUE', 'EXTRA', 'PAYOUT'];
const METHODS = ['ALL', 'CASH', 'BKASH', 'NAGAD', 'BANK', 'CARD'];
const METHOD_COLORS: Record<string, string> = { CASH: 'green', BKASH: 'purple', NAGAD: 'orange', BANK: 'teal', CARD: 'blue' };
const KIND_COLORS: Record<string, string> = { ADVANCE: 'gold', DUE: 'orange', EXTRA: 'blue', PAYOUT: 'red' };

export default function PaymentsPage() {
  const [payments, setPayments] = useState<Payment[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [kindFilter, setKindFilter] = useState('ALL');
  const [methodFilter, setMethodFilter] = useState('ALL');
  const [showModal, setShowModal] = useState(false);
  const [form, setForm] = useState({ bookingId: '', amount: '', kind: 'ADVANCE', method: 'CASH', note: '' });
  const [submitting, setSubmitting] = useState(false);
  const [modalError, setModalError] = useState('');

  const load = async () => {
    setLoading(true);
    try {
      const res = await api<Payment[] | { data?: Payment[]; payments?: Payment[] }>('/api/payments');
      setPayments(Array.isArray(res) ? res : res?.data ?? res?.payments ?? []);
    } catch (e: any) { setError(e.message); }
    finally { setLoading(false); }
  };

  useEffect(() => { load(); }, []);

  const filtered = payments.filter((p) => {
    if (kindFilter !== 'ALL' && p.kind !== kindFilter) return false;
    if (methodFilter !== 'ALL' && p.method !== methodFilter) return false;
    return true;
  });

  const totalReceived = payments.filter((p) => p.kind !== 'PAYOUT').reduce((s, p) => s + (Number(p.amount) || 0), 0);
  const advanceTotal = payments.filter((p) => p.kind === 'ADVANCE').reduce((s, p) => s + (Number(p.amount) || 0), 0);
  const dueTotal = payments.filter((p) => p.kind === 'DUE').reduce((s, p) => s + (Number(p.amount) || 0), 0);
  const payoutTotal = payments.filter((p) => p.kind === 'PAYOUT').reduce((s, p) => s + (Number(p.amount) || 0), 0);

  const methodTotals = METHODS.slice(1).map((m) => ({
    method: m,
    total: payments.filter((p) => p.method === m && p.kind !== 'PAYOUT').reduce((s, p) => s + (Number(p.amount) || 0), 0),
  }));

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    if (!form.bookingId || !form.amount) { setModalError('Booking ID and amount are required.'); return; }
    setSubmitting(true); setModalError('');
    try {
      await api('/api/payments', { method: 'POST', body: { bookingId: form.bookingId, eventId: form.bookingId, amount: Number(form.amount), kind: form.kind, method: form.method, note: form.note } });
      setShowModal(false);
      setForm({ bookingId: '', amount: '', kind: 'ADVANCE', method: 'CASH', note: '' });
      load();
    } catch (e: any) { setModalError(e.message); }
    finally { setSubmitting(false); }
  };

  return (
    <AppShell>
      <div style={{ padding: 24 }}>
        <div className="toolbar" style={{ marginBottom: 16 }}>
          <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 24 }}>Payments</div>
          <span className="spacer" />
          <button className="btn" style={{ background: 'var(--orange)', color: '#000' }} onClick={() => { setModalError(''); setShowModal(true); }}>+ Add Payment</button>
        </div>

        {error && <div className="error" style={{ marginBottom: 12 }}>{error}</div>}

        {/* Summary Cards */}
        <div className="cards cards-4" style={{ marginBottom: 16 }}>
          {[
            { label: 'Total Received', value: totalReceived, color: 'var(--green)' },
            { label: 'Advance Total', value: advanceTotal, color: 'var(--gold)' },
            { label: 'Due Total', value: dueTotal, color: 'var(--orange)' },
            { label: 'Payout Total', value: payoutTotal, color: 'var(--red)' },
          ].map((k) => (
            <div key={k.label} className="card" style={{ textAlign: 'center' }}>
              <div className="muted text-sm" style={{ marginBottom: 6 }}>{k.label}</div>
              <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 26, color: k.color }}>{tk(k.value)}</div>
            </div>
          ))}
        </div>

        {/* Method Breakdown */}
        <div className="cards cards-4" style={{ marginBottom: 20 }}>
          {methodTotals.map((m) => (
            <div key={m.method} className="card" style={{ textAlign: 'center' }}>
              <span className={`badge ${METHOD_COLORS[m.method] || 'gray'}`}>{m.method}</span>
              <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 22, marginTop: 8 }}>{tk(m.total)}</div>
            </div>
          ))}
        </div>

        {/* Filters */}
        <div className="row" style={{ gap: 8, marginBottom: 8, flexWrap: 'wrap' }}>
          <span className="muted text-sm" style={{ alignSelf: 'center' }}>Kind:</span>
          {KINDS.map((k) => (
            <button key={k} className={`chip${kindFilter === k ? ' active' : ''}`} onClick={() => setKindFilter(k)}>{k}</button>
          ))}
        </div>
        <div className="row" style={{ gap: 8, marginBottom: 20, flexWrap: 'wrap' }}>
          <span className="muted text-sm" style={{ alignSelf: 'center' }}>Method:</span>
          {METHODS.map((m) => (
            <button key={m} className={`chip${methodFilter === m ? ' active' : ''}`} onClick={() => setMethodFilter(m)}>{m}</button>
          ))}
        </div>

        <div className="panel">
          <div className="panel-header">
            <span className="panel-title">Payment Records</span>
            <span className="badge gray">{filtered.length}</span>
          </div>
          <div className="panel-body">
            {loading && [...Array(6)].map((_, i) => <div key={i} className="shimmer" style={{ height: 48, borderRadius: 6, marginBottom: 8 }} />)}
            {!loading && filtered.length === 0 && <div className="empty">No payments found.</div>}
            {!loading && filtered.length > 0 && (
              <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                <thead>
                  <tr style={{ borderBottom: '1px solid var(--surface-3)' }}>
                    {['Booking', 'Amount', 'Kind', 'Method', 'Date', 'Note'].map((h) => (
                      <th key={h} style={{ textAlign: 'left', padding: '8px 10px', fontSize: 11, fontFamily: 'JetBrains Mono, monospace', color: 'var(--film-muted)', textTransform: 'uppercase' }}>{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {filtered.map((p: any, i: number) => (
                    <tr key={p.id || i} style={{ borderBottom: '1px solid var(--surface-3)' }}>
                      <td style={{ padding: '10px', fontSize: 13 }}>{p.booking?.title || p.bookingId || p.eventId || '—'}</td>
                      <td style={{ padding: '10px', fontFamily: 'Bebas Neue, sans-serif', fontSize: 20, color: 'var(--orange)' }}>{tk(Number(p.amount) || 0)}</td>
                      <td style={{ padding: '10px' }}><span className={`badge ${KIND_COLORS[p.kind] || 'gray'}`}>{p.kind}</span></td>
                      <td style={{ padding: '10px' }}><span className={`badge ${METHOD_COLORS[p.method] || 'gray'}`}>{p.method}</span></td>
                      <td style={{ padding: '10px', fontSize: 12 }}>{fmtDate(p.createdAt || p.paid_at || p.date)}</td>
                      <td style={{ padding: '10px', fontSize: 12, color: 'var(--film-muted)' }} className="truncate">{p.note || '—'}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </div>
      </div>

      {/* Add Payment Modal */}
      {showModal && (
        <div className="modal-backdrop" onClick={() => setShowModal(false)}>
          <div className="modal" onClick={(e) => e.stopPropagation()}>
            <div className="row" style={{ marginBottom: 16 }}>
              <span style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 20 }}>Add Payment</span>
              <span className="spacer" />
              <button className="btn ghost xs" onClick={() => setShowModal(false)}>×</button>
            </div>
            {modalError && <div className="error" style={{ marginBottom: 10 }}>{modalError}</div>}
            <form onSubmit={handleSubmit}>
              <div className="field" style={{ marginBottom: 12 }}>
                <label>Booking ID *</label>
                <input className="field" required value={form.bookingId} onChange={(e) => setForm({ ...form, bookingId: e.target.value })} placeholder="Booking ID" />
              </div>
              <div className="form-grid">
                <div className="field">
                  <label>Amount (৳) *</label>
                  <input type="number" className="field" required value={form.amount} onChange={(e) => setForm({ ...form, amount: e.target.value })} placeholder="0" />
                </div>
                <div className="field">
                  <label>Kind</label>
                  <select className="field" value={form.kind} onChange={(e) => setForm({ ...form, kind: e.target.value })}>
                    {['ADVANCE', 'DUE', 'EXTRA', 'PAYOUT'].map((k) => <option key={k}>{k}</option>)}
                  </select>
                </div>
                <div className="field">
                  <label>Method</label>
                  <select className="field" value={form.method} onChange={(e) => setForm({ ...form, method: e.target.value })}>
                    {['CASH', 'BKASH', 'NAGAD', 'BANK', 'CARD'].map((m) => <option key={m}>{m}</option>)}
                  </select>
                </div>
                <div className="field">
                  <label>Note</label>
                  <input className="field" value={form.note} onChange={(e) => setForm({ ...form, note: e.target.value })} placeholder="Optional note" />
                </div>
              </div>
              <div className="row" style={{ gap: 10, marginTop: 16, justifyContent: 'flex-end' }}>
                <button type="button" className="btn ghost" onClick={() => setShowModal(false)}>Cancel</button>
                <button type="submit" className="btn" style={{ background: 'var(--orange)', color: '#000' }} disabled={submitting}>{submitting ? 'Adding...' : 'Add Payment'}</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </AppShell>
  );
}
