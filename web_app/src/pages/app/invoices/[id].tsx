import { useEffect, useState } from 'react';
import { useRouter } from 'next/router';
import Link from 'next/link';
import AppShell from '@/components/AppShell';
import { api } from '@/lib/api';
import { tk } from '@/lib/format';

const fmtDate = (d: string) =>
  d ? new Date(d).toLocaleDateString('en-BD', { day: 'numeric', month: 'long', year: 'numeric' }) : '—';

function statusBadge(s: string) {
  const map: Record<string, string> = { DRAFT: 'gray', SENT: 'teal', PAID: 'green', OVERDUE: 'red' };
  return <span className={`badge ${map[s] || 'gray'}`}>{s}</span>;
}

export default function InvoiceDetailPage() {
  const router = useRouter();
  const { id } = router.query as { id: string };

  const [invoice, setInvoice] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [updating, setUpdating] = useState(false);

  const load = async () => {
    if (!id) return;
    setLoading(true);
    try {
      const res = await api<any>(`/api/invoices/${id}`);
      setInvoice(res?.data ?? res);
    } catch (e: any) { setError(e.message); }
    finally { setLoading(false); }
  };

  useEffect(() => { load(); }, [id]);

  const updateStatus = async (status: string) => {
    setUpdating(true);
    try {
      await api(`/api/invoices/${id}`, { method: 'PATCH', body: { status } });
      load();
    } catch (e: any) { alert(e.message); }
    finally { setUpdating(false); }
  };

  if (!id) return null;

  return (
    <AppShell>
      <div style={{ padding: 24 }}>
        <div className="toolbar" style={{ marginBottom: 20 }}>
          <Link href="/app/invoices" className="muted text-sm" style={{ textDecoration: 'none' }}>← Invoices</Link>
          <span className="spacer" />
          <div className="row" style={{ gap: 8 }}>
            {invoice && invoice.status !== 'SENT' && (
              <button className="btn ghost sm" onClick={() => updateStatus('SENT')} disabled={updating}>Mark as Sent</button>
            )}
            {invoice && invoice.status !== 'PAID' && (
              <button className="btn sm" style={{ background: 'var(--green)', color: '#000' }} onClick={() => updateStatus('PAID')} disabled={updating}>Mark as Paid</button>
            )}
            <button className="btn ghost sm" onClick={() => window.print()}>🖨 Print</button>
          </div>
        </div>

        {loading && <div className="shimmer" style={{ height: 500, borderRadius: 8 }} />}
        {error && <div className="error">{error}</div>}

        {!loading && invoice && (
          <div className="card" style={{ maxWidth: 760, margin: '0 auto', padding: 40 }} id="invoice-print">
            {/* Invoice Header */}
            <div className="row" style={{ justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 32 }}>
              <div>
                <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 32, color: 'var(--orange)', letterSpacing: '0.05em' }}>ClickerPro</div>
                <div className="muted text-sm">Professional Photography & Videography</div>
              </div>
              <div style={{ textAlign: 'right' }}>
                <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 22 }}>INVOICE</div>
                <div className="muted text-sm" style={{ fontFamily: 'JetBrains Mono, monospace' }}>
                  #{invoice.invoiceNumber || invoice.id?.slice(0, 8).toUpperCase()}
                </div>
                <div style={{ marginTop: 8 }}>{statusBadge(invoice.status)}</div>
              </div>
            </div>

            {/* Date */}
            <div className="row" style={{ justifyContent: 'space-between', marginBottom: 24 }}>
              <div>
                <div className="muted text-sm">Invoice Date</div>
                <div style={{ fontSize: 14, fontWeight: 600 }}>{fmtDate(invoice.createdAt || invoice.created_at)}</div>
              </div>
              {invoice.dueDate && (
                <div style={{ textAlign: 'right' }}>
                  <div className="muted text-sm">Due Date</div>
                  <div style={{ fontSize: 14, fontWeight: 600 }}>{fmtDate(invoice.dueDate)}</div>
                </div>
              )}
            </div>

            {/* Client & Booking Info */}
            <div className="cards cards-2" style={{ marginBottom: 28 }}>
              <div style={{ padding: '14px 16px', background: 'var(--surface-3)', borderRadius: 6 }}>
                <div style={{ fontFamily: 'JetBrains Mono, monospace', fontSize: 10, color: 'var(--film-muted)', textTransform: 'uppercase', marginBottom: 8 }}>Bill To</div>
                <div style={{ fontWeight: 700, fontSize: 16 }}>{invoice.booking?.clientName || invoice.client?.name || '—'}</div>
                <div className="muted text-sm">{invoice.booking?.clientPhone || invoice.client?.phone || ''}</div>
                <div className="muted text-sm">{invoice.client?.email || ''}</div>
              </div>
              <div style={{ padding: '14px 16px', background: 'var(--surface-3)', borderRadius: 6 }}>
                <div style={{ fontFamily: 'JetBrains Mono, monospace', fontSize: 10, color: 'var(--film-muted)', textTransform: 'uppercase', marginBottom: 8 }}>Event Details</div>
                <div style={{ fontWeight: 700, fontSize: 16 }}>{invoice.booking?.title || invoice.booking?.eventType || 'Event'}</div>
                <div className="muted text-sm">{fmtDate(invoice.booking?.date || invoice.booking?.event_date)}</div>
                <div className="muted text-sm">{invoice.booking?.venue || ''}</div>
              </div>
            </div>

            {/* Line Items */}
            <div style={{ marginBottom: 24 }}>
              <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                <thead>
                  <tr style={{ borderBottom: '2px solid var(--surface-3)' }}>
                    <th style={{ textAlign: 'left', padding: '8px 0', fontSize: 11, fontFamily: 'JetBrains Mono, monospace', color: 'var(--film-muted)', textTransform: 'uppercase' }}>Description</th>
                    <th style={{ textAlign: 'right', padding: '8px 0', fontSize: 11, fontFamily: 'JetBrains Mono, monospace', color: 'var(--film-muted)', textTransform: 'uppercase' }}>Amount</th>
                  </tr>
                </thead>
                <tbody>
                  <tr style={{ borderBottom: '1px solid var(--surface-3)' }}>
                    <td style={{ padding: '12px 0', fontSize: 14 }}>Photography / Videography Services</td>
                    <td style={{ padding: '12px 0', textAlign: 'right', fontSize: 14 }}>{tk(Number(invoice.subtotal) || 0)}</td>
                  </tr>
                  {invoice.taxRate > 0 && (
                    <tr style={{ borderBottom: '1px solid var(--surface-3)' }}>
                      <td style={{ padding: '12px 0', fontSize: 14 }}>Tax ({invoice.taxRate}%)</td>
                      <td style={{ padding: '12px 0', textAlign: 'right', fontSize: 14 }}>{tk(Number(invoice.tax) || 0)}</td>
                    </tr>
                  )}
                </tbody>
                <tfoot>
                  <tr>
                    <td style={{ padding: '16px 0', fontWeight: 700, fontSize: 16 }}>Total</td>
                    <td style={{ padding: '16px 0', textAlign: 'right', fontFamily: 'Bebas Neue, sans-serif', fontSize: 28, color: 'var(--orange)' }}>{tk(Number(invoice.total) || 0)}</td>
                  </tr>
                </tfoot>
              </table>
            </div>

            {/* Notes */}
            {invoice.notes && (
              <div style={{ padding: '14px 16px', background: 'var(--surface-3)', borderRadius: 6, marginBottom: 20 }}>
                <div className="muted text-sm" style={{ marginBottom: 6 }}>Notes</div>
                <div style={{ fontSize: 14 }}>{invoice.notes}</div>
              </div>
            )}

            {/* Footer */}
            <div className="divider" />
            <div className="muted text-sm" style={{ textAlign: 'center', marginTop: 16 }}>
              Thank you for your business! · ClickerPro · eventfile.nhh@gmail.com
            </div>
          </div>
        )}
      </div>

      <style>{`
        @media print {
          .app-sidebar, .app-shell > *:first-child, .toolbar, nav { display: none !important; }
          .app-main { margin: 0 !important; padding: 0 !important; }
          #invoice-print { box-shadow: none !important; border: none !important; }
        }
      `}</style>
    </AppShell>
  );
}
