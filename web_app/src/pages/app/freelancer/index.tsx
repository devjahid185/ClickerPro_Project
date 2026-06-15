import { useEffect, useState, FormEvent } from 'react';
import Link from 'next/link';
import AppShell from '@/components/AppShell';
import { api } from '@/lib/api';
import { tk } from '@/lib/format';

const fmtDate = (d: string) =>
  d ? new Date(d).toLocaleDateString('en-BD', { day: 'numeric', month: 'short', year: 'numeric' }) : '—';

const TABS = ['Earnings', 'Availability', 'Leave', 'Work History', 'Badges', 'Dashboard'];

// Achievement badges derived from completed-job count + earnings.
const BADGE_TIERS = [
  { name: 'Rookie',        icon: '🌱', threshold: 0,   desc: 'Welcome aboard — your journey starts here.' },
  { name: 'Rising Star',   icon: '⭐', threshold: 5,   desc: 'Completed 5+ jobs. People are noticing.' },
  { name: 'Pro Shooter',   icon: '📸', threshold: 15,  desc: 'Completed 15+ jobs. A seasoned pro.' },
  { name: 'Veteran',       icon: '🏆', threshold: 30,  desc: 'Completed 30+ jobs. Truly battle-tested.' },
  { name: 'Legend',        icon: '👑', threshold: 50,  desc: 'Completed 50+ jobs. Studio legend status.' },
];

// ── Status badges ───────────────────────────────────────────────
const STATUS_COLORS: Record<string, string> = {
  PENDING: 'gold',
  CONFIRMED: 'teal',
  IN_PROGRESS: 'orange',
  SHOT_COMPLETE: 'blue',
  DELIVERED: 'purple',
  COMPLETED: 'green',
  CANCELLED: 'red',
};
const statusBadge = (status: string) => {
  const color = STATUS_COLORS[status] || 'gray';
  return <span className={'badge ' + color}>{(status || '').replace(/_/g, ' ')}</span>;
};

const LEAVE_COLORS: Record<string, string> = { PENDING: 'gold', APPROVED: 'green', REJECTED: 'red' };
const leaveBadge = (status: string) => {
  const color = LEAVE_COLORS[status] || 'gray';
  return <span className={'badge ' + color}>{(status || '').replace(/_/g, ' ')}</span>;
};

const RECURRENCE_COLORS: Record<string, string> = { none: 'gray', weekly: 'blue', monthly: 'teal', yearly: 'purple' };
const RECURRENCES = ['none', 'weekly', 'monthly', 'yearly'];

const METHODS = ['CASH', 'BKASH', 'NAGAD', 'BANK'];

// ── Blank form factories ────────────────────────────────────────
const blankPayment = () => ({ event_id: '', amount: '', method: 'CASH', note: '' });
const blankBlackout = () => ({ date: '', end_date: '', reason: '', recurrence: 'none' });
const blankLeave = () => ({ start_date: '', end_date: '', reason: '', notes: '' });

export default function FreelancerPage() {
  const [tab, setTab] = useState(0);

  // ── Earnings ──────────────────────────────────────────────────
  const [earnings, setEarnings] = useState<any>({
    totalEarnings: 0, receivedAmount: 0, pendingAmount: 0, advance: 0, due: 0, extra: 0, payout: 0,
  });
  const [earnLoading, setEarnLoading] = useState(true);
  const [earnError, setEarnError] = useState('');
  const [bookings, setBookings] = useState<any[]>([]);
  const [showPayModal, setShowPayModal] = useState(false);
  const [payForm, setPayForm] = useState<any>(blankPayment());
  const [paySubmitting, setPaySubmitting] = useState(false);
  const [payError, setPayError] = useState('');
  const [paySuccess, setPaySuccess] = useState('');

  // ── Availability (blackouts) ──────────────────────────────────
  const [blackouts, setBlackouts] = useState<any[]>([]);
  const [boLoading, setBoLoading] = useState(true);
  const [boError, setBoError] = useState('');
  const [showBoModal, setShowBoModal] = useState(false);
  const [boForm, setBoForm] = useState<any>(blankBlackout());
  const [boSubmitting, setBoSubmitting] = useState(false);
  const [boModalError, setBoModalError] = useState('');

  // ── Leave ─────────────────────────────────────────────────────
  const [leaves, setLeaves] = useState<any[]>([]);
  const [leaveLoading, setLeaveLoading] = useState(true);
  const [leaveError, setLeaveError] = useState('');
  const [showLeaveModal, setShowLeaveModal] = useState(false);
  const [leaveForm, setLeaveForm] = useState<any>(blankLeave());
  const [leaveSubmitting, setLeaveSubmitting] = useState(false);
  const [leaveModalError, setLeaveModalError] = useState('');

  // ── Work History ──────────────────────────────────────────────
  const [history, setHistory] = useState<any[]>([]);
  const [histLoading, setHistLoading] = useState(true);
  const [histError, setHistError] = useState('');

  // ── Multi-owner Dashboard + Check-in ──────────────────────────
  const [dashEvents, setDashEvents] = useState<any[]>([]);
  const [conflicts, setConflicts] = useState<any[]>([]);
  const [dashLoading, setDashLoading] = useState(true);
  const [dashError, setDashError] = useState('');
  const [checkins, setCheckins] = useState<Record<string, any>>({});
  const [checkingIn, setCheckingIn] = useState<string | null>(null);

  // ── Loaders ───────────────────────────────────────────────────
  const loadEarnings = async () => {
    setEarnLoading(true); setEarnError('');
    try {
      const [resE, resB] = await Promise.all([
        api<any>('/api/freelancer/earnings'),
        api<any>('/api/bookings?limit=200'),
      ]);
      const e = resE?.data ?? resE ?? {};
      setEarnings({
        totalEarnings: Number(e.totalEarnings) || 0,
        receivedAmount: Number(e.receivedAmount) || 0,
        pendingAmount: Number(e.pendingAmount) || 0,
        advance: Number(e.advance) || 0,
        due: Number(e.due) || 0,
        extra: Number(e.extra) || 0,
        payout: Number(e.payout) || 0,
      });
      setBookings(Array.isArray(resB) ? resB : resB?.data ?? []);
    } catch (e: any) { setEarnError(e.message); }
    finally { setEarnLoading(false); }
  };

  const loadBlackouts = async () => {
    setBoLoading(true); setBoError('');
    try {
      const res = await api<any>('/api/freelancer/blackouts');
      setBlackouts(Array.isArray(res) ? res : res?.data ?? []);
    } catch (e: any) { setBoError(e.message); }
    finally { setBoLoading(false); }
  };

  const loadLeaves = async () => {
    setLeaveLoading(true); setLeaveError('');
    try {
      const res = await api<any>('/api/freelancer/leaves');
      setLeaves(Array.isArray(res) ? res : res?.data ?? []);
    } catch (e: any) { setLeaveError(e.message); }
    finally { setLeaveLoading(false); }
  };

  const loadHistory = async () => {
    setHistLoading(true); setHistError('');
    try {
      const res = await api<any>('/api/freelancer/work-history');
      setHistory(Array.isArray(res) ? res : res?.data ?? []);
    } catch (e: any) { setHistError(e.message); }
    finally { setHistLoading(false); }
  };

  const loadDashboard = async () => {
    setDashLoading(true); setDashError('');
    try {
      const [resE, resC] = await Promise.all([
        api<any>('/api/freelancer/dashboard/events'),
        api<any>('/api/freelancer/dashboard/conflicts'),
      ]);
      const events = Array.isArray(resE) ? resE : resE?.data ?? [];
      setDashEvents(events);
      setConflicts(Array.isArray(resC) ? resC : resC?.data ?? []);
      // Pull current check-in status for each event in parallel.
      const statuses = await Promise.all(
        events.map((ev: any) =>
          api<any>(`/api/freelancer/checkin/${ev.eventId}`).then((r) => r?.data ?? r).catch(() => null)),
      );
      const map: Record<string, any> = {};
      events.forEach((ev: any, i: number) => { if (statuses[i]) map[ev.eventId] = statuses[i]; });
      setCheckins(map);
    } catch (e: any) { setDashError(e.message); }
    finally { setDashLoading(false); }
  };

  const doCheckin = async (eventId: string) => {
    setCheckingIn(eventId);
    try {
      const r = await api<any>('/api/freelancer/checkin', {
        method: 'POST',
        body: { eventId, checkinTime: new Date().toISOString(), status: 'checkedIn' },
      });
      setCheckins((prev) => ({ ...prev, [eventId]: r?.data ?? r }));
    } catch (e: any) { alert(e.message); }
    finally { setCheckingIn(null); }
  };

  useEffect(() => {
    if (tab === 0) loadEarnings();
    else if (tab === 1) loadBlackouts();
    else if (tab === 2) loadLeaves();
    else if (tab === 3 || tab === 4) loadHistory();
    else if (tab === 5) loadDashboard();
  }, [tab]);

  // ── Payment request ───────────────────────────────────────────
  const openPay = () => { setPayForm(blankPayment()); setPayError(''); setPaySuccess(''); setShowPayModal(true); };
  const submitPayment = async (e: FormEvent) => {
    e.preventDefault();
    if (!payForm.amount) { setPayError('Amount is required.'); return; }
    setPaySubmitting(true); setPayError('');
    try {
      await api('/api/payments', {
        method: 'POST',
        body: {
          amount: Number(payForm.amount),
          kind: 'PAYOUT',
          method: payForm.method,
          note: payForm.note,
          event_id: payForm.event_id || null,
        },
      });
      setShowPayModal(false);
      setPaySuccess('Payment request submitted successfully.');
      loadEarnings();
    } catch (e: any) { setPayError(e.message); }
    finally { setPaySubmitting(false); }
  };

  // ── Blackout create / delete ──────────────────────────────────
  const openBo = () => { setBoForm(blankBlackout()); setBoModalError(''); setShowBoModal(true); };
  const submitBlackout = async (e: FormEvent) => {
    e.preventDefault();
    if (!boForm.date) { setBoModalError('Date is required.'); return; }
    setBoSubmitting(true); setBoModalError('');
    try {
      await api('/api/freelancer/blackouts', {
        method: 'POST',
        body: {
          date: boForm.date,
          end_date: boForm.end_date || null,
          reason: boForm.reason,
          recurrence: boForm.recurrence,
        },
      });
      setShowBoModal(false);
      loadBlackouts();
    } catch (e: any) { setBoModalError(e.message); }
    finally { setBoSubmitting(false); }
  };
  const deleteBlackout = async (id: string) => {
    if (!confirm('Remove this blackout date?')) return;
    try { await api(`/api/freelancer/blackouts/${id}`, { method: 'DELETE' }); loadBlackouts(); }
    catch (e: any) { alert(e.message); }
  };

  // ── Leave create / delete ─────────────────────────────────────
  const openLeave = () => { setLeaveForm(blankLeave()); setLeaveModalError(''); setShowLeaveModal(true); };
  const submitLeave = async (e: FormEvent) => {
    e.preventDefault();
    if (!leaveForm.start_date || !leaveForm.end_date || !leaveForm.reason) {
      setLeaveModalError('Start date, end date and reason are required.'); return;
    }
    setLeaveSubmitting(true); setLeaveModalError('');
    try {
      await api('/api/freelancer/leaves', {
        method: 'POST',
        body: {
          start_date: leaveForm.start_date,
          end_date: leaveForm.end_date,
          reason: leaveForm.reason,
          notes: leaveForm.notes,
        },
      });
      setShowLeaveModal(false);
      loadLeaves();
    } catch (e: any) { setLeaveModalError(e.message); }
    finally { setLeaveSubmitting(false); }
  };
  const deleteLeave = async (id: string) => {
    if (!confirm('Cancel this leave request?')) return;
    try { await api(`/api/freelancer/leaves/${id}`, { method: 'DELETE' }); loadLeaves(); }
    catch (e: any) { alert(e.message); }
  };

  // ── Work history derived ──────────────────────────────────────
  const totalJobs = history.length;
  const completedJobs = history.filter((h) => h.status === 'COMPLETED' || h.status === 'DELIVERED').length;
  const totalValue = history.reduce((s, h) => s + (Number(h.price) || 0), 0);

  return (
    <AppShell>
      <div style={{ padding: 24 }}>
        <div className="toolbar" style={{ marginBottom: 4 }}>
          <div>
            <h1 className="page-title">Freelancer</h1>
            <p className="page-sub">Your earnings, availability and work history</p>
          </div>
          <span className="spacer" />
          {tab === 0 && <button className="btn" style={{ background: 'var(--orange)', color: '#000' }} onClick={openPay}>Request Payment</button>}
          {tab === 1 && <button className="btn" style={{ background: 'var(--orange)', color: '#000' }} onClick={openBo}>+ Add Blackout</button>}
          {tab === 2 && <button className="btn" style={{ background: 'var(--orange)', color: '#000' }} onClick={openLeave}>Request Leave</button>}
        </div>

        <div className="tabs" style={{ margin: '16px 0 24px' }}>
          {TABS.map((t, i) => (
            <button key={t} className={`tab${tab === i ? ' active' : ''}`} onClick={() => setTab(i)}>{t}</button>
          ))}
        </div>

        {/* ── Tab 0: Earnings ─────────────────────────────────── */}
        {tab === 0 && (
          <>
            {earnError && <div className="error" style={{ marginBottom: 12 }}>{earnError}</div>}
            {paySuccess && <div className="success-msg" style={{ marginBottom: 12 }}>{paySuccess}</div>}

            <div className="cards cards-3" style={{ marginBottom: 20 }}>
              <div className="card" style={{ textAlign: 'center' }}>
                <div className="muted text-sm" style={{ marginBottom: 6 }}>Total Earnings</div>
                <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 30, color: 'var(--orange)' }}>{earnLoading ? '…' : tk(earnings.totalEarnings)}</div>
              </div>
              <div className="card" style={{ textAlign: 'center' }}>
                <div className="muted text-sm" style={{ marginBottom: 6 }}>Received</div>
                <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 30, color: 'var(--green)' }}>{earnLoading ? '…' : tk(earnings.receivedAmount)}</div>
              </div>
              <div className="card" style={{ textAlign: 'center' }}>
                <div className="muted text-sm" style={{ marginBottom: 6 }}>Pending</div>
                <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 30, color: 'var(--gold)' }}>{earnLoading ? '…' : tk(earnings.pendingAmount)}</div>
              </div>
            </div>

            <div className="panel">
              <div className="panel-header"><span className="panel-title">Earnings Breakdown</span></div>
              <div className="panel-body">
                {earnLoading ? (
                  [...Array(4)].map((_, i) => <div key={i} className="shimmer" style={{ height: 32, borderRadius: 6, marginBottom: 8 }} />)
                ) : (
                  <>
                    <div className="info-row"><span className="muted">Advance</span><span style={{ fontFamily: 'JetBrains Mono, monospace' }}>{tk(earnings.advance)}</span></div>
                    <div className="info-row"><span className="muted">Due</span><span style={{ fontFamily: 'JetBrains Mono, monospace' }}>{tk(earnings.due)}</span></div>
                    <div className="info-row"><span className="muted">Extra</span><span style={{ fontFamily: 'JetBrains Mono, monospace' }}>{tk(earnings.extra)}</span></div>
                    <div className="info-row"><span className="muted">Payout</span><span style={{ fontFamily: 'JetBrains Mono, monospace', color: 'var(--green)' }}>{tk(earnings.payout)}</span></div>
                    <div className="divider" />
                    <div className="info-row"><span style={{ fontWeight: 700 }}>Total</span><span style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 22, color: 'var(--orange)' }}>{tk(earnings.totalEarnings)}</span></div>
                  </>
                )}
              </div>
            </div>
          </>
        )}

        {/* ── Tab 1: Availability ─────────────────────────────── */}
        {tab === 1 && (
          <>
            <p className="muted text-sm" style={{ marginBottom: 16 }}>Mark dates you&apos;re unavailable so you don&apos;t get double-booked.</p>
            {boError && <div className="error" style={{ marginBottom: 12 }}>{boError}</div>}

            <div className="panel">
              <div className="panel-header">
                <span className="panel-title">Blackout Dates</span>
                <span className="badge gray">{blackouts.length}</span>
              </div>
              <div className="panel-body">
                {boLoading && [...Array(4)].map((_, i) => <div key={i} className="shimmer" style={{ height: 48, borderRadius: 6, marginBottom: 8 }} />)}
                {!boLoading && blackouts.length === 0 && <div className="empty">No blackout dates yet. Add one to block off your calendar.</div>}
                {!boLoading && blackouts.map((b) => (
                  <div key={b.id} className="info-row" style={{ alignItems: 'center' }}>
                    <div>
                      <div style={{ fontWeight: 600 }}>
                        {fmtDate(b.date)}{b.end_date ? ` → ${fmtDate(b.end_date)}` : ''}
                      </div>
                      {b.reason && <div className="muted text-sm" style={{ marginTop: 2 }}>{b.reason}</div>}
                    </div>
                    <span className="spacer" />
                    <span className={`badge ${RECURRENCE_COLORS[b.recurrence] || 'gray'}`} style={{ marginRight: 10 }}>{b.recurrence || 'none'}</span>
                    <button className="btn danger xs" onClick={() => deleteBlackout(b.id)}>Delete</button>
                  </div>
                ))}
              </div>
            </div>
          </>
        )}

        {/* ── Tab 2: Leave ────────────────────────────────────── */}
        {tab === 2 && (
          <>
            {leaveError && <div className="error" style={{ marginBottom: 12 }}>{leaveError}</div>}

            <div className="panel">
              <div className="panel-header">
                <span className="panel-title">Leave Requests</span>
                <span className="badge gray">{leaves.length}</span>
              </div>
              <div className="panel-body">
                {leaveLoading && [...Array(4)].map((_, i) => <div key={i} className="shimmer" style={{ height: 48, borderRadius: 6, marginBottom: 8 }} />)}
                {!leaveLoading && leaves.length === 0 && <div className="empty">No leave requests yet.</div>}
                {!leaveLoading && leaves.map((l) => (
                  <div key={l.id} className="info-row" style={{ alignItems: 'center' }}>
                    <div>
                      <div style={{ fontWeight: 600 }}>{fmtDate(l.start_date)} → {fmtDate(l.end_date)}</div>
                      <div className="muted text-sm" style={{ marginTop: 2 }}>{l.reason}{l.notes ? ` — ${l.notes}` : ''}</div>
                    </div>
                    <span className="spacer" />
                    <span style={{ marginRight: 10 }}>{leaveBadge(l.status)}</span>
                    <button className="btn danger xs" onClick={() => deleteLeave(l.id)}>Cancel</button>
                  </div>
                ))}
              </div>
            </div>
          </>
        )}

        {/* ── Tab 3: Work History ─────────────────────────────── */}
        {tab === 3 && (
          <>
            {histError && <div className="error" style={{ marginBottom: 12 }}>{histError}</div>}

            <div className="cards cards-3" style={{ marginBottom: 20 }}>
              <div className="card" style={{ textAlign: 'center' }}>
                <div className="muted text-sm" style={{ marginBottom: 6 }}>Total Jobs</div>
                <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 30 }}>{histLoading ? '…' : totalJobs}</div>
              </div>
              <div className="card" style={{ textAlign: 'center' }}>
                <div className="muted text-sm" style={{ marginBottom: 6 }}>Completed Jobs</div>
                <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 30, color: 'var(--green)' }}>{histLoading ? '…' : completedJobs}</div>
              </div>
              <div className="card" style={{ textAlign: 'center' }}>
                <div className="muted text-sm" style={{ marginBottom: 6 }}>Total Value</div>
                <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 30, color: 'var(--orange)' }}>{histLoading ? '…' : tk(totalValue)}</div>
              </div>
            </div>

            <div className="panel">
              <div className="panel-header">
                <span className="panel-title">Work History</span>
                <span className="badge gray">{history.length}</span>
              </div>
              <div className="panel-body">
                {histLoading && [...Array(5)].map((_, i) => <div key={i} className="shimmer" style={{ height: 48, borderRadius: 6, marginBottom: 8 }} />)}
                {!histLoading && history.length === 0 && <div className="empty">No work history yet.</div>}
                {!histLoading && history.length > 0 && (
                  <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                    <thead>
                      <tr style={{ borderBottom: '1px solid var(--surface-3)' }}>
                        {['Title', 'Client', 'Date', 'Venue', 'Status', 'Price'].map((h) => (
                          <th key={h} style={{ textAlign: 'left', padding: '8px 10px', fontSize: 11, fontFamily: 'JetBrains Mono, monospace', color: 'var(--film-muted)', textTransform: 'uppercase' }}>{h}</th>
                        ))}
                      </tr>
                    </thead>
                    <tbody>
                      {history.map((h) => (
                        <tr key={h.id} style={{ borderBottom: '1px solid var(--surface-3)' }}>
                          <td style={{ padding: '10px', fontSize: 14, fontWeight: 600 }}>
                            <Link href={`/app/bookings/${h.id}`} style={{ color: 'var(--orange)', textDecoration: 'none' }}>{h.title}</Link>
                          </td>
                          <td style={{ padding: '10px', fontSize: 13 }}>{h.clientName || '—'}</td>
                          <td style={{ padding: '10px', fontSize: 12 }}>{fmtDate(h.date)}</td>
                          <td style={{ padding: '10px', fontSize: 12, color: 'var(--film-muted)' }}>{h.venue || '—'}</td>
                          <td style={{ padding: '10px' }}>{statusBadge(h.status)}</td>
                          <td style={{ padding: '10px', fontFamily: 'Bebas Neue, sans-serif', fontSize: 20 }}>{tk(Number(h.price) || 0)}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                )}
              </div>
            </div>
          </>
        )}

        {/* ── Tab 4: Badges ──────────────────────────────────── */}
        {tab === 4 && (
          <>
            <div className="card" style={{ marginBottom: 20, textAlign: 'center' }}>
              <div className="muted text-sm" style={{ marginBottom: 6 }}>Jobs Completed</div>
              <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 44, color: 'var(--orange)' }}>
                {histLoading ? '…' : completedJobs}
              </div>
              <div className="muted text-sm" style={{ marginTop: 4 }}>
                {(() => {
                  const next = BADGE_TIERS.find((t) => completedJobs < t.threshold);
                  return next ? `${next.threshold - completedJobs} more to unlock "${next.name}"` : 'All badges unlocked! 👑';
                })()}
              </div>
            </div>

            <div className="cards cards-3">
              {BADGE_TIERS.map((t) => {
                const earned = completedJobs >= t.threshold;
                return (
                  <div
                    key={t.name}
                    className="card"
                    style={{ textAlign: 'center', opacity: earned ? 1 : 0.45, border: earned ? '1px solid var(--orange)' : undefined }}
                  >
                    <div style={{ fontSize: 40, marginBottom: 8, filter: earned ? 'none' : 'grayscale(1)' }}>{t.icon}</div>
                    <div style={{ fontWeight: 600, marginBottom: 4 }}>{t.name}</div>
                    <div className="muted text-sm" style={{ marginBottom: 8 }}>{t.desc}</div>
                    <span className={`badge ${earned ? 'green' : 'gray'}`}>{earned ? 'Unlocked' : `${t.threshold}+ jobs`}</span>
                  </div>
                );
              })}
            </div>
          </>
        )}

        {/* ── Tab 5: Multi-owner Dashboard + Check-in ───────────── */}
        {tab === 5 && (
          <>
            {dashError && <div className="error" style={{ marginBottom: 12 }}>{dashError}</div>}

            {/* Conflict warnings */}
            {conflicts.length > 0 && (
              <div className="card" style={{ marginBottom: 16, borderLeft: '3px solid var(--red)' }}>
                <div style={{ fontWeight: 700, color: 'var(--red)', marginBottom: 8 }}>⚠ Schedule Conflicts ({conflicts.length})</div>
                {conflicts.map((c, i) => (
                  <div key={i} className="muted text-sm" style={{ padding: '4px 0' }}>
                    {new Date(c.date).toLocaleDateString()} — “{c.first?.title}” ({c.first?.shift}) ↔ “{c.second?.title}” ({c.second?.shift})
                  </div>
                ))}
              </div>
            )}

            {dashLoading && (
              <div>{[...Array(4)].map((_, i) => <div key={i} className="shimmer" style={{ height: 76, borderRadius: 8, marginBottom: 10 }} />)}</div>
            )}
            {!dashLoading && dashEvents.length === 0 && <div className="empty">No assigned events across your studios yet.</div>}

            {!dashLoading && dashEvents.map((ev) => {
              const ci = checkins[ev.eventId];
              const isToday = ev.date && new Date(ev.date).toDateString() === new Date().toDateString();
              return (
                <div key={ev.assignmentId} className="card" style={{ marginBottom: 10 }}>
                  <div className="row" style={{ gap: 12, alignItems: 'center' }}>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div className="truncate" style={{ fontWeight: 600 }}>{ev.title}</div>
                      <div className="muted text-sm">
                        {ev.date ? new Date(ev.date).toLocaleDateString() : '—'} · {ev.shift || '—'} · {ev.role}
                        {ev.ownerName ? ` · ${ev.ownerName}` : ''}
                      </div>
                      {ev.venue && <div className="muted text-sm truncate">📍 {ev.venue}</div>}
                    </div>
                    {ci
                      ? <span className={`badge ${ci.status === 'late' ? 'gold' : 'green'}`}>{ci.status === 'late' ? 'Late' : 'Checked in'}</span>
                      : (
                        <button
                          className="btn sm"
                          style={{ background: isToday ? 'var(--orange)' : 'var(--surface-2)', color: isToday ? '#000' : 'var(--film-muted)' }}
                          disabled={checkingIn === ev.eventId}
                          onClick={() => doCheckin(ev.eventId)}
                        >{checkingIn === ev.eventId ? '…' : "I'm Here"}</button>
                      )}
                  </div>
                </div>
              );
            })}
          </>
        )}
      </div>

      {/* ── Request Payment Modal ──────────────────────────────── */}
      {showPayModal && (
        <div className="modal-backdrop" onClick={() => setShowPayModal(false)}>
          <div className="modal" onClick={(e) => e.stopPropagation()}>
            <div className="row" style={{ marginBottom: 16 }}>
              <span style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 20 }}>Request Payment</span>
              <span className="spacer" />
              <button className="btn ghost xs" onClick={() => setShowPayModal(false)}>×</button>
            </div>
            {payError && <div className="error" style={{ marginBottom: 10 }}>{payError}</div>}
            <form onSubmit={submitPayment}>
              <div className="form-grid">
                <div className="field">
                  <label>Amount (৳) *</label>
                  <input type="number" className="field" required value={payForm.amount} onChange={(e) => setPayForm({ ...payForm, amount: e.target.value })} placeholder="0" />
                </div>
                <div className="field">
                  <label>Method</label>
                  <select className="field" value={payForm.method} onChange={(e) => setPayForm({ ...payForm, method: e.target.value })}>
                    {METHODS.map((m) => <option key={m} value={m}>{m}</option>)}
                  </select>
                </div>
                <div className="field" style={{ gridColumn: '1/-1' }}>
                  <label>Booking (optional)</label>
                  <select className="field" value={payForm.event_id} onChange={(e) => setPayForm({ ...payForm, event_id: e.target.value })}>
                    <option value="">Select booking...</option>
                    {bookings.map((b) => <option key={b.id} value={b.id}>{b.title}</option>)}
                  </select>
                </div>
                <div className="field" style={{ gridColumn: '1/-1' }}>
                  <label>Note</label>
                  <textarea className="field" rows={2} value={payForm.note} onChange={(e) => setPayForm({ ...payForm, note: e.target.value })} placeholder="Optional note..." />
                </div>
              </div>
              <div className="row" style={{ gap: 10, marginTop: 16, justifyContent: 'flex-end' }}>
                <button type="button" className="btn ghost" onClick={() => setShowPayModal(false)}>Cancel</button>
                <button type="submit" className="btn" style={{ background: 'var(--orange)', color: '#000' }} disabled={paySubmitting}>{paySubmitting ? 'Submitting...' : 'Request Payment'}</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ── Add Blackout Modal ─────────────────────────────────── */}
      {showBoModal && (
        <div className="modal-backdrop" onClick={() => setShowBoModal(false)}>
          <div className="modal" onClick={(e) => e.stopPropagation()}>
            <div className="row" style={{ marginBottom: 16 }}>
              <span style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 20 }}>Add Blackout</span>
              <span className="spacer" />
              <button className="btn ghost xs" onClick={() => setShowBoModal(false)}>×</button>
            </div>
            {boModalError && <div className="error" style={{ marginBottom: 10 }}>{boModalError}</div>}
            <form onSubmit={submitBlackout}>
              <div className="form-grid">
                <div className="field">
                  <label>Date *</label>
                  <input type="date" className="field" required value={boForm.date} onChange={(e) => setBoForm({ ...boForm, date: e.target.value })} />
                </div>
                <div className="field">
                  <label>End Date (for a range)</label>
                  <input type="date" className="field" value={boForm.end_date} onChange={(e) => setBoForm({ ...boForm, end_date: e.target.value })} />
                </div>
                <div className="field" style={{ gridColumn: '1/-1' }}>
                  <label>Reason</label>
                  <input className="field" value={boForm.reason} onChange={(e) => setBoForm({ ...boForm, reason: e.target.value })} placeholder="e.g. Personal, Travel..." />
                </div>
                <div className="field" style={{ gridColumn: '1/-1' }}>
                  <label>Recurrence</label>
                  <select className="field" value={boForm.recurrence} onChange={(e) => setBoForm({ ...boForm, recurrence: e.target.value })}>
                    {RECURRENCES.map((r) => <option key={r} value={r}>{r}</option>)}
                  </select>
                </div>
              </div>
              <div className="row" style={{ gap: 10, marginTop: 16, justifyContent: 'flex-end' }}>
                <button type="button" className="btn ghost" onClick={() => setShowBoModal(false)}>Cancel</button>
                <button type="submit" className="btn" style={{ background: 'var(--orange)', color: '#000' }} disabled={boSubmitting}>{boSubmitting ? 'Saving...' : 'Add Blackout'}</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ── Request Leave Modal ────────────────────────────────── */}
      {showLeaveModal && (
        <div className="modal-backdrop" onClick={() => setShowLeaveModal(false)}>
          <div className="modal" onClick={(e) => e.stopPropagation()}>
            <div className="row" style={{ marginBottom: 16 }}>
              <span style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 20 }}>Request Leave</span>
              <span className="spacer" />
              <button className="btn ghost xs" onClick={() => setShowLeaveModal(false)}>×</button>
            </div>
            {leaveModalError && <div className="error" style={{ marginBottom: 10 }}>{leaveModalError}</div>}
            <form onSubmit={submitLeave}>
              <div className="form-grid">
                <div className="field">
                  <label>Start Date *</label>
                  <input type="date" className="field" required value={leaveForm.start_date} onChange={(e) => setLeaveForm({ ...leaveForm, start_date: e.target.value })} />
                </div>
                <div className="field">
                  <label>End Date *</label>
                  <input type="date" className="field" required value={leaveForm.end_date} onChange={(e) => setLeaveForm({ ...leaveForm, end_date: e.target.value })} />
                </div>
                <div className="field" style={{ gridColumn: '1/-1' }}>
                  <label>Reason *</label>
                  <input className="field" required value={leaveForm.reason} onChange={(e) => setLeaveForm({ ...leaveForm, reason: e.target.value })} placeholder="e.g. Vacation, Sick leave..." />
                </div>
                <div className="field" style={{ gridColumn: '1/-1' }}>
                  <label>Notes</label>
                  <textarea className="field" rows={2} value={leaveForm.notes} onChange={(e) => setLeaveForm({ ...leaveForm, notes: e.target.value })} placeholder="Optional notes..." />
                </div>
              </div>
              <div className="row" style={{ gap: 10, marginTop: 16, justifyContent: 'flex-end' }}>
                <button type="button" className="btn ghost" onClick={() => setShowLeaveModal(false)}>Cancel</button>
                <button type="submit" className="btn" style={{ background: 'var(--orange)', color: '#000' }} disabled={leaveSubmitting}>{leaveSubmitting ? 'Submitting...' : 'Request Leave'}</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </AppShell>
  );
}
