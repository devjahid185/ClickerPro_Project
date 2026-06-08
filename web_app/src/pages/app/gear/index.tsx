import { useEffect, useState, FormEvent } from 'react';
import AppShell from '@/components/AppShell';
import { api } from '@/lib/api';
import { tk } from '@/lib/format';

const fmtDate = (d: string) =>
  d ? new Date(d).toLocaleDateString('en-BD', { day: 'numeric', month: 'short', year: 'numeric' }) : '—';

const CONDITIONS = ['GOOD', 'FAIR', 'DAMAGED'];
const COND_COLORS: Record<string, string> = { GOOD: 'green', FAIR: 'gold', DAMAGED: 'red' };
const STATUS_FILTERS = ['ALL', 'Available', 'In Use', 'Maintenance', 'Damaged'];

const blank = () => ({ name: '', category: '', serialNumber: '', condition: 'GOOD', purchaseValue: '', notes: '' });

export default function GearPage() {
  const [gear, setGear] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [filter, setFilter] = useState('ALL');
  const [showModal, setShowModal] = useState(false);
  const [editId, setEditId] = useState<string | null>(null);
  const [form, setForm] = useState<any>(blank());
  const [submitting, setSubmitting] = useState(false);
  const [modalError, setModalError] = useState('');
  const [deleteId, setDeleteId] = useState<string | null>(null);

  // Rental
  const [rentGearId, setRentGearId] = useState<string | null>(null);
  const [rentals, setRentals] = useState<any[]>([]);
  const [loadingRentals, setLoadingRentals] = useState(false);
  const [showRentModal, setShowRentModal] = useState(false);
  const [rentForm, setRentForm] = useState({ rentedTo: '', amount: '', notes: '' });
  const [rentErr, setRentErr] = useState('');

  const load = async () => {
    setLoading(true);
    try {
      const res = await api<any>('/api/gear');
      setGear(Array.isArray(res) ? res : res?.data ?? res?.gear ?? []);
    } catch (e: any) { setError(e.message); }
    finally { setLoading(false); }
  };

  useEffect(() => { load(); }, []);

  const loadRentals = async (gid: string) => {
    setLoadingRentals(true);
    try {
      const res = await api<any>(`/api/gear/${gid}/rent`);
      setRentals(Array.isArray(res) ? res : res?.data ?? []);
    } catch { setRentals([]); }
    finally { setLoadingRentals(false); }
  };

  const openRentals = (gid: string) => { setRentGearId(gid); setRentals([]); loadRentals(gid); };
  const closeRentals = () => { setRentGearId(null); setRentals([]); };

  const filtered = gear.filter((g) => {
    if (filter === 'ALL') return true;
    if (filter === 'Available') return g.available !== false && g.condition !== 'DAMAGED';
    if (filter === 'Damaged') return g.condition === 'DAMAGED';
    if (filter === 'In Use') return g.available === false;
    if (filter === 'Maintenance') return g.condition === 'FAIR';
    return true;
  });

  const openNew = () => { setForm(blank()); setEditId(null); setModalError(''); setShowModal(true); };
  const openEdit = (g: any) => {
    setForm({ name: g.name || '', category: g.category || '', serialNumber: g.serialNumber || g.serial || '', condition: g.condition || 'GOOD', purchaseValue: g.purchaseValue || g.value || '', notes: g.notes || '' });
    setEditId(g.id); setModalError(''); setShowModal(true);
  };

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    if (!form.name) { setModalError('Name is required.'); return; }
    setSubmitting(true); setModalError('');
    try {
      if (editId) {
        await api(`/api/gear/${editId}`, { method: 'PATCH', body: { ...form, purchaseValue: Number(form.purchaseValue) } });
      } else {
        await api('/api/gear', { method: 'POST', body: { ...form, purchaseValue: Number(form.purchaseValue) } });
      }
      setShowModal(false);
      load();
    } catch (e: any) { setModalError(e.message); }
    finally { setSubmitting(false); }
  };

  const handleDelete = async (id: string) => {
    try { await api(`/api/gear/${id}`, { method: 'DELETE' }); setDeleteId(null); load(); } catch (e: any) { alert(e.message); }
  };

  const toggleAvailable = async (g: any) => {
    try { await api(`/api/gear/${g.id}`, { method: 'PATCH', body: { available: !g.available } }); load(); } catch (e: any) { alert(e.message); }
  };

  const handleRentOut = async (e: FormEvent) => {
    e.preventDefault();
    if (!rentForm.rentedTo) { setRentErr('Rented to is required'); return; }
    setSubmitting(true); setRentErr('');
    try {
      await api('/api/rent', { method: 'POST', body: { gearItemId: rentGearId, direction: 'OUT', rentedTo: rentForm.rentedTo, amount: Number(rentForm.amount), notes: rentForm.notes } });
      setShowRentModal(false);
      setRentForm({ rentedTo: '', amount: '', notes: '' });
      if (rentGearId) loadRentals(rentGearId);
    } catch (e: any) { setRentErr(e.message); }
    finally { setSubmitting(false); }
  };

  const handleReturn = async () => {
    if (!rentGearId) return;
    try {
      await api('/api/rent', { method: 'POST', body: { gearItemId: rentGearId, direction: 'IN', notes: 'Returned' } });
      loadRentals(rentGearId);
      load();
    } catch (e: any) { alert(e.message); }
  };

  return (
    <AppShell>
      <div style={{ padding: 24 }}>
        <div className="toolbar" style={{ marginBottom: 16 }}>
          <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 24 }}>Gear Inventory</div>
          <span className="spacer" />
          <button className="btn" style={{ background: 'var(--orange)', color: '#000' }} onClick={openNew}>+ Add Gear</button>
        </div>

        {error && <div className="error" style={{ marginBottom: 12 }}>{error}</div>}

        <div className="chip-row" style={{ marginBottom: 16 }}>
          {STATUS_FILTERS.map((f) => (
            <button key={f} className={`chip${filter === f ? ' active' : ''}`} onClick={() => setFilter(f)}>{f}</button>
          ))}
        </div>

        <div className="panel">
          <div className="panel-header">
            <span className="panel-title">Gear List</span>
            <span className="badge gray">{filtered.length} items</span>
          </div>
          <div className="panel-body">
            {loading && [...Array(4)].map((_, i) => <div key={i} className="shimmer" style={{ height: 52, borderRadius: 6, marginBottom: 8 }} />)}
            {!loading && filtered.length === 0 && <div className="empty">No gear items found.</div>}
            {!loading && filtered.length > 0 && (
              <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                <thead>
                  <tr style={{ borderBottom: '1px solid var(--surface-3)' }}>
                    {['Name', 'Category', 'Serial', 'Condition', 'Value', 'Available', 'Actions'].map((h) => (
                      <th key={h} style={{ textAlign: 'left', padding: '8px 10px', fontSize: 11, fontFamily: 'JetBrains Mono, monospace', color: 'var(--film-muted)', textTransform: 'uppercase' }}>{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {filtered.map((g) => (
                    <tr key={g.id} style={{ borderBottom: '1px solid var(--surface-3)' }}>
                      <td style={{ padding: '10px', fontSize: 14, fontWeight: 600 }}>{g.name}</td>
                      <td style={{ padding: '10px', fontSize: 13 }}>{g.category || '—'}</td>
                      <td style={{ padding: '10px', fontSize: 12, fontFamily: 'JetBrains Mono, monospace', color: 'var(--film-muted)' }}>{g.serialNumber || g.serial || '—'}</td>
                      <td style={{ padding: '10px' }}><span className={`badge ${COND_COLORS[g.condition] || 'gray'}`}>{g.condition}</span></td>
                      <td style={{ padding: '10px', fontSize: 13, color: 'var(--orange)' }}>{tk(Number(g.purchaseValue || g.value) || 0)}</td>
                      <td style={{ padding: '10px' }}>
                        <label className="toggle-row" style={{ gap: 8 }}>
                          <span className="toggle">
                            <input type="checkbox" checked={g.available !== false} onChange={() => toggleAvailable(g)} style={{ display: 'none' }} />
                            <span className="toggle-slider" />
                          </span>
                          <span className="text-sm muted">{g.available !== false ? 'Yes' : 'No'}</span>
                        </label>
                      </td>
                      <td style={{ padding: '10px' }}>
                        <div className="row" style={{ gap: 4 }}>
                          <button className="btn ghost xs" onClick={() => openRentals(g.id)}>Rentals</button>
                          <button className="btn ghost xs" onClick={() => openEdit(g)}>Edit</button>
                          <button className="btn danger xs" onClick={() => setDeleteId(g.id)}>Del</button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </div>

        {/* Rental Panel */}
        {rentGearId && (
          <div className="panel" style={{ marginTop: 20 }}>
            <div className="panel-header">
              <span className="panel-title">Rental History — {gear.find((g) => g.id === rentGearId)?.name || rentGearId}</span>
              <div className="row" style={{ gap: 8 }}>
                <button className="btn ghost sm" onClick={() => { setRentErr(''); setShowRentModal(true); }}>Rent Out</button>
                <button className="btn ghost sm" onClick={handleReturn}>Mark Returned</button>
                <button className="btn ghost sm" onClick={closeRentals}>×</button>
              </div>
            </div>
            <div className="panel-body">
              {loadingRentals && <div className="shimmer" style={{ height: 80, borderRadius: 6 }} />}
              {!loadingRentals && rentals.length === 0 && <div className="empty">No rental records.</div>}
              {rentals.map((r: any, i: number) => (
                <div key={r.id || i} className="row" style={{ padding: '10px 0', borderBottom: '1px solid var(--surface-3)', gap: 12 }}>
                  <span className={`badge ${r.direction === 'OUT' ? 'orange' : 'green'}`}>{r.direction === 'OUT' ? 'Rented Out' : 'Returned'}</span>
                  <div style={{ flex: 1 }}>
                    <div style={{ fontSize: 13 }}>{r.rentedTo || '—'}</div>
                    <div className="muted text-sm">{fmtDate(r.createdAt || r.date)} {r.notes ? `· ${r.notes}` : ''}</div>
                  </div>
                  {r.amount > 0 && <span style={{ color: 'var(--orange)', fontSize: 13 }}>{tk(Number(r.amount))}</span>}
                </div>
              ))}
            </div>
          </div>
        )}
      </div>

      {/* Add/Edit Modal */}
      {showModal && (
        <div className="modal-backdrop" onClick={() => setShowModal(false)}>
          <div className="modal" onClick={(e) => e.stopPropagation()}>
            <div className="row" style={{ marginBottom: 16 }}>
              <span style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 20 }}>{editId ? 'Edit Gear' : 'Add Gear'}</span>
              <span className="spacer" />
              <button className="btn ghost xs" onClick={() => setShowModal(false)}>×</button>
            </div>
            {modalError && <div className="error" style={{ marginBottom: 10 }}>{modalError}</div>}
            <form onSubmit={handleSubmit}>
              <div className="form-grid">
                <div className="field" style={{ gridColumn: '1/-1' }}>
                  <label>Name *</label>
                  <input className="field" required value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} placeholder="Gear name" />
                </div>
                <div className="field">
                  <label>Category</label>
                  <input className="field" value={form.category} onChange={(e) => setForm({ ...form, category: e.target.value })} placeholder="Camera / Lens / Light..." />
                </div>
                <div className="field">
                  <label>Serial Number</label>
                  <input className="field" value={form.serialNumber} onChange={(e) => setForm({ ...form, serialNumber: e.target.value })} placeholder="SN-XXXX" />
                </div>
                <div className="field">
                  <label>Condition</label>
                  <select className="field" value={form.condition} onChange={(e) => setForm({ ...form, condition: e.target.value })}>
                    {CONDITIONS.map((c) => <option key={c}>{c}</option>)}
                  </select>
                </div>
                <div className="field">
                  <label>Purchase Value (৳)</label>
                  <input type="number" className="field" value={form.purchaseValue} onChange={(e) => setForm({ ...form, purchaseValue: e.target.value })} placeholder="0" />
                </div>
                <div className="field" style={{ gridColumn: '1/-1' }}>
                  <label>Notes</label>
                  <textarea className="field" rows={2} value={form.notes} onChange={(e) => setForm({ ...form, notes: e.target.value })} />
                </div>
              </div>
              <div className="row" style={{ gap: 10, marginTop: 16, justifyContent: 'flex-end' }}>
                <button type="button" className="btn ghost" onClick={() => setShowModal(false)}>Cancel</button>
                <button type="submit" className="btn" style={{ background: 'var(--orange)', color: '#000' }} disabled={submitting}>{submitting ? 'Saving...' : editId ? 'Save' : 'Add'}</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Rent Out Modal */}
      {showRentModal && (
        <div className="modal-backdrop" onClick={() => setShowRentModal(false)}>
          <div className="modal" onClick={(e) => e.stopPropagation()}>
            <div className="row" style={{ marginBottom: 16 }}>
              <span style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 20 }}>Rent Out Gear</span>
              <span className="spacer" />
              <button className="btn ghost xs" onClick={() => setShowRentModal(false)}>×</button>
            </div>
            {rentErr && <div className="error" style={{ marginBottom: 10 }}>{rentErr}</div>}
            <form onSubmit={handleRentOut}>
              <div className="field" style={{ marginBottom: 12 }}><label>Rented To *</label><input className="field" required value={rentForm.rentedTo} onChange={(e) => setRentForm({ ...rentForm, rentedTo: e.target.value })} placeholder="Person or company name" /></div>
              <div className="field" style={{ marginBottom: 12 }}><label>Amount (৳)</label><input type="number" className="field" value={rentForm.amount} onChange={(e) => setRentForm({ ...rentForm, amount: e.target.value })} placeholder="0" /></div>
              <div className="field" style={{ marginBottom: 16 }}><label>Notes</label><input className="field" value={rentForm.notes} onChange={(e) => setRentForm({ ...rentForm, notes: e.target.value })} /></div>
              <div className="row" style={{ gap: 10, justifyContent: 'flex-end' }}>
                <button type="button" className="btn ghost" onClick={() => setShowRentModal(false)}>Cancel</button>
                <button type="submit" className="btn" style={{ background: 'var(--orange)', color: '#000' }} disabled={submitting}>{submitting ? 'Renting...' : 'Rent Out'}</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {deleteId && (
        <div className="modal-backdrop" onClick={() => setDeleteId(null)}>
          <div className="modal" onClick={(e) => e.stopPropagation()} style={{ maxWidth: 380 }}>
            <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 20, marginBottom: 12 }}>Delete Gear Item?</div>
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
