import { useEffect, useState } from 'react';
import Head from 'next/head';
import AppShell from '@/components/AppShell';
import { api } from '@/lib/api';

type Broadcast = {
  id: string;
  title?: string;
  message?: string;
  body?: string;
  type?: string;
  createdAt?: string;
  read?: boolean;
};

function formatDate(d?: string) {
  if (!d) return '';
  const date = new Date(d);
  const now = new Date();
  const diff = now.getTime() - date.getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 1) return 'Just now';
  if (mins < 60) return `${mins}m ago`;
  const hrs = Math.floor(mins / 60);
  if (hrs < 24) return `${hrs}h ago`;
  const days = Math.floor(hrs / 24);
  if (days < 7) return `${days}d ago`;
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
}

const TYPE_ICONS: Record<string, string> = {
  BOOKING: '📅',
  PAYMENT: '💳',
  INVOICE: '🧾',
  SYSTEM: '🔔',
  INFO: 'ℹ️',
  WARNING: '⚠️',
  SUCCESS: '✅',
};

export default function NotificationsPage() {
  const [notifications, setNotifications] = useState<Broadcast[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [readIds, setReadIds] = useState<Set<string>>(new Set());

  useEffect(() => {
    const load = async () => {
      try {
        const res = await api<any>('/api/broadcasts');
        const list: Broadcast[] = Array.isArray(res) ? res : res.data ?? res.broadcasts ?? res.notifications ?? [];
        setNotifications(list);
      } catch (err: any) {
        setError(err.message || 'Failed to load notifications');
      } finally {
        setLoading(false);
      }
    };
    load();
  }, []);

  const markRead = (id: string) => setReadIds((s) => { const next = new Set(Array.from(s)); next.add(id); return next; });
  const markAllRead = () => setReadIds(new Set(notifications.map((n) => n.id)));

  const unreadCount = notifications.filter((n) => !readIds.has(n.id) && !n.read).length;

  return (
    <AppShell>
      <Head><title>Notifications — ClickerPro</title></Head>

      <div className="row" style={{ marginBottom: 4 }}>
        <h1 className="page-title" style={{ marginBottom: 0 }}>Notifications</h1>
        {unreadCount > 0 && (
          <span className="badge orange" style={{ marginLeft: 8 }}>{unreadCount} new</span>
        )}
      </div>
      <div className="row" style={{ marginBottom: 28 }}>
        <p className="page-sub" style={{ marginBottom: 0 }}>Updates and broadcasts</p>
        <div className="spacer" />
        {unreadCount > 0 && (
          <button className="btn ghost sm" onClick={markAllRead}>Mark all read</button>
        )}
      </div>

      {loading && <div className="empty">Loading…</div>}
      {error && <div className="error">{error}</div>}

      {!loading && !error && notifications.length === 0 && (
        <div className="panel">
          <div className="empty" style={{ padding: '80px 20px' }}>
            <div style={{ fontSize: 40, marginBottom: 16 }}>🔔</div>
            <div style={{ fontWeight: 500, color: 'var(--film-dim)', marginBottom: 8 }}>No notifications yet</div>
            <div>You&apos;re all caught up! Notifications will appear here.</div>
          </div>
        </div>
      )}

      {!loading && notifications.length > 0 && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
          {notifications.map((n) => {
            const isRead = readIds.has(n.id) || n.read;
            return (
              <div
                key={n.id}
                className="panel"
                style={{
                  borderRadius: 12,
                  borderColor: isRead ? 'rgba(255,98,0,0.08)' : 'rgba(255,98,0,0.25)',
                  background: isRead ? 'var(--surface-3)' : 'rgba(255,98,0,0.04)',
                  cursor: isRead ? 'default' : 'pointer',
                }}
                onClick={() => !isRead && markRead(n.id)}
              >
                <div style={{ padding: '16px 20px', display: 'flex', gap: 16, alignItems: 'flex-start' }}>
                  <div style={{
                    width: 40, height: 40, borderRadius: 10,
                    background: isRead ? 'var(--film-faint)' : 'rgba(255,98,0,0.15)',
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    fontSize: 18, flexShrink: 0,
                  }}>
                    {TYPE_ICONS[n.type || ''] || '🔔'}
                  </div>
                  <div style={{ flex: 1 }}>
                    {n.title && (
                      <div style={{
                        fontWeight: 600, fontSize: 14,
                        color: isRead ? 'var(--film-dim)' : 'var(--film)',
                        marginBottom: 4,
                      }}>
                        {n.title}
                      </div>
                    )}
                    <div style={{ fontSize: 13, color: isRead ? 'var(--film-muted)' : 'rgba(255,255,255,0.65)', lineHeight: 1.5 }}>
                      {n.message || n.body || 'No content'}
                    </div>
                    {n.createdAt && (
                      <div style={{
                        marginTop: 8,
                        fontFamily: "'JetBrains Mono', monospace",
                        fontSize: 10, color: 'var(--film-muted)',
                        letterSpacing: '0.05em',
                      }}>
                        {formatDate(n.createdAt)}
                      </div>
                    )}
                  </div>
                  {!isRead && (
                    <div style={{
                      width: 8, height: 8, borderRadius: '50%',
                      background: 'var(--orange)', flexShrink: 0, marginTop: 6,
                    }} />
                  )}
                </div>
              </div>
            );
          })}
        </div>
      )}
    </AppShell>
  );
}
