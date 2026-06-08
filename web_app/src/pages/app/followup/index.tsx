import { useEffect, useState, FormEvent } from 'react';
import AppShell from '@/components/AppShell';
import { api } from '@/lib/api';

const fmtDate = (d: string) =>
  d ? new Date(d).toLocaleDateString('en-BD', { day: 'numeric', month: 'short', year: 'numeric' }) : '—';

const TYPES = ['album', 'payment', 'feedback'];
const TYPE_LABELS: Record<string, string> = { album: 'Album', payment: 'Payment', feedback: 'Feedback' };
const TYPE_COLORS: Record<string, string> = { album: 'purple', payment: 'gold', feedback: 'teal' };

const today = () => new Date().toISOString().split('T')[0];
const blank = () => ({ event_id: '', type: 'album', scheduled_date: today(), note: '' });

const isOverdue = (f: any) => !f.completed && f.scheduled_date && new Date(f.scheduled_date) < new Date(today());

export default function FollowupPage() {
  const [followups, setFollowups] = useState<any[]>([]);
  const [bookings, setBookings] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [statusFilter, setStatusFilter] = useState('ALL');
  const [typeFilter, setTypeFilter] = useState('ALL');
  const [showModal, setShowModal] = useState(false);
  const [form, setForm] = useState<any>(blank());
  const [submitting, setSubmitting] = useState(false);
  const [modalError, setModalError] = useState('');
  const [togglingId, setTogglingId] = useState<string | null>(null);
  const [deleteId, setDeleteId] = useState<string | null>(null);

  const load = async () => {
    setLoading(true);
    setError('');
    try {
      const [resF, resB] = await Promise.all([
        api<any>('/api/followups'),
        api<any>('/api/bookings?limit=200'),
      ]);
      setFollowups(Array.isArray(resF) ? resF : resF?.data ?? []);
      setBookings(Array.isArray(resB) ? resB : resB?.data ?? []);
    } catch (e: any) { setError(e.message); }
    finally { setLoading(false); }
  };

  useEffect(() => { load(); }, []);

  const bookingTitle = (f: any) =>
    f.event?.title || bookings.find((b) => b.id === f.event_id)?.title || '—';

  const filtered = followups
    .filter((f) => {
      if (statusFilter === 'PENDING') return !f.completed;
      if (statusFilter === 'COMPLETED') return f.completed;
      if (statusFilter === 'OVERDUE') return isOverdue(f);
      return true;
    })
    .filter((f) => typeFilter === 'ALL' || f.type === typeFilter)
    .sort((a, b) => {
      if (!!a.completed !== !!b.completed) return a.completed ? 1 : -1;
      const da = new Date(a.scheduled_date || 0).getTime();
      const db = new Date(b.scheduled_date || 0).getTime();
      return da - db;
    });

  const openNew = () => { setForm(blank()); setModalError(''); setShowModal(true); };

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    if (!form.scheduled_date) { setModalError('Scheduled date is required.'); return; }
    setSubmitting(true); setModalError('');
    try {
      await api('/api/followups', {
        method: 'POST',
        body: {
          event_id: form.event_id || null,
          type: form.type,
          scheduled_date: form.scheduled_date,
          note: form.note,
        },
      });
      setShowModal(false);
      load();
    } catch (e: any) { setModalError(e.message); }
    finally { setSubmitting(false); }
  };

  const toggleCompleted = async (f: any) => {
    setTogglingId(f.id);
    try {
      await api(`/api/followups/${f.id}`, { method: 'PATCH', body: { completed: !f.completed } });
      load();
    } catch (e: any) { alert(e.message); }
    finally { setTogglingId(null); }
  };

  const handleDelete = async (id: string) => {
    try { await api(`/api/followups/${id}`, { method: 'DELETE' }); setDeleteId(null); load(); } catch (e: any) { alert(e.message); }
  };

  return (
    <AppShell>
      <div style={{ padding: 24 }}>
        <div className="toolbar" style={{ marginBottom: 4 }}>
          <div>
            <h1 className="page-title">Follow-ups</h1>
            <p className="page-sub">Stay on top of client follow-ups</p>
          </div>
          <span className="spacer" />
          <button className="btn" style={{ background: 'var(--orange)', color: '#000' }} onClick={openNew}>+ New Follow-up</button>
        </div>

        {error && <div className="error" style={{ marginBottom: 12 }}>{error}</div>}

        {/* Status Filter */}
        <div className="chip-row" style={{ marginTop: 16, marginBottom: 10 }}>
          {[['ALL', 'All'], ['PENDING', 'Pending'], ['COMPLETED', 'Completed'], ['OVERDUE', 'Overdue']].map(([v, l]) => (
            <button key={v} className={`chip${statusFilter === v ? ' active' : ''}`} onClick={() => setStatusFilter(v)}>{l}</button>
          ))}
        </div>

        {/* Type Filter */}
        <div className="chip-row" style={{ marginBottom: 16 }}>
          <button className={`chip${typeFilter === 'ALL' ? ' active' : ''}`} onClick={() => setTypeFilter('ALL')}>All Types</button>
          {TYPES.map((t) => (
            <button key={t} className={`chip${typeFilter === t ? ' active' : ''}`} onClick={() => setTypeFilter(t)}>{TYPE_LABELS[t]}</button>
          ))}
        </div>

        <div className="panel">
          <div className="panel-header">
            <span className="panel-title">Follow-up List</span>
            <span className="badge gray">{filtered.length}</span>
          </div>
          <div className="panel-body">
            {loading && [...Array(5)].map((_, i) => <div key={i} className="shimmer" style={{ height: 56, borderRadius: 6, marginBottom: 8 }} />)}
            {!loading && filtered.length === 0 && <div className="empty">No follow-ups found.</div>}
            {!loading && filtered.length > 0 && filtered.map((f) => {
              const overdue = isOverdue(f);
              return (
                <div key={f.id} className="row" style={{ alignItems: 'flex-start', gap: 12, padding: '12px 4px', borderBottom: '1px solid var(--surface-3)', opacity: f.completed ? 0.55 : 1 }}>
                  <input
                    type="checkbox"
                    checked={!!f.completed}
                    disabled={togglingId === f.id}
                    onChange={() => toggleCompleted(f)}
                    style={{ marginTop: 4, width: 18, height: 18, accentColor: 'var(--orange)', cursor: 'pointer' }}
                  />
                  <div style={{ flex: 1 }}>
                    <div className="row" style={{ gap: 8, alignItems: 'center', marginBottom: 4, flexWrap: 'wrap' }}>
                      <span className={`badge ${TYPE_COLORS[f.type] || 'gray'}`}>{TYPE_LABELS[f.type] || f.type}</span>
                      <span style={{ fontWeight: 600, textDecoration: f.completed ? 'line-through' : 'none' }}>{bookingTitle(f)}</span>
                      {overdue && <span className="badge red">Overdue</span>}
                    </div>
                    {f.note && <div className="text-sm muted" style={{ textDecoration: f.completed ? 'line-through' : 'none' }}>{f.note}</div>}
                  </div>
                  <div style={{ textAlign: 'right', minWidth: 110 }}>
                    <div className="text-sm" style={{ color: overdue ? 'var(--red)' : 'var(--film-muted)' }}>{fmtDate(f.scheduled_date)}</div>
                    <button className="btn danger xs" style={{ marginTop: 6 }} onClick={() => setDeleteId(f.id)}>Delete</button>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </div>

      {/* New Follow-up Modal */}
      {showModal && (
        <div className="modal-backdrop" onClick={() => setShowModal(false)}>
          <div className="modal" onClick={(e) => e.stopPropagation()}>
            <div className="row" style={{ marginBottom: 16 }}>
              <span style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 20 }}>New Follow-up</span>
              <span className="spacer" />
              <button className="btn ghost xs" onClick={() => setShowModal(false)}>×</button>
            </div>
            {modalError && <div className="error" style={{ marginBottom: 10 }}>{modalError}</div>}
            <form onSubmit={handleSubmit}>
              <div className="form-grid">
                <div className="field" style={{ gridColumn: '1/-1' }}>
                  <label>Booking (optional)</label>
                  <select className="field" value={form.event_id} onChange={(e) => setForm({ ...form, event_id: e.target.value })}>
                    <option value="">No booking</option>
                    {bookings.map((b) => <option key={b.id} value={b.id}>{b.title}</option>)}
                  </select>
                </div>
                <div className="field">
                  <label>Type</label>
                  <select className="field" value={form.type} onChange={(e) => setForm({ ...form, type: e.target.value })}>
                    {TYPES.map((t) => <option key={t} value={t}>{TYPE_LABELS[t]}</option>)}
                  </select>
                </div>
                <div className="field">
                  <label>Scheduled Date *</label>
                  <input type="date" className="field" required value={form.scheduled_date} onChange={(e) => setForm({ ...form, scheduled_date: e.target.value })} />
                </div>
                <div className="field" style={{ gridColumn: '1/-1' }}>
                  <label>Note</label>
                  <textarea className="field" rows={2} value={form.note} onChange={(e) => setForm({ ...form, note: e.target.value })} placeholder="Optional note..." />
                </div>
              </div>
              <div className="row" style={{ gap: 10, marginTop: 16, justifyContent: 'flex-end' }}>
                <button type="button" className="btn ghost" onClick={() => setShowModal(false)}>Cancel</button>
                <button type="submit" className="btn" style={{ background: 'var(--orange)', color: '#000' }} disabled={submitting}>{submitting ? 'Saving...' : 'Create'}</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {deleteId && (
        <div className="modal-backdrop" onClick={() => setDeleteId(null)}>
          <div className="modal" onClick={(e) => e.stopPropagation()} style={{ maxWidth: 380 }}>
            <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 20, marginBottom: 12 }}>Delete Follow-up?</div>
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
