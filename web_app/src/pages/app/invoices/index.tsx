import { useEffect, useState, FormEvent } from 'react';
import Link from 'next/link';
import AppShell from '@/components/AppShell';
import { api } from '@/lib/api';
import { tk } from '@/lib/format';

const fmtDate = (d: string) =>
  d ? new Date(d).toLocaleDateString('en-BD', { day: 'numeric', month: 'short', year: 'numeric' }) : '—';

function statusBadge(s: string) {
  const map: Record<string, string> = { DRAFT: 'gray', SENT: 'teal', PAID: 'green', OVERDUE: 'red' };
  return <span className={`badge ${map[s] || 'gray'}`}>{s}</span>;
}

const STATUSES = ['ALL', 'DRAFT', 'SENT', 'PAID', 'OVERDUE'];
const blank = () => ({ bookingId: '', subtotal: '', taxRate: '', notes: '', language: 'EN' });

export default function InvoicesPage() {
  const [invoices, setInvoices] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [filter, setFilter] = useState('ALL');
  const [showModal, setShowModal] = useState(false);
  const [form, setForm] = useState<any>(blank());
  const [submitting, setSubmitting] = useState(false);
  const [modalError, setModalError] = useState('');

  const load = async () => {
    setLoading(true);
    try {
      const res = await api<any>('/api/invoices');
      setInvoices(Array.isArray(res) ? res : res?.data ?? res?.invoices ?? []);
    } catch (e: any) { setError(e.message); }
    finally { setLoading(false); }
  };

  useEffect(() => { load(); }, []);

  const filtered = invoices.filter((inv) => filter === 'ALL' || inv.status === filter);

  const total = invoices.reduce((s, inv) => s + (Number(inv.total) || 0), 0);
  const billed = invoices.filter((i) => i.status !== 'DRAFT').reduce((s, inv) => s + (Number(inv.total) || 0), 0);
  const paid = invoices.filter((i) => i.status === 'PAID').reduce((s, inv) => s + (Number(inv.total) || 0), 0);
  const outstanding = invoices.filter((i) => ['SENT', 'OVERDUE'].includes(i.status)).reduce((s, inv) => s + (Number(inv.total) || 0), 0);

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    if (!form.bookingId || !form.subtotal) { setModalError('Booking ID and subtotal are required.'); return; }
    setSubmitting(true); setModalError('');
    try {
      const subtotal = Number(form.subtotal);
      const taxRate = Number(form.taxRate) || 0;
      const tax = subtotal * taxRate / 100;
      const total = subtotal + tax;
      await api('/api/invoices', { method: 'POST', body: { bookingId: form.bookingId, subtotal, taxRate, tax, total, notes: form.notes, language: form.language } });
      setShowModal(false);
      load();
    } catch (e: any) { setModalError(e.message); }
    finally { setSubmitting(false); }
  };

  const handleStatusChange = async (id: string, status: string) => {
    try {
      await api(`/api/invoices/${id}`, { method: 'PATCH', body: { status } });
      load();
    } catch (e: any) { alert(e.message); }
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Delete this invoice?')) return;
    try { await api(`/api/invoices/${id}`, { method: 'DELETE' }); load(); } catch (e: any) { alert(e.message); }
  };

  const subtotal = Number(form.subtotal) || 0;
  const taxAmt = subtotal * (Number(form.taxRate) || 0) / 100;

  return (
    <AppShell>
      <div style={{ padding: 24 }}>
        <div className="toolbar" style={{ marginBottom: 16 }}>
          <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 24 }}>Invoices</div>
          <span className="spacer" />
          <button className="btn" style={{ background: 'var(--orange)', color: '#000' }} onClick={() => { setForm(blank()); setModalError(''); setShowModal(true); }}>+ Create Invoice</button>
        </div>

        {error && <div className="error" style={{ marginBottom: 12 }}>{error}</div>}

        {/* Summary Cards */}
        <div className="cards cards-4" style={{ marginBottom: 20 }}>
          {[
            { label: 'Total', value: total, color: 'var(--film)' },
            { label: 'Billed', value: billed, color: 'var(--blue)' },
            { label: 'Paid', value: paid, color: 'var(--green)' },
            { label: 'Outstanding', value: outstanding, color: 'var(--red)' },
          ].map((k) => (
            <div key={k.label} className="card" style={{ textAlign: 'center' }}>
              <div className="muted text-sm" style={{ marginBottom: 6 }}>{k.label}</div>
              <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 26, color: k.color }}>{tk(k.value)}</div>
            </div>
          ))}
        </div>

        {/* Filter */}
        <div className="chip-row" style={{ marginBottom: 16 }}>
          {STATUSES.map((s) => (
            <button key={s} className={`chip${filter === s ? ' active' : ''}`} onClick={() => setFilter(s)}>{s}</button>
          ))}
        </div>

        <div className="panel">
          <div className="panel-header">
            <span className="panel-title">Invoice List</span>
            <span className="badge gray">{filtered.length}</span>
          </div>
          <div className="panel-body">
            {loading && [...Array(5)].map((_, i) => <div key={i} className="shimmer" style={{ height: 48, borderRadius: 6, marginBottom: 8 }} />)}
            {!loading && filtered.length === 0 && <div className="empty">No invoices found.</div>}
            {!loading && filtered.length > 0 && (
              <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                <thead>
                  <tr style={{ borderBottom: '1px solid var(--surface-3)' }}>
                    {['#', 'Booking', 'Client', 'Subtotal', 'Tax', 'Total', 'Status', 'Date', 'Actions'].map((h) => (
                      <th key={h} style={{ textAlign: 'left', padding: '8px 10px', fontSize: 11, fontFamily: 'JetBrains Mono, monospace', color: 'var(--film-muted)', textTransform: 'uppercase' }}>{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {filtered.map((inv) => (
                    <tr key={inv.id} style={{ borderBottom: '1px solid var(--surface-3)' }}>
                      <td style={{ padding: '10px', fontSize: 12, fontFamily: 'JetBrains Mono, monospace', color: 'var(--film-muted)' }}>#{inv.invoiceNumber || inv.id?.slice(0, 6)}</td>
                      <td style={{ padding: '10px', fontSize: 13 }}>{inv.booking?.title || inv.bookingId || '—'}</td>
                      <td style={{ padding: '10px', fontSize: 13 }}>{inv.booking?.clientName || inv.client?.name || '—'}</td>
                      <td style={{ padding: '10px', fontSize: 13 }}>{tk(Number(inv.subtotal) || 0)}</td>
                      <td style={{ padding: '10px', fontSize: 13 }}>{inv.taxRate || 0}%</td>
                      <td style={{ padding: '10px', fontSize: 13, color: 'var(--orange)' }}>{tk(Number(inv.total) || 0)}</td>
                      <td style={{ padding: '10px' }}>{statusBadge(inv.status)}</td>
                      <td style={{ padding: '10px', fontSize: 12 }}>{fmtDate(inv.createdAt || inv.created_at)}</td>
                      <td style={{ padding: '10px' }}>
                        <div className="row" style={{ gap: 4 }}>
                          <Link href={`/app/invoices/${inv.id}`} className="btn ghost xs">View</Link>
                          <select
                            className="field"
                            value={inv.status}
                            onChange={(e) => handleStatusChange(inv.id, e.target.value)}
                            style={{ fontSize: 11, padding: '2px 4px', height: 24 }}
                          >
                            <option value="DRAFT">Draft</option>
                            <option value="SENT">Sent</option>
                            <option value="PAID">Paid</option>
                            <option value="OVERDUE">Overdue</option>
                          </select>
                          <button className="btn danger xs" onClick={() => handleDelete(inv.id)}>×</button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </div>
      </div>

      {/* Create Modal */}
      {showModal && (
        <div className="modal-backdrop" onClick={() => setShowModal(false)}>
          <div className="modal" onClick={(e) => e.stopPropagation()}>
            <div className="row" style={{ marginBottom: 16 }}>
              <span style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 20 }}>Create Invoice</span>
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
                  <label>Subtotal (৳) *</label>
                  <input type="number" className="field" required value={form.subtotal} onChange={(e) => setForm({ ...form, subtotal: e.target.value })} placeholder="0" />
                </div>
                <div className="field">
                  <label>Tax Rate (%)</label>
                  <input type="number" min={0} max={30} className="field" value={form.taxRate} onChange={(e) => setForm({ ...form, taxRate: e.target.value })} placeholder="0" />
                </div>
              </div>
              {subtotal > 0 && (
                <div className="card" style={{ marginBottom: 12, padding: '10px 12px' }}>
                  <div className="row" style={{ justifyContent: 'space-between' }}>
                    <span className="muted text-sm">Subtotal</span><span>{tk(subtotal)}</span>
                  </div>
                  <div className="row" style={{ justifyContent: 'space-between' }}>
                    <span className="muted text-sm">Tax ({form.taxRate || 0}%)</span><span>{tk(taxAmt)}</span>
                  </div>
                  <div className="divider" style={{ margin: '6px 0' }} />
                  <div className="row" style={{ justifyContent: 'space-between' }}>
                    <span style={{ fontWeight: 700 }}>Total</span>
                    <span style={{ color: 'var(--orange)', fontFamily: 'Bebas Neue, sans-serif', fontSize: 20 }}>{tk(subtotal + taxAmt)}</span>
                  </div>
                </div>
              )}
              <div className="field" style={{ marginBottom: 12 }}>
                <label>Language</label>
                <select className="field" value={form.language} onChange={(e) => setForm({ ...form, language: e.target.value })}>
                  <option value="EN">English</option>
                </select>
              </div>
              <div className="field" style={{ marginBottom: 16 }}>
                <label>Notes</label>
                <textarea className="field" rows={3} value={form.notes} onChange={(e) => setForm({ ...form, notes: e.target.value })} placeholder="Any notes for this invoice..." />
              </div>
              <div className="row" style={{ gap: 10, justifyContent: 'flex-end' }}>
                <button type="button" className="btn ghost" onClick={() => setShowModal(false)}>Cancel</button>
                <button type="submit" className="btn" style={{ background: 'var(--orange)', color: '#000' }} disabled={submitting}>{submitting ? 'Creating...' : 'Create Invoice'}</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </AppShell>
  );
}
