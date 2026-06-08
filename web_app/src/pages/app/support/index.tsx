import { useEffect, useState, FormEvent } from 'react';
import AppShell from '@/components/AppShell';
import { api } from '@/lib/api';

const fmtDate = (d: string) =>
  d ? new Date(d).toLocaleDateString('en-BD', { day: 'numeric', month: 'short', year: 'numeric' }) : '—';

const STATUS_COLORS: Record<string, string> = { OPEN: 'orange', IN_PROGRESS: 'teal', RESOLVED: 'green', CLOSED: 'gray' };

function TicketStatusBadge({ s }: { s: string }) {
  return <span className={`badge ${STATUS_COLORS[s] || 'gray'}`}>{s.replace(/_/g, ' ')}</span>;
}

export default function SupportPage() {
  const [tab, setTab] = useState<'tickets' | 'faq'>('tickets');
  const [tickets, setTickets] = useState<any[]>([]);
  const [faqs, setFaqs] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [form, setForm] = useState({ subject: '', body: '' });
  const [submitting, setSubmitting] = useState(false);
  const [modalError, setModalError] = useState('');
  const [expandedTicket, setExpandedTicket] = useState<string | null>(null);
  const [expandedFaq, setExpandedFaq] = useState<string | null>(null);

  const loadTickets = async () => {
    setLoading(true);
    try {
      const res = await api<any>('/api/support');
      setTickets(Array.isArray(res) ? res : res?.data ?? res?.tickets ?? []);
    } catch (e: any) { setError(e.message); }
    finally { setLoading(false); }
  };

  const loadFaqs = async () => {
    setLoading(true);
    try {
      const res = await api<any>('/api/faqs').catch(() => []);
      setFaqs(Array.isArray(res) ? res : res?.data ?? []);
    } catch { setFaqs([]); }
    finally { setLoading(false); }
  };

  useEffect(() => {
    if (tab === 'tickets') loadTickets();
    else loadFaqs();
  }, [tab]);

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    if (!form.subject.trim() || !form.body.trim()) { setModalError('Subject and message are required.'); return; }
    setSubmitting(true); setModalError('');
    try {
      await api('/api/support', { method: 'POST', body: form });
      setShowModal(false);
      setForm({ subject: '', body: '' });
      loadTickets();
    } catch (e: any) { setModalError(e.message); }
    finally { setSubmitting(false); }
  };

  return (
    <AppShell>
      <div style={{ padding: 24 }}>
        <div className="toolbar" style={{ marginBottom: 20 }}>
          <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 24 }}>Support</div>
          <span className="spacer" />
          {tab === 'tickets' && (
            <button className="btn" style={{ background: 'var(--orange)', color: '#000' }} onClick={() => { setForm({ subject: '', body: '' }); setModalError(''); setShowModal(true); }}>+ New Ticket</button>
          )}
        </div>

        <div className="tabs" style={{ marginBottom: 20 }}>
          <button className={`tab${tab === 'tickets' ? ' active' : ''}`} onClick={() => setTab('tickets')}>My Tickets</button>
          <button className={`tab${tab === 'faq' ? ' active' : ''}`} onClick={() => setTab('faq')}>FAQ</button>
        </div>

        {error && <div className="error" style={{ marginBottom: 12 }}>{error}</div>}

        {/* Tickets Tab */}
        {tab === 'tickets' && (
          <div className="panel">
            <div className="panel-header">
              <span className="panel-title">My Support Tickets</span>
              <span className="badge gray">{tickets.length}</span>
            </div>
            <div className="panel-body">
              {loading && [...Array(3)].map((_, i) => <div key={i} className="shimmer" style={{ height: 60, borderRadius: 6, marginBottom: 8 }} />)}
              {!loading && tickets.length === 0 && <div className="empty">No support tickets yet.</div>}
              {!loading && tickets.map((t) => (
                <div key={t.id} style={{ marginBottom: 8 }}>
                  <div
                    style={{ padding: '14px 16px', background: 'var(--surface-3)', cursor: 'pointer', borderBottom: expandedTicket === t.id ? 'none' : undefined, borderRadius: expandedTicket === t.id ? '6px 6px 0 0' : 6 }}
                    onClick={() => setExpandedTicket(expandedTicket === t.id ? null : t.id)}
                  >
                    <div className="row" style={{ justifyContent: 'space-between', marginBottom: 4 }}>
                      <div style={{ fontWeight: 600, fontSize: 14 }}>{t.subject}</div>
                      <TicketStatusBadge s={t.status || 'OPEN'} />
                    </div>
                    <div className="muted text-sm">{fmtDate(t.createdAt || t.created_at)} · Click to expand</div>
                  </div>
                  {expandedTicket === t.id && (
                    <div style={{ padding: '14px 16px', background: 'rgba(255,255,255,0.03)', borderRadius: '0 0 6px 6px', border: '1px solid var(--surface-3)', borderTop: 'none' }}>
                      <div className="muted text-sm" style={{ marginBottom: 8, textTransform: 'uppercase', fontFamily: 'JetBrains Mono, monospace', letterSpacing: '0.06em' }}>Your Message</div>
                      <div style={{ fontSize: 14, marginBottom: 16, lineHeight: 1.6 }}>{t.body || t.message}</div>
                      {(t.adminReply || t.reply) && (
                        <div style={{ background: 'var(--surface-3)', borderRadius: 6, padding: '12px 14px', borderLeft: '3px solid var(--orange)' }}>
                          <div className="muted text-sm" style={{ marginBottom: 6, textTransform: 'uppercase', fontFamily: 'JetBrains Mono, monospace', letterSpacing: '0.06em' }}>Admin Reply</div>
                          <div style={{ fontSize: 14, lineHeight: 1.6 }}>{t.adminReply || t.reply}</div>
                          {t.repliedAt && <div className="muted text-sm" style={{ marginTop: 6 }}>{fmtDate(t.repliedAt)}</div>}
                        </div>
                      )}
                      {!t.adminReply && !t.reply && (
                        <div className="muted text-sm" style={{ fontStyle: 'italic' }}>Awaiting reply from support team...</div>
                      )}
                    </div>
                  )}
                </div>
              ))}
            </div>
          </div>
        )}

        {/* FAQ Tab */}
        {tab === 'faq' && (
          <div className="panel">
            <div className="panel-header"><span className="panel-title">Frequently Asked Questions</span></div>
            <div className="panel-body">
              {loading && [...Array(4)].map((_, i) => <div key={i} className="shimmer" style={{ height: 50, borderRadius: 6, marginBottom: 8 }} />)}
              {!loading && faqs.length === 0 && <div className="empty">No FAQs available.</div>}
              {!loading && faqs.map((f) => (
                <div key={f.id} style={{ marginBottom: 6 }}>
                  <div
                    style={{ padding: '14px 16px', background: 'var(--surface-3)', cursor: 'pointer', borderRadius: expandedFaq === f.id ? '6px 6px 0 0' : 6, fontWeight: 600, fontSize: 14 }}
                    onClick={() => setExpandedFaq(expandedFaq === f.id ? null : f.id)}
                  >
                    <div className="row" style={{ justifyContent: 'space-between' }}>
                      <span>{f.question}</span>
                      <span className="muted" style={{ fontSize: 18, transition: 'transform 0.2s', transform: expandedFaq === f.id ? 'rotate(180deg)' : 'none' }}>⌄</span>
                    </div>
                  </div>
                  {expandedFaq === f.id && (
                    <div style={{ padding: '14px 16px', background: 'rgba(255,255,255,0.02)', borderRadius: '0 0 6px 6px', border: '1px solid var(--surface-3)', borderTop: 'none', fontSize: 14, lineHeight: 1.6, color: 'var(--film-muted)' }}>
                      {f.answer}
                    </div>
                  )}
                </div>
              ))}
            </div>
          </div>
        )}
      </div>

      {/* New Ticket Modal */}
      {showModal && (
        <div className="modal-backdrop" onClick={() => setShowModal(false)}>
          <div className="modal" onClick={(e) => e.stopPropagation()}>
            <div className="row" style={{ marginBottom: 16 }}>
              <span style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 20 }}>New Support Ticket</span>
              <span className="spacer" />
              <button className="btn ghost xs" onClick={() => setShowModal(false)}>×</button>
            </div>
            {modalError && <div className="error" style={{ marginBottom: 10 }}>{modalError}</div>}
            <form onSubmit={handleSubmit}>
              <div className="field" style={{ marginBottom: 12 }}>
                <label>Subject *</label>
                <input className="field" required value={form.subject} onChange={(e) => setForm({ ...form, subject: e.target.value })} placeholder="Brief description of your issue" />
              </div>
              <div className="field" style={{ marginBottom: 16 }}>
                <label>Message *</label>
                <textarea className="field" rows={5} required value={form.body} onChange={(e) => setForm({ ...form, body: e.target.value })} placeholder="Describe your issue in detail..." />
              </div>
              <div className="row" style={{ gap: 10, justifyContent: 'flex-end' }}>
                <button type="button" className="btn ghost" onClick={() => setShowModal(false)}>Cancel</button>
                <button type="submit" className="btn" style={{ background: 'var(--orange)', color: '#000' }} disabled={submitting}>{submitting ? 'Submitting...' : 'Submit Ticket'}</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </AppShell>
  );
}
