import { useEffect, useState, FormEvent } from 'react';
import { useRouter } from 'next/router';
import AppShell from '@/components/AppShell';
import { api } from '@/lib/api';

const fmtDate = (d: string) =>
  d ? new Date(d).toLocaleDateString('en-BD', { day: 'numeric', month: 'short', year: 'numeric' }) : '—';

const blank = () => ({ name: '', phone: '', email: '', dateRequested: '', notes: '' });

export default function WaitlistPage() {
  const router = useRouter();
  const [waitlist, setWaitlist] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [form, setForm] = useState<any>(blank());
  const [submitting, setSubmitting] = useState(false);
  const [modalError, setModalError] = useState('');
  const [deleteId, setDeleteId] = useState<string | null>(null);

  const load = async () => {
    setLoading(true);
    try {
      const res = await api<any>('/api/waitlist');
      setWaitlist(Array.isArray(res) ? res : res?.data ?? res?.waitlist ?? []);
    } catch (e: any) { setError(e.message); }
    finally { setLoading(false); }
  };

  useEffect(() => { load(); }, []);

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    if (!form.name.trim()) { setModalError('Name is required.'); return; }
    setSubmitting(true); setModalError('');
    try {
      await api('/api/waitlist', { method: 'POST', body: form });
      setShowModal(false);
      setForm(blank());
      load();
    } catch (e: any) { setModalError(e.message); }
    finally { setSubmitting(false); }
  };

  const handleDelete = async (id: string) => {
    try {
      await api(`/api/waitlist/${id}`, { method: 'DELETE' });
      setDeleteId(null);
      load();
    } catch (e: any) { alert(e.message); }
  };

  const convertToBooking = (w: any) => {
    const params = new URLSearchParams();
    if (w.name) params.set('clientName', w.name);
    if (w.phone) params.set('clientPhone', w.phone);
    if (w.dateRequested) params.set('date', w.dateRequested?.split('T')[0] || '');
    router.push(`/app/bookings?${params.toString()}`);
  };

  return (
    <AppShell>
      <div style={{ padding: 24 }}>
        <div className="toolbar" style={{ marginBottom: 16 }}>
          <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 24 }}>Waitlist</div>
          <span className="spacer" />
          <button className="btn" style={{ background: 'var(--orange)', color: '#000' }} onClick={() => { setForm(blank()); setModalError(''); setShowModal(true); }}>+ Add to Waitlist</button>
        </div>

        {error && <div className="error" style={{ marginBottom: 12 }}>{error}</div>}

        {/* Count */}
        <div className="card" style={{ marginBottom: 20, display: 'inline-flex', alignItems: 'center', gap: 12, padding: '12px 20px' }}>
          <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 36, color: 'var(--orange)' }}>{waitlist.length}</div>
          <div className="muted">Total on Waitlist</div>
        </div>

        <div className="panel">
          <div className="panel-header">
            <span className="panel-title">Waitlist Entries</span>
          </div>
          <div className="panel-body">
            {loading && [...Array(4)].map((_, i) => <div key={i} className="shimmer" style={{ height: 52, borderRadius: 6, marginBottom: 8 }} />)}
            {!loading && waitlist.length === 0 && <div className="empty">No one on the waitlist.</div>}
            {!loading && waitlist.length > 0 && (
              <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                <thead>
                  <tr style={{ borderBottom: '1px solid var(--surface-3)' }}>
                    {['Name', 'Phone', 'Email', 'Date Requested', 'Notes', 'Actions'].map((h) => (
                      <th key={h} style={{ textAlign: 'left', padding: '8px 10px', fontSize: 11, fontFamily: 'JetBrains Mono, monospace', color: 'var(--film-muted)', textTransform: 'uppercase' }}>{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {waitlist.map((w) => (
                    <tr key={w.id} style={{ borderBottom: '1px solid var(--surface-3)' }}>
                      <td style={{ padding: '12px 10px', fontWeight: 600, fontSize: 14 }}>{w.name}</td>
                      <td style={{ padding: '12px 10px', fontSize: 13 }}>{w.phone || '—'}</td>
                      <td style={{ padding: '12px 10px', fontSize: 13 }}>{w.email || '—'}</td>
                      <td style={{ padding: '12px 10px', fontSize: 13 }}>{fmtDate(w.dateRequested || w.date_requested)}</td>
                      <td style={{ padding: '12px 10px', fontSize: 12, color: 'var(--film-muted)', maxWidth: 160 }} className="truncate">{w.notes || '—'}</td>
                      <td style={{ padding: '12px 10px' }}>
                        <div className="row" style={{ gap: 6 }}>
                          <button className="btn ghost xs" onClick={() => convertToBooking(w)}>→ Booking</button>
                          <button className="btn danger xs" onClick={() => setDeleteId(w.id)}>Del</button>
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

      {/* Modal */}
      {showModal && (
        <div className="modal-backdrop" onClick={() => setShowModal(false)}>
          <div className="modal" onClick={(e) => e.stopPropagation()}>
            <div className="row" style={{ marginBottom: 16 }}>
              <span style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 20 }}>Add to Waitlist</span>
              <span className="spacer" />
              <button className="btn ghost xs" onClick={() => setShowModal(false)}>×</button>
            </div>
            {modalError && <div className="error" style={{ marginBottom: 10 }}>{modalError}</div>}
            <form onSubmit={handleSubmit}>
              <div className="form-grid">
                <div className="field" style={{ gridColumn: '1/-1' }}>
                  <label>Name *</label>
                  <input className="field" required value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} placeholder="Client name" />
                </div>
                <div className="field">
                  <label>Phone</label>
                  <input className="field" value={form.phone} onChange={(e) => setForm({ ...form, phone: e.target.value })} placeholder="+880..." />
                </div>
                <div className="field">
                  <label>Email</label>
                  <input type="email" className="field" value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} />
                </div>
                <div className="field">
                  <label>Date Requested</label>
                  <input type="date" className="field" value={form.dateRequested} onChange={(e) => setForm({ ...form, dateRequested: e.target.value })} />
                </div>
                <div className="field" style={{ gridColumn: '1/-1' }}>
                  <label>Notes</label>
                  <textarea className="field" rows={3} value={form.notes} onChange={(e) => setForm({ ...form, notes: e.target.value })} placeholder="Any notes..." />
                </div>
              </div>
              <div className="row" style={{ gap: 10, marginTop: 16, justifyContent: 'flex-end' }}>
                <button type="button" className="btn ghost" onClick={() => setShowModal(false)}>Cancel</button>
                <button type="submit" className="btn" style={{ background: 'var(--orange)', color: '#000' }} disabled={submitting}>{submitting ? 'Adding...' : 'Add to Waitlist'}</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Delete Confirm */}
      {deleteId && (
        <div className="modal-backdrop" onClick={() => setDeleteId(null)}>
          <div className="modal" onClick={(e) => e.stopPropagation()} style={{ maxWidth: 380 }}>
            <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 20, marginBottom: 12 }}>Remove from Waitlist?</div>
            <p className="muted" style={{ marginBottom: 20 }}>This cannot be undone.</p>
            <div className="row" style={{ gap: 10, justifyContent: 'flex-end' }}>
              <button className="btn ghost" onClick={() => setDeleteId(null)}>Cancel</button>
              <button className="btn danger" onClick={() => handleDelete(deleteId)}>Remove</button>
            </div>
          </div>
        </div>
      )}
    </AppShell>
  );
}
