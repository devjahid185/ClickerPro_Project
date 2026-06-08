import { useEffect, useState, FormEvent } from 'react';
import { useRouter } from 'next/router';
import Link from 'next/link';
import AppShell from '@/components/AppShell';
import { api } from '@/lib/api';
import { tk } from '@/lib/format';
import { Payment } from '@/types/api';

const fmtDate = (d: string) =>
  d ? new Date(d).toLocaleDateString('en-BD', { day: 'numeric', month: 'short', year: 'numeric' }) : '—';
const fmtDateTime = (d: string) =>
  d ? new Date(d).toLocaleString('en-BD', { day: 'numeric', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' }) : '—';

function statusBadge(s: string) {
  const map: Record<string, string> = {
    PENDING: 'gold', CONFIRMED: 'teal', IN_PROGRESS: 'orange',
    SHOT_COMPLETE: 'blue', DELIVERED: 'purple', COMPLETED: 'green', CANCELLED: 'red',
  };
  return <span className={`badge ${map[s] || 'gray'}`}>{s.replace(/_/g, ' ')}</span>;
}

const STATUSES = ['PENDING', 'CONFIRMED', 'IN_PROGRESS', 'SHOT_COMPLETE', 'DELIVERED', 'COMPLETED', 'CANCELLED'];
const PAYMENT_KINDS = ['ADVANCE', 'DUE', 'EXTRA', 'PAYOUT'];
const PAYMENT_METHODS = ['CASH', 'BKASH', 'NAGAD', 'BANK', 'CARD'];
const ROLES = ['Photographer', 'Cinematographer', 'Chief', 'Editor', 'Assistant'];

export default function BookingDetailPage() {
  const router = useRouter();
  const { id } = router.query as { id: string };
  const [tab, setTab] = useState(0);
  const [booking, setBooking] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  // Assignments
  const [assignments, setAssignments] = useState<any[]>([]);
  const [showAssignModal, setShowAssignModal] = useState(false);
  const [assignForm, setAssignForm] = useState({ userId: '', role: 'Photographer', payout: '' });
  const [assignErr, setAssignErr] = useState('');

  // Payments
  const [evtPayments, setEvtPayments] = useState<Payment[]>([]);
  const [showPayModal, setShowPayModal] = useState(false);
  const [payForm, setPayForm] = useState({ amount: '', kind: 'ADVANCE', method: 'CASH', note: '' });
  const [payErr, setPayErr] = useState('');

  // Tasks
  const [tasks, setTasks] = useState<any[]>([]);
  const [showTaskModal, setShowTaskModal] = useState(false);
  const [taskForm, setTaskForm] = useState({ percentage: 0, note: '' });
  const [taskErr, setTaskErr] = useState('');

  // Re-edits
  const [reedits, setReedits] = useState<any[]>([]);
  const [showReditModal, setShowReditModal] = useState(false);
  const [reditForm, setReditForm] = useState({ description: '' });
  const [reditErr, setReditErr] = useState('');

  // Edit booking
  const [showEditModal, setShowEditModal] = useState(false);
  const [editForm, setEditForm] = useState<any>({});
  const [editErr, setEditErr] = useState('');

  const [submitting, setSubmitting] = useState(false);

  const loadBooking = async () => {
    if (!id) return;
    setLoading(true);
    try {
      const b = await api<any>(`/api/bookings/${id}`);
      setBooking(b?.data ?? b);
      setEditForm({
        clientName: b?.clientName || b?.client_name || b?.client?.name || '',
        clientPhone: b?.clientPhone || b?.client_phone || b?.client?.phone || '',
        eventType: b?.eventType || b?.event_type || '',
        date: (b?.date || b?.event_date || '').split('T')[0],
        shift: b?.shift || 'DAY',
        venue: b?.venue || '',
        price: b?.price || '',
        advance: b?.advance || '',
        notes: b?.notes || '',
        status: b?.status || 'PENDING',
      });
    } catch (e: any) { setError(e.message); }
    finally { setLoading(false); }
  };

  const loadTab = async () => {
    if (!id) return;
    try {
      if (tab === 1) {
        const r = await api<any>(`/api/bookings/${id}/assignments`);
        setAssignments(Array.isArray(r) ? r : r?.data ?? []);
      } else if (tab === 2) {
        const r = await api<Payment[] | { data?: Payment[]; payments?: Payment[] }>(`/api/payments/event/${id}`);
        setEvtPayments(Array.isArray(r) ? r : r?.data ?? r?.payments ?? []);
      } else if (tab === 3) {
        const r = await api<any>(`/api/bookings/${id}/tasks`);
        setTasks(Array.isArray(r) ? r : r?.data ?? []);
      } else if (tab === 4) {
        const r = await api<any>(`/api/bookings/${id}/reedits`);
        setReedits(Array.isArray(r) ? r : r?.data ?? []);
      }
    } catch { /* ignore */ }
  };

  useEffect(() => { loadBooking(); }, [id]);
  useEffect(() => { loadTab(); }, [tab, id]);

  const getDate = (b: any) => (b?.date || b?.event_date || '').split('T')[0];
  const getName = (b: any) => b?.clientName || b?.client_name || b?.client?.name || '—';
  const getPhone = (b: any) => b?.clientPhone || b?.client_phone || b?.client?.phone || '—';

  const handleStatusChange = async (status: string) => {
    try {
      await api(`/api/bookings/${id}`, { method: 'PATCH', body: { status } });
      loadBooking();
    } catch (e: any) { alert(e.message); }
  };

  const handleEdit = async (e: FormEvent) => {
    e.preventDefault();
    setSubmitting(true); setEditErr('');
    try {
      await api(`/api/bookings/${id}`, { method: 'PATCH', body: editForm });
      setShowEditModal(false); loadBooking();
    } catch (e: any) { setEditErr(e.message); }
    finally { setSubmitting(false); }
  };

  const handleAddAssignment = async (e: FormEvent) => {
    e.preventDefault();
    if (!assignForm.userId) { setAssignErr('User ID is required'); return; }
    setSubmitting(true); setAssignErr('');
    try {
      await api(`/api/bookings/${id}/assignments`, { method: 'POST', body: { userId: assignForm.userId, role: assignForm.role, payout: Number(assignForm.payout) } });
      setShowAssignModal(false); loadTab();
    } catch (e: any) { setAssignErr(e.message); }
    finally { setSubmitting(false); }
  };

  const handleDeleteAssignment = async (aid: string) => {
    if (!confirm('Remove this assignment?')) return;
    try {
      await api(`/api/assignments/${aid}`, { method: 'DELETE' });
      loadTab();
    } catch (e: any) { alert(e.message); }
  };

  const handleAddPayment = async (e: FormEvent) => {
    e.preventDefault();
    if (!payForm.amount) { setPayErr('Amount is required'); return; }
    setSubmitting(true); setPayErr('');
    try {
      await api('/api/payments', { method: 'POST', body: { eventId: id, bookingId: id, amount: Number(payForm.amount), kind: payForm.kind, method: payForm.method, note: payForm.note } });
      setShowPayModal(false); loadTab();
    } catch (e: any) { setPayErr(e.message); }
    finally { setSubmitting(false); }
  };

  const handleUpdateTask = async (e: FormEvent) => {
    e.preventDefault();
    setSubmitting(true); setTaskErr('');
    try {
      await api(`/api/bookings/${id}/tasks`, { method: 'POST', body: taskForm });
      setShowTaskModal(false); loadTab();
    } catch (e: any) { setTaskErr(e.message); }
    finally { setSubmitting(false); }
  };

  const handleAddRedit = async (e: FormEvent) => {
    e.preventDefault();
    if (!reditForm.description) { setReditErr('Description is required'); return; }
    setSubmitting(true); setReditErr('');
    try {
      await api(`/api/bookings/${id}/reedits`, { method: 'POST', body: reditForm });
      setShowReditModal(false); loadTab();
    } catch (e: any) { setReditErr(e.message); }
    finally { setSubmitting(false); }
  };

  const totalReceived = evtPayments.filter((p) => p.kind !== 'PAYOUT').reduce((s, p) => s + (Number(p.amount) || 0), 0);
  const due = (Number(booking?.price) || 0) - totalReceived;

  const TABS = ['Overview', 'Assignments', 'Payments', 'Tasks', 'Re-edits', 'History'];

  if (!id) return null;

  return (
    <AppShell>
      <div style={{ padding: 24 }}>
        {loading && <div className="shimmer" style={{ height: 200, borderRadius: 8 }} />}
        {error && <div className="error">{error}</div>}

        {!loading && booking && (
          <>
            <div className="toolbar" style={{ marginBottom: 20 }}>
              <div>
                <Link href="/app/bookings" className="muted text-sm" style={{ textDecoration: 'none' }}>← Bookings</Link>
                <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 26, color: 'var(--film)', marginTop: 4 }}>
                  {booking.title || booking.eventType || 'Booking'}
                </div>
              </div>
              <span className="spacer" />
              <div className="row" style={{ gap: 8 }}>
                {statusBadge(booking.status)}
                <button className="btn ghost sm" onClick={() => setShowEditModal(true)}>Edit</button>
              </div>
            </div>

            {/* Tabs */}
            <div className="tabs" style={{ marginBottom: 20 }}>
              {TABS.map((t, i) => (
                <button key={t} className={`tab${tab === i ? ' active' : ''}`} onClick={() => setTab(i)}>{t}</button>
              ))}
            </div>

            {/* Tab 0: Overview */}
            {tab === 0 && (
              <div className="panel">
                <div className="panel-header">
                  <span className="panel-title">Booking Info</span>
                  <div className="row" style={{ gap: 8 }}>
                    <select className="field" value={booking.status} onChange={(e) => handleStatusChange(e.target.value)} style={{ fontSize: 13, padding: '4px 8px' }}>
                      {STATUSES.map((s) => <option key={s} value={s}>{s.replace(/_/g, ' ')}</option>)}
                    </select>
                  </div>
                </div>
                <div className="panel-body">
                  <div className="detail-grid">
                    {[
                      ['Title', booking.title || '—'],
                      ['Client', getName(booking)],
                      ['Phone', getPhone(booking)],
                      ['Event Type', booking.eventType || booking.event_type || '—'],
                      ['Date', fmtDate(getDate(booking))],
                      ['Shift', booking.shift || '—'],
                      ['Venue', booking.venue || '—'],
                      ['Price', tk(Number(booking.price) || 0)],
                      ['Advance', tk(Number(booking.advance) || 0)],
                      ['Due', tk(Math.max(0, (Number(booking.price) || 0) - (Number(booking.advance) || 0)))],
                      ['Status', booking.status],
                      ['Notes', booking.notes || '—'],
                    ].map(([k, v]) => (
                      <div key={k} className="info-row">
                        <span className="info-key">{k}</span>
                        <span className="info-val">{k === 'Status' ? statusBadge(String(v)) : v}</span>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            )}

            {/* Tab 1: Assignments */}
            {tab === 1 && (
              <div className="panel">
                <div className="panel-header">
                  <span className="panel-title">Team Assignments</span>
                  <button className="btn ghost sm" onClick={() => { setAssignForm({ userId: '', role: 'Photographer', payout: '' }); setAssignErr(''); setShowAssignModal(true); }}>+ Add</button>
                </div>
                <div className="panel-body">
                  {assignments.length === 0 && <div className="empty">No assignments yet.</div>}
                  {assignments.map((a: any) => (
                    <div key={a.id} className="row" style={{ padding: '10px 0', borderBottom: '1px solid var(--surface-3)', gap: 12 }}>
                      <div className="avatar avatar-sm">{(a.user?.name || a.userId || '?')[0].toUpperCase()}</div>
                      <div style={{ flex: 1 }}>
                        <div style={{ fontWeight: 600, fontSize: 14 }}>{a.user?.name || a.userId || 'Unknown'}</div>
                        <div className="muted text-sm">{a.role}</div>
                      </div>
                      <div style={{ textAlign: 'right' }}>
                        <div style={{ color: 'var(--orange)', fontSize: 13 }}>{tk(Number(a.payout) || 0)}</div>
                        <span className={`badge ${a.payoutPaid ? 'green' : 'gray'}`}>{a.payoutPaid ? 'Paid' : 'Pending'}</span>
                      </div>
                      <button className="btn danger xs" onClick={() => handleDeleteAssignment(a.id)}>×</button>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Tab 2: Payments */}
            {tab === 2 && (
              <div className="panel">
                <div className="panel-header">
                  <span className="panel-title">Payments</span>
                  <button className="btn ghost sm" onClick={() => { setPayForm({ amount: '', kind: 'ADVANCE', method: 'CASH', note: '' }); setPayErr(''); setShowPayModal(true); }}>+ Add Payment</button>
                </div>
                <div className="panel-body">
                  <div className="cards cards-2" style={{ marginBottom: 16 }}>
                    <div className="card" style={{ textAlign: 'center' }}>
                      <div className="muted text-sm">Total Received</div>
                      <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 26, color: 'var(--green)' }}>{tk(totalReceived)}</div>
                    </div>
                    <div className="card" style={{ textAlign: 'center' }}>
                      <div className="muted text-sm">Due Remaining</div>
                      <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 26, color: due > 0 ? 'var(--red)' : 'var(--green)' }}>{tk(Math.max(0, due))}</div>
                    </div>
                  </div>
                  {evtPayments.length === 0 && <div className="empty">No payments recorded.</div>}
                  {evtPayments.map((p: any, i: number) => (
                    <div key={p.id || i} className="row" style={{ padding: '10px 0', borderBottom: '1px solid var(--surface-3)', gap: 12 }}>
                      <div style={{ flex: 1 }}>
                        <div className="row" style={{ gap: 8 }}>
                          <span className="badge teal">{p.kind}</span>
                          <span className="badge gray">{p.method}</span>
                        </div>
                        <div className="muted text-sm" style={{ marginTop: 4 }}>{p.note || '—'} · {fmtDate(p.createdAt || p.paid_at || p.date)}</div>
                      </div>
                      <div style={{ color: 'var(--orange)', fontFamily: 'Bebas Neue, sans-serif', fontSize: 20 }}>{tk(Number(p.amount) || 0)}</div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Tab 3: Tasks */}
            {tab === 3 && (
              <div className="panel">
                <div className="panel-header">
                  <span className="panel-title">Task Progress</span>
                  <button className="btn ghost sm" onClick={() => { setTaskForm({ percentage: 0, note: '' }); setTaskErr(''); setShowTaskModal(true); }}>Update Task</button>
                </div>
                <div className="panel-body">
                  {tasks.length === 0 && <div className="empty">No tasks yet.</div>}
                  {tasks.map((t: any, i: number) => (
                    <div key={t.id || i} style={{ marginBottom: 16 }}>
                      <div className="row" style={{ justifyContent: 'space-between', marginBottom: 6 }}>
                        <span style={{ fontSize: 14, fontWeight: 600 }}>{t.user?.name || t.userId || 'Team'}</span>
                        <span style={{ color: 'var(--orange)', fontFamily: 'JetBrains Mono, monospace', fontSize: 13 }}>{t.percentage || 0}%</span>
                      </div>
                      <div style={{ background: 'var(--surface-3)', borderRadius: 4, height: 8 }}>
                        <div style={{ width: `${t.percentage || 0}%`, height: '100%', background: 'var(--orange)', borderRadius: 4, transition: 'width 0.3s' }} />
                      </div>
                      {t.note && <div className="muted text-sm" style={{ marginTop: 4 }}>{t.note}</div>}
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Tab 4: Re-edits */}
            {tab === 4 && (
              <div className="panel">
                <div className="panel-header">
                  <span className="panel-title">Re-edit Requests</span>
                  <button className="btn ghost sm" onClick={() => { setReditForm({ description: '' }); setReditErr(''); setShowReditModal(true); }}>+ New Request</button>
                </div>
                <div className="panel-body">
                  {reedits.length === 0 && <div className="empty">No re-edit requests.</div>}
                  {reedits.map((r: any, i: number) => (
                    <div key={r.id || i} style={{ padding: '12px', background: 'var(--surface-3)', borderRadius: 6, marginBottom: 10 }}>
                      <div className="row" style={{ justifyContent: 'space-between', marginBottom: 6 }}>
                        {statusBadge(r.status || 'PENDING')}
                        <span className="muted text-sm">{fmtDate(r.createdAt || r.created_at)}</span>
                      </div>
                      <div style={{ fontSize: 14, marginBottom: 4 }}>{r.description}</div>
                      {r.adminNote && <div className="muted text-sm">Admin: {r.adminNote}</div>}
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Tab 5: History */}
            {tab === 5 && (
              <div className="panel">
                <div className="panel-header"><span className="panel-title">Status History</span></div>
                <div className="panel-body">
                  {(!booking.statusHistories || booking.statusHistories.length === 0) && (
                    <div className="empty">No status history available.</div>
                  )}
                  <div className="timeline">
                    {(booking.statusHistories || []).map((h: any, i: number) => (
                      <div key={i} className="timeline-item">
                        <div className="timeline-dot" />
                        <div className="timeline-content">
                          <div style={{ fontSize: 14, fontWeight: 600 }}>
                            {h.from ? `${h.from} → ` : ''}{h.to || h.status || '—'}
                          </div>
                          <div className="muted text-sm">
                            {h.changedBy || h.user?.name || 'System'} · {fmtDateTime(h.createdAt || h.changed_at)}
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            )}
          </>
        )}
      </div>

      {/* Edit Modal */}
      {showEditModal && (
        <div className="modal-backdrop" onClick={() => setShowEditModal(false)}>
          <div className="modal modal-lg" onClick={(e) => e.stopPropagation()}>
            <div className="row" style={{ marginBottom: 16 }}>
              <span style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 20 }}>Edit Booking</span>
              <span className="spacer" />
              <button className="btn ghost xs" onClick={() => setShowEditModal(false)}>×</button>
            </div>
            {editErr && <div className="error" style={{ marginBottom: 10 }}>{editErr}</div>}
            <form onSubmit={handleEdit}>
              <div className="form-grid">
                <div className="field"><label>Client Name</label><input className="field" value={editForm.clientName} onChange={(e) => setEditForm({ ...editForm, clientName: e.target.value })} /></div>
                <div className="field"><label>Client Phone</label><input className="field" value={editForm.clientPhone} onChange={(e) => setEditForm({ ...editForm, clientPhone: e.target.value })} /></div>
                <div className="field"><label>Event Type</label><input className="field" value={editForm.eventType} onChange={(e) => setEditForm({ ...editForm, eventType: e.target.value })} /></div>
                <div className="field"><label>Date</label><input type="date" className="field" value={editForm.date} onChange={(e) => setEditForm({ ...editForm, date: e.target.value })} /></div>
                <div className="field"><label>Shift</label>
                  <select className="field" value={editForm.shift} onChange={(e) => setEditForm({ ...editForm, shift: e.target.value })}>
                    <option>DAY</option><option>NIGHT</option><option>BOTH</option>
                  </select>
                </div>
                <div className="field"><label>Venue</label><input className="field" value={editForm.venue} onChange={(e) => setEditForm({ ...editForm, venue: e.target.value })} /></div>
                <div className="field"><label>Price (৳)</label><input type="number" className="field" value={editForm.price} onChange={(e) => setEditForm({ ...editForm, price: e.target.value })} /></div>
                <div className="field"><label>Advance (৳)</label><input type="number" className="field" value={editForm.advance} onChange={(e) => setEditForm({ ...editForm, advance: e.target.value })} /></div>
                <div className="field" style={{ gridColumn: '1/-1' }}><label>Notes</label><textarea className="field" rows={3} value={editForm.notes} onChange={(e) => setEditForm({ ...editForm, notes: e.target.value })} /></div>
              </div>
              <div className="row" style={{ gap: 10, marginTop: 16, justifyContent: 'flex-end' }}>
                <button type="button" className="btn ghost" onClick={() => setShowEditModal(false)}>Cancel</button>
                <button type="submit" className="btn" style={{ background: 'var(--orange)', color: '#000' }} disabled={submitting}>{submitting ? 'Saving...' : 'Save Changes'}</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Assignment Modal */}
      {showAssignModal && (
        <div className="modal-backdrop" onClick={() => setShowAssignModal(false)}>
          <div className="modal" onClick={(e) => e.stopPropagation()}>
            <div className="row" style={{ marginBottom: 16 }}>
              <span style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 20 }}>Add Assignment</span>
              <span className="spacer" />
              <button className="btn ghost xs" onClick={() => setShowAssignModal(false)}>×</button>
            </div>
            {assignErr && <div className="error" style={{ marginBottom: 10 }}>{assignErr}</div>}
            <form onSubmit={handleAddAssignment}>
              <div className="field" style={{ marginBottom: 12 }}><label>User ID / Name *</label><input className="field" required value={assignForm.userId} onChange={(e) => setAssignForm({ ...assignForm, userId: e.target.value })} placeholder="Team member ID or name" /></div>
              <div className="field" style={{ marginBottom: 12 }}><label>Role</label>
                <select className="field" value={assignForm.role} onChange={(e) => setAssignForm({ ...assignForm, role: e.target.value })}>
                  {ROLES.map((r) => <option key={r}>{r}</option>)}
                </select>
              </div>
              <div className="field" style={{ marginBottom: 16 }}><label>Payout (৳)</label><input type="number" className="field" value={assignForm.payout} onChange={(e) => setAssignForm({ ...assignForm, payout: e.target.value })} placeholder="0" /></div>
              <div className="row" style={{ gap: 10, justifyContent: 'flex-end' }}>
                <button type="button" className="btn ghost" onClick={() => setShowAssignModal(false)}>Cancel</button>
                <button type="submit" className="btn" style={{ background: 'var(--orange)', color: '#000' }} disabled={submitting}>{submitting ? 'Adding...' : 'Add'}</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Payment Modal */}
      {showPayModal && (
        <div className="modal-backdrop" onClick={() => setShowPayModal(false)}>
          <div className="modal" onClick={(e) => e.stopPropagation()}>
            <div className="row" style={{ marginBottom: 16 }}>
              <span style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 20 }}>Add Payment</span>
              <span className="spacer" />
              <button className="btn ghost xs" onClick={() => setShowPayModal(false)}>×</button>
            </div>
            {payErr && <div className="error" style={{ marginBottom: 10 }}>{payErr}</div>}
            <form onSubmit={handleAddPayment}>
              <div className="form-grid">
                <div className="field"><label>Amount (৳) *</label><input type="number" className="field" required value={payForm.amount} onChange={(e) => setPayForm({ ...payForm, amount: e.target.value })} placeholder="0" /></div>
                <div className="field"><label>Kind</label>
                  <select className="field" value={payForm.kind} onChange={(e) => setPayForm({ ...payForm, kind: e.target.value })}>
                    {PAYMENT_KINDS.map((k) => <option key={k}>{k}</option>)}
                  </select>
                </div>
                <div className="field"><label>Method</label>
                  <select className="field" value={payForm.method} onChange={(e) => setPayForm({ ...payForm, method: e.target.value })}>
                    {PAYMENT_METHODS.map((m) => <option key={m}>{m}</option>)}
                  </select>
                </div>
                <div className="field"><label>Note</label><input className="field" value={payForm.note} onChange={(e) => setPayForm({ ...payForm, note: e.target.value })} placeholder="Optional note" /></div>
              </div>
              <div className="row" style={{ gap: 10, marginTop: 16, justifyContent: 'flex-end' }}>
                <button type="button" className="btn ghost" onClick={() => setShowPayModal(false)}>Cancel</button>
                <button type="submit" className="btn" style={{ background: 'var(--orange)', color: '#000' }} disabled={submitting}>{submitting ? 'Adding...' : 'Add Payment'}</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Task Modal */}
      {showTaskModal && (
        <div className="modal-backdrop" onClick={() => setShowTaskModal(false)}>
          <div className="modal" onClick={(e) => e.stopPropagation()}>
            <div className="row" style={{ marginBottom: 16 }}>
              <span style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 20 }}>Update Task Progress</span>
              <span className="spacer" />
              <button className="btn ghost xs" onClick={() => setShowTaskModal(false)}>×</button>
            </div>
            {taskErr && <div className="error" style={{ marginBottom: 10 }}>{taskErr}</div>}
            <form onSubmit={handleUpdateTask}>
              <div className="field" style={{ marginBottom: 12 }}>
                <label>Progress: {taskForm.percentage}%</label>
                <input type="range" min={0} max={100} value={taskForm.percentage} onChange={(e) => setTaskForm({ ...taskForm, percentage: Number(e.target.value) })} style={{ width: '100%', marginTop: 8 }} />
              </div>
              <div className="field" style={{ marginBottom: 16 }}><label>Note</label><textarea className="field" rows={3} value={taskForm.note} onChange={(e) => setTaskForm({ ...taskForm, note: e.target.value })} /></div>
              <div className="row" style={{ gap: 10, justifyContent: 'flex-end' }}>
                <button type="button" className="btn ghost" onClick={() => setShowTaskModal(false)}>Cancel</button>
                <button type="submit" className="btn" style={{ background: 'var(--orange)', color: '#000' }} disabled={submitting}>{submitting ? 'Updating...' : 'Update'}</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Re-edit Modal */}
      {showReditModal && (
        <div className="modal-backdrop" onClick={() => setShowReditModal(false)}>
          <div className="modal" onClick={(e) => e.stopPropagation()}>
            <div className="row" style={{ marginBottom: 16 }}>
              <span style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 20 }}>New Re-edit Request</span>
              <span className="spacer" />
              <button className="btn ghost xs" onClick={() => setShowReditModal(false)}>×</button>
            </div>
            {reditErr && <div className="error" style={{ marginBottom: 10 }}>{reditErr}</div>}
            <form onSubmit={handleAddRedit}>
              <div className="field" style={{ marginBottom: 16 }}><label>Description *</label><textarea className="field" rows={4} required value={reditForm.description} onChange={(e) => setReditForm({ description: e.target.value })} placeholder="Describe what needs to be re-edited..." /></div>
              <div className="row" style={{ gap: 10, justifyContent: 'flex-end' }}>
                <button type="button" className="btn ghost" onClick={() => setShowReditModal(false)}>Cancel</button>
                <button type="submit" className="btn" style={{ background: 'var(--orange)', color: '#000' }} disabled={submitting}>{submitting ? 'Submitting...' : 'Submit'}</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </AppShell>
  );
}
