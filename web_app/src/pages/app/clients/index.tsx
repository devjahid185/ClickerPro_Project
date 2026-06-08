import { useEffect, useState, FormEvent } from 'react';
import Link from 'next/link';
import AppShell from '@/components/AppShell';
import { api } from '@/lib/api';
import { Client } from '@/types/api';

const fmtDate = (d?: string | null) =>
  d ? new Date(d).toLocaleDateString('en-BD', { day: 'numeric', month: 'short', year: 'numeric' }) : '—';

const initials = (name: string) =>
  name.split(' ').map((w) => w[0]).join('').slice(0, 2).toUpperCase();

const blank = () => ({
  name: '', phone: '', email: '', notes: '', dob: '', anniversary: '',
});

export default function ClientsPage() {
  const [clients, setClients] = useState<Client[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [search, setSearch] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [editId, setEditId] = useState<string | null>(null);
  const [form, setForm] = useState<any>(blank());
  const [submitting, setSubmitting] = useState(false);
  const [modalError, setModalError] = useState('');
  const [deleteId, setDeleteId] = useState<string | number | null>(null);

  const load = async () => {
    setLoading(true);
    try {
      const res = await api<Client[] | { data?: Client[]; clients?: Client[] }>('/api/clients');
      setClients(Array.isArray(res) ? res : res?.data ?? res?.clients ?? []);
    } catch (e: any) { setError(e.message); }
    finally { setLoading(false); }
  };

  useEffect(() => { load(); }, []);

  const filtered = clients.filter((c) => {
    const q = search.toLowerCase();
    return !q || c.name?.toLowerCase().includes(q) || c.phone?.toLowerCase().includes(q) || c.email?.toLowerCase().includes(q);
  });

  const openNew = () => { setForm(blank()); setEditId(null); setModalError(''); setShowModal(true); };
  const openEdit = (c: any) => {
    setForm({ name: c.name || '', phone: c.phone || '', email: c.email || '', notes: c.notes || '', dob: c.dob?.split('T')[0] || '', anniversary: c.anniversary?.split('T')[0] || '' });
    setEditId(c.id); setModalError(''); setShowModal(true);
  };

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    if (!form.name.trim()) { setModalError('Name is required.'); return; }
    setSubmitting(true); setModalError('');
    try {
      if (editId) {
        await api(`/api/clients/${editId}`, { method: 'PATCH', body: form });
      } else {
        await api('/api/clients', { method: 'POST', body: form });
      }
      setShowModal(false);
      load();
    } catch (e: any) { setModalError(e.message); }
    finally { setSubmitting(false); }
  };

  const handleDelete = async (id: string | number) => {
    try {
      await api(`/api/clients/${id}`, { method: 'DELETE' });
      setDeleteId(null);
      load();
    } catch (e: any) { alert(e.message); }
  };

  return (
    <AppShell>
      <div style={{ padding: 24 }}>
        <div className="toolbar" style={{ marginBottom: 16 }}>
          <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 24 }}>Clients</div>
          <span className="spacer" />
          <button className="btn" style={{ background: 'var(--orange)', color: '#000' }} onClick={openNew}>+ New Client</button>
        </div>

        {error && <div className="error" style={{ marginBottom: 12 }}>{error}</div>}

        <div className="search-input-wrap" style={{ marginBottom: 16 }}>
          <input className="field" placeholder="Search by name, phone, email..." value={search} onChange={(e) => setSearch(e.target.value)} style={{ width: '100%' }} />
        </div>

        <div className="panel">
          <div className="panel-header">
            <span className="panel-title">All Clients</span>
            <span className="badge gray">{filtered.length}</span>
          </div>
          <div className="panel-body">
            {loading && [...Array(5)].map((_, i) => <div key={i} className="shimmer" style={{ height: 52, borderRadius: 6, marginBottom: 8 }} />)}
            {!loading && filtered.length === 0 && <div className="empty">No clients found.</div>}
            {!loading && (
              <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                <thead>
                  <tr style={{ borderBottom: '1px solid var(--surface-3)' }}>
                    {['Client', 'Phone', 'Email', 'DOB', 'Actions'].map((h) => (
                      <th key={h} style={{ textAlign: 'left', padding: '8px 12px', fontSize: 11, fontFamily: 'JetBrains Mono, monospace', color: 'var(--film-muted)', textTransform: 'uppercase' }}>{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {filtered.map((c) => (
                    <tr key={c.id} style={{ borderBottom: '1px solid var(--surface-3)' }}>
                      <td style={{ padding: '12px' }}>
                        <div className="row" style={{ gap: 10 }}>
                          <div className="avatar avatar-md">{initials(c.name || '?')}</div>
                          <div>
                            <div style={{ fontWeight: 600, fontSize: 14 }}>{c.name}</div>
                            <div className="muted text-sm">{c.notes || ''}</div>
                          </div>
                        </div>
                      </td>
                      <td style={{ padding: '12px', fontSize: 13 }}>{c.phone || '—'}</td>
                      <td style={{ padding: '12px', fontSize: 13 }}>{c.email || '—'}</td>
                      <td style={{ padding: '12px', fontSize: 13 }}>{fmtDate(c.dob)}</td>
                      <td style={{ padding: '12px' }}>
                        <div className="row" style={{ gap: 6 }}>
                          <Link href={`/app/clients/${c.id}`} className="btn ghost xs">View</Link>
                          <button className="btn ghost xs" onClick={() => openEdit(c)}>Edit</button>
                          <button className="btn danger xs" onClick={() => setDeleteId(c.id)}>Del</button>
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

      {/* New / Edit Modal */}
      {showModal && (
        <div className="modal-backdrop" onClick={() => setShowModal(false)}>
          <div className="modal" onClick={(e) => e.stopPropagation()}>
            <div className="row" style={{ marginBottom: 16 }}>
              <span style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 20 }}>{editId ? 'Edit Client' : 'New Client'}</span>
              <span className="spacer" />
              <button className="btn ghost xs" onClick={() => setShowModal(false)}>×</button>
            </div>
            {modalError && <div className="error" style={{ marginBottom: 10 }}>{modalError}</div>}
            <form onSubmit={handleSubmit}>
              <div className="form-grid">
                <div className="field" style={{ gridColumn: '1/-1' }}>
                  <label>Full Name *</label>
                  <input className="field" required value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} placeholder="Client full name" />
                </div>
                <div className="field">
                  <label>Phone</label>
                  <input className="field" value={form.phone} onChange={(e) => setForm({ ...form, phone: e.target.value })} placeholder="+880..." />
                </div>
                <div className="field">
                  <label>Email</label>
                  <input type="email" className="field" value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} placeholder="email@example.com" />
                </div>
                <div className="field">
                  <label>Date of Birth</label>
                  <input type="date" className="field" value={form.dob} onChange={(e) => setForm({ ...form, dob: e.target.value })} />
                </div>
                <div className="field">
                  <label>Anniversary</label>
                  <input type="date" className="field" value={form.anniversary} onChange={(e) => setForm({ ...form, anniversary: e.target.value })} />
                </div>
                <div className="field" style={{ gridColumn: '1/-1' }}>
                  <label>Notes</label>
                  <textarea className="field" rows={3} value={form.notes} onChange={(e) => setForm({ ...form, notes: e.target.value })} placeholder="Any notes about this client..." />
                </div>
              </div>
              <div className="row" style={{ gap: 10, marginTop: 16, justifyContent: 'flex-end' }}>
                <button type="button" className="btn ghost" onClick={() => setShowModal(false)}>Cancel</button>
                <button type="submit" className="btn" style={{ background: 'var(--orange)', color: '#000' }} disabled={submitting}>
                  {submitting ? 'Saving...' : editId ? 'Save Changes' : 'Create Client'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Delete Confirm */}
      {deleteId && (
        <div className="modal-backdrop" onClick={() => setDeleteId(null)}>
          <div className="modal" onClick={(e) => e.stopPropagation()} style={{ maxWidth: 380 }}>
            <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 20, marginBottom: 12 }}>Delete Client?</div>
            <p className="muted" style={{ marginBottom: 20 }}>This will permanently delete the client record. This cannot be undone.</p>
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
