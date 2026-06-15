import { useEffect, useState, FormEvent } from 'react';
import AppShell from '@/components/AppShell';
import { api, getUser } from '@/lib/api';

const TABS = ['Profile', 'Business', 'Security', 'Preferences', 'Data'];

export default function SettingsPage() {
  const [tab, setTab] = useState(0);
  const user = getUser();

  // Profile
  const [profile, setProfile] = useState({ name: '', email: '', phone: '', bio: '' });
  const [profileMsg, setProfileMsg] = useState('');
  const [profileErr, setProfileErr] = useState('');
  const [profileLoading, setProfileLoading] = useState(false);

  // Studio. `logo` is a data-URL/base64 string stored on the user's logo_url
  // field (separate from the personal profile photo / avatar).
  const [studio, setStudio] = useState({ businessName: '', logo: '', distributionMode: false, publicToken: '' });
  const [studioMsg, setStudioMsg] = useState('');
  const [studioErr, setStudioErr] = useState('');
  const [studioCopied, setStudioCopied] = useState(false);
  const [logoUploading, setLogoUploading] = useState(false);

  // Security
  const [security, setSecurity] = useState({ currentPassword: '', newPassword: '', confirmPassword: '' });
  const [secMsg, setSecMsg] = useState('');
  const [secErr, setSecErr] = useState('');
  const [secLoading, setSecLoading] = useState(false);

  // Preferences
  const [lang, setLang] = useState('English');
  const [notifPrefs, setNotifPrefs] = useState({ booking: true, payment: true, team: false, system: true });

  // Data
  const [deleteConfirm, setDeleteConfirm] = useState('');
  const [deleteMsg, setDeleteMsg] = useState('');
  const [deleteErr, setDeleteErr] = useState('');

  useEffect(() => {
    if (user) {
      setProfile({ name: user.name || '', email: user.email || '', phone: user.phone || '', bio: user.bio || '' });
      setStudio({ businessName: user.studioName || user.businessName || '', logo: user.logoUrl || user.logo_url || '', distributionMode: user.distributionMode || false, publicToken: user.publicToken || user.bookingToken || '' });
    }
    const savedLang = localStorage.getItem('cp_lang') || 'English';
    setLang(savedLang);
    const savedNotif = localStorage.getItem('cp_notif_prefs');
    if (savedNotif) { try { setNotifPrefs(JSON.parse(savedNotif)); } catch {} }
  }, []);

  const saveProfile = async (e: FormEvent) => {
    e.preventDefault();
    setProfileLoading(true); setProfileErr(''); setProfileMsg('');
    try {
      await api('/api/profile', { method: 'PATCH', body: profile });
      setProfileMsg('Profile updated successfully.');
    } catch (e: any) { setProfileErr(e.message); }
    finally { setProfileLoading(false); }
  };

  const saveStudio = async (e: FormEvent) => {
    e.preventDefault();
    setStudioErr(''); setStudioMsg('');
    try {
      // Backend accepts snake_case `business_name` and `logo_url` (the studio
      // logo — separate from the personal `avatar` profile photo).
      await api('/api/profile', { method: 'PATCH', body: { business_name: studio.businessName, logo_url: studio.logo, distributionMode: studio.distributionMode } });
      // Keep the cached user in sync so the logo persists on reload.
      const cached = getUser() || {};
      localStorage.setItem('cp_web_user', JSON.stringify({ ...cached, businessName: studio.businessName, logoUrl: studio.logo }));
      setStudioMsg('Studio settings updated.');
    } catch (e: any) { setStudioErr(e.message); }
  };

  // Read an image file as a base64 data-URL. Capped at ~512KB so the
  // payload stays small (logos are tiny) — bigger files are rejected.
  const onLogoFile = (file: File | null) => {
    if (!file) return;
    if (!file.type.startsWith('image/')) { setStudioErr('Please choose an image file.'); return; }
    if (file.size > 512 * 1024) { setStudioErr('Logo must be under 512KB.'); return; }
    setStudioErr(''); setLogoUploading(true);
    const reader = new FileReader();
    reader.onload = () => { setStudio((s) => ({ ...s, logo: String(reader.result) })); setLogoUploading(false); };
    reader.onerror = () => { setStudioErr('Could not read that file.'); setLogoUploading(false); };
    reader.readAsDataURL(file);
  };

  const changePassword = async (e: FormEvent) => {
    e.preventDefault();
    if (security.newPassword !== security.confirmPassword) { setSecErr('Passwords do not match.'); return; }
    if (security.newPassword.length < 6) { setSecErr('Password must be at least 6 characters.'); return; }
    setSecLoading(true); setSecErr(''); setSecMsg('');
    try {
      await api('/api/auth/change-password', { method: 'POST', body: { currentPassword: security.currentPassword, newPassword: security.newPassword } });
      setSecMsg('Password changed successfully.');
      setSecurity({ currentPassword: '', newPassword: '', confirmPassword: '' });
    } catch (e: any) { setSecErr(e.message); }
    finally { setSecLoading(false); }
  };

  const saveLang = (l: string) => { setLang(l); localStorage.setItem('cp_lang', l); };
  const saveNotif = (key: string, val: boolean) => {
    const updated = { ...notifPrefs, [key]: val };
    setNotifPrefs(updated);
    localStorage.setItem('cp_notif_prefs', JSON.stringify(updated));
  };

  const copyLink = () => {
    const link = `${window.location.origin}/book/${studio.publicToken}`;
    navigator.clipboard.writeText(link);
    setStudioCopied(true);
    setTimeout(() => setStudioCopied(false), 2000);
  };

  const exportCSV = async (type: string) => {
    try {
      const res = await api<any>(`/api/${type}`);
      const data = Array.isArray(res) ? res : res?.data ?? [];
      if (data.length === 0) { alert('No data to export.'); return; }
      const headers = Object.keys(data[0]);
      const rows = data.map((r: any) => headers.map((h) => `"${String(r[h] ?? '').replace(/"/g, '""')}"`).join(','));
      const csv = [headers.join(','), ...rows].join('\n');
      const a = document.createElement('a');
      a.href = 'data:text/csv;charset=utf-8,' + encodeURIComponent(csv);
      a.download = `${type}.csv`;
      a.click();
    } catch (e: any) { alert(e.message); }
  };

  const requestDelete = async () => {
    if (deleteConfirm !== 'DELETE') { setDeleteErr('Please type DELETE to confirm.'); return; }
    setDeleteErr(''); setDeleteMsg('');
    try {
      await api('/api/account/delete-request', { method: 'POST' });
      setDeleteMsg('Deletion request submitted. Your account will be deleted after 7 days. Contact support to cancel.');
    } catch (e: any) { setDeleteErr(e.message); }
  };

  const ToggleRow = ({ label, checked, onChange }: { label: string; checked: boolean; onChange: (v: boolean) => void }) => (
    <div className="toggle-row" style={{ marginBottom: 14 }}>
      <span style={{ fontSize: 14 }}>{label}</span>
      <span className="spacer" />
      <label className="toggle" style={{ cursor: 'pointer' }}>
        <input type="checkbox" checked={checked} onChange={(e) => onChange(e.target.checked)} style={{ display: 'none' }} />
        <span className="toggle-slider" style={{ background: checked ? 'var(--orange)' : 'var(--surface-3)', display: 'inline-block', width: 40, height: 22, borderRadius: 11, position: 'relative', transition: 'background 0.2s' }}>
          <span style={{ position: 'absolute', top: 3, left: checked ? 21 : 3, width: 16, height: 16, borderRadius: '50%', background: '#fff', transition: 'left 0.2s' }} />
        </span>
      </label>
    </div>
  );

  return (
    <AppShell>
      <div style={{ padding: 24 }}>
        <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 24, marginBottom: 20 }}>Settings</div>

        <div className="tabs" style={{ marginBottom: 24 }}>
          {TABS.map((t, i) => (
            <button key={t} className={`tab${tab === i ? ' active' : ''}`} onClick={() => setTab(i)}>{t}</button>
          ))}
        </div>

        {/* Profile */}
        {tab === 0 && (
          <div className="panel" style={{ maxWidth: 560 }}>
            <div className="panel-header"><span className="panel-title">Profile Information</span></div>
            <div className="panel-body">
              {profileMsg && <div className="success-msg" style={{ marginBottom: 12 }}>{profileMsg}</div>}
              {profileErr && <div className="error" style={{ marginBottom: 12 }}>{profileErr}</div>}
              <form onSubmit={saveProfile}>
                <div className="form-grid">
                  <div className="field"><label>Full Name</label><input className="field" value={profile.name} onChange={(e) => setProfile({ ...profile, name: e.target.value })} placeholder="Your name" /></div>
                  <div className="field"><label>Email</label><input type="email" className="field" value={profile.email} onChange={(e) => setProfile({ ...profile, email: e.target.value })} placeholder="email@example.com" /></div>
                  <div className="field"><label>Phone</label><input className="field" value={profile.phone} onChange={(e) => setProfile({ ...profile, phone: e.target.value })} placeholder="+880..." /></div>
                  <div className="field" style={{ gridColumn: '1/-1' }}>
                    <label>Bio</label>
                    <textarea className="field" rows={3} value={profile.bio} onChange={(e) => setProfile({ ...profile, bio: e.target.value })} placeholder="Brief bio..." />
                  </div>
                </div>
                <button type="submit" className="btn" style={{ marginTop: 16, background: 'var(--orange)', color: '#000' }} disabled={profileLoading}>{profileLoading ? 'Saving...' : 'Save Profile'}</button>
              </form>
            </div>
          </div>
        )}

        {/* Studio */}
        {tab === 1 && (
          <div className="panel" style={{ maxWidth: 560 }}>
            <div className="panel-header"><span className="panel-title">Business Settings</span></div>
            <div className="panel-body">
              {studioMsg && <div className="success-msg" style={{ marginBottom: 12 }}>{studioMsg}</div>}
              {studioErr && <div className="error" style={{ marginBottom: 12 }}>{studioErr}</div>}
              <form onSubmit={saveStudio}>
                <div className="field" style={{ marginBottom: 12 }}><label>Business Name</label><input className="field" value={studio.businessName} onChange={(e) => setStudio({ ...studio, businessName: e.target.value })} /></div>
                <div className="field" style={{ marginBottom: 16 }}>
                  <label>Studio Logo</label>
                  <div className="row" style={{ gap: 14, alignItems: 'center' }}>
                    <div style={{ width: 64, height: 64, borderRadius: 10, background: 'var(--surface-3)', border: '1px solid var(--border)', display: 'flex', alignItems: 'center', justifyContent: 'center', overflow: 'hidden', flex: '0 0 64px' }}>
                      {studio.logo
                        // eslint-disable-next-line @next/next/no-img-element
                        ? <img src={studio.logo} alt="Studio logo" style={{ width: '100%', height: '100%', objectFit: 'contain' }} />
                        : <span className="muted text-sm">No logo</span>}
                    </div>
                    <div className="row" style={{ gap: 8 }}>
                      <label className="btn ghost sm" style={{ cursor: 'pointer' }}>
                        {logoUploading ? 'Reading…' : studio.logo ? 'Change' : 'Upload Logo'}
                        <input type="file" accept="image/*" style={{ display: 'none' }} onChange={(e) => onLogoFile(e.target.files?.[0] || null)} />
                      </label>
                      {studio.logo && <button type="button" className="btn ghost sm" onClick={() => setStudio({ ...studio, logo: '' })}>Remove</button>}
                    </div>
                  </div>
                  <div className="field-hint">PNG or JPG, under 512KB. The owner&apos;s logo appears on shared booking pages.</div>
                </div>

                <ToggleRow label="Distribution Mode (allow multiple bookings same date/shift)" checked={studio.distributionMode} onChange={(v) => setStudio({ ...studio, distributionMode: v })} />

                {studio.publicToken && (
                  <div style={{ marginBottom: 16 }}>
                    <div className="muted text-sm" style={{ marginBottom: 8 }}>Public Booking Link</div>
                    <div className="row" style={{ gap: 8 }}>
                      <code style={{ flex: 1, padding: '8px 12px', background: 'var(--surface-3)', borderRadius: 6, fontSize: 12, fontFamily: 'JetBrains Mono, monospace', wordBreak: 'break-all' }}>
                        {typeof window !== 'undefined' ? window.location.origin : ''}/book/{studio.publicToken}
                      </code>
                      <button type="button" className="btn ghost sm" onClick={copyLink}>{studioCopied ? 'Copied!' : 'Copy'}</button>
                    </div>
                  </div>
                )}

                <button type="submit" className="btn" style={{ background: 'var(--orange)', color: '#000' }}>Save Business Settings</button>
              </form>
            </div>
          </div>
        )}

        {/* Security */}
        {tab === 2 && (
          <div className="panel" style={{ maxWidth: 480 }}>
            <div className="panel-header"><span className="panel-title">Change Password</span></div>
            <div className="panel-body">
              {secMsg && <div className="success-msg" style={{ marginBottom: 12 }}>{secMsg}</div>}
              {secErr && <div className="error" style={{ marginBottom: 12 }}>{secErr}</div>}
              <form onSubmit={changePassword}>
                <div className="field" style={{ marginBottom: 12 }}><label>Current Password</label><input type="password" className="field" required value={security.currentPassword} onChange={(e) => setSecurity({ ...security, currentPassword: e.target.value })} /></div>
                <div className="field" style={{ marginBottom: 12 }}><label>New Password</label><input type="password" className="field" required value={security.newPassword} onChange={(e) => setSecurity({ ...security, newPassword: e.target.value })} /></div>
                <div className="field" style={{ marginBottom: 16 }}><label>Confirm New Password</label><input type="password" className="field" required value={security.confirmPassword} onChange={(e) => setSecurity({ ...security, confirmPassword: e.target.value })} /></div>
                <button type="submit" className="btn" style={{ background: 'var(--orange)', color: '#000' }} disabled={secLoading}>{secLoading ? 'Changing...' : 'Change Password'}</button>
              </form>
            </div>
          </div>
        )}

        {/* Preferences */}
        {tab === 3 && (
          <div className="panel" style={{ maxWidth: 480 }}>
            <div className="panel-header"><span className="panel-title">Preferences</span></div>
            <div className="panel-body">
              <div className="muted text-sm" style={{ marginBottom: 12, textTransform: 'uppercase', fontFamily: 'JetBrains Mono, monospace', letterSpacing: '0.08em' }}>Language</div>
              <div className="row" style={{ gap: 10, marginBottom: 24 }}>
                {['English', 'Bangla'].map((l) => (
                  <button key={l} className={`btn ${lang === l ? '' : 'ghost'} sm`} style={lang === l ? { background: 'var(--orange)', color: '#000' } : {}} onClick={() => saveLang(l)}>{l}</button>
                ))}
              </div>

              <div className="muted text-sm" style={{ marginBottom: 6, textTransform: 'uppercase', fontFamily: 'JetBrains Mono, monospace', letterSpacing: '0.08em' }}>Theme</div>
              <div className="row" style={{ gap: 8, marginBottom: 24 }}>
                <button className="btn sm" style={{ background: 'var(--orange)', color: '#fff', border: '1px solid var(--orange)' }}>Light (Active)</button>
                <button className="btn ghost sm" disabled style={{ opacity: 0.4 }}>Dark (Coming Soon)</button>
              </div>

              <div className="muted text-sm" style={{ marginBottom: 12, textTransform: 'uppercase', fontFamily: 'JetBrains Mono, monospace', letterSpacing: '0.08em' }}>Notifications</div>
              <ToggleRow label="Booking notifications" checked={notifPrefs.booking} onChange={(v) => saveNotif('booking', v)} />
              <ToggleRow label="Payment notifications" checked={notifPrefs.payment} onChange={(v) => saveNotif('payment', v)} />
              <ToggleRow label="Team notifications" checked={notifPrefs.team} onChange={(v) => saveNotif('team', v)} />
              <ToggleRow label="System notifications" checked={notifPrefs.system} onChange={(v) => saveNotif('system', v)} />
            </div>
          </div>
        )}

        {/* Data */}
        {tab === 4 && (
          <div style={{ maxWidth: 560 }}>
            <div className="panel" style={{ marginBottom: 20 }}>
              <div className="panel-header"><span className="panel-title">Export Data</span></div>
              <div className="panel-body">
                <div className="row" style={{ gap: 10, flexWrap: 'wrap' }}>
                  <button className="btn ghost sm" onClick={() => exportCSV('bookings')}>Export Bookings CSV</button>
                  <button className="btn ghost sm" onClick={() => exportCSV('clients')}>Export Clients CSV</button>
                  <button className="btn ghost sm" onClick={() => exportCSV('payments')}>Export Payments CSV</button>
                </div>
              </div>
            </div>

            <div className="panel" style={{ borderColor: 'var(--red)' }}>
              <div className="panel-header"><span className="panel-title" style={{ color: 'var(--red)' }}>Danger Zone</span></div>
              <div className="panel-body">
                <p className="muted" style={{ marginBottom: 12, fontSize: 14 }}>
                  Requesting account deletion will initiate a 7-day grace period. After that, all your data will be permanently removed. This cannot be undone.
                </p>
                {deleteMsg && <div className="success-msg" style={{ marginBottom: 12 }}>{deleteMsg}</div>}
                {deleteErr && <div className="error" style={{ marginBottom: 12 }}>{deleteErr}</div>}
                <div className="field" style={{ marginBottom: 12 }}>
                  <label>Type DELETE to confirm</label>
                  <input className="field" value={deleteConfirm} onChange={(e) => setDeleteConfirm(e.target.value)} placeholder="DELETE" />
                </div>
                <button className="btn danger" onClick={requestDelete}>Request Account Deletion</button>
              </div>
            </div>
          </div>
        )}
      </div>
    </AppShell>
  );
}
