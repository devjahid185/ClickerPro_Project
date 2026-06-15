'use client';

import { useEffect, useState, useCallback, useRef } from 'react';
import Shell from '@/components/Shell';
import { api, getToken } from '@/lib/api';

type Broadcast = {
  id: string;
  title: string;
  content: string;
  priority: string;
  type: string;
  status: string;
  link: string | null;
  buttonLabel: string | null;
  createdAt: string;
};

export default function BroadcastsPage() {
  const [items, setItems] = useState<Broadcast[]>([]);
  const [err, setErr] = useState('');
  const [showNew, setShowNew] = useState(false);

  const load = useCallback(async () => {
    setErr('');
    try {
      const r = await api<{ data: Broadcast[] }>('/api/admin/broadcasts');
      setItems(r.data);
    } catch (e: any) {
      setErr(e.message);
    }
  }, []);

  useEffect(() => { load(); }, [load]);

  const toggleStatus = async (b: Broadcast) => {
    const status = b.status === 'ACTIVE' ? 'ARCHIVED' : 'ACTIVE';
    try {
      await api(`/api/admin/broadcasts/${b.id}`, { method: 'PATCH', body: { status } });
      load();
    } catch (e: any) { alert(e.message); }
  };

  const remove = async (b: Broadcast) => {
    if (!confirm(`Delete "${b.title}"?`)) return;
    try {
      await api(`/api/admin/broadcasts/${b.id}`, { method: 'DELETE' });
      load();
    } catch (e: any) { alert(e.message); }
  };

  return (
    <Shell>
      <div className="row" style={{ marginBottom: 24 }}>
        <div>
          <h1 className="page-title">Broadcasts</h1>
          <p className="page-sub" style={{ margin: 0 }}>Announcements shown to all users</p>
        </div>
        <div className="spacer" />
        <button className="btn" onClick={() => setShowNew(true)}>+ New broadcast</button>
      </div>

      {err && <div className="error">{err}</div>}

      <div className="panel">
        <table>
          <thead>
            <tr>
              <th>Title</th>
              <th>Priority</th>
              <th>Link</th>
              <th>Status</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {items.map((b) => (
              <tr key={b.id}>
                <td>
                  <strong>{b.title}</strong>
                  <div className="muted">{b.content.slice(0, 60)}{b.content.length > 60 ? '…' : ''}</div>
                </td>
                <td><span className="badge gold">{b.priority}</span></td>
                <td>
                  {b.link ? (
                    <a href={b.link} target="_blank" rel="noreferrer" className="badge teal">
                      {b.buttonLabel || 'Open'} ↗
                    </a>
                  ) : (
                    <span className="muted">—</span>
                  )}
                </td>
                <td>
                  <span className={`badge ${b.status === 'ACTIVE' ? 'green' : 'gray'}`}>{b.status}</span>
                </td>
                <td>
                  <div className="row">
                    <button className="btn sm secondary" onClick={() => toggleStatus(b)}>
                      {b.status === 'ACTIVE' ? 'Archive' : 'Activate'}
                    </button>
                    <button className="btn sm danger" onClick={() => remove(b)}>Delete</button>
                  </div>
                </td>
              </tr>
            ))}
            {items.length === 0 && (
              <tr><td colSpan={5} className="empty">No broadcasts yet</td></tr>
            )}
          </tbody>
        </table>
      </div>

      {showNew && <NewBroadcastModal onClose={() => setShowNew(false)} onDone={load} />}
    </Shell>
  );
}

function NewBroadcastModal({ onClose, onDone }: { onClose: () => void; onDone: () => void }) {
  const [title, setTitle] = useState('');
  const [content, setContent] = useState('');
  const [priority, setPriority] = useState('Normal');
  const [type, setType] = useState('Announcement');
  const [link, setLink] = useState('');
  const [buttonLabel, setButtonLabel] = useState('');
  const [audience, setAudience] = useState('all');
  const [imageUrl, setImageUrl] = useState('');
  const [err, setErr] = useState('');
  const [saving, setSaving] = useState(false);
  const [uploading, setUploading] = useState(false);
  const fileRef = useRef<HTMLInputElement>(null);

  const uploadBanner = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setUploading(true);
    setErr('');
    try {
      const fd = new FormData();
      fd.append('file', file);
      const res = await fetch('/api/files/upload', {
        method: 'POST',
        headers: { Authorization: `Bearer ${getToken()}` },
        body: fd,
      });
      const json = await res.json().catch(() => ({}));
      if (!res.ok) throw new Error(json?.message || 'Upload failed');
      const url = json?.data?.url || json?.url;
      if (!url) throw new Error('No URL returned');
      setImageUrl(url);
    } catch (e: any) {
      setErr(e.message);
    } finally {
      setUploading(false);
      if (fileRef.current) fileRef.current.value = '';
    }
  };

  const save = async () => {
    const url = link.trim();
    if (url && !/^https?:\/\//i.test(url)) {
      setErr('Link must start with http:// or https://');
      return;
    }
    setSaving(true);
    setErr('');
    try {
      await api('/api/admin/broadcasts', {
        method: 'POST',
        body: {
          title: title.trim(),
          // Send both keys so the broadcast saves regardless of whether the
          // backend expects `body` or the `content` alias.
          body: content.trim(),
          content: content.trim(),
          priority,
          type,
          audience,
          imageUrl: imageUrl.trim() || null,
          link: url || null,
          buttonLabel: url ? (buttonLabel.trim() || 'Learn more') : null,
        },
      });
      onDone();
      onClose();
    } catch (e: any) {
      setErr(e.message);
      setSaving(false);
    }
  };

  return (
    <div className="modal-backdrop" onClick={onClose}>
      <div className="modal" onClick={(e) => e.stopPropagation()}>
        <h2>New broadcast</h2>
        <div className="field">
          <label>Title</label>
          <input value={title} onChange={(e) => setTitle(e.target.value)} />
        </div>
        <div className="field">
          <label>Content</label>
          <textarea rows={4} value={content} onChange={(e) => setContent(e.target.value)} />
        </div>
        <div className="row">
          <div className="field" style={{ flex: 1 }}>
            <label>Priority</label>
            <select value={priority} onChange={(e) => setPriority(e.target.value)}>
              <option>Normal</option>
              <option>Important</option>
              <option>Emergency</option>
            </select>
          </div>
          <div className="field" style={{ flex: 1 }}>
            <label>Type</label>
            <select value={type} onChange={(e) => setType(e.target.value)}>
              <option>Announcement</option>
              <option>Update</option>
              <option>Maintenance</option>
            </select>
          </div>
          <div className="field" style={{ flex: 1 }}>
            <label>Audience</label>
            <select value={audience} onChange={(e) => setAudience(e.target.value)}>
              <option value="all">Everyone</option>
              <option value="owner">Owners only</option>
              <option value="freelancer">Freelancers only</option>
            </select>
          </div>
        </div>
        <div className="field">
          <label>Banner image (optional)</label>
          <div className="row" style={{ gap: 8 }}>
            <input
              style={{ flex: 1 }}
              placeholder="https://example.com/banner.jpg — or upload →"
              value={imageUrl}
              onChange={(e) => setImageUrl(e.target.value)}
            />
            <input
              ref={fileRef}
              type="file"
              accept="image/png,image/jpeg,image/webp,image/gif"
              style={{ display: 'none' }}
              onChange={uploadBanner}
            />
            <button type="button" className="btn secondary" onClick={() => fileRef.current?.click()} disabled={uploading}>
              {uploading ? 'Uploading…' : '⬆ Upload'}
            </button>
          </div>
          {imageUrl && (
            <div style={{ marginTop: 8 }}>
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img src={imageUrl} alt="Banner preview" style={{ maxHeight: 120, borderRadius: 8, border: '1px solid var(--border, #333)' }} />
              <button type="button" className="btn sm danger" style={{ marginLeft: 8 }} onClick={() => setImageUrl('')}>Remove</button>
            </div>
          )}
        </div>
        <div className="field">
          <label>Link (optional) — tapping the broadcast opens this</label>
          <input
            placeholder="https://example.com/promo"
            value={link}
            onChange={(e) => setLink(e.target.value)}
          />
        </div>
        {link.trim() && (
          <div className="field">
            <label>Button label</label>
            <input
              placeholder="Learn more"
              value={buttonLabel}
              onChange={(e) => setButtonLabel(e.target.value)}
            />
          </div>
        )}
        {err && <div className="error">{err}</div>}
        <div className="row" style={{ marginTop: 18, justifyContent: 'flex-end' }}>
          <button className="btn secondary" onClick={onClose}>Cancel</button>
          <button className="btn" onClick={save} disabled={saving || !title || !content}>
            {saving ? 'Posting…' : 'Post'}
          </button>
        </div>
      </div>
    </div>
  );
}
