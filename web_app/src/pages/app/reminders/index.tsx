import { useEffect, useState, FormEvent } from 'react';
import AppShell from '@/components/AppShell';
import { api } from '@/lib/api';

const fmtDateTime = (d: string) =>
  d ? new Date(d).toLocaleString('en-BD', { day: 'numeric', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' }) : '—';

const REMINDER_TYPES = ['PAYMENT_DUE', 'DELIVERY', 'FEEDBACK', 'CUSTOM'];
const TYPE_COLORS: Record<string, string> = { PAYMENT_DUE: 'orange', DELIVERY: 'blue', FEEDBACK: 'teal', CUSTOM: 'purple' };

const blank = () => ({ type: 'PAYMENT_DUE', message: '', eventId: '', remindAt: '' });

function StatusBadge({ sent, remindAt }: { sent: boolean; remindAt: string }) {
  const isPast = remindAt && new Date(remindAt) < new Date();
  if (sent) return <span className="badge green">Sent</span>;
  if (isPast) return <span className="badge red">Overdue</span>;
  return <span className="badge gold">Scheduled</span>;
}

export default function RemindersPage() {
  const [reminders, setReminders] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [filter, setFilter] = useState('ALL');
  const [showModal, setShowModal] = useState(false);
  const [form, setForm] = useState<any>(blank());
  const [submitting, setSubmitting] = useState(false);
  const [modalError, setModalError] = useState('');
  const [deleteId, setDeleteId] = useState<string | null>(null);

  const load = async () => {
    setLoading(true);
    try {
      const res = await api<any>('/api/reminders');
      setReminders(Array.isArray(res) ? res : res?.data ?? res?.reminders ?? []);
    } catch (e: any) { setError(e.message); }
    finally { setLoading(false); }
  };

  useEffect(() => { load(); }, []);

  const filtered = reminders.filter((r) => {
    if (filter === 'ALL') return true;
    if (filter === 'Upcoming') return !r.sent && new Date(r.remindAt) >= new Date();
    if (filter === 'Sent') return r.sent;
    return true;
  });

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    if (!form.message || !form.remindAt) { setModalError('Message and remind time are required.'); return; }
    setSubmitting(true); setModalError('');
    try {
      await api('/api/reminders', { method: 'POST', body: form });
      setShowModal(false);
      setForm(blank());
      load();
    } catch (e: any) { setModalError(e.message); }
    finally { setSubmitting(false); }
  };

  const handleDelete = async (id: string) => {
    try { await api(`/api/reminders/${id}`, { method: 'DELETE' }); setDeleteId(null); load(); } catch (e: any) { alert(e.message); }
  };

  return (
    <AppShell>
      <div style={{ padding: 24 }}>
        <div className="toolbar" style={{ marginBottom: 16 }}>
          <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 24 }}>Reminders</div>
          <span className="spacer" />
          <button className="btn" style={{ background: 'var(--orange)', color: '#000' }} onClick={() => { setForm(blank()); setModalError(''); setShowModal(true); }}>+ Add Reminder</button>
        </div>

        {error && <div className="error" style={{ marginBottom: 12 }}>{error}</div>}

        <div className="chip-row" style={{ marginBottom: 16 }}>
          {['ALL', 'Upcoming', 'Sent'].map((f) => (
            <button key={f} className={`chip${filter === f ? ' active' : ''}`} onClick={() => setFilter(f)}>{f}</button>
          ))}
        </div>

        <div className="panel">
          <div className="panel-header">
            <span className="panel-title">Reminders</span>
            <span className="badge gray">{filtered.length}</span>
          </div>
          <div className="panel-body">
            {loading && [...Array(4)].map((_, i) => <div key={i} className="shimmer" style={{ height: 52, borderRadius: 6, marginBottom: 8 }} />)}
            {!loading && filtered.length === 0 && <div className="empty">No reminders found.</div>}
            {!loading && filtered.length > 0 && (
              <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                <thead>
                  <tr style={{ borderBottom: '1px solid var(--surface-3)' }}>
                    {['Type', 'Message', 'Event', 'Remind At', 'Status', 'Actions'].map((h) => (
                      <th key={h} style={{ textAlign: 'left', padding: '8px 10px', fontSize: 11, fontFamily: 'JetBrains Mono, monospace', color: 'var(--film-muted)', textTransform: 'uppercase' }}>{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {filtered.map((r) => (
                    <tr key={r.id} style={{ borderBottom: '1px solid var(--surface-3)' }}>
                      <td style={{ padding: '10px' }}>
                        <span className={`badge ${TYPE_COLORS[r.type] || 'gray'}`} style={{ fontSize: 10 }}>{r.type?.replace(/_/g, ' ')}</span>
                      </td>
                      <td style={{ padding: '10px', fontSize: 13, maxWidth: 220 }} className="truncate">{r.message}</td>
                      <td style={{ padding: '10px', fontSize: 12, color: 'var(--film-muted)' }}>{r.eventId || r.event_id || '—'}</td>
                      <td style={{ padding: '10px', fontSize: 12 }}>{fmtDateTime(r.remindAt || r.remind_at)}</td>
                      <td style={{ padding: '10px' }}><StatusBadge sent={r.sent} remindAt={r.remindAt || r.remind_at} /></td>
                      <td style={{ padding: '10px' }}>
                        <button className="btn danger xs" onClick={() => setDeleteId(r.id)}>Del</button>
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
              <span style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 20 }}>Add Reminder</span>
              <span className="spacer" />
              <button className="btn ghost xs" onClick={() => setShowModal(false)}>×</button>
            </div>
            {modalError && <div className="error" style={{ marginBottom: 10 }}>{modalError}</div>}
            <form onSubmit={handleSubmit}>
              <div className="field" style={{ marginBottom: 12 }}>
                <label>Type</label>
                <select className="field" value={form.type} onChange={(e) => setForm({ ...form, type: e.target.value })}>
                  {REMINDER_TYPES.map((t) => <option key={t} value={t}>{t.replace(/_/g, ' ')}</option>)}
                </select>
              </div>
              <div className="field" style={{ marginBottom: 12 }}>
                <label>Message *</label>
                <textarea className="field" rows={3} required value={form.message} onChange={(e) => setForm({ ...form, message: e.target.value })} placeholder="Reminder message..." />
              </div>
              <div className="form-grid">
                <div className="field">
                  <label>Event ID (optional)</label>
                  <input className="field" value={form.eventId} onChange={(e) => setForm({ ...form, eventId: e.target.value })} placeholder="Booking ID" />
                </div>
                <div className="field">
                  <label>Remind At *</label>
                  <input type="datetime-local" className="field" required value={form.remindAt} onChange={(e) => setForm({ ...form, remindAt: e.target.value })} />
                </div>
              </div>
              <div className="row" style={{ gap: 10, marginTop: 16, justifyContent: 'flex-end' }}>
                <button type="button" className="btn ghost" onClick={() => setShowModal(false)}>Cancel</button>
                <button type="submit" className="btn" style={{ background: 'var(--orange)', color: '#000' }} disabled={submitting}>{submitting ? 'Adding...' : 'Add Reminder'}</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Delete Confirm */}
      {deleteId && (
        <div className="modal-backdrop" onClick={() => setDeleteId(null)}>
          <div className="modal" onClick={(e) => e.stopPropagation()} style={{ maxWidth: 380 }}>
            <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 20, marginBottom: 12 }}>Delete Reminder?</div>
            <p className="muted" style={{ marginBottom: 20 }}>This cannot be undone.</p>
            <div className="row" style={{ gap: 10, justifyContent: 'flex-end' }}>
              <button className="btn ghost" onClick={() => setDeleteId(null)}>Cancel</button>
              <button className="btn danger" onClick={() => handleDelete(deleteId)}>Delete</button>
            </div>
          </div>
        </div>
      )}
    </AppShell>
  );
}
