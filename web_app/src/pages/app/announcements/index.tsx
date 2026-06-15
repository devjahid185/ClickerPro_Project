import { useEffect, useState, FormEvent } from 'react';
import AppShell from '@/components/AppShell';
import { api } from '@/lib/api';

const fmtDate = (d: string) =>
  d ? new Date(d).toLocaleDateString('en-BD', { day: 'numeric', month: 'short', year: 'numeric' }) : '—';

const isNew = (d: string) => {
  if (!d) return false;
  const created = new Date(d).getTime();
  if (isNaN(created)) return false;
  return Date.now() - created <= 7 * 24 * 60 * 60 * 1000;
};

export default function AnnouncementsPage() {
  // Owner→team announcements (this studio).
  const [team, setTeam] = useState<any[]>([]);
  const [teamLoading, setTeamLoading] = useState(true);
  // Platform broadcasts (ClickerPro → everyone).
  const [platform, setPlatform] = useState<any[]>([]);
  const [error, setError] = useState('');
  const [isOwner, setIsOwner] = useState(false);

  // Create form (owner only).
  const [showCreate, setShowCreate] = useState(false);
  const [form, setForm] = useState({ title: '', body: '', pinned: false });
  const [submitting, setSubmitting] = useState(false);
  const [formError, setFormError] = useState('');

  const loadTeam = async () => {
    setTeamLoading(true);
    try {
      const res = await api<any>('/api/announcements');
      const list = Array.isArray(res) ? res : res?.data ?? [];
      setTeam(list);
    } catch (e: any) { setError(e.message); }
    finally { setTeamLoading(false); }
  };

  const loadPlatform = async () => {
    try {
      const res = await api<any>('/api/broadcasts');
      const list = Array.isArray(res) ? res : res?.data ?? [];
      const sorted = [...list].sort(
        (a, b) => new Date(b.created_at || 0).getTime() - new Date(a.created_at || 0).getTime());
      setPlatform(sorted);
      sorted.forEach((a: any) => {
        if (a?.id != null) api(`/api/broadcasts/${a.id}/view`, { method: 'POST' }).catch(() => {});
      });
    } catch { /* platform feed is optional */ }
  };

  const loadRole = async () => {
    try {
      const res = await api<any>('/api/profile');
      const u = res?.data?.user ?? res?.data ?? res ?? {};
      const role = (u.role || '').toUpperCase();
      setIsOwner(role === 'OWNER' || role === 'BOTH');
    } catch { /* default: not owner */ }
  };

  useEffect(() => { loadTeam(); loadPlatform(); loadRole(); }, []);

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    if (!form.title.trim() || !form.body.trim()) { setFormError('Title and message are required.'); return; }
    setSubmitting(true); setFormError('');
    try {
      await api('/api/announcements', { method: 'POST', body: { title: form.title, body: form.body, pinned: form.pinned } });
      setForm({ title: '', body: '', pinned: false });
      setShowCreate(false);
      loadTeam();
    } catch (e: any) { setFormError(e.message); }
    finally { setSubmitting(false); }
  };

  const remove = async (id: string) => {
    if (!confirm('Delete this announcement?')) return;
    try {
      await api(`/api/announcements/${id}`, { method: 'DELETE' });
      loadTeam();
    } catch (e: any) { alert(e.message); }
  };

  return (
    <AppShell>
      <div style={{ padding: 24 }}>
        <div className="toolbar" style={{ marginBottom: 8 }}>
          <h1 className="page-title" style={{ margin: 0 }}>Announcements</h1>
          <span className="spacer" />
          {isOwner && (
            <button className="btn sm" style={{ background: 'var(--orange)', color: '#000' }} onClick={() => { setForm({ title: '', body: '', pinned: false }); setFormError(''); setShowCreate(true); }}>
              + Post to Team
            </button>
          )}
        </div>
        <p className="page-sub">Messages from your studio, plus platform updates from ClickerPro</p>

        {error && <div className="error" style={{ marginBottom: 12 }}>{error}</div>}

        {/* Team announcements */}
        <div className="panel" style={{ marginBottom: 24 }}>
          <div className="panel-header"><span className="panel-title">Team Announcements</span></div>
          <div className="panel-body">
            {teamLoading && [...Array(2)].map((_, i) => <div key={i} className="shimmer" style={{ height: 80, borderRadius: 8, marginBottom: 10 }} />)}
            {!teamLoading && team.length === 0 && <div className="empty">No team announcements yet.</div>}
            {!teamLoading && team.map((a) => (
              <div key={a.id} className="card" style={{ marginBottom: 10 }}>
                <div className="row" style={{ justifyContent: 'space-between', alignItems: 'flex-start', gap: 12, marginBottom: 6 }}>
                  <div style={{ fontWeight: 700, fontSize: 16 }}>
                    {a.pinned && <span className="badge gold" style={{ marginRight: 8 }}>Pinned</span>}
                    {a.title}
                  </div>
                  <div className="row" style={{ gap: 8 }}>
                    {isNew(a.created_at) && <span className="badge orange">NEW</span>}
                    {isOwner && <button className="btn danger xs" onClick={() => remove(a.id)}>×</button>}
                  </div>
                </div>
                <div style={{ fontSize: 14, lineHeight: 1.6, whiteSpace: 'pre-wrap', marginBottom: 10 }}>{a.body}</div>
                <div className="muted text-sm">{fmtDate(a.created_at)}</div>
              </div>
            ))}
          </div>
        </div>

        {/* Platform broadcasts */}
        {platform.length > 0 && (
          <div className="panel">
            <div className="panel-header"><span className="panel-title">Platform Updates</span></div>
            <div className="panel-body">
              {platform.map((a) => (
                <div key={a.id} className="card" style={{ marginBottom: 10 }}>
                  <div className="row" style={{ justifyContent: 'space-between', alignItems: 'flex-start', gap: 12, marginBottom: 6 }}>
                    <div style={{ fontWeight: 700, fontSize: 16 }}>{a.title}</div>
                    {isNew(a.created_at) && <span className="badge orange">NEW</span>}
                  </div>
                  <div style={{ fontSize: 14, lineHeight: 1.6, whiteSpace: 'pre-wrap', marginBottom: 10 }}>{a.body}</div>
                  <div className="muted text-sm">{fmtDate(a.created_at)}</div>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>

      {/* Create modal (owner only) */}
      {showCreate && (
        <div className="modal-backdrop" onClick={() => setShowCreate(false)}>
          <div className="modal" onClick={(e) => e.stopPropagation()}>
            <div className="row" style={{ marginBottom: 16 }}>
              <span style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 20 }}>Post to Team</span>
              <span className="spacer" />
              <button className="btn ghost xs" onClick={() => setShowCreate(false)}>×</button>
            </div>
            {formError && <div className="error" style={{ marginBottom: 10 }}>{formError}</div>}
            <form onSubmit={submit}>
              <div className="field" style={{ marginBottom: 12 }}>
                <label>Title</label>
                <input className="field" value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} placeholder="Announcement title" />
              </div>
              <div className="field" style={{ marginBottom: 12 }}>
                <label>Message</label>
                <textarea className="field" rows={5} value={form.body} onChange={(e) => setForm({ ...form, body: e.target.value })} placeholder="Write your message to the team…" />
              </div>
              <div className="field" style={{ marginBottom: 16, flexDirection: 'row', alignItems: 'center', gap: 8 }}>
                <input type="checkbox" id="pin-chk" checked={form.pinned} onChange={(e) => setForm({ ...form, pinned: e.target.checked })} />
                <label htmlFor="pin-chk" style={{ margin: 0 }}>Pin to top</label>
              </div>
              <div className="row" style={{ gap: 10, justifyContent: 'flex-end' }}>
                <button type="button" className="btn ghost" onClick={() => setShowCreate(false)}>Cancel</button>
                <button type="submit" className="btn" style={{ background: 'var(--orange)', color: '#000' }} disabled={submitting}>{submitting ? 'Posting…' : 'Post'}</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </AppShell>
  );
}
