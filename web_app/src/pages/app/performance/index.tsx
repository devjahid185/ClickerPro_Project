import { useEffect, useState } from 'react';
import AppShell from '@/components/AppShell';
import { api } from '@/lib/api';
import { tk } from '@/lib/format';

type Row = {
  userId: string;
  name: string;
  role: string;
  totalEvents: number;
  totalEarnings: number;
  pendingReEdits: number;
  performanceScore: number;
};

const ROLE_COLORS: Record<string, string> = {
  PHOTOGRAPHER: 'orange', VIDEOGRAPHER: 'teal', CINEMATOGRAPHER: 'teal',
  EDITOR: 'purple', FREELANCER: 'blue', MANAGER: 'gold', OWNER: 'gold', BOTH: 'green',
};

const initials = (name: string) =>
  (name || '?').split(' ').map((w) => w[0]).join('').slice(0, 2).toUpperCase();

/** Team Performance — events, earnings, pending re-edits and a score per member. */
export default function PerformancePage() {
  const [rows, setRows] = useState<Row[]>([]);
  const [year, setYear] = useState(0); // 0 = all time
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const thisYear = new Date().getFullYear();

  const load = async (y: number) => {
    setLoading(true); setError('');
    try {
      const res = await api<any>(`/api/reports/team-performance${y ? `?year=${y}` : ''}`);
      const d = res?.data ?? res;
      setRows(d?.teamPerformance ?? []);
    } catch (e: any) { setError(e.message); }
    finally { setLoading(false); }
  };

  useEffect(() => { load(year); }, [year]);

  const maxScore = Math.max(1, ...rows.map((r) => r.performanceScore));

  return (
    <AppShell>
      <div style={{ padding: 24 }}>
        <div className="toolbar" style={{ marginBottom: 20 }}>
          <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 24 }}>Team Performance</div>
          <span className="spacer" />
          <select className="input" value={year} onChange={(e) => setYear(Number(e.target.value))} style={{ width: 140 }}>
            <option value={0}>All time</option>
            <option value={thisYear}>{thisYear}</option>
            <option value={thisYear - 1}>{thisYear - 1}</option>
          </select>
        </div>

        {error && <div className="error" style={{ marginBottom: 12 }}>{error}</div>}
        {loading && <div className="shimmer" style={{ height: 220, borderRadius: 8 }} />}
        {!loading && rows.length === 0 && <div className="empty">No assignment data yet — add team members to bookings first.</div>}

        {!loading && rows.length > 0 && (
          <div className="panel">
            <table style={{ width: '100%', borderCollapse: 'collapse' }}>
              <thead>
                <tr style={{ borderBottom: '2px solid var(--surface-3)' }}>
                  {['#', 'Member', 'Role', 'Events', 'Earnings', 'Pending Re-edits', 'Score'].map((h) => (
                    <th key={h} style={{ textAlign: 'left', padding: '10px 12px', fontSize: 11, fontFamily: 'JetBrains Mono, monospace', color: 'var(--film-muted)', textTransform: 'uppercase' }}>{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {rows.map((r, i) => (
                  <tr key={r.userId} style={{ borderBottom: '1px solid var(--surface-3)' }}>
                    <td style={{ padding: '12px', fontFamily: 'Bebas Neue, sans-serif', fontSize: 18, color: i === 0 ? 'var(--orange)' : 'var(--film-muted)' }}>
                      {i + 1}{i === 0 ? ' 🏆' : ''}
                    </td>
                    <td style={{ padding: '12px' }}>
                      <div className="row" style={{ gap: 10 }}>
                        <div className="avatar avatar-sm">{initials(r.name)}</div>
                        <span style={{ fontWeight: 600 }}>{r.name}</span>
                      </div>
                    </td>
                    <td style={{ padding: '12px' }}>
                      <span className={`badge ${ROLE_COLORS[r.role?.toUpperCase()] || 'gray'}`}>{r.role}</span>
                    </td>
                    <td style={{ padding: '12px', fontFamily: 'Bebas Neue, sans-serif', fontSize: 18 }}>{r.totalEvents}</td>
                    <td style={{ padding: '12px', color: 'var(--orange)', fontFamily: 'Bebas Neue, sans-serif', fontSize: 18 }}>{tk(r.totalEarnings)}</td>
                    <td style={{ padding: '12px' }}>
                      {r.pendingReEdits > 0
                        ? <span className="badge red">{r.pendingReEdits}</span>
                        : <span className="muted">0</span>}
                    </td>
                    <td style={{ padding: '12px', minWidth: 160 }}>
                      <div className="row" style={{ gap: 8, alignItems: 'center' }}>
                        <div style={{ flex: 1, height: 6, background: 'var(--surface-3)', borderRadius: 3, overflow: 'hidden' }}>
                          <div style={{ width: `${Math.max(4, (r.performanceScore / maxScore) * 100)}%`, height: '100%', background: 'var(--orange)' }} />
                        </div>
                        <span style={{ fontFamily: 'JetBrains Mono, monospace', fontSize: 13 }}>{r.performanceScore}</span>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </AppShell>
  );
}
