import { useEffect, useState, FormEvent } from 'react';
import AppShell from '@/components/AppShell';
import { api } from '@/lib/api';
import { tk } from '@/lib/format';

const fmtDate = (d: string) =>
  d ? new Date(d).toLocaleDateString('en-BD', { day: 'numeric', month: 'short', year: 'numeric' }) : '—';

const today = () => new Date().toISOString().split('T')[0];
const blank = () => ({ gear_item_id: '', rented_to: '', amount: '', rented_at: today(), notes: '' });

export default function RentPage() {
  const [records, setRecords] = useState<any[]>([]);
  const [gear, setGear] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [dirFilter, setDirFilter] = useState('ALL');
  const [showModal, setShowModal] = useState(false);
  const [form, setForm] = useState<any>(blank());
  const [submitting, setSubmitting] = useState(false);
  const [modalError, setModalError] = useState('');
  const [returningId, setReturningId] = useState<string | null>(null);

  const load = async () => {
    setLoading(true);
    setError('');
    try {
      const [resRent, resGear] = await Promise.all([
        api<any>('/api/rent'),
        api<any>('/api/gear'),
      ]);
      setRecords(Array.isArray(resRent) ? resRent : resRent?.data ?? []);
      setGear(Array.isArray(resGear) ? resGear : resGear?.data ?? []);
    } catch (e: any) { setError(e.message); }
    finally { setLoading(false); }
  };

  useEffect(() => { load(); }, []);

  const gearName = (rec: any) =>
    rec.gearItem?.name || gear.find((g) => g.id === rec.gear_item_id)?.name || '—';

  const filtered = records.filter((r) => {
    if (dirFilter === 'ALL') return true;
    return r.direction === dirFilter;
  });

  const currentlyOut = records.filter((r) => r.direction === 'OUT' && !r.returned_at).length;
  const rentalIncome = records
    .filter((r) => r.direction === 'OUT')
    .reduce((s, r) => s + (Number(r.amount) || 0), 0);

  const openNew = () => { setForm(blank()); setModalError(''); setShowModal(true); };

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    if (!form.gear_item_id || !form.rented_to) { setModalError('Gear and rented-to are required.'); return; }
    setSubmitting(true); setModalError('');
    try {
      await api('/api/rent', {
        method: 'POST',
        body: {
          gear_item_id: form.gear_item_id,
          direction: 'OUT',
          rented_to: form.rented_to,
          amount: Number(form.amount) || 0,
          rented_at: form.rented_at,
          notes: form.notes,
        },
      });
      setShowModal(false);
      load();
    } catch (e: any) { setModalError(e.message); }
    finally { setSubmitting(false); }
  };

  const markReturned = async (record: any) => {
    setReturningId(record.id);
    try {
      await api('/api/rent', {
        method: 'POST',
        body: {
          gear_item_id: record.gear_item_id,
          direction: 'IN',
          rented_at: today(),
          notes: 'Returned',
        },
      });
      load();
    } catch (e: any) { alert(e.message); }
    finally { setReturningId(null); }
  };

  return (
    <AppShell>
      <div style={{ padding: 24 }}>
        <div className="toolbar" style={{ marginBottom: 4 }}>
          <div>
            <h1 className="page-title">Gear Rental</h1>
            <p className="page-sub">Track gear lent out and returned</p>
          </div>
          <span className="spacer" />
          <button className="btn" style={{ background: 'var(--orange)', color: '#000' }} onClick={openNew}>+ Rent Out</button>
        </div>

        {error && <div className="error" style={{ marginBottom: 12 }}>{error}</div>}

        {/* Summary */}
        <div className="cards cards-3" style={{ marginTop: 16, marginBottom: 20 }}>
          <div className="card" style={{ textAlign: 'center' }}>
            <div className="muted text-sm" style={{ marginBottom: 6 }}>Currently Out</div>
            <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 30, color: 'var(--gold)' }}>{currentlyOut}</div>
          </div>
          <div className="card" style={{ textAlign: 'center' }}>
            <div className="muted text-sm" style={{ marginBottom: 6 }}>Total Rental Income</div>
            <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 30, color: 'var(--green)' }}>{tk(rentalIncome)}</div>
          </div>
          <div className="card" style={{ textAlign: 'center' }}>
            <div className="muted text-sm" style={{ marginBottom: 6 }}>Total Records</div>
            <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 30 }}>{records.length}</div>
          </div>
        </div>

        {/* Filter */}
        <div className="chip-row" style={{ marginBottom: 16 }}>
          <button className={`chip${dirFilter === 'ALL' ? ' active' : ''}`} onClick={() => setDirFilter('ALL')}>All</button>
          <button className={`chip${dirFilter === 'OUT' ? ' active' : ''}`} onClick={() => setDirFilter('OUT')}>Out</button>
          <button className={`chip${dirFilter === 'IN' ? ' active' : ''}`} onClick={() => setDirFilter('IN')}>In/Returned</button>
        </div>

        <div className="panel">
          <div className="panel-header">
            <span className="panel-title">Rental Records</span>
            <span className="badge gray">{filtered.length}</span>
          </div>
          <div className="panel-body">
            {loading && [...Array(5)].map((_, i) => <div key={i} className="shimmer" style={{ height: 48, borderRadius: 6, marginBottom: 8 }} />)}
            {!loading && filtered.length === 0 && <div className="empty">No rental records yet.</div>}
            {!loading && filtered.length > 0 && (
              <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                <thead>
                  <tr style={{ borderBottom: '1px solid var(--surface-3)' }}>
                    {['Gear', 'Direction', 'Rented To', 'Amount', 'Rented', 'Returned', 'Notes', ''].map((h, i) => (
                      <th key={i} style={{ textAlign: 'left', padding: '8px 10px', fontSize: 11, fontFamily: 'JetBrains Mono, monospace', color: 'var(--film-muted)', textTransform: 'uppercase' }}>{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {filtered.map((rec) => (
                    <tr key={rec.id} style={{ borderBottom: '1px solid var(--surface-3)' }}>
                      <td style={{ padding: '10px', fontSize: 14, fontWeight: 600 }}>{gearName(rec)}</td>
                      <td style={{ padding: '10px' }}><span className={`badge ${rec.direction === 'OUT' ? 'orange' : 'green'}`}>{rec.direction}</span></td>
                      <td style={{ padding: '10px', fontSize: 13 }}>{rec.rented_to || '—'}</td>
                      <td style={{ padding: '10px', fontFamily: 'Bebas Neue, sans-serif', fontSize: 20 }}>{tk(Number(rec.amount) || 0)}</td>
                      <td style={{ padding: '10px', fontSize: 12 }}>{fmtDate(rec.rented_at)}</td>
                      <td style={{ padding: '10px', fontSize: 12 }}>{rec.returned_at ? fmtDate(rec.returned_at) : '—'}</td>
                      <td style={{ padding: '10px', fontSize: 12, color: 'var(--film-muted)' }} className="truncate">{rec.notes || '—'}</td>
                      <td style={{ padding: '10px' }}>
                        {rec.direction === 'OUT' && !rec.returned_at && (
                          <button className="btn success xs" disabled={returningId === rec.id} onClick={() => markReturned(rec)}>
                            {returningId === rec.id ? '...' : 'Mark Returned'}
                          </button>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </div>
      </div>

      {/* Rent Out Modal */}
      {showModal && (
        <div className="modal-backdrop" onClick={() => setShowModal(false)}>
          <div className="modal" onClick={(e) => e.stopPropagation()}>
            <div className="row" style={{ marginBottom: 16 }}>
              <span style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 20 }}>Rent Out Gear</span>
              <span className="spacer" />
              <button className="btn ghost xs" onClick={() => setShowModal(false)}>×</button>
            </div>
            {modalError && <div className="error" style={{ marginBottom: 10 }}>{modalError}</div>}
            <form onSubmit={handleSubmit}>
              <div className="form-grid">
                <div className="field" style={{ gridColumn: '1/-1' }}>
                  <label>Gear *</label>
                  <select className="field" required value={form.gear_item_id} onChange={(e) => setForm({ ...form, gear_item_id: e.target.value })}>
                    <option value="">Select gear...</option>
                    {gear.map((g) => <option key={g.id} value={g.id}>{g.name}</option>)}
                  </select>
                </div>
                <div className="field">
                  <label>Rented To *</label>
                  <input className="field" required value={form.rented_to} onChange={(e) => setForm({ ...form, rented_to: e.target.value })} placeholder="Person / company name" />
                </div>
                <div className="field">
                  <label>Amount (৳)</label>
                  <input type="number" className="field" value={form.amount} onChange={(e) => setForm({ ...form, amount: e.target.value })} placeholder="0" />
                </div>
                <div className="field">
                  <label>Rented Date</label>
                  <input type="date" className="field" value={form.rented_at} onChange={(e) => setForm({ ...form, rented_at: e.target.value })} />
                </div>
                <div className="field" style={{ gridColumn: '1/-1' }}>
                  <label>Notes</label>
                  <textarea className="field" rows={2} value={form.notes} onChange={(e) => setForm({ ...form, notes: e.target.value })} placeholder="Optional notes..." />
                </div>
              </div>
              <div className="row" style={{ gap: 10, marginTop: 16, justifyContent: 'flex-end' }}>
                <button type="button" className="btn ghost" onClick={() => setShowModal(false)}>Cancel</button>
                <button type="submit" className="btn" style={{ background: 'var(--orange)', color: '#000' }} disabled={submitting}>{submitting ? 'Saving...' : 'Rent Out'}</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </AppShell>
  );
}
