'use client';

import { useEffect, useState, useCallback } from 'react';
import Shell from '@/components/Shell';
import { api } from '@/lib/api';

type Setting = { key: string; value: string; isSecret: boolean; hasValue: boolean };
type Grouped = Record<string, Setting[]>;

const GROUP_LABELS: Record<string, string> = {
  general: 'General',
  branding: 'Branding (theme color, logo, banner)',
  smtp: 'SMTP / Email',
  gateway: 'Payment Gateway',
  social: 'Social Media',
};

// Friendly field label from a key like "smtp.fromEmail" → "From Email"
function fieldLabel(key: string) {
  const last = key.split('.').pop() || key;
  return last.replace(/([A-Z])/g, ' $1').replace(/^./, (c) => c.toUpperCase());
}

export default function SettingsPage() {
  const [groups, setGroups] = useState<Grouped>({});
  const [edits, setEdits] = useState<Record<string, string>>({});
  const [err, setErr] = useState('');
  const [msg, setMsg] = useState('');
  const [saving, setSaving] = useState(false);

  const load = useCallback(async () => {
    setErr('');
    try {
      const r = await api<{ data: Grouped }>('/api/admin/settings');
      setGroups(r.data);
      const seed: Record<string, string> = {};
      Object.values(r.data).flat().forEach((s) => { seed[s.key] = s.value; });
      setEdits(seed);
    } catch (e: any) { setErr(e.message); }
  }, []);

  useEffect(() => { load(); }, [load]);

  const save = async () => {
    setSaving(true);
    setErr(''); setMsg('');
    try {
      await api('/api/admin/settings', { method: 'PUT', body: { settings: edits } });
      setMsg('Settings saved');
      load();
    } catch (e: any) { setErr(e.message); }
    finally { setSaving(false); }
  };

  return (
    <Shell>
      <div className="row" style={{ marginBottom: 24 }}>
        <div>
          <h1 className="page-title">Settings</h1>
          <p className="page-sub" style={{ margin: 0 }}>Platform configuration</p>
        </div>
        <div className="spacer" />
        <button className="btn" onClick={save} disabled={saving}>
          {saving ? 'Saving…' : 'Save changes'}
        </button>
      </div>

      {err && <div className="error">{err}</div>}
      {msg && <div style={{ color: 'var(--green)', marginBottom: 12, fontWeight: 600 }}>{msg}</div>}

      {Object.entries(groups).map(([group, items]) => (
        <div className="panel" key={group} style={{ padding: 20, marginBottom: 20 }}>
          <h3 style={{ marginBottom: 16 }}>{GROUP_LABELS[group] || group}</h3>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
            {items.map((s) => (
              <div className="field" key={s.key} style={{ margin: 0 }}>
                <label>{fieldLabel(s.key)} {s.isSecret && <span className="muted">(secret)</span>}</label>
                <input
                  type={s.isSecret ? 'password' : 'text'}
                  value={edits[s.key] ?? ''}
                  placeholder={s.isSecret && s.hasValue ? '•••••• (set)' : ''}
                  onChange={(e) => setEdits((p) => ({ ...p, [s.key]: e.target.value }))}
                />
              </div>
            ))}
          </div>
        </div>
      ))}
    </Shell>
  );
}
