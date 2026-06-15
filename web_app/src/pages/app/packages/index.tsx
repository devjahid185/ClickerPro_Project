import { useEffect, useState, FormEvent } from 'react';
import AppShell from '@/components/AppShell';
import { api } from '@/lib/api';
import { tk } from '@/lib/format';


const PRINT_SIZES = ['8×10', '10×12', '12×18', '16×24', '20×30', '24×36', 'Custom'];
const DELIVERY_OPTS = ['Pendrive', 'Google Drive', 'Both'];

const blank = () => ({
  name: '', price: '', discount: '', printsQty: '', printSize: '10×12',
  albumDesc: '', delivery: 'Both', trailers: '', fullVideos: '',
  photographers: '', cinematographers: '', includesChief: false,
  additionalItems: [''], notes: '',
});

export default function PackagesPage() {
  const [packages, setPackages] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [editId, setEditId] = useState<string | null>(null);
  const [form, setForm] = useState<any>(blank());
  const [submitting, setSubmitting] = useState(false);
  const [modalError, setModalError] = useState('');
  const [deleteId, setDeleteId] = useState<string | null>(null);

  const load = async () => {
    setLoading(true);
    try {
      const res = await api<any>('/api/packages');
      setPackages(Array.isArray(res) ? res : res?.data ?? res?.packages ?? []);
    } catch (e: any) { setError(e.message); }
    finally { setLoading(false); }
  };

  useEffect(() => { load(); }, []);

  const openNew = () => { setForm(blank()); setEditId(null); setModalError(''); setShowModal(true); };
  const openEdit = (p: any) => {
    setForm({
      name: p.name || '', price: p.price || '', discount: p.discount || '',
      printsQty: p.printsQty || p.prints_qty || '',
      printSize: p.printSize || p.print_size || '10×12',
      albumDesc: p.albumDesc || p.album_desc || '',
      delivery: p.delivery || 'Both',
      trailers: p.trailers || '',
      fullVideos: p.fullVideos || p.full_videos || '',
      photographers: p.photographers || p.photographer_count || p.photographerCount || '',
      cinematographers: p.cinematographers || p.cinematographer_count || p.cinematographerCount || '',
      includesChief: p.includesChief ?? p.includes_chief ?? false,
      additionalItems: (p.additionalItems || p.additional_items || []).length > 0 ? (p.additionalItems || p.additional_items) : [''],
      notes: p.notes || '',
    });
    setEditId(p.id); setModalError(''); setShowModal(true);
  };

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    if (!form.name || !form.price) { setModalError('Name and price are required.'); return; }
    setSubmitting(true); setModalError('');
    try {
      const payload = {
        ...form,
        price: Number(form.price),
        discount: form.discount ? Number(form.discount) : undefined,
        printsQty: form.printsQty ? Number(form.printsQty) : undefined,
        trailers: form.trailers ? Number(form.trailers) : undefined,
        fullVideos: form.fullVideos ? Number(form.fullVideos) : undefined,
        photographers: form.photographers ? Number(form.photographers) : undefined,
        cinematographers: form.cinematographers ? Number(form.cinematographers) : undefined,
        includesChief: !!form.includesChief,
        additionalItems: form.additionalItems.filter((i: string) => i.trim()),
      };
      if (editId) {
        await api(`/api/packages/${editId}`, { method: 'PATCH', body: payload });
      } else {
        await api('/api/packages', { method: 'POST', body: payload });
      }
      setShowModal(false);
      load();
    } catch (e: any) { setModalError(e.message); }
    finally { setSubmitting(false); }
  };

  const handleDelete = async (id: string) => {
    try { await api(`/api/packages/${id}`, { method: 'DELETE' }); setDeleteId(null); load(); } catch (e: any) { alert(e.message); }
  };

  const addItem = () => setForm({ ...form, additionalItems: [...form.additionalItems, ''] });
  const removeItem = (i: number) => setForm({ ...form, additionalItems: form.additionalItems.filter((_: string, j: number) => j !== i) });
  const setItem = (i: number, v: string) => {
    const items = [...form.additionalItems];
    items[i] = v;
    setForm({ ...form, additionalItems: items });
  };

  const netPrice = (p: any) => {
    const price = Number(p.price) || 0;
    const disc = Number(p.discount) || 0;
    return price - disc;
  };

  return (
    <AppShell>
      <div style={{ padding: 24 }}>
        <div className="toolbar" style={{ marginBottom: 20 }}>
          <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 24 }}>Packages</div>
          <span className="spacer" />
          <button className="btn" style={{ background: 'var(--orange)', color: '#000' }} onClick={openNew}>+ Add Package</button>
        </div>

        {error && <div className="error" style={{ marginBottom: 12 }}>{error}</div>}

        {loading && (
          <div className="cards cards-3">
            {[...Array(3)].map((_, i) => <div key={i} className="shimmer" style={{ height: 240, borderRadius: 8 }} />)}
          </div>
        )}

        {!loading && packages.length === 0 && (
          <div className="empty" style={{ marginTop: 40 }}>No packages yet. Create your first package.</div>
        )}

        {!loading && packages.length > 0 && (
          <div className="cards cards-3">
            {packages.map((p) => (
              <div key={p.id} className="pkg-card card">
                <div style={{ marginBottom: 12 }}>
                  <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 22, color: 'var(--film)', marginBottom: 4 }}>{p.name}</div>
                  <div className="row" style={{ gap: 8, alignItems: 'baseline' }}>
                    <span style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 28, color: 'var(--orange)' }}>{tk(netPrice(p))}</span>
                    {p.discount > 0 && (
                      <span style={{ fontSize: 14, color: 'var(--film-muted)', textDecoration: 'line-through' }}>{tk(Number(p.price))}</span>
                    )}
                  </div>
                  {p.discount > 0 && (
                    <span className="badge green" style={{ fontSize: 10 }}>Save {tk(Number(p.discount))}</span>
                  )}
                </div>

                <div className="divider" style={{ margin: '12px 0' }} />

                <div style={{ fontSize: 13, display: 'flex', flexDirection: 'column', gap: 6 }}>
                  {p.printsQty > 0 && (
                    <div className="row" style={{ gap: 6 }}>
                      <span className="muted" style={{ minWidth: 80 }}>Prints</span>
                      <span>{p.printsQty}× {p.printSize || p.print_size}</span>
                    </div>
                  )}
                  {(p.albumDesc || p.album_desc) && (
                    <div className="row" style={{ gap: 6 }}>
                      <span className="muted" style={{ minWidth: 80 }}>Album</span>
                      <span>{p.albumDesc || p.album_desc}</span>
                    </div>
                  )}
                  {p.trailers > 0 && (
                    <div className="row" style={{ gap: 6 }}>
                      <span className="muted" style={{ minWidth: 80 }}>Trailers</span>
                      <span>{p.trailers}</span>
                    </div>
                  )}
                  {(p.fullVideos || p.full_videos) > 0 && (
                    <div className="row" style={{ gap: 6 }}>
                      <span className="muted" style={{ minWidth: 80 }}>Full Videos</span>
                      <span>{p.fullVideos || p.full_videos}</span>
                    </div>
                  )}
                  {(p.photographers || p.photographer_count || p.photographerCount) > 0 && (
                    <div className="row" style={{ gap: 6 }}>
                      <span className="muted" style={{ minWidth: 80 }}>Photographers</span>
                      <span>{p.photographers || p.photographer_count || p.photographerCount}</span>
                    </div>
                  )}
                  {(p.cinematographers || p.cinematographer_count || p.cinematographerCount) > 0 && (
                    <div className="row" style={{ gap: 6 }}>
                      <span className="muted" style={{ minWidth: 80 }}>Cinematographers</span>
                      <span>{p.cinematographers || p.cinematographer_count || p.cinematographerCount}</span>
                    </div>
                  )}
                  {(p.includesChief ?? p.includes_chief) && (
                    <div className="row" style={{ gap: 6 }}>
                      <span className="muted" style={{ minWidth: 80 }}>Chief</span>
                      <span className="badge gold" style={{ fontSize: 10 }}>Included</span>
                    </div>
                  )}
                  {p.delivery && (
                    <div className="row" style={{ gap: 6 }}>
                      <span className="muted" style={{ minWidth: 80 }}>Delivery</span>
                      <span className="badge teal" style={{ fontSize: 10 }}>{p.delivery}</span>
                    </div>
                  )}
                  {(p.additionalItems || p.additional_items || []).filter((i: string) => i).map((item: string, idx: number) => (
                    <div key={idx} className="row" style={{ gap: 6 }}>
                      <span style={{ color: 'var(--film-muted)' }}>·</span>
                      <span>{item}</span>
                    </div>
                  ))}
                </div>

                {p.notes && (
                  <>
                    <div className="divider" style={{ margin: '10px 0' }} />
                    <div className="muted text-sm">{p.notes}</div>
                  </>
                )}

                <div className="row" style={{ gap: 8, marginTop: 14 }}>
                  <button className="btn ghost sm" style={{ flex: 1 }} onClick={() => openEdit(p)}>Edit</button>
                  <button className="btn danger sm" onClick={() => setDeleteId(p.id)}>Delete</button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Add/Edit Modal */}
      {showModal && (
        <div className="modal-backdrop" onClick={() => setShowModal(false)}>
          <div className="modal modal-lg" onClick={(e) => e.stopPropagation()} style={{ maxHeight: '90vh', overflowY: 'auto' }}>
            <div className="row" style={{ marginBottom: 16, position: 'sticky', top: 0, background: 'var(--bg)', paddingTop: 4 }}>
              <span style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 22 }}>{editId ? 'Edit Package' : 'New Package'}</span>
              <span className="spacer" />
              <button className="btn ghost xs" onClick={() => setShowModal(false)}>×</button>
            </div>

            {modalError && <div className="error" style={{ marginBottom: 10 }}>{modalError}</div>}

            <form onSubmit={handleSubmit}>
              <div className="form-grid">
                <div className="field" style={{ gridColumn: '1/-1' }}>
                  <label>Package Name *</label>
                  <input className="field" required value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} placeholder="e.g. Premium Wedding Package" />
                </div>
                <div className="field">
                  <label>Price (৳) *</label>
                  <input type="number" className="field" required value={form.price} onChange={(e) => setForm({ ...form, price: e.target.value })} placeholder="0" />
                </div>
                <div className="field">
                  <label>Discount (৳)</label>
                  <input type="number" className="field" value={form.discount} onChange={(e) => setForm({ ...form, discount: e.target.value })} placeholder="0" />
                </div>
              </div>

              {form.price && (
                <div className="card" style={{ marginBottom: 12, padding: '8px 12px' }}>
                  <div className="row" style={{ justifyContent: 'space-between' }}>
                    <span className="muted text-sm">Net Price</span>
                    <span style={{ color: 'var(--orange)', fontFamily: 'Bebas Neue, sans-serif', fontSize: 20 }}>
                      {tk((Number(form.price) || 0) - (Number(form.discount) || 0))}
                    </span>
                  </div>
                </div>
              )}

              <div className="divider" style={{ margin: '14px 0' }} />
              <div className="muted text-sm" style={{ marginBottom: 12, textTransform: 'uppercase', fontFamily: 'JetBrains Mono, monospace' }}>Inclusions</div>

              <div className="form-grid">
                <div className="field">
                  <label>Prints Quantity</label>
                  <input type="number" className="field" value={form.printsQty} onChange={(e) => setForm({ ...form, printsQty: e.target.value })} placeholder="0" />
                </div>
                <div className="field">
                  <label>Print Size</label>
                  <select className="field" value={form.printSize} onChange={(e) => setForm({ ...form, printSize: e.target.value })}>
                    {PRINT_SIZES.map((s) => <option key={s}>{s}</option>)}
                  </select>
                </div>
                <div className="field">
                  <label>Trailers Count</label>
                  <input type="number" className="field" value={form.trailers} onChange={(e) => setForm({ ...form, trailers: e.target.value })} placeholder="0" />
                </div>
                <div className="field">
                  <label>Full Videos Count</label>
                  <input type="number" className="field" value={form.fullVideos} onChange={(e) => setForm({ ...form, fullVideos: e.target.value })} placeholder="0" />
                </div>
                <div className="field">
                  <label>Photographers</label>
                  <input type="number" className="field" value={form.photographers} onChange={(e) => setForm({ ...form, photographers: e.target.value })} placeholder="e.g. 2" />
                </div>
                <div className="field">
                  <label>Cinematographers</label>
                  <input type="number" className="field" value={form.cinematographers} onChange={(e) => setForm({ ...form, cinematographers: e.target.value })} placeholder="e.g. 1" />
                </div>
                <div className="field" style={{ gridColumn: '1/-1' }}>
                  <label style={{ display: 'flex', alignItems: 'center', gap: 8, cursor: 'pointer' }}>
                    <input type="checkbox" checked={form.includesChief} onChange={(e) => setForm({ ...form, includesChief: e.target.checked })} />
                    Includes Chief Photographer
                  </label>
                </div>
                <div className="field" style={{ gridColumn: '1/-1' }}>
                  <label>Album Description</label>
                  <input className="field" value={form.albumDesc} onChange={(e) => setForm({ ...form, albumDesc: e.target.value })} placeholder="e.g. 12×18 hardbound, 40 pages" />
                </div>
              </div>

              <div className="field" style={{ marginBottom: 14 }}>
                <label>Delivery Method</label>
                <div className="row" style={{ gap: 10, marginTop: 8 }}>
                  {DELIVERY_OPTS.map((d) => (
                    <button
                      key={d} type="button"
                      className={`chip${form.delivery === d ? ' active' : ''}`}
                      onClick={() => setForm({ ...form, delivery: d })}
                    >{d}</button>
                  ))}
                </div>
              </div>

              <div className="field" style={{ marginBottom: 14 }}>
                <div className="row" style={{ marginBottom: 8 }}>
                  <label>Additional Items</label>
                  <span className="spacer" />
                  <button type="button" className="btn ghost xs" onClick={addItem}>+ Add</button>
                </div>
                {form.additionalItems.map((item: string, i: number) => (
                  <div key={i} className="row" style={{ gap: 8, marginBottom: 8 }}>
                    <input className="field" value={item} onChange={(e) => setItem(i, e.target.value)} placeholder={`Item ${i + 1}`} style={{ flex: 1 }} />
                    {form.additionalItems.length > 1 && (
                      <button type="button" className="btn ghost xs" onClick={() => removeItem(i)}>×</button>
                    )}
                  </div>
                ))}
              </div>

              <div className="field" style={{ marginBottom: 16 }}>
                <label>Notes</label>
                <textarea className="field" rows={2} value={form.notes} onChange={(e) => setForm({ ...form, notes: e.target.value })} placeholder="Any additional notes..." />
              </div>

              <div className="row" style={{ gap: 10, justifyContent: 'flex-end' }}>
                <button type="button" className="btn ghost" onClick={() => setShowModal(false)}>Cancel</button>
                <button type="submit" className="btn" style={{ background: 'var(--orange)', color: '#000' }} disabled={submitting}>
                  {submitting ? 'Saving...' : editId ? 'Save Package' : 'Create Package'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {deleteId && (
        <div className="modal-backdrop" onClick={() => setDeleteId(null)}>
          <div className="modal" onClick={(e) => e.stopPropagation()} style={{ maxWidth: 380 }}>
            <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 20, marginBottom: 12 }}>Delete Package?</div>
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
