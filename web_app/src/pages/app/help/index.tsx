import { useEffect, useState } from 'react';
import Link from 'next/link';
import AppShell from '@/components/AppShell';
import { api } from '@/lib/api';

export default function HelpPage() {
  const [tab, setTab] = useState<'faq' | 'contact'>('faq');
  const [faqs, setFaqs] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [expanded, setExpanded] = useState<string | null>(null);

  useEffect(() => {
    if (tab !== 'faq') return;
    let cancelled = false;
    (async () => {
      setLoading(true);
      setError('');
      try {
        const res = await api<any>('/api/faqs');
        const list = Array.isArray(res) ? res : res?.data ?? [];
        if (!cancelled) setFaqs(list);
      } catch (e: any) {
        if (!cancelled) setError(e.message);
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [tab]);

  return (
    <AppShell>
      <div style={{ padding: 24 }}>
        <h1 className="page-title">Help Center</h1>
        <p className="page-sub">Find answers and get support</p>

        <div className="tabs" style={{ marginBottom: 20 }}>
          <button className={`tab${tab === 'faq' ? ' active' : ''}`} onClick={() => setTab('faq')}>FAQ</button>
          <button className={`tab${tab === 'contact' ? ' active' : ''}`} onClick={() => setTab('contact')}>Contact</button>
        </div>

        {/* FAQ Tab */}
        {tab === 'faq' && (
          <div className="panel">
            <div className="panel-header">
              <span className="panel-title">Frequently Asked Questions</span>
            </div>
            <div className="panel-body">
              {error && <div className="error" style={{ marginBottom: 12 }}>{error}</div>}

              {loading &&
                [...Array(4)].map((_, i) => (
                  <div key={i} className="shimmer" style={{ height: 50, borderRadius: 6, marginBottom: 8 }} />
                ))}

              {!loading && !error && faqs.length === 0 && (
                <div className="empty">No FAQs available.</div>
              )}

              {!loading &&
                !error &&
                faqs.map((f) => (
                  <div key={f.id} style={{ marginBottom: 6 }}>
                    <div
                      style={{
                        padding: '14px 16px',
                        background: 'var(--surface-3)',
                        cursor: 'pointer',
                        borderRadius: expanded === f.id ? '6px 6px 0 0' : 6,
                        fontWeight: 600,
                        fontSize: 14,
                      }}
                      onClick={() => setExpanded(expanded === f.id ? null : f.id)}
                    >
                      <div className="row" style={{ justifyContent: 'space-between' }}>
                        <span>{f.question}</span>
                        <span
                          className="muted"
                          style={{
                            fontSize: 18,
                            transition: 'transform 0.2s',
                            transform: expanded === f.id ? 'rotate(180deg)' : 'none',
                          }}
                        >
                          ⌄
                        </span>
                      </div>
                    </div>
                    {expanded === f.id && (
                      <div
                        style={{
                          padding: '14px 16px',
                          background: 'rgba(255,255,255,0.02)',
                          borderRadius: '0 0 6px 6px',
                          border: '1px solid var(--surface-3)',
                          borderTop: 'none',
                          fontSize: 14,
                          lineHeight: 1.6,
                          color: 'var(--film-muted)',
                        }}
                      >
                        {f.answer}
                      </div>
                    )}
                  </div>
                ))}
            </div>
          </div>
        )}

        {/* Contact Tab */}
        {tab === 'contact' && (
          <div className="cards-2" style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 16 }}>
            <div className="card">
              <div style={{ fontWeight: 700, fontSize: 16, marginBottom: 8 }}>Email Support</div>
              <div style={{ fontSize: 14, lineHeight: 1.6 }}>
                Reach us at <strong>support@clickerpro.app</strong>, we reply within 24 hours.
              </div>
            </div>

            <div className="card">
              <div style={{ fontWeight: 700, fontSize: 16, marginBottom: 8 }}>In-App Support</div>
              <div style={{ fontSize: 14, lineHeight: 1.6, marginBottom: 12 }}>
                Have an account-specific issue? Open a ticket and track its progress.
              </div>
              <Link href="/app/support" className="btn" style={{ background: 'var(--orange)', color: '#000' }}>
                Open a Support Ticket
              </Link>
            </div>

            <div className="card">
              <div style={{ fontWeight: 700, fontSize: 16, marginBottom: 8 }}>Documentation</div>
              <div style={{ fontSize: 14, lineHeight: 1.6, marginBottom: 12 }}>
                Browse guides and tutorials.
              </div>
              <a href="#" className="btn ghost">View Docs</a>
            </div>

            <div className="card">
              <div style={{ fontWeight: 700, fontSize: 16, marginBottom: 8 }}>Community</div>
              <div style={{ fontSize: 14, lineHeight: 1.6, marginBottom: 12 }}>
                Join our photographer community.
              </div>
              <a href="#" className="btn ghost">Join Community</a>
            </div>
          </div>
        )}
      </div>
    </AppShell>
  );
}
