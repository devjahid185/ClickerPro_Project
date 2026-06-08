import { useEffect, useState, FormEvent } from 'react';
import { useRouter } from 'next/router';
import Link from 'next/link';
import AppShell from '@/components/AppShell';
import { api } from '@/lib/api';
import { tk } from '@/lib/format';
import { Client, Booking, Payment } from '@/types/api';

const fmtDate = (d?: string | null) =>
  d ? new Date(d).toLocaleDateString('en-BD', { day: 'numeric', month: 'short', year: 'numeric' }) : '—';

const initials = (name: string) =>
  name.split(' ').map((w) => w[0]).join('').slice(0, 2).toUpperCase();

function statusBadge(s: string) {
  const map: Record<string, string> = {
    PENDING: 'gold', CONFIRMED: 'teal', IN_PROGRESS: 'orange',
    SHOT_COMPLETE: 'blue', DELIVERED: 'purple', COMPLETED: 'green', CANCELLED: 'red',
  };
  return <span className={`badge ${map[s] || 'gray'}`}>{s.replace(/_/g, ' ')}</span>;
}

export default function ClientDetailPage() {
  const router = useRouter();
  const { id } = router.query as { id: string };

  const [client, setClient] = useState<(Client & { bookings?: Booking[] }) | null>(null);
  const [bookings, setBookings] = useState<Booking[]>([]);
  const [payments, setPayments] = useState<Payment[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [editing, setEditing] = useState(false);
  const [form, setForm] = useState<any>({});
  const [editErr, setEditErr] = useState('');
  const [submitting, setSubmitting] = useState(false);

  const load = async () => {
    if (!id) return;
    setLoading(true);
    try {
      const [c, bRes, pRes] = await Promise.all([
        api<Client | { data?: Client }>(`/api/clients/${id}`),
        api<Booking[] | { data?: Booking[]; bookings?: Booking[] }>(`/api/bookings?clientId=${id}&limit=50`).catch(() => [] as Booking[]),
        api<Payment[] | { data?: Payment[]; payments?: Payment[] }>(`/api/payments?clientId=${id}&limit=100`).catch(() => [] as Payment[]),
      ]);
      const clientData = (c && 'data' in c ? c.data : c) as (Client & { bookings?: Booking[] }) | null;
      setClient(clientData);
      setForm({
        name: clientData?.name || '',
        phone: clientData?.phone || '',
        email: clientData?.email || '',
        notes: clientData?.notes || '',
        dob: clientData?.dob?.split('T')[0] || '',
        anniversary: clientData?.anniversary?.split('T')[0] || '',
      });
      setBookings(Array.isArray(bRes) ? bRes : bRes?.data ?? bRes?.bookings ?? []);
      setPayments(Array.isArray(pRes) ? pRes : pRes?.data ?? pRes?.payments ?? []);
    } catch (e: any) { setError(e.message); }
    finally { setLoading(false); }
  };

  useEffect(() => { load(); }, [id]);

  const handleSave = async (e: FormEvent) => {
    e.preventDefault();
    if (!form.name?.trim()) { setEditErr('Name is required'); return; }
    setSubmitting(true); setEditErr('');
    try {
      await api(`/api/clients/${id}`, { method: 'PATCH', body: form });
      setEditing(false);
      load();
    } catch (e: any) { setEditErr(e.message); }
    finally { setSubmitting(false); }
  };

  const getDate = (b: any) => b.date?.split('T')[0] || b.event_date?.split('T')[0] || '';

  const totalPaid = payments.filter((p) => p.kind !== 'PAYOUT').reduce((s, p) => s + (Number(p.amount) || 0), 0);
  const totalBookingValue = bookings.reduce((s, b) => s + (Number(b.price) || 0), 0);

  if (!id) return null;

  return (
    <AppShell>
      <div style={{ padding: 24 }}>
        <Link href="/app/clients" className="muted text-sm" style={{ textDecoration: 'none' }}>← Back to Clients</Link>

        {loading && <div className="shimmer" style={{ height: 160, borderRadius: 8, marginTop: 16 }} />}
        {error && <div className="error" style={{ marginTop: 16 }}>{error}</div>}

        {!loading && client && (
          <>
            {/* Client Header */}
            <div className="card" style={{ marginTop: 16, marginBottom: 20 }}>
              <div className="row" style={{ gap: 16, alignItems: 'flex-start' }}>
                <div className="avatar avatar-lg">{initials(client.name || '?')}</div>
                <div style={{ flex: 1 }}>
                  {!editing ? (
                    <>
                      <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 26 }}>{client.name}</div>
                      <div className="info-row"><span className="info-key">Phone</span><span className="info-val">{client.phone || '—'}</span></div>
                      <div className="info-row"><span className="info-key">Email</span><span className="info-val">{client.email || '—'}</span></div>
                      <div className="info-row"><span className="info-key">DOB</span><span className="info-val">{fmtDate(client.dob)}</span></div>
                      <div className="info-row"><span className="info-key">Anniversary</span><span className="info-val">{fmtDate(client.anniversary)}</span></div>
                      {client.notes && <div className="info-row"><span className="info-key">Notes</span><span className="info-val">{client.notes}</span></div>}
                    </>
                  ) : (
                    <form onSubmit={handleSave}>
                      {editErr && <div className="error" style={{ marginBottom: 10 }}>{editErr}</div>}
                      <div className="form-grid">
                        <div className="field"><label>Name *</label><input className="field" required value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} /></div>
                        <div className="field"><label>Phone</label><input className="field" value={form.phone} onChange={(e) => setForm({ ...form, phone: e.target.value })} /></div>
                        <div className="field"><label>Email</label><input type="email" className="field" value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} /></div>
                        <div className="field"><label>DOB</label><input type="date" className="field" value={form.dob} onChange={(e) => setForm({ ...form, dob: e.target.value })} /></div>
                        <div className="field"><label>Anniversary</label><input type="date" className="field" value={form.anniversary} onChange={(e) => setForm({ ...form, anniversary: e.target.value })} /></div>
                        <div className="field" style={{ gridColumn: '1/-1' }}><label>Notes</label><textarea className="field" rows={2} value={form.notes} onChange={(e) => setForm({ ...form, notes: e.target.value })} /></div>
                      </div>
                      <div className="row" style={{ gap: 8, marginTop: 12 }}>
                        <button type="submit" className="btn sm" style={{ background: 'var(--orange)', color: '#000' }} disabled={submitting}>{submitting ? 'Saving...' : 'Save'}</button>
                        <button type="button" className="btn ghost sm" onClick={() => setEditing(false)}>Cancel</button>
                      </div>
                    </form>
                  )}
                </div>
                {!editing && (
                  <button className="btn ghost sm" onClick={() => setEditing(true)}>Edit</button>
                )}
              </div>
            </div>

            {/* Summary Cards */}
            <div className="cards cards-3" style={{ marginBottom: 20 }}>
              <div className="card" style={{ textAlign: 'center' }}>
                <div className="muted text-sm">Total Bookings</div>
                <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 32, color: 'var(--orange)' }}>{bookings.length}</div>
              </div>
              <div className="card" style={{ textAlign: 'center' }}>
                <div className="muted text-sm">Total Booked Value</div>
                <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 26, color: 'var(--blue)' }}>{tk(totalBookingValue)}</div>
              </div>
              <div className="card" style={{ textAlign: 'center' }}>
                <div className="muted text-sm">Total Paid</div>
                <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 26, color: 'var(--green)' }}>{tk(totalPaid)}</div>
              </div>
            </div>

            {/* Booking History */}
            <div className="panel" style={{ marginBottom: 20 }}>
              <div className="panel-header"><span className="panel-title">Booking History</span></div>
              <div className="panel-body">
                {bookings.length === 0 && <div className="empty">No bookings for this client.</div>}
                {bookings.length > 0 && (
                  <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                    <thead>
                      <tr style={{ borderBottom: '1px solid var(--surface-3)' }}>
                        {['Event', 'Date', 'Status', 'Price'].map((h) => (
                          <th key={h} style={{ textAlign: 'left', padding: '8px 12px', fontSize: 11, fontFamily: 'JetBrains Mono, monospace', color: 'var(--film-muted)', textTransform: 'uppercase' }}>{h}</th>
                        ))}
                      </tr>
                    </thead>
                    <tbody>
                      {bookings.map((b) => (
                        <tr key={b.id} style={{ borderBottom: '1px solid var(--surface-3)' }}>
                          <td style={{ padding: '10px 12px' }}>
                            <Link href={`/app/bookings/${b.id}`} style={{ fontWeight: 600, fontSize: 14, color: 'var(--film)' }}>
                              {b.title || b.eventType || 'Booking'}
                            </Link>
                          </td>
                          <td style={{ padding: '10px 12px', fontSize: 13 }}>{fmtDate(getDate(b))}</td>
                          <td style={{ padding: '10px 12px' }}>{statusBadge(b.status)}</td>
                          <td style={{ padding: '10px 12px', fontSize: 13, color: 'var(--orange)' }}>{tk(Number(b.price) || 0)}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                )}
              </div>
            </div>

            {/* Payment History */}
            <div className="panel">
              <div className="panel-header"><span className="panel-title">Payment History</span></div>
              <div className="panel-body">
                {payments.length === 0 && <div className="empty">No payment records found.</div>}
                {payments.map((p: any, i: number) => (
                  <div key={p.id || i} className="row" style={{ padding: '10px 0', borderBottom: '1px solid var(--surface-3)', gap: 12 }}>
                    <div style={{ flex: 1 }}>
                      <div className="row" style={{ gap: 8 }}>
                        <span className="badge teal">{p.kind}</span>
                        <span className="badge gray">{p.method}</span>
                      </div>
                      {p.note && <div className="muted text-sm" style={{ marginTop: 4 }}>{p.note}</div>}
                      <div className="muted text-sm">{fmtDate(p.createdAt || p.paid_at || p.date)}</div>
                    </div>
                    <div style={{ color: 'var(--orange)', fontFamily: 'Bebas Neue, sans-serif', fontSize: 20 }}>{tk(Number(p.amount) || 0)}</div>
                  </div>
                ))}
              </div>
            </div>
          </>
        )}
      </div>
    </AppShell>
  );
}
