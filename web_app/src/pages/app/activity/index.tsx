import { useEffect, useState } from 'react';
import AppShell from '@/components/AppShell';
import { api } from '@/lib/api';

const fmtDate = (d: string) =>
  d ? new Date(d).toLocaleDateString('en-BD', { day: 'numeric', month: 'short', year: 'numeric' }) : '—';

const fmtRelative = (d: string) => {
  if (!d) return '—';
  const t = new Date(d).getTime();
  if (isNaN(t)) return fmtDate(d);
  const diff = Date.now() - t;
  const min = Math.round(diff / 60000);
  if (min < 1) return 'just now';
  if (min < 60) return `${min}m ago`;
  const hr = Math.round(min / 60);
  if (hr < 24) return `${hr}h ago`;
  const days = Math.round(hr / 24);
  if (days < 7) return `${days}d ago`;
  return fmtDate(d);
};

const ACTION_COLORS: Record<string, string> = {
  CREATE: 'green',
  UPDATE: 'blue',
  DELETE: 'red',
  LOGIN: 'gold',
};

export default function ActivityPage() {
  const [items, setItems] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    let cancelled = false;
    (async () => {
      setLoading(true);
      setError('');
      try {
        const res = await api<any>('/api/my-activity');
        const list = Array.isArray(res) ? res : res?.data ?? [];
        if (!cancelled) setItems(list);
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
        <h1 className="page-title">My Activity</h1>
        <p className="page-sub">A record of recent actions on your account</p>

        {error && <div className="error" style={{ marginBottom: 12 }}>{error}</div>}

        {loading && (
          <div style={{ display: 'grid', gap: 10 }}>
            {[...Array(5)].map((_, i) => (
              <div key={i} className="shimmer" style={{ height: 56, borderRadius: 8 }} />
            ))}
          </div>
        )}

        {!loading && !error && items.length === 0 && (
          <div className="empty">No activity recorded yet.</div>
        )}

        {!loading && !error && items.length > 0 && (
          <div className="timeline">
            {items.map((it) => {
              const action: string = it.action || 'ACTION';
              const verb = (action.split(/\s+/)[0] || action).toUpperCase();
              const color = ACTION_COLORS[verb] || 'gray';
              const entityLabel = [it.entityType, it.entityId != null ? `#${it.entityId}` : '']
                .filter(Boolean)
                .join(' ');
              return (
                <div key={it.id} className="timeline-item">
                  <div className="timeline-dot" />
                  <div className="timeline-content">
                    <div className="row" style={{ justifyContent: 'space-between', alignItems: 'center', gap: 12, marginBottom: 4 }}>
                      <span className={'badge ' + color}>{action}</span>
                      <span className="muted text-sm">{fmtRelative(it.createdAt)}</span>
                    </div>
                    {entityLabel && (
                      <div style={{ fontSize: 14, marginBottom: 2 }}>{entityLabel}</div>
                    )}
                    {it.ip && <div className="muted text-sm">IP {it.ip}</div>}
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </AppShell>
  );
}
