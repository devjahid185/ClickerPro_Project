'use client';

import { useEffect, useState, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import Shell from '@/components/Shell';
import { api, downloadFile } from '@/lib/api';

type User = {
  id: string;
  email: string;
  fullName: string;
  phone: string | null;
  role: string;
  plan: string;
  planExpiresAt: string | null;
  businessName: string | null;
  totalEvents: number;
  deletedAt: string | null;
  createdAt: string;
};

const ROLES = ['OWNER', 'FREELANCER', 'BOTH', 'MANAGER', 'ADMIN'];

export default function UsersPage() {
  const router = useRouter();
  const [users, setUsers] = useState<User[]>([]);
  const [total, setTotal] = useState(0);
  const [search, setSearch] = useState('');
  const [role, setRole] = useState('');
  const [err, setErr] = useState('');
  const [showCreate, setShowCreate] = useState(false);

  const load = useCallback(async () => {
    setErr('');
    const params = new URLSearchParams();
    if (search) params.set('search', search);
    if (role) params.set('role', role);
    try {
      const r = await api<{ data: User[]; total: number }>(`/api/admin/users?${params}`);
      setUsers(r.data);
      setTotal(r.total);
    } catch (e: any) {
      setErr(e.message);
    }
  }, [search, role]);

  useEffect(() => {
    const t = setTimeout(load, 300);
    return () => clearTimeout(t);
  }, [load]);

  const changeRole = async (u: User, newRole: string) => {
    try {
      await api(`/api/admin/users/${u.id}/role`, { method: 'PATCH', body: { role: newRole } });
      load();
    } catch (e: any) {
      alert(e.message);
    }
  };

  const toggleSuspend = async (u: User) => {
    const suspended = !u.deletedAt;
    if (!confirm(`${suspended ? 'Suspend' : 'Reactivate'} ${u.email}?`)) return;
    try {
      await api(`/api/admin/users/${u.id}/suspend`, { method: 'PATCH', body: { suspended } });
      load();
    } catch (e: any) {
      alert(e.message);
    }
  };

  const togglePlan = async (u: User) => {
    const plan = u.plan === 'PRO' ? 'FREE' : 'PRO';
    try {
      await api(`/api/admin/users/${u.id}/plan`, { method: 'PATCH', body: { plan } });
      load();
    } catch (e: any) {
      alert(e.message);
    }
  };

  return (
    <Shell>
      <h1 className="page-title">Users</h1>
      <p className="page-sub">{total} accounts</p>

      <div className="toolbar">
        <input
          placeholder="Search name, email, business…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
        <select value={role} onChange={(e) => setRole(e.target.value)}>
          <option value="">All roles</option>
          {ROLES.map((r) => (
            <option key={r} value={r}>{r}</option>
          ))}
        </select>
        <div className="spacer" />
        <button
          className="btn secondary"
          onClick={() => downloadFile('/api/admin/export/users.csv', 'users.csv').catch((e) => alert(e.message))}
        >
          ⬇ Export CSV
        </button>
        <button className="btn" onClick={() => setShowCreate(true)}>+ New user</button>
      </div>

      {err && <div className="error">{err}</div>}

      <div className="panel">
        <table>
          <thead>
            <tr>
              <th>Name</th>
              <th>Email</th>
              <th>Role</th>
              <th>Plan</th>
              <th>Status</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {users.map((u) => (
              <tr key={u.id}>
                <td
                  onClick={() => router.push(`/users/${u.id}`)}
                  style={{ cursor: 'pointer' }}
                >
                  <strong style={{ color: 'var(--orange)' }}>{u.fullName}</strong>
                  {u.businessName && <div className="muted">{u.businessName}</div>}
                </td>
                <td>{u.email}</td>
                <td>
                  <select
                    value={u.role.toUpperCase()}
                    onChange={(e) => changeRole(u, e.target.value)}
                    style={{ width: 130 }}
                  >
                    {ROLES.map((r) => (
                      <option key={r} value={r}>{r}</option>
                    ))}
                  </select>
                </td>
                <td>
                  <span className={`badge ${u.plan === 'PRO' ? 'gold' : 'gray'}`}>{u.plan}</span>
                </td>
                <td>
                  {u.deletedAt ? (
                    <span className="badge red">Suspended</span>
                  ) : (
                    <span className="badge green">Active</span>
                  )}
                </td>
                <td>
                  <div className="row">
                    <button className="btn sm secondary" onClick={() => togglePlan(u)}>
                      {u.plan === 'PRO' ? 'Downgrade' : 'Make PRO'}
                    </button>
                    <button className="btn sm secondary" onClick={() => toggleSuspend(u)}>
                      {u.deletedAt ? 'Reactivate' : 'Suspend'}
                    </button>
                  </div>
                </td>
              </tr>
            ))}
            {users.length === 0 && (
              <tr>
                <td colSpan={6} className="empty">No users found</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {showCreate && <CreateUserModal onClose={() => setShowCreate(false)} onDone={load} />}
    </Shell>
  );
}

function CreateUserModal({ onClose, onDone }: { onClose: () => void; onDone: () => void }) {
  const [email, setEmail] = useState('');
  const [fullName, setFullName] = useState('');
  const [password, setPassword] = useState('');
  const [role, setRole] = useState('OWNER');
  const [err, setErr] = useState('');
  const [saving, setSaving] = useState(false);

  const save = async () => {
    setSaving(true);
    setErr('');
    try {
      await api('/api/admin/users', {
        method: 'POST',
        body: { email: email.trim(), fullName: fullName.trim(), password, role },
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
        <h2>New user</h2>
        <div className="field">
          <label>Full name</label>
          <input value={fullName} onChange={(e) => setFullName(e.target.value)} />
        </div>
        <div className="field">
          <label>Email</label>
          <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} />
        </div>
        <div className="field">
          <label>Password</label>
          <input type="text" value={password} onChange={(e) => setPassword(e.target.value)} />
        </div>
        <div className="field">
          <label>Role</label>
          <select value={role} onChange={(e) => setRole(e.target.value)}>
            {ROLES.map((r) => (
              <option key={r} value={r}>{r}</option>
            ))}
          </select>
        </div>
        {err && <div className="error">{err}</div>}
        <div className="row" style={{ marginTop: 18, justifyContent: 'flex-end' }}>
          <button className="btn secondary" onClick={onClose}>Cancel</button>
          <button className="btn" onClick={save} disabled={saving || !email || !password || !fullName}>
            {saving ? 'Creating…' : 'Create'}
          </button>
        </div>
      </div>
    </div>
  );
}
