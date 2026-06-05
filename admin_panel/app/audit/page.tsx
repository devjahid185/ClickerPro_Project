'use client';

import { useEffect, useState, useCallback } from 'react';
import Shell from '@/components/Shell';
import { api } from '@/lib/api';

type AuditLog = {
  id: string;
  actorName: string;
  action: string;
  entityType: string;
  entityId: string;
  entityLabel: string | null;
  createdAt: string;
};

function actionBadge(action: string) {
  const a = action.toUpperCase();
  const cls =
    a === 'CREATE' ? 'green' : a === 'DELETE' ? 'red' : a === 'PERMISSION' ? 'gold' : 'teal';
  return <span className={`badge ${cls}`}>{a}</span>;
}

export default function AuditPage() {
  const [logs, setLogs] = useState<AuditLog[]>([]);
  const [offset, setOffset] = useState(0);
  const [err, setErr] = useState('');
  const limit = 100;

  const load = useCallback(async () => {
    setErr('');
    try {
      const r = await api<{ data: AuditLog[] }>(`/api/admin/audit?limit=${limit}&offset=${offset}`);
      setLogs(r.data);
    } catch (e: any) { setErr(e.message); }
  }, [offset]);

  useEffect(() => { load(); }, [load]);

  return (
    <Shell>
      <h1 className="page-title">Audit Log</h1>
      <p className="page-sub">Every create / update / delete across the platform</p>

      {err && <div className="error">{err}</div>}

      <div className="panel">
        <table>
          <thead>
            <tr>
              <th>When</th>
              <th>Actor</th>
              <th>Action</th>
              <th>Entity</th>
            </tr>
          </thead>
          <tbody>
            {logs.map((l) => (
              <tr key={l.id}>
                <td className="muted">{new Date(l.createdAt).toLocaleString()}</td>
                <td><strong>{l.actorName}</strong></td>
                <td>{actionBadge(l.action)}</td>
                <td>
                  {l.entityType}
                  {l.entityLabel && <span className="muted"> · {l.entityLabel}</span>}
                </td>
              </tr>
            ))}
            {logs.length === 0 && <tr><td colSpan={4} className="empty">No audit entries</td></tr>}
          </tbody>
        </table>
      </div>

      <div className="row" style={{ marginTop: 16, justifyContent: 'center' }}>
        <button
          className="btn secondary sm"
          disabled={offset === 0}
          onClick={() => setOffset(Math.max(0, offset - limit))}
        >
          ← Newer
        </button>
        <span className="muted">Showing {offset + 1}–{offset + logs.length}</span>
        <button
          className="btn secondary sm"
          disabled={logs.length < limit}
          onClick={() => setOffset(offset + limit)}
        >
          Older →
        </button>
      </div>
    </Shell>
  );
}
