import { useEffect, useState } from 'react';
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
  const [items, setItems] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    let cancelled = false;
    (async () => {
      setLoading(true);
      setError('');
      try {
        const res = await api<any>('/api/broadcasts');
        const list = Array.isArray(res) ? res : res?.data ?? [];
        const sorted = [...list].sort(
          (a, b) =>
            new Date(b.created_at || 0).getTime() - new Date(a.created_at || 0).getTime()
        );
        if (cancelled) return;
        setItems(sorted);
        // Fire-and-forget: mark each shown announcement as viewed.
        sorted.forEach((a: any) => {
          if (a?.id != null) api(`/api/broadcasts/${a.id}/view`, { method: 'POST' }).catch(() => {});
        });
      } catch (e: any) {
        if (!cancelled) setError(e.message);
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  return (
    <AppShell>
      <div style={{ padding: 24 }}>
        <h1 className="page-title">Announcements</h1>
        <p className="page-sub">Platform updates and news from the ClickerPro team</p>

        {error && <div className="error" style={{ marginBottom: 12 }}>{error}</div>}

        {loading && (
          <div className="cards" style={{ display: 'grid', gap: 12 }}>
            {[...Array(3)].map((_, i) => (
              <div key={i} className="shimmer" style={{ height: 110, borderRadius: 8 }} />
            ))}
          </div>
        )}

        {!loading && !error && items.length === 0 && (
          <div className="empty">No announcements yet.</div>
        )}

        {!loading && !error && items.length > 0 && (
          <div style={{ display: 'grid', gap: 12 }}>
            {items.map((a) => (
              <div key={a.id} className="card">
                <div className="row" style={{ justifyContent: 'space-between', alignItems: 'flex-start', gap: 12, marginBottom: 6 }}>
                  <div style={{ fontWeight: 700, fontSize: 16 }}>{a.title}</div>
                  {isNew(a.created_at) && <span className="badge orange">NEW</span>}
                </div>
                <div style={{ fontSize: 14, lineHeight: 1.6, whiteSpace: 'pre-wrap', marginBottom: 10 }}>
                  {a.body}
                </div>
                <div className="muted text-sm">{fmtDate(a.created_at)}</div>
              </div>
            ))}
          </div>
        )}
      </div>
    </AppShell>
  );
}
