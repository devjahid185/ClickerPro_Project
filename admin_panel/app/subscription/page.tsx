'use client';

import { useEffect, useState, useCallback } from 'react';
import Shell from '@/components/Shell';
import { api } from '@/lib/api';

type Feature = {
  id: string;
  key: string;
  label: string;
  description: string | null;
  requiresPro: boolean;
};

export default function SubscriptionPage() {
  const [features, setFeatures] = useState<Feature[]>([]);
  const [err, setErr] = useState('');
  const [busy, setBusy] = useState<string | null>(null);

  const load = useCallback(async () => {
    setErr('');
    try {
      const r = await api<{ data: Feature[] }>('/api/admin/features');
      setFeatures(r.data);
    } catch (e: any) { setErr(e.message); }
  }, []);

  useEffect(() => { load(); }, [load]);

  const toggle = async (f: Feature) => {
    setBusy(f.key);
    try {
      await api(`/api/admin/features/${f.key}`, {
        method: 'PATCH',
        body: { requiresPro: !f.requiresPro },
      });
      setFeatures((prev) =>
        prev.map((x) => (x.key === f.key ? { ...x, requiresPro: !x.requiresPro } : x))
      );
    } catch (e: any) {
      alert(e.message);
    } finally {
      setBusy(null);
    }
  };

  const paidCount = features.filter((f) => f.requiresPro).length;

  return (
    <Shell>
      <h1 className="page-title">Subscription & Features</h1>
      <p className="page-sub">
        Toggle which features require a PRO plan. {paidCount === 0
          ? 'Everything is free right now.'
          : `${paidCount} feature${paidCount > 1 ? 's' : ''} marked PRO-only.`}
      </p>

      {err && <div className="error">{err}</div>}

      <div className="panel">
        <table>
          <thead>
            <tr>
              <th>Feature</th>
              <th>Access</th>
              <th style={{ width: 140 }}></th>
            </tr>
          </thead>
          <tbody>
            {features.map((f) => (
              <tr key={f.key}>
                <td>
                  <strong>{f.label}</strong>
                  {f.description && <div className="muted">{f.description}</div>}
                </td>
                <td>
                  {f.requiresPro ? (
                    <span className="badge gold">PRO only</span>
                  ) : (
                    <span className="badge green">Free</span>
                  )}
                </td>
                <td>
                  <button
                    className={`btn sm ${f.requiresPro ? 'secondary' : ''}`}
                    onClick={() => toggle(f)}
                    disabled={busy === f.key}
                  >
                    {busy === f.key
                      ? '…'
                      : f.requiresPro
                      ? 'Make free'
                      : 'Make PRO'}
                  </button>
                </td>
              </tr>
            ))}
            {features.length === 0 && (
              <tr><td colSpan={3} className="empty">No feature flags. Run seedFeatures.js.</td></tr>
            )}
          </tbody>
        </table>
      </div>

      <p className="muted" style={{ marginTop: 16 }}>
        💡 Grant individual users a PRO plan from the <strong>Users</strong> page.
      </p>
    </Shell>
  );
}
