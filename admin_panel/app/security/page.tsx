'use client';

import { useEffect, useState, useCallback } from 'react';
import Shell from '@/components/Shell';
import { api } from '@/lib/api';

type Activity = {
  id: string; email: string; ip: string | null; success: boolean;
  reason: string | null; userAgent: string | null; createdAt: string;
};
type Blocked = { ip: string; reason: string | null; createdAt: string };

export default function SecurityPage() {
  const [tab, setTab] = useState<'activity' | 'blocked' | '2fa'>('activity');
  return (
    <Shell>
      <h1 className="page-title">Security</h1>
      <div className="toolbar">
        <button className={`btn ${tab === 'activity' ? '' : 'secondary'}`} onClick={() => setTab('activity')}>Login Activity</button>
        <button className={`btn ${tab === 'blocked' ? '' : 'secondary'}`} onClick={() => setTab('blocked')}>Blocked IPs</button>
        <button className={`btn ${tab === '2fa' ? '' : 'secondary'}`} onClick={() => setTab('2fa')}>Two-Factor Auth</button>
      </div>
      {tab === 'activity' && <LoginActivity />}
      {tab === 'blocked' && <BlockedIps />}
      {tab === '2fa' && <TwoFactor />}
    </Shell>
  );
}

function LoginActivity() {
  const [rows, setRows] = useState<Activity[]>([]);
  const [onlyFailed, setOnlyFailed] = useState(false);
  const [err, setErr] = useState('');

  const load = useCallback(async () => {
    setErr('');
    try {
      const r = await api<{ data: Activity[] }>(`/api/admin/security/login-activity?onlyFailed=${onlyFailed}`);
      setRows(r.data);
    } catch (e: any) { setErr(e.message); }
  }, [onlyFailed]);
  useEffect(() => { load(); }, [load]);

  return (
    <>
      <div className="toolbar">
        <label className="row" style={{ margin: 0, gap: 6 }}>
          <input type="checkbox" style={{ width: 'auto' }} checked={onlyFailed} onChange={(e) => setOnlyFailed(e.target.checked)} />
          Failed only
        </label>
      </div>
      {err && <div className="error">{err}</div>}
      <div className="panel">
        <table>
          <thead><tr><th>When</th><th>Email</th><th>IP</th><th>Result</th></tr></thead>
          <tbody>
            {rows.map((r) => (
              <tr key={r.id}>
                <td className="muted">{new Date(r.createdAt).toLocaleString()}</td>
                <td>{r.email}</td>
                <td>{r.ip || '—'}</td>
                <td>
                  {r.success
                    ? <span className="badge green">Success</span>
                    : <span className="badge red">{r.reason || 'Failed'}</span>}
                </td>
              </tr>
            ))}
            {rows.length === 0 && <tr><td colSpan={4} className="empty">No activity</td></tr>}
          </tbody>
        </table>
      </div>
    </>
  );
}

function BlockedIps() {
  const [rows, setRows] = useState<Blocked[]>([]);
  const [ip, setIp] = useState('');
  const [reason, setReason] = useState('');
  const [err, setErr] = useState('');

  const load = useCallback(async () => {
    setErr('');
    try {
      const r = await api<{ data: Blocked[] }>('/api/admin/security/blocked-ips');
      setRows(r.data);
    } catch (e: any) { setErr(e.message); }
  }, []);
  useEffect(() => { load(); }, [load]);

  const block = async () => {
    if (!ip.trim()) return;
    try {
      await api('/api/admin/security/blocked-ips', { method: 'POST', body: { ip: ip.trim(), reason: reason.trim() || null } });
      setIp(''); setReason(''); load();
    } catch (e: any) { alert(e.message); }
  };
  const unblock = async (b: Blocked) => {
    try {
      await api(`/api/admin/security/blocked-ips/${encodeURIComponent(b.ip)}`, { method: 'DELETE' });
      load();
    } catch (e: any) { alert(e.message); }
  };

  return (
    <>
      <div className="toolbar">
        <input placeholder="IP address" value={ip} onChange={(e) => setIp(e.target.value)} />
        <input placeholder="Reason (optional)" value={reason} onChange={(e) => setReason(e.target.value)} />
        <button className="btn" onClick={block}>Block IP</button>
      </div>
      {err && <div className="error">{err}</div>}
      <div className="panel">
        <table>
          <thead><tr><th>IP</th><th>Reason</th><th>Blocked</th><th></th></tr></thead>
          <tbody>
            {rows.map((b) => (
              <tr key={b.ip}>
                <td><strong>{b.ip}</strong></td>
                <td>{b.reason || '—'}</td>
                <td className="muted">{new Date(b.createdAt).toLocaleDateString()}</td>
                <td><button className="btn sm secondary" onClick={() => unblock(b)}>Unblock</button></td>
              </tr>
            ))}
            {rows.length === 0 && <tr><td colSpan={4} className="empty">No blocked IPs</td></tr>}
          </tbody>
        </table>
      </div>
    </>
  );
}

function TwoFactor() {
  const [enabled, setEnabled] = useState<boolean | null>(null);
  const [qr, setQr] = useState('');
  const [token, setToken] = useState('');
  const [err, setErr] = useState('');
  const [msg, setMsg] = useState('');

  const loadStatus = useCallback(async () => {
    try {
      const r = await api<{ data: { enabled: boolean } }>('/api/admin/security/2fa/status');
      setEnabled(r.data.enabled);
    } catch (e: any) { setErr(e.message); }
  }, []);
  useEffect(() => { loadStatus(); }, [loadStatus]);

  const setup = async () => {
    setErr(''); setMsg('');
    try {
      const r = await api<{ data: { qr: string } }>('/api/admin/security/2fa/setup', { method: 'POST' });
      setQr(r.data.qr);
    } catch (e: any) { setErr(e.message); }
  };
  const verify = async () => {
    setErr(''); setMsg('');
    try {
      await api('/api/admin/security/2fa/verify', { method: 'POST', body: { token } });
      setMsg('2FA enabled successfully'); setQr(''); setToken(''); loadStatus();
    } catch (e: any) { setErr(e.message); }
  };
  const disable = async () => {
    if (!confirm('Disable 2FA?')) return;
    try {
      await api('/api/admin/security/2fa/disable', { method: 'POST' });
      loadStatus();
    } catch (e: any) { alert(e.message); }
  };

  return (
    <div className="panel" style={{ padding: 24, maxWidth: 480 }}>
      {err && <div className="error">{err}</div>}
      {msg && <div style={{ color: 'var(--green)', marginBottom: 12, fontWeight: 600 }}>{msg}</div>}

      {enabled === null ? <p className="muted">Loading…</p> : enabled ? (
        <>
          <div className="row" style={{ marginBottom: 16 }}>
            <span className="badge green">2FA Enabled</span>
          </div>
          <p className="muted" style={{ marginBottom: 16 }}>Your admin account is protected with an authenticator app.</p>
          <button className="btn danger" onClick={disable}>Disable 2FA</button>
        </>
      ) : qr ? (
        <>
          <p style={{ marginBottom: 12 }}>Scan with Google Authenticator / Authy, then enter the 6-digit code:</p>
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src={qr} alt="2FA QR" style={{ width: 200, height: 200, marginBottom: 16 }} />
          <div className="field"><label>6-digit code</label><input value={token} onChange={(e) => setToken(e.target.value)} placeholder="123456" /></div>
          <button className="btn" onClick={verify} disabled={token.length < 6}>Verify & Enable</button>
        </>
      ) : (
        <>
          <p style={{ marginBottom: 16 }}>Add an extra layer of security with an authenticator app.</p>
          <button className="btn" onClick={setup}>Set up 2FA</button>
        </>
      )}
    </div>
  );
}
