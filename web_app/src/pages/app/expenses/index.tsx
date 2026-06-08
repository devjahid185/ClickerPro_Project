import { useEffect, useState, FormEvent } from 'react';
import AppShell from '@/components/AppShell';
import { api } from '@/lib/api';
import { tk } from '@/lib/format';

const fmtDate = (d: string) =>
  d ? new Date(d).toLocaleDateString('en-BD', { day: 'numeric', month: 'short', year: 'numeric' }) : '—';

const CATEGORIES = ['ALL', 'Travel', 'Food', 'Gear', 'Print', 'Phone', 'Other'];
const CAT_COLORS: Record<string, string> = { Travel: 'blue', Food: 'green', Gear: 'orange', Print: 'purple', Phone: 'teal', Other: 'gray' };

const blank = () => ({ title: '', amount: '', category: 'Travel', date: '', eventId: '', note: '' });

export default function ExpensesPage() {
  const [expenses, setExpenses] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [catFilter, setCatFilter] = useState('ALL');
  const [showModal, setShowModal] = useState(false);
  const [editId, setEditId] = useState<string | null>(null);
  const [form, setForm] = useState<any>(blank());
  const [submitting, setSubmitting] = useState(false);
  const [modalError, setModalError] = useState('');
  const [deleteId, setDeleteId] = useState<string | null>(null);

  const load = async () => {
    setLoading(true);
    try {
      const res = await api<any>('/api/expenses');
      setExpenses(Array.isArray(res) ? res : res?.data ?? res?.expenses ?? []);
    } catch (e: any) { setError(e.message); }
    finally { setLoading(false); }
  };

  useEffect(() => { load(); }, []);

  const filtered = expenses.filter((e) => catFilter === 'ALL' || e.category === catFilter);

  const total = expenses.reduce((s, e) => s + (Number(e.amount) || 0), 0);

  const now = new Date();
  const monthTotal = expenses
    .filter((e) => {
      const d = new Date(e.date || e.createdAt || 0);
      return d.getMonth() === now.getMonth() && d.getFullYear() === now.getFullYear();
    })
    .reduce((s, e) => s + (Number(e.amount) || 0), 0);

  const catBreakdown = CATEGORIES.slice(1).map((cat) => ({
    cat,
    total: expenses.filter((e) => e.category === cat).reduce((s, e) => s + (Number(e.amount) || 0), 0),
  }));

  const openNew = () => { setForm(blank()); setEditId(null); setModalError(''); setShowModal(true); };
  const openEdit = (exp: any) => {
    setForm({ title: exp.title || '', amount: exp.amount || '', category: exp.category || 'Travel', date: exp.date?.split('T')[0] || '', eventId: exp.eventId || exp.event_id || '', note: exp.note || exp.notes || '' });
    setEditId(exp.id); setModalError(''); setShowModal(true);
  };

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    if (!form.title || !form.amount) { setModalError('Title and amount are required.'); return; }
    setSubmitting(true); setModalError('');
    try {
      if (editId) {
        await api(`/api/expenses/${editId}`, { method: 'PATCH', body: { ...form, amount: Number(form.amount) } });
      } else {
        await api('/api/expenses', { method: 'POST', body: { ...form, amount: Number(form.amount) } });
      }
      setShowModal(false);
      load();
    } catch (e: any) { setModalError(e.message); }
    finally { setSubmitting(false); }
  };

  const handleDelete = async (id: string) => {
    try { await api(`/api/expenses/${id}`, { method: 'DELETE' }); setDeleteId(null); load(); } catch (e: any) { alert(e.message); }
  };

  const maxCat = Math.max(...catBreakdown.map((c) => c.total), 1);

  return (
    <AppShell>
      <div style={{ padding: 24 }}>
        <div className="toolbar" style={{ marginBottom: 16 }}>
          <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 24 }}>Expenses</div>
          <span className="spacer" />
          <button className="btn" style={{ background: 'var(--orange)', color: '#000' }} onClick={openNew}>+ Add Expense</button>
        </div>

        {error && <div className="error" style={{ marginBottom: 12 }}>{error}</div>}

        {/* Summary */}
        <div className="cards cards-2" style={{ marginBottom: 20 }}>
          <div className="card" style={{ textAlign: 'center' }}>
            <div className="muted text-sm" style={{ marginBottom: 6 }}>Total Expenses</div>
            <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 30, color: 'var(--red)' }}>{tk(total)}</div>
          </div>
          <div className="card" style={{ textAlign: 'center' }}>
            <div className="muted text-sm" style={{ marginBottom: 6 }}>This Month</div>
            <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 30, color: 'var(--gold)' }}>{tk(monthTotal)}</div>
          </div>
        </div>

        {/* Category Breakdown */}
        <div className="panel" style={{ marginBottom: 20 }}>
          <div className="panel-header"><span className="panel-title">By Category</span></div>
          <div className="panel-body">
            {catBreakdown.map(({ cat, total: t }) => (
              <div key={cat} style={{ marginBottom: 10 }}>
                <div className="row" style={{ justifyContent: 'space-between', marginBottom: 4 }}>
                  <span className="text-sm" style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
                    <span className={`badge ${CAT_COLORS[cat] || 'gray'}`}>{cat}</span>
                  </span>
                  <span className="text-sm" style={{ fontFamily: 'JetBrains Mono, monospace' }}>{tk(t)}</span>
                </div>
                <div style={{ background: 'var(--surface-3)', borderRadius: 4, height: 6 }}>
                  <div style={{ width: `${(t / maxCat) * 100}%`, height: '100%', background: 'var(--orange)', borderRadius: 4 }} />
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Filter */}
        <div className="chip-row" style={{ marginBottom: 16 }}>
          {CATEGORIES.map((c) => (
            <button key={c} className={`chip${catFilter === c ? ' active' : ''}`} onClick={() => setCatFilter(c)}>{c}</button>
          ))}
        </div>

        <div className="panel">
          <div className="panel-header">
            <span className="panel-title">Expense List</span>
            <span className="badge gray">{filtered.length}</span>
          </div>
          <div className="panel-body">
            {loading && [...Array(5)].map((_, i) => <div key={i} className="shimmer" style={{ height: 48, borderRadius: 6, marginBottom: 8 }} />)}
            {!loading && filtered.length === 0 && <div className="empty">No expenses found.</div>}
            {!loading && filtered.length > 0 && (
              <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                <thead>
                  <tr style={{ borderBottom: '1px solid var(--surface-3)' }}>
                    {['Title', 'Amount', 'Category', 'Date', 'Event', 'Note', 'Actions'].map((h) => (
                      <th key={h} style={{ textAlign: 'left', padding: '8px 10px', fontSize: 11, fontFamily: 'JetBrains Mono, monospace', color: 'var(--film-muted)', textTransform: 'uppercase' }}>{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {filtered.map((exp) => (
                    <tr key={exp.id} style={{ borderBottom: '1px solid var(--surface-3)' }}>
                      <td style={{ padding: '10px', fontSize: 14, fontWeight: 600 }}>{exp.title}</td>
                      <td style={{ padding: '10px', fontFamily: 'Bebas Neue, sans-serif', fontSize: 20, color: 'var(--red)' }}>{tk(Number(exp.amount) || 0)}</td>
                      <td style={{ padding: '10px' }}><span className={`badge ${CAT_COLORS[exp.category] || 'gray'}`}>{exp.category}</span></td>
                      <td style={{ padding: '10px', fontSize: 12 }}>{fmtDate(exp.date || exp.createdAt)}</td>
                      <td style={{ padding: '10px', fontSize: 12, color: 'var(--film-muted)' }}>{exp.eventId || exp.event_id || '—'}</td>
                      <td style={{ padding: '10px', fontSize: 12, color: 'var(--film-muted)' }} className="truncate">{exp.note || exp.notes || '—'}</td>
                      <td style={{ padding: '10px' }}>
                        <div className="row" style={{ gap: 4 }}>
                          <button className="btn ghost xs" onClick={() => openEdit(exp)}>Edit</button>
                          <button className="btn danger xs" onClick={() => setDeleteId(exp.id)}>Del</button>
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

      {/* Add/Edit Modal */}
      {showModal && (
        <div className="modal-backdrop" onClick={() => setShowModal(false)}>
          <div className="modal" onClick={(e) => e.stopPropagation()}>
            <div className="row" style={{ marginBottom: 16 }}>
              <span style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 20 }}>{editId ? 'Edit Expense' : 'Add Expense'}</span>
              <span className="spacer" />
              <button className="btn ghost xs" onClick={() => setShowModal(false)}>×</button>
            </div>
            {modalError && <div className="error" style={{ marginBottom: 10 }}>{modalError}</div>}
            <form onSubmit={handleSubmit}>
              <div className="form-grid">
                <div className="field" style={{ gridColumn: '1/-1' }}>
                  <label>Title *</label>
                  <input className="field" required value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} placeholder="Expense title" />
                </div>
                <div className="field">
                  <label>Amount (৳) *</label>
                  <input type="number" className="field" required value={form.amount} onChange={(e) => setForm({ ...form, amount: e.target.value })} placeholder="0" />
                </div>
                <div className="field">
                  <label>Category</label>
                  <select className="field" value={form.category} onChange={(e) => setForm({ ...form, category: e.target.value })}>
                    {CATEGORIES.slice(1).map((c) => <option key={c}>{c}</option>)}
                  </select>
                </div>
                <div className="field">
                  <label>Date</label>
                  <input type="date" className="field" value={form.date} onChange={(e) => setForm({ ...form, date: e.target.value })} />
                </div>
                <div className="field">
                  <label>Event ID (optional)</label>
                  <input className="field" value={form.eventId} onChange={(e) => setForm({ ...form, eventId: e.target.value })} placeholder="Booking/event ID" />
                </div>
                <div className="field" style={{ gridColumn: '1/-1' }}>
                  <label>Note</label>
                  <textarea className="field" rows={2} value={form.note} onChange={(e) => setForm({ ...form, note: e.target.value })} placeholder="Optional note..." />
                </div>
              </div>
              <div className="row" style={{ gap: 10, marginTop: 16, justifyContent: 'flex-end' }}>
                <button type="button" className="btn ghost" onClick={() => setShowModal(false)}>Cancel</button>
                <button type="submit" className="btn" style={{ background: 'var(--orange)', color: '#000' }} disabled={submitting}>{submitting ? 'Saving...' : editId ? 'Save' : 'Add Expense'}</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {deleteId && (
        <div className="modal-backdrop" onClick={() => setDeleteId(null)}>
          <div className="modal" onClick={(e) => e.stopPropagation()} style={{ maxWidth: 380 }}>
            <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 20, marginBottom: 12 }}>Delete Expense?</div>
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
