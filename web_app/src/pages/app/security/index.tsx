import { useEffect, useState } from 'react';
import AppShell from '@/components/AppShell';
import { api } from '@/lib/api';

/**
 * Security — two-factor authentication (TOTP) management.
 * Flow: Enable → server issues secret + QR → user scans in Google
 * Authenticator → enters the 6-digit code → verified → 2FA on.
 */
export default function SecurityPage() {
  const [enabled, setEnabled] = useState<boolean | null>(null);
  const [setup, setSetup] = useState<{ qr: string; secret: string; otpauth: string } | null>(null);
  const [code, setCode] = useState('');
  const [busy, setBusy] = useState(false);
  const [msg, setMsg] = useState('');
  const [err, setErr] = useState('');

  const loadStatus = async () => {
    try {
      const res = await api<any>('/api/security/2fa/status');
      setEnabled(!!(res?.data?.enabled ?? res?.enabled));
    } catch (e: any) { setErr(e.message); }
  };

  useEffect(() => { loadStatus(); }, []);

  const startSetup = async () => {
    setBusy(true); setErr(''); setMsg('');
    try {
      const res = await api<any>('/api/security/2fa/setup', { method: 'POST' });
      const d = res?.data ?? res;
      setSetup({ qr: d.qr, secret: d.secret, otpauth: d.otpauth });
    } catch (e: any) { setErr(e.message); }
    finally { setBusy(false); }
  };

  const verify = async () => {
    if (code.trim().length !== 6) { setErr('Enter the 6-digit code from the app.'); return; }
    setBusy(true); setErr('');
    try {
      await api('/api/security/2fa/verify', { method: 'POST', body: { token: code.trim() } });
      setEnabled(true); setSetup(null); setCode('');
      setMsg('2FA is on ✓ — login will now ask for the authenticator code.');
    } catch {
      setErr('Code did not match — check your app time and try again.');
    } finally { setBusy(false); }
  };

  const disable = async () => {
    if (!confirm('Turn off 2FA? Your account will be less secure.')) return;
    setBusy(true); setErr(''); setMsg('');
    try {
      await api('/api/security/2fa/disable', { method: 'POST' });
      setEnabled(false);
      setMsg('2FA has been turned off.');
    } catch (e: any) { setErr(e.message); }
    finally { setBusy(false); }
  };

  return (
    <AppShell>
      <div style={{ padding: 24, maxWidth: 640 }}>
        <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 24, marginBottom: 20 }}>Security</div>

        {err && <div className="error" style={{ marginBottom: 12 }}>{err}</div>}
        {msg && <div className="card" style={{ marginBottom: 12, borderLeft: '3px solid var(--green, #22c55e)' }}>{msg}</div>}

        <div className="card">
          <div className="row" style={{ alignItems: 'center', marginBottom: 8 }}>
            <div>
              <div style={{ fontWeight: 700, fontSize: 16 }}>Two-Factor Authentication (2FA)</div>
              <div className="muted text-sm" style={{ marginTop: 4 }}>
                Without the 6-digit Google Authenticator code, no one can sign in — even if your password leaks.
              </div>
            </div>
            <span className="spacer" />
            {enabled === null ? (
              <span className="muted">…</span>
            ) : (
              <span className={`badge ${enabled ? 'green' : 'gray'}`}>{enabled ? 'ON' : 'OFF'}</span>
            )}
          </div>

          {enabled === false && !setup && (
            <button className="btn" style={{ background: 'var(--orange)', color: '#000', marginTop: 8 }} onClick={startSetup} disabled={busy}>
              {busy ? 'Preparing…' : 'Enable 2FA'}
            </button>
          )}

          {enabled === true && (
            <button className="btn ghost sm" style={{ marginTop: 8 }} onClick={disable} disabled={busy}>
              Disable 2FA
            </button>
          )}

          {setup && (
            <div style={{ marginTop: 18, borderTop: '1px solid var(--surface-3)', paddingTop: 18 }}>
              <ol style={{ margin: 0, paddingLeft: 18, lineHeight: 2 }}>
                <li>Open the <strong>Google Authenticator</strong> app on your phone (get it from the Play Store if needed)</li>
                <li>Scan the QR code below:</li>
              </ol>
              <div style={{ textAlign: 'center', margin: '14px 0' }}>
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img src={setup.qr} alt="2FA QR" width={200} height={200} style={{ borderRadius: 8, background: '#fff', padding: 8 }} />
                <div className="muted text-sm" style={{ marginTop: 8 }}>
                  If scanning fails, enter this code manually:
                </div>
                <code style={{ display: 'inline-block', marginTop: 6, padding: '6px 12px', background: 'var(--surface-3)', borderRadius: 6, fontSize: 12, wordBreak: 'break-all' }}>
                  {setup.secret}
                </code>
              </div>
              <div className="row" style={{ gap: 10 }}>
                <input
                  className="input"
                  style={{ flex: 1, fontFamily: 'JetBrains Mono, monospace', letterSpacing: '0.3em', textAlign: 'center' }}
                  inputMode="numeric"
                  maxLength={6}
                  placeholder="123456"
                  value={code}
                  onChange={(e) => setCode(e.target.value.replace(/\D/g, ''))}
                />
                <button className="btn" style={{ background: 'var(--orange)', color: '#000' }} onClick={verify} disabled={busy}>
                  {busy ? 'Checking…' : 'Verify & Turn On'}
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </AppShell>
  );
}
