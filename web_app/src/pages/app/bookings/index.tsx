import { useEffect, useState, FormEvent } from 'react';
import Link from 'next/link';
import AppShell from '@/components/AppShell';
import { api } from '@/lib/api';
import { tk } from '@/lib/format';
import { Booking } from '@/types/api';

const fmtDate = (d: string) =>
  new Date(d).toLocaleDateString('en-BD', { day: 'numeric', month: 'short', year: 'numeric' });

function statusBadge(s: string) {
  const map: Record<string, string> = {
    PENDING: 'gold', CONFIRMED: 'teal', IN_PROGRESS: 'orange',
    SHOT_COMPLETE: 'blue', DELIVERED: 'purple', COMPLETED: 'green', CANCELLED: 'red',
  };
  return <span className={`badge ${map[s] || 'gray'}`}>{s.replace(/_/g, ' ')}</span>;
}

const EVENT_TYPES = ['Wedding', 'Holud', 'Reception', 'Corporate', 'Birthday', 'Engagement', 'Aqiqah', 'Portrait', 'Other'];
const STATUSES = ['ALL', 'PENDING', 'CONFIRMED', 'IN_PROGRESS', 'SHOT_COMPLETE', 'DELIVERED', 'COMPLETED', 'CANCELLED'];
const DATE_FILTERS = ['Today', 'This Week', 'This Month', 'Custom'];

// Canonical shift windows — Day 12pm–5pm, Night 6pm–11pm (matches mobile).
const SHIFT_TIMES: Record<string, string> = {
  DAY: '12pm–5pm',
  NIGHT: '6pm–11pm',
  BOTH: '12pm–11pm',
};

const blank = () => ({
  clientName: '', clientPhone: '', companyName: '', eventType: 'Wedding',
  brideName: '', groomName: '', date: '', shift: 'DAY',
  startTime: '', endTime: '', venue: '', mapLink: '',
  outdoor: false, outdoorLocation: '', reportingTime: '',
  package: '', price: '', customPrice: '', coverageHours: '', extraHourRate: '',
  advance: '', driveLink: '', chiefPhotographer: '', requirements: '', notes: '',
});

export default function BookingsPage() {
  const [bookings, setBookings] = useState<Booking[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [statusFilter, setStatusFilter] = useState('ALL');
  const [dateFilter, setDateFilter] = useState('This Month');
  const [customFrom, setCustomFrom] = useState('');
  const [customTo, setCustomTo] = useState('');
  const [search, setSearch] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [editId, setEditId] = useState<string | null>(null);
  const [form, setForm] = useState<any>(blank());
  const [submitting, setSubmitting] = useState(false);
  const [modalError, setModalError] = useState('');
  const [deleteId, setDeleteId] = useState<string | null>(null);
  const [shareCopied, setShareCopied] = useState(false);

  // Client self-booking link: clients fill the form themselves and the
  // booking lands as PENDING. Token lives on the owner profile.
  const shareBookingLink = async () => {
    try {
      const res = await api<any>('/api/profile');
      const d = res?.data ?? res;
      const u = d?.user ?? d;
      const token = u?.bookingToken || u?.public_booking_token || u?.publicToken;
      if (!token) { alert('Booking link token pawa gelo na.'); return; }
      const url = `${window.location.origin}/book/${token}`;
      await navigator.clipboard.writeText(url);
      setShareCopied(true);
      setTimeout(() => setShareCopied(false), 2500);
    } catch (e: any) { alert(e.message); }
  };

  const load = async () => {
    setLoading(true);
    try {
      const res = await api<Booking[] | { data?: Booking[]; bookings?: Booking[] }>('/api/bookings?limit=200');
      setBookings(Array.isArray(res) ? res : res?.data ?? res?.bookings ?? []);
    } catch (e: any) { setError(e.message); }
    finally { setLoading(false); }
  };

  useEffect(() => { load(); }, []);

  const getDate = (b: any) => b.date?.split('T')[0] || b.event_date?.split('T')[0] || '';
  const getName = (b: any) => b.clientName || b.client_name || b.client?.name || '';
  const getPhone = (b: any) => b.clientPhone || b.client_phone || b.client?.phone || '';

  const now = new Date();
  const todayStr = now.toISOString().split('T')[0];

  const filtered = bookings.filter((b) => {
    const d = getDate(b);
    const q = search.toLowerCase();
    if (q && !((b.title || '').toLowerCase().includes(q) || getName(b).toLowerCase().includes(q) || (b.venue || '').toLowerCase().includes(q))) return false;
    if (statusFilter !== 'ALL' && b.status !== statusFilter) return false;
    if (dateFilter === 'Today' && d !== todayStr) return false;
    if (dateFilter === 'This Week') {
      const w = new Date(now); w.setDate(now.getDate() - now.getDay());
      const we = new Date(w); we.setDate(w.getDate() + 6);
      if (d < w.toISOString().split('T')[0] || d > we.toISOString().split('T')[0]) return false;
    }
    if (dateFilter === 'This Month') {
      const prefix = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
      if (!d.startsWith(prefix)) return false;
    }
    if (dateFilter === 'Custom') {
      if (customFrom && d < customFrom) return false;
      if (customTo && d > customTo) return false;
    }
    return true;
  });

  const dayBookings = filtered.filter((b) => b.shift === 'DAY' || b.shift === 'BOTH');
  const nightBookings = filtered.filter((b) => b.shift === 'NIGHT' || b.shift === 'BOTH');
  // "BOTH"-shift bookings intentionally appear in both columns, so the column
  // counts can sum to more than the unique total. Surface that to avoid confusion.
  const bothCount = filtered.filter((b) => b.shift === 'BOTH').length;

  const openNew = () => { setForm(blank()); setEditId(null); setModalError(''); setShowModal(true); };
  const fillFrom = (b: any, keepDate: boolean) => ({
    ...blank(),
    clientName: getName(b), clientPhone: getPhone(b),
    companyName: b.company_name || b.companyName || '',
    eventType: b.eventType || b.event_type || 'Wedding',
    brideName: b.bride_name || b.brideName || '',
    groomName: b.groom_name || b.groomName || '',
    date: keepDate ? getDate(b) : '', shift: b.shift || 'DAY',
    startTime: b.start_time || b.startTime || '',
    endTime: b.end_time || b.endTime || '',
    venue: b.venue || '', mapLink: b.map_link || b.mapLink || '',
    outdoor: !!(b.outdoor),
    outdoorLocation: b.outdoor_location || b.outdoorLocation || '',
    reportingTime: b.reporting_time || b.reportingTime || '',
    package: b.package || '',
    price: b.price ?? '', customPrice: b.custom_price ?? b.customPrice ?? '',
    coverageHours: b.coverage_hours ?? b.coverageHours ?? '',
    extraHourRate: b.extra_hour_rate ?? b.extraHourRate ?? '',
    advance: b.advance_paid ?? b.advance ?? '',
    driveLink: b.drive_link || b.driveLink || '',
    chiefPhotographer: b.chief_photographer_name || b.chiefPhotographerName || '',
    requirements: b.requirements_note || b.requirementsNote || '',
    notes: b.notes || '',
  });
  const openEdit = (b: any) => {
    setForm(fillFrom(b, true));
    setEditId(b.id); setModalError(''); setShowModal(true);
  };
  const openDuplicate = (b: any) => {
    setForm(fillFrom(b, false));
    setEditId(null); setModalError(''); setShowModal(true);
  };

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    if (!form.clientName || !form.date) { setModalError('Client name and date are required.'); return; }
    setSubmitting(true); setModalError('');
    try {
      // Laravel expects snake_case keys and a required `title` — the raw
      // camelCase form body failed validation on every save.
      const num = (v: any) => (v !== '' && v != null ? Number(v) : null);
      const payload = {
        title: `${form.clientName} — ${form.eventType}`,
        date: form.date,
        event_type: form.eventType,
        shift: form.shift,
        venue: form.venue || null,
        price: num(form.price),
        advance_paid: num(form.advance),
        notes: form.notes || null,
        client_name: form.clientName,
        client_phone: form.clientPhone || null,
        // Rich detail fields (mobile↔web parity).
        company_name: form.companyName || null,
        bride_name: form.brideName || null,
        groom_name: form.groomName || null,
        start_time: form.startTime || null,
        end_time: form.endTime || null,
        map_link: form.mapLink || null,
        outdoor: !!form.outdoor,
        outdoor_location: form.outdoorLocation || null,
        reporting_time: form.reportingTime || null,
        custom_price: num(form.customPrice),
        coverage_hours: num(form.coverageHours),
        extra_hour_rate: num(form.extraHourRate),
        drive_link: form.driveLink || null,
        chief_photographer_name: form.chiefPhotographer || null,
        requirements_note: form.requirements || null,
      };
      if (editId) {
        await api(`/api/bookings/${editId}`, { method: 'PATCH', body: payload });
      } else {
        await api('/api/bookings', { method: 'POST', body: payload });
      }
      setShowModal(false);
      load();
    } catch (e: any) { setModalError(e.message); }
    finally { setSubmitting(false); }
  };

  const handleDelete = async (id: string) => {
    try {
      await api(`/api/bookings/${id}`, { method: 'DELETE' });
      setDeleteId(null);
      load();
    } catch (e: any) { alert(e.message); }
  };

  const exportCSV = () => {
    const headers = ['Title', 'Client', 'Phone', 'Date', 'Shift', 'Status', 'Price', 'Advance', 'Venue'];
    const rows = filtered.map((b) => [
      b.title || b.eventType || '', getName(b), getPhone(b), getDate(b),
      b.shift || '', b.status, b.price || 0, b.advance || 0, b.venue || '',
    ]);
    const csv = [headers, ...rows].map((r) => r.map((v) => `"${String(v).replace(/"/g, '""')}"`).join(',')).join('\n');
    const a = document.createElement('a');
    a.href = 'data:text/csv;charset=utf-8,' + encodeURIComponent(csv);
    a.download = 'bookings.csv';
    a.click();
  };

  const BookingCard = ({ b, night }: { b: any; night?: boolean }) => (
    <div className="card" style={{ marginBottom: 10, borderLeft: `3px solid ${night ? 'var(--purple)' : 'var(--gold)'}` }}>
      <div className="row" style={{ justifyContent: 'space-between', marginBottom: 6 }}>
        <Link href={`/app/bookings/${b.id}`} style={{ fontWeight: 700, fontSize: 15, color: 'var(--film)', textDecoration: 'none' }}>
          {b.title || b.eventType || 'Booking'}
        </Link>
        <span className={`pill ${b.shift === 'NIGHT' ? 'night' : b.shift === 'BOTH' ? 'both' : 'day'}`} title={SHIFT_TIMES[b.shift] || ''}>
          {b.shift} · {SHIFT_TIMES[b.shift] || ''}
        </span>
      </div>
      <div className="info-row">
        <span className="info-key">Client</span>
        <span className="info-val">{getName(b)}</span>
      </div>
      <div className="info-row">
        <span className="info-key">Date</span>
        <span className="info-val">{fmtDate(getDate(b))}</span>
      </div>
      <div className="info-row">
        <span className="info-key">Venue</span>
        <span className="info-val">{b.venue || '—'}</span>
      </div>
      <div className="row" style={{ justifyContent: 'space-between', marginTop: 8, flexWrap: 'wrap', gap: 6 }}>
        <div className="row" style={{ gap: 6 }}>
          {statusBadge(b.status)}
          <span style={{ color: 'var(--orange)', fontSize: 13, fontFamily: 'JetBrains Mono, monospace' }}>{tk(Number(b.price) || 0)}</span>
        </div>
        <div className="row" style={{ gap: 6 }}>
          <Link href={`/app/bookings/${b.id}`} className="btn ghost xs">View</Link>
          <button className="btn ghost xs" onClick={() => openEdit(b)}>Edit</button>
          <button className="btn ghost xs" onClick={() => openDuplicate(b)}>Dup</button>
          <button className="btn danger xs" onClick={() => setDeleteId(b.id)}>Del</button>
        </div>
      </div>
    </div>
  );

  return (
    <AppShell>
      <div style={{ padding: 24 }}>
        {/* Toolbar */}
        <div className="toolbar" style={{ marginBottom: 16 }}>
          <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 24, color: 'var(--film)' }}>Bookings</div>
          <span className="spacer" />
          <button className="btn ghost sm" onClick={exportCSV}>Export CSV</button>
          <button className="btn ghost" onClick={shareBookingLink}>{shareCopied ? 'Link Copied!' : 'Share Booking Link'}</button>
          <button className="btn sm" style={{ background: 'var(--orange)', color: '#000' }} onClick={openNew}>+ New Booking</button>
        </div>

        {error && <div className="error" style={{ marginBottom: 12 }}>{error}</div>}

        {/* Search */}
        <div className="search-input-wrap" style={{ marginBottom: 14 }}>
          <input
            className="field"
            placeholder="Search by title, client, venue..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            style={{ width: '100%' }}
          />
        </div>

        {/* Status Filter Chips */}
        <div className="chip-row" style={{ marginBottom: 14 }}>
          {STATUSES.map((s) => (
            <button
              key={s}
              className={`chip${statusFilter === s ? ' active' : ''}`}
              onClick={() => setStatusFilter(s)}
            >
              {s.replace(/_/g, ' ')}
            </button>
          ))}
        </div>

        {/* Date Filter */}
        <div className="row" style={{ gap: 8, marginBottom: 20, flexWrap: 'wrap' }}>
          {DATE_FILTERS.map((f) => (
            <button
              key={f}
              className={`chip${dateFilter === f ? ' active' : ''}`}
              onClick={() => setDateFilter(f)}
            >
              {f}
            </button>
          ))}
          {dateFilter === 'Custom' && (
            <>
              <input type="date" className="field" style={{ width: 140 }} value={customFrom} onChange={(e) => setCustomFrom(e.target.value)} />
              <input type="date" className="field" style={{ width: 140 }} value={customTo} onChange={(e) => setCustomTo(e.target.value)} />
            </>
          )}
        </div>

        {/* Count */}
        <div className="muted text-sm" style={{ marginBottom: 14 }}>
          {filtered.length} booking{filtered.length !== 1 ? 's' : ''} found
          {bothCount > 0 && (
            <span> · {bothCount} run day &amp; night (shown in both columns)</span>
          )}
        </div>

        {loading && (
          <div className="cards cards-2">
            {[...Array(6)].map((_, i) => <div key={i} className="shimmer" style={{ height: 140, borderRadius: 8 }} />)}
          </div>
        )}

        {!loading && filtered.length === 0 && <div className="empty">No bookings match your filters.</div>}

        {/* Day / Night Split */}
        {!loading && filtered.length > 0 && (
          <div className="bookings-split" style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 20 }}>
            <div>
              <div className="row" style={{ marginBottom: 12, gap: 8 }}>
                <span className="pill day">DAY</span>
                <span className="muted text-sm">{dayBookings.length} bookings</span>
              </div>
              {dayBookings.map((b) => <BookingCard key={b.id} b={b} />)}
              {dayBookings.length === 0 && <div className="empty">No day bookings</div>}
            </div>
            <div>
              <div className="row" style={{ marginBottom: 12, gap: 8 }}>
                <span className="pill night">NIGHT</span>
                <span className="muted text-sm">{nightBookings.length} bookings</span>
              </div>
              {nightBookings.map((b) => <BookingCard key={b.id} b={b} night />)}
              {nightBookings.length === 0 && <div className="empty">No night bookings</div>}
            </div>
          </div>
        )}
      </div>

      {/* New/Edit Modal */}
      {showModal && (
        <div className="modal-backdrop" onClick={() => setShowModal(false)}>
          <div className="modal modal-lg" onClick={(e) => e.stopPropagation()}>
            <div className="row" style={{ marginBottom: 16, alignItems: 'center' }}>
              <span style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 20 }}>{editId ? 'Edit Booking' : 'New Booking'}</span>
              <span className="spacer" />
              <button className="btn ghost xs" onClick={() => setShowModal(false)}>×</button>
            </div>
            {modalError && <div className="error" style={{ marginBottom: 10 }}>{modalError}</div>}
            <form onSubmit={handleSubmit}>
              <div className="form-grid">
                <div className="field">
                  <label>Client Name *</label>
                  <input className="field" required value={form.clientName} onChange={(e) => setForm({ ...form, clientName: e.target.value })} placeholder="Client name" />
                </div>
                <div className="field">
                  <label>Client Phone</label>
                  <input className="field" value={form.clientPhone} onChange={(e) => setForm({ ...form, clientPhone: e.target.value })} placeholder="+880..." />
                </div>
                <div className="field">
                  <label>Event Type</label>
                  <select className="field" value={form.eventType} onChange={(e) => setForm({ ...form, eventType: e.target.value })}>
                    {EVENT_TYPES.map((t) => <option key={t}>{t}</option>)}
                  </select>
                </div>
                <div className="field">
                  <label>Date *</label>
                  <input type="date" className="field" required value={form.date} onChange={(e) => setForm({ ...form, date: e.target.value })} />
                </div>
                <div className="field" style={{ gridColumn: '1/-1' }}>
                  <label>Shift</label>
                  <div className="row" style={{ gap: 10, marginTop: 6 }}>
                    {['DAY', 'NIGHT', 'BOTH'].map((s) => (
                      <button
                        key={s} type="button"
                        className={`pill ${s === 'DAY' ? 'day' : s === 'NIGHT' ? 'night' : 'both'}`}
                        style={{ opacity: form.shift === s ? 1 : 0.4, border: form.shift === s ? '1px solid currentColor' : '1px solid transparent' }}
                        onClick={() => setForm({ ...form, shift: s })}
                      >{s} · {SHIFT_TIMES[s]}</button>
                    ))}
                  </div>
                </div>
                <div className="field">
                  <label>Venue</label>
                  <input className="field" value={form.venue} onChange={(e) => setForm({ ...form, venue: e.target.value })} placeholder="Event venue" />
                </div>
                <div className="field">
                  <label>Package</label>
                  <input className="field" value={form.package} onChange={(e) => setForm({ ...form, package: e.target.value })} placeholder="Package name or ID" />
                </div>
                <div className="field">
                  <label>Price (৳)</label>
                  <input type="number" className="field" value={form.price} onChange={(e) => setForm({ ...form, price: e.target.value })} placeholder="0" />
                </div>
                <div className="field">
                  <label>Advance (৳)</label>
                  <input type="number" className="field" value={form.advance} onChange={(e) => setForm({ ...form, advance: e.target.value })} placeholder="0" />
                </div>
                <div className="field">
                  <label>Company / Studio Name</label>
                  <input className="field" value={form.companyName} onChange={(e) => setForm({ ...form, companyName: e.target.value })} placeholder="Studio or brand name" />
                </div>
                <div className="field">
                  <label>Bride</label>
                  <input className="field" value={form.brideName} onChange={(e) => setForm({ ...form, brideName: e.target.value })} placeholder="Optional" />
                </div>
                <div className="field">
                  <label>Groom</label>
                  <input className="field" value={form.groomName} onChange={(e) => setForm({ ...form, groomName: e.target.value })} placeholder="Optional" />
                </div>
                <div className="field">
                  <label>Start Time</label>
                  <input className="field" value={form.startTime} onChange={(e) => setForm({ ...form, startTime: e.target.value })} placeholder="10:00" />
                </div>
                <div className="field">
                  <label>End Time</label>
                  <input className="field" value={form.endTime} onChange={(e) => setForm({ ...form, endTime: e.target.value })} placeholder="18:00" />
                </div>
                <div className="field">
                  <label>Map Link</label>
                  <input className="field" value={form.mapLink} onChange={(e) => setForm({ ...form, mapLink: e.target.value })} placeholder="https://maps…" />
                </div>
                <div className="field" style={{ gridColumn: '1/-1', flexDirection: 'row', alignItems: 'center', gap: 8 }}>
                  <input type="checkbox" id="new-outdoor" checked={form.outdoor} onChange={(e) => setForm({ ...form, outdoor: e.target.checked })} />
                  <label htmlFor="new-outdoor" style={{ margin: 0 }}>Outdoor shoot</label>
                </div>
                {form.outdoor && (
                  <>
                    <div className="field">
                      <label>Outdoor Location</label>
                      <input className="field" value={form.outdoorLocation} onChange={(e) => setForm({ ...form, outdoorLocation: e.target.value })} />
                    </div>
                    <div className="field">
                      <label>Reporting Time</label>
                      <input className="field" value={form.reportingTime} onChange={(e) => setForm({ ...form, reportingTime: e.target.value })} />
                    </div>
                  </>
                )}
                <div className="field">
                  <label>Custom Price (৳)</label>
                  <input type="number" className="field" value={form.customPrice} onChange={(e) => setForm({ ...form, customPrice: e.target.value })} placeholder="0" />
                </div>
                <div className="field">
                  <label>Coverage Hours</label>
                  <input type="number" className="field" value={form.coverageHours} onChange={(e) => setForm({ ...form, coverageHours: e.target.value })} placeholder="0" />
                </div>
                <div className="field">
                  <label>Extra Hour Rate (৳)</label>
                  <input type="number" className="field" value={form.extraHourRate} onChange={(e) => setForm({ ...form, extraHourRate: e.target.value })} placeholder="0" />
                </div>
                <div className="field">
                  <label>Chief Photographer</label>
                  <input className="field" value={form.chiefPhotographer} onChange={(e) => setForm({ ...form, chiefPhotographer: e.target.value })} placeholder="Lead photographer name" />
                </div>
                <div className="field" style={{ gridColumn: '1/-1' }}>
                  <label>Drive Link</label>
                  <input className="field" value={form.driveLink} onChange={(e) => setForm({ ...form, driveLink: e.target.value })} placeholder="https://drive.google.com/…" />
                </div>
                <div className="field" style={{ gridColumn: '1/-1' }}>
                  <label>Client Requirements</label>
                  <textarea className="field" rows={2} value={form.requirements} onChange={(e) => setForm({ ...form, requirements: e.target.value })} placeholder="Any specific requirements…" />
                </div>
                <div className="field" style={{ gridColumn: '1/-1' }}>
                  <label>Notes</label>
                  <textarea className="field" rows={3} value={form.notes} onChange={(e) => setForm({ ...form, notes: e.target.value })} placeholder="Additional notes..." />
                </div>
              </div>
              <div className="row" style={{ gap: 10, marginTop: 16, justifyContent: 'flex-end' }}>
                <button type="button" className="btn ghost" onClick={() => setShowModal(false)}>Cancel</button>
                <button type="submit" className="btn" style={{ background: 'var(--orange)', color: '#000' }} disabled={submitting}>
                  {submitting ? 'Saving...' : editId ? 'Save Changes' : 'Create Booking'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Delete Confirm */}
      {deleteId && (
        <div className="modal-backdrop" onClick={() => setDeleteId(null)}>
          <div className="modal" onClick={(e) => e.stopPropagation()} style={{ maxWidth: 400 }}>
            <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 20, marginBottom: 12 }}>Confirm Delete</div>
            <p className="muted" style={{ marginBottom: 20 }}>Are you sure you want to delete this booking? This cannot be undone.</p>
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
