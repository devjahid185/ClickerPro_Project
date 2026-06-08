import { useEffect, useState, FormEvent } from 'react';
import { useRouter } from 'next/router';

const EVENT_TYPES = ['Wedding', 'Holud', 'Reception', 'Corporate', 'Birthday', 'Engagement', 'Aqiqah', 'Portrait', 'Other'];

const blank = () => ({
  clientName: '', clientPhone: '', eventType: 'Wedding', date: '', shift: 'DAY',
  venue: '', packageId: '', notes: '',
});

export default function PublicBookingPage() {
  const router = useRouter();
  const { token } = router.query as { token: string };

  const [studioInfo, setStudioInfo] = useState<any>(null);
  const [packages, setPackages] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [form, setForm] = useState<any>(blank());
  const [submitting, setSubmitting] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const [submitError, setSubmitError] = useState('');
  const [selectedPkg, setSelectedPkg] = useState<string | null>(null);

  useEffect(() => {
    if (!token) return;
    fetch(`/api/public-booking/${token}`)
      .then((r) => r.json())
      .then((data) => {
        if (data.error) { setError(data.error); return; }
        setStudioInfo(data.studio || data.owner || data);
        setPackages(data.packages || []);
      })
      .catch(() => setError('Failed to load booking page.'))
      .finally(() => setLoading(false));
  }, [token]);

  const tk = (n: number) => '৳' + Number(n).toLocaleString('en-BD');

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    if (!form.clientName || !form.clientPhone || !form.date) {
      setSubmitError('Name, phone and date are required.');
      return;
    }
    setSubmitting(true); setSubmitError('');
    try {
      const res = await fetch(`/api/public-booking/${token}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ ...form, packageId: selectedPkg }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.message || 'Submission failed');
      setSubmitted(true);
    } catch (e: any) { setSubmitError(e.message); }
    finally { setSubmitting(false); }
  };

  if (!token) return null;

  return (
    <div style={{ minHeight: '100vh', background: '#000', color: '#fff', fontFamily: 'DM Sans, sans-serif' }}>
      <style>{`
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { background: #000; color: #fff; }
        .pub-header { background: #0d0300; padding: 20px 24px; borderBottom: 1px solid rgba(255,98,0,0.2); display: flex; align-items: center; gap: 16px; }
        .pub-container { max-width: 800px; margin: 0 auto; padding: 32px 24px; }
        .pub-field { display: flex; flex-direction: column; gap: 6px; margin-bottom: 16px; }
        .pub-field label { font-family: 'JetBrains Mono', monospace; font-size: 11px; text-transform: uppercase; letter-spacing: 0.08em; color: rgba(255,255,255,0.5); }
        .pub-input { background: #0d0300; border: 1px solid rgba(255,255,255,0.12); border-radius: 6px; padding: 10px 14px; color: #fff; font-size: 14px; font-family: DM Sans, sans-serif; outline: none; width: 100%; }
        .pub-input:focus { border-color: #FF6200; }
        .pub-select { background: #0d0300; border: 1px solid rgba(255,255,255,0.12); border-radius: 6px; padding: 10px 14px; color: #fff; font-size: 14px; font-family: DM Sans, sans-serif; outline: none; width: 100%; }
        .pub-btn { background: #FF6200; color: #000; border: none; border-radius: 6px; padding: 12px 24px; font-size: 15px; font-weight: 700; cursor: pointer; font-family: DM Sans, sans-serif; }
        .pub-btn:disabled { opacity: 0.6; cursor: not-allowed; }
        .pub-card { background: #0d0300; border: 1px solid rgba(255,255,255,0.08); border-radius: 10px; padding: 20px; margin-bottom: 12px; cursor: pointer; transition: border-color 0.15s; }
        .pub-card.selected { border-color: #FF6200; background: rgba(255,98,0,0.06); }
        .pub-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; }
        @media (max-width: 600px) { .pub-grid { grid-template-columns: 1fr; } }
        .pub-error { background: rgba(239,68,68,0.1); border: 1px solid #ef4444; border-radius: 6px; padding: 12px 16px; color: #ef4444; margin-bottom: 16px; font-size: 14px; }
        .pub-success { background: rgba(34,197,94,0.1); border: 1px solid #22c55e; border-radius: 6px; padding: 24px; color: #22c55e; text-align: center; border-radius: 12px; }
        .pub-pill { padding: 6px 16px; border-radius: 20px; border: 1px solid rgba(255,255,255,0.15); cursor: pointer; font-size: 13px; background: transparent; color: #fff; }
        .pub-pill.active { background: #FF6200; border-color: #FF6200; color: #000; }
      `}</style>

      {/* Header */}
      <div className="pub-header">
        <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 28, color: '#FF6200', letterSpacing: '0.05em' }}>ClickerPro</div>
        {studioInfo?.businessName && (
          <>
            <div style={{ width: 1, height: 28, background: 'rgba(255,255,255,0.15)' }} />
            <div style={{ fontSize: 15, fontWeight: 600 }}>{studioInfo.businessName}</div>
          </>
        )}
      </div>

      <div className="pub-container">
        {loading && (
          <div style={{ textAlign: 'center', padding: 60, color: 'rgba(255,255,255,0.4)' }}>Loading...</div>
        )}

        {error && (
          <div className="pub-error" style={{ marginTop: 20 }}>
            <div style={{ fontWeight: 700, marginBottom: 4 }}>Page Not Found</div>
            <div>{error}</div>
          </div>
        )}

        {!loading && !error && submitted && (
          <div className="pub-success" style={{ marginTop: 40 }}>
            <div style={{ fontSize: 48, marginBottom: 16 }}>✓</div>
            <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 28, marginBottom: 12 }}>Booking Request Submitted!</div>
            <div style={{ fontSize: 16, color: 'rgba(255,255,255,0.7)' }}>
              Your booking request has been submitted! The studio will confirm soon.
            </div>
          </div>
        )}

        {!loading && !error && !submitted && (
          <>
            <div style={{ marginBottom: 32 }}>
              <h1 style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 36, color: '#FF6200', marginBottom: 8 }}>Book Your Session</h1>
              <p style={{ color: 'rgba(255,255,255,0.6)', fontSize: 15 }}>Fill out the form below and we&apos;ll get back to you shortly to confirm your booking.</p>
            </div>

            {/* Packages */}
            {packages.length > 0 && (
              <div style={{ marginBottom: 32 }}>
                <div style={{ fontFamily: 'JetBrains Mono, monospace', fontSize: 11, textTransform: 'uppercase', letterSpacing: '0.08em', color: 'rgba(255,255,255,0.4)', marginBottom: 14 }}>Select a Package (Optional)</div>
                <div className="pub-grid">
                  {packages.map((p) => {
                    const net = (Number(p.price) || 0) - (Number(p.discount) || 0);
                    return (
                      <div
                        key={p.id}
                        className={`pub-card${selectedPkg === p.id ? ' selected' : ''}`}
                        onClick={() => setSelectedPkg(selectedPkg === p.id ? null : p.id)}
                      >
                        <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 20, marginBottom: 4 }}>{p.name}</div>
                        <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 26, color: '#FF6200', marginBottom: 8 }}>{tk(net)}</div>
                        {p.delivery && <div style={{ fontSize: 12, color: 'rgba(255,255,255,0.5)' }}>Delivery: {p.delivery}</div>}
                        {p.trailers > 0 && <div style={{ fontSize: 12, color: 'rgba(255,255,255,0.5)' }}>Trailers: {p.trailers}</div>}
                        {p.printsQty > 0 && <div style={{ fontSize: 12, color: 'rgba(255,255,255,0.5)' }}>Prints: {p.printsQty}× {p.printSize}</div>}
                        {selectedPkg === p.id && (
                          <div style={{ marginTop: 8, color: '#FF6200', fontSize: 12, fontWeight: 700 }}>✓ Selected</div>
                        )}
                      </div>
                    );
                  })}
                </div>
              </div>
            )}

            {/* Booking Form */}
            <form onSubmit={handleSubmit}>
              {submitError && <div className="pub-error">{submitError}</div>}

              <div className="pub-grid">
                <div className="pub-field">
                  <label>Your Name *</label>
                  <input className="pub-input" required value={form.clientName} onChange={(e) => setForm({ ...form, clientName: e.target.value })} placeholder="Full name" />
                </div>
                <div className="pub-field">
                  <label>Phone Number *</label>
                  <input className="pub-input" required value={form.clientPhone} onChange={(e) => setForm({ ...form, clientPhone: e.target.value })} placeholder="+880..." />
                </div>
                <div className="pub-field">
                  <label>Event Type</label>
                  <select className="pub-select" value={form.eventType} onChange={(e) => setForm({ ...form, eventType: e.target.value })}>
                    {EVENT_TYPES.map((t) => <option key={t}>{t}</option>)}
                  </select>
                </div>
                <div className="pub-field">
                  <label>Event Date *</label>
                  <input type="date" className="pub-input" required value={form.date} onChange={(e) => setForm({ ...form, date: e.target.value })} />
                </div>
              </div>

              <div className="pub-field">
                <label>Shift</label>
                <div style={{ display: 'flex', gap: 10, marginTop: 4 }}>
                  {['DAY', 'NIGHT', 'BOTH'].map((s) => (
                    <button
                      key={s}
                      type="button"
                      className={`pub-pill${form.shift === s ? ' active' : ''}`}
                      onClick={() => setForm({ ...form, shift: s })}
                    >{s}</button>
                  ))}
                </div>
              </div>

              <div className="pub-field">
                <label>Venue</label>
                <input className="pub-input" value={form.venue} onChange={(e) => setForm({ ...form, venue: e.target.value })} placeholder="Event venue / location" />
              </div>

              {packages.length > 0 && !selectedPkg && (
                <div className="pub-field">
                  <label>Package (or describe your needs)</label>
                  <input className="pub-input" value={form.packageId} onChange={(e) => setForm({ ...form, packageId: e.target.value })} placeholder="Package name or custom requirements" />
                </div>
              )}

              <div className="pub-field">
                <label>Notes</label>
                <textarea
                  className="pub-input"
                  rows={4}
                  value={form.notes}
                  onChange={(e) => setForm({ ...form, notes: e.target.value })}
                  placeholder="Any special requests or additional information..."
                  style={{ resize: 'vertical' }}
                />
              </div>

              <div style={{ marginTop: 8 }}>
                <button type="submit" className="pub-btn" disabled={submitting} style={{ width: '100%', padding: '14px', fontSize: 16 }}>
                  {submitting ? 'Submitting...' : 'Submit Booking Request'}
                </button>
              </div>

              <p style={{ marginTop: 16, fontSize: 12, color: 'rgba(255,255,255,0.35)', textAlign: 'center' }}>
                Powered by ClickerPro · Your booking request will be reviewed and confirmed by the studio.
              </p>
            </form>
          </>
        )}
      </div>
    </div>
  );
}
