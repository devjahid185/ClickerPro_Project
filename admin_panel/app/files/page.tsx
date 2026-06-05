'use client';

import { useEffect, useState, useCallback, useRef } from 'react';
import Shell from '@/components/Shell';
import { api, getToken } from '@/lib/api';

type FileItem = { name: string; url: string; size: number; modified: string };

function fmtSize(bytes: number) {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / 1024 / 1024).toFixed(1)} MB`;
}

export default function FilesPage() {
  const [files, setFiles] = useState<FileItem[]>([]);
  const [totalBytes, setTotalBytes] = useState(0);
  const [err, setErr] = useState('');
  const [uploading, setUploading] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);

  const load = useCallback(async () => {
    setErr('');
    try {
      const r = await api<{ data: FileItem[]; totalBytes: number }>('/api/admin/files');
      setFiles(r.data); setTotalBytes(r.totalBytes);
    } catch (e: any) { setErr(e.message); }
  }, []);
  useEffect(() => { load(); }, [load]);

  const onUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setUploading(true); setErr('');
    try {
      const fd = new FormData();
      fd.append('file', file);
      const res = await fetch('/api/admin/files', {
        method: 'POST',
        headers: { Authorization: `Bearer ${getToken()}` },
        body: fd,
      });
      if (!res.ok) {
        const j = await res.json().catch(() => ({}));
        throw new Error(j.message || 'Upload failed');
      }
      load();
    } catch (e: any) { setErr(e.message); }
    finally { setUploading(false); if (inputRef.current) inputRef.current.value = ''; }
  };

  const remove = async (f: FileItem) => {
    if (!confirm(`Delete ${f.name}?`)) return;
    try {
      await api(`/api/admin/files/${encodeURIComponent(f.name)}`, { method: 'DELETE' });
      load();
    } catch (e: any) { alert(e.message); }
  };

  const copyUrl = (url: string) => {
    navigator.clipboard.writeText(url);
    alert('URL copied');
  };

  const isImage = (n: string) => /\.(png|jpe?g|gif|webp|svg)$/i.test(n);

  return (
    <Shell>
      <div className="row" style={{ marginBottom: 8 }}>
        <div>
          <h1 className="page-title">Files</h1>
          <p className="page-sub" style={{ margin: 0 }}>{files.length} files · {fmtSize(totalBytes)} used</p>
        </div>
        <div className="spacer" />
        <input ref={inputRef} type="file" onChange={onUpload} style={{ display: 'none' }} />
        <button className="btn" onClick={() => inputRef.current?.click()} disabled={uploading}>
          {uploading ? 'Uploading…' : '⬆ Upload file'}
        </button>
      </div>
      <div style={{ height: 16 }} />
      {err && <div className="error">{err}</div>}

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(180px, 1fr))', gap: 16 }}>
        {files.map((f) => (
          <div className="card" key={f.name} style={{ padding: 12 }}>
            <div style={{ height: 110, background: 'var(--bg)', borderRadius: 8, display: 'flex', alignItems: 'center', justifyContent: 'center', overflow: 'hidden', marginBottom: 8 }}>
              {isImage(f.name)
                // eslint-disable-next-line @next/next/no-img-element
                ? <img src={f.url} alt={f.name} style={{ maxWidth: '100%', maxHeight: '100%', objectFit: 'cover' }} />
                : <span style={{ fontSize: 32 }}>📄</span>}
            </div>
            <div style={{ fontSize: 12, fontWeight: 600, wordBreak: 'break-all' }}>{f.name}</div>
            <div className="muted" style={{ fontSize: 11, marginBottom: 8 }}>{fmtSize(f.size)}</div>
            <div className="row">
              <button className="btn sm secondary" onClick={() => copyUrl(f.url)}>Copy URL</button>
              <button className="btn sm danger" onClick={() => remove(f)}>Delete</button>
            </div>
          </div>
        ))}
        {files.length === 0 && <p className="muted">No files uploaded yet.</p>}
      </div>
    </Shell>
  );
}
