import { useEffect, useState } from 'react';
import AppShell from '@/components/AppShell';
import { api } from '@/lib/api';
import { tk } from '@/lib/format';


const ROLE_COLORS: Record<string, string> = {
  PHOTOGRAPHER: 'orange', VIDEOGRAPHER: 'teal', EDITOR: 'purple',
  ASSISTANT: 'gray', OWNER: 'gold', MANAGER: 'blue', BOTH: 'green',
};

const initials = (name: string) =>
  (name || '?').split(' ').map((w) => w[0]).join('').slice(0, 2).toUpperCase();

export default function TeamPage() {
  const [members, setMembers] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [inviteCode, setInviteCode] = useState('');
  const [showSalary, setShowSalary] = useState(false);
  const [showPermModal, setShowPermModal] = useState(false);
  const [permMember, setPermMember] = useState<any>(null);
  const [perms, setPerms] = useState<any>({});
  const [copied, setCopied] = useState(false);
  const [generatingCode, setGeneratingCode] = useState(false);

  const load = async () => {
    setLoading(true);
    try {
      const res = await api<any>('/api/team');
      setMembers(Array.isArray(res) ? res : res?.data ?? res?.members ?? []);
    } catch (e: any) { setError(e.message); }
    finally { setLoading(false); }
  };

  const loadInvite = async () => {
    try {
      const res = await api<any>('/api/team/invite');
      setInviteCode(res?.code || res?.inviteCode || '');
    } catch { /* invite may not exist yet */ }
  };

  useEffect(() => { load(); loadInvite(); }, []);

  const generateInvite = async () => {
    setGeneratingCode(true);
    try {
      const res = await api<any>('/api/team/invite', { method: 'POST' });
      setInviteCode(res?.code || res?.inviteCode || '');
    } catch (e: any) { alert(e.message); }
    finally { setGeneratingCode(false); }
  };

  const copyCode = () => {
    navigator.clipboard.writeText(inviteCode).then(() => { setCopied(true); setTimeout(() => setCopied(false), 2000); });
  };

  const openPerms = (m: any) => {
    setPermMember(m);
    setPerms({
      can_see_finance: m.permissions?.can_see_finance ?? m.canSeeFinance ?? false,
      can_create_booking: m.permissions?.can_create_booking ?? m.canCreateBooking ?? false,
      can_manage_team: m.permissions?.can_manage_team ?? m.canManageTeam ?? false,
    });
    setShowPermModal(true);
  };

  const savePerms = async () => {
    if (!permMember) return;
    try {
      await api(`/api/team/members/${permMember.id}/permissions`, { method: 'PATCH', body: perms });
      setShowPermModal(false);
      load();
    } catch (e: any) { alert(e.message); }
  };

  const stats = {
    total: members.length,
    photographers: members.filter((m) => m.role === 'PHOTOGRAPHER').length,
    videographers: members.filter((m) => ['VIDEOGRAPHER', 'CINEMATOGRAPHER'].includes(m.role)).length,
    editors: members.filter((m) => m.role === 'EDITOR').length,
  };

  return (
    <AppShell>
      <div style={{ padding: 24 }}>
        <div className="toolbar" style={{ marginBottom: 20 }}>
          <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 24 }}>Team</div>
          <span className="spacer" />
          <button className="btn ghost sm" onClick={() => setShowSalary(true)}>Salary Sheet</button>
        </div>

        {error && <div className="error" style={{ marginBottom: 12 }}>{error}</div>}

        {/* Stats */}
        <div className="cards cards-4" style={{ marginBottom: 20 }}>
          {[
            { label: 'Total Members', value: stats.total, color: 'var(--film)' },
            { label: 'Photographers', value: stats.photographers, color: 'var(--orange)' },
            { label: 'Videographers', value: stats.videographers, color: 'var(--teal)' },
            { label: 'Editors', value: stats.editors, color: 'var(--purple)' },
          ].map((s) => (
            <div key={s.label} className="card" style={{ textAlign: 'center' }}>
              <div className="muted text-sm" style={{ marginBottom: 6 }}>{s.label}</div>
              <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 32, color: s.color }}>{s.value}</div>
            </div>
          ))}
        </div>

        {/* Invite Code */}
        <div className="card" style={{ marginBottom: 20 }}>
          <div className="muted text-sm" style={{ marginBottom: 10, textTransform: 'uppercase', fontFamily: 'JetBrains Mono, monospace', letterSpacing: '0.08em' }}>Team Invite Code</div>
          {inviteCode ? (
            <div className="row" style={{ gap: 10 }}>
              <code style={{ flex: 1, padding: '10px 14px', background: 'var(--surface-3)', borderRadius: 6, fontFamily: 'JetBrains Mono, monospace', fontSize: 18, letterSpacing: '0.2em', color: 'var(--orange)' }}>
                {inviteCode}
              </code>
              <button className="btn ghost sm" onClick={copyCode}>{copied ? 'Copied!' : 'Copy'}</button>
              <button className="btn ghost sm" onClick={generateInvite} disabled={generatingCode}>Regenerate</button>
            </div>
          ) : (
            <button className="btn ghost sm" onClick={generateInvite} disabled={generatingCode}>
              {generatingCode ? 'Generating...' : 'Generate Invite Code'}
            </button>
          )}
        </div>

        {/* Member Cards */}
        {loading && (
          <div className="cards cards-3">
            {[...Array(6)].map((_, i) => <div key={i} className="shimmer" style={{ height: 140, borderRadius: 8 }} />)}
          </div>
        )}
        {!loading && members.length === 0 && <div className="empty">No team members yet.</div>}
        {!loading && members.length > 0 && (
          <div className="cards cards-3">
            {members.map((m) => (
              <div key={m.id} className="card">
                <div className="row" style={{ gap: 12, marginBottom: 12 }}>
                  <div className="avatar avatar-lg">{initials(m.name || m.email || '?')}</div>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontWeight: 700, fontSize: 16 }} className="truncate">{m.name || 'Unnamed'}</div>
                    <span className={`badge ${ROLE_COLORS[m.role] || 'gray'}`}>{m.role}</span>
                  </div>
                </div>
                <div className="info-row"><span className="info-key">Email</span><span className="info-val truncate">{m.email || '—'}</span></div>
                <div className="info-row"><span className="info-key">Phone</span><span className="info-val">{m.phone || '—'}</span></div>
                <div className="info-row"><span className="info-key">Assignments</span><span className="info-val">{m.assignmentCount ?? m._count?.assignments ?? 0}</span></div>
                <div className="row" style={{ gap: 8, marginTop: 12 }}>
                  <button className="btn ghost xs" style={{ flex: 1 }} onClick={() => openPerms(m)}>Permissions</button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Salary Sheet Modal */}
      {showSalary && (
        <div className="modal-backdrop" onClick={() => setShowSalary(false)}>
          <div className="modal modal-lg" onClick={(e) => e.stopPropagation()}>
            <div className="row" style={{ marginBottom: 20 }}>
              <span style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 22 }}>Salary Sheet</span>
              <span className="spacer" />
              <button className="btn ghost xs" onClick={() => setShowSalary(false)}>×</button>
            </div>
            <table style={{ width: '100%', borderCollapse: 'collapse' }}>
              <thead>
                <tr style={{ borderBottom: '2px solid var(--surface-3)' }}>
                  {['Member', 'Role', 'Assignments', 'Est. Payout'].map((h) => (
                    <th key={h} style={{ textAlign: 'left', padding: '8px 12px', fontSize: 11, fontFamily: 'JetBrains Mono, monospace', color: 'var(--film-muted)', textTransform: 'uppercase' }}>{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {members.map((m) => (
                  <tr key={m.id} className="salary-row">
                    <td style={{ padding: '12px' }}>
                      <div className="row" style={{ gap: 10 }}>
                        <div className="avatar avatar-sm">{initials(m.name || '?')}</div>
                        <div>
                          <div style={{ fontWeight: 600 }}>{m.name || '—'}</div>
                          <div className="muted text-sm">{m.email || ''}</div>
                        </div>
                      </div>
                    </td>
                    <td style={{ padding: '12px' }}><span className={`badge ${ROLE_COLORS[m.role] || 'gray'}`}>{m.role}</span></td>
                    <td style={{ padding: '12px', fontSize: 18, fontFamily: 'Bebas Neue, sans-serif' }}>{m.assignmentCount ?? m._count?.assignments ?? 0}</td>
                    <td style={{ padding: '12px', color: 'var(--orange)', fontFamily: 'Bebas Neue, sans-serif', fontSize: 20 }}>
                      {tk(Number(m.totalPayout || m.estimatedPayout) || 0)}
                    </td>
                  </tr>
                ))}
              </tbody>
              <tfoot>
                <tr style={{ borderTop: '2px solid var(--surface-3)' }}>
                  <td colSpan={3} style={{ padding: '12px', fontWeight: 700 }}>Total Payouts</td>
                  <td style={{ padding: '12px', color: 'var(--orange)', fontFamily: 'Bebas Neue, sans-serif', fontSize: 22 }}>
                    {tk(members.reduce((s, m) => s + (Number(m.totalPayout || m.estimatedPayout) || 0), 0))}
                  </td>
                </tr>
              </tfoot>
            </table>
          </div>
        </div>
      )}

      {/* Permissions Modal */}
      {showPermModal && permMember && (
        <div className="modal-backdrop" onClick={() => setShowPermModal(false)}>
          <div className="modal" onClick={(e) => e.stopPropagation()}>
            <div className="row" style={{ marginBottom: 16 }}>
              <span style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 20 }}>Permissions — {permMember.name}</span>
              <span className="spacer" />
              <button className="btn ghost xs" onClick={() => setShowPermModal(false)}>×</button>
            </div>
            {[
              { key: 'can_see_finance', label: 'Can View Finance' },
              { key: 'can_create_booking', label: 'Can Create Bookings' },
              { key: 'can_manage_team', label: 'Can Manage Team' },
            ].map((p) => (
              <div key={p.key} className="toggle-row" style={{ marginBottom: 14 }}>
                <span style={{ fontSize: 14 }}>{p.label}</span>
                <span className="spacer" />
                <label className="toggle">
                  <input type="checkbox" checked={!!perms[p.key]} onChange={(e) => setPerms({ ...perms, [p.key]: e.target.checked })} style={{ display: 'none' }} />
                  <span className="toggle-slider" />
                </label>
              </div>
            ))}
            <div className="row" style={{ gap: 10, marginTop: 20, justifyContent: 'flex-end' }}>
              <button className="btn ghost" onClick={() => setShowPermModal(false)}>Cancel</button>
              <button className="btn" style={{ background: 'var(--orange)', color: '#000' }} onClick={savePerms}>Save</button>
            </div>
          </div>
        </div>
      )}
    </AppShell>
  );
}
