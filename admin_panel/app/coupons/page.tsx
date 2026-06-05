'use client';

import { useEffect, useState, useCallback } from 'react';
import Shell from '@/components/Shell';
import { api } from '@/lib/api';

type Coupon = {
  id: string;
  code: string;
  description: string | null;
  discountType: string;
  discountValue: number;
  maxRedemptions: number | null;
  redeemedCount: number;
  expiresAt: string | null;
  active: boolean;
};

function discountLabel(c: Coupon) {
  if (c.discountType === 'PERCENT') return `${c.discountValue}% off`;
  if (c.discountType === 'FLAT') return `৳${c.discountValue} off`;
  if (c.discountType === 'PRO_DAYS') return `${c.discountValue} PRO days`;
  return `${c.discountValue}`;
}

export default function CouponsPage() {
  const [items, setItems] = useState<Coupon[]>([]);
  const [err, setErr] = useState('');
  const [showNew, setShowNew] = useState(false);

  const load = useCallback(async () => {
    setErr('');
    try {
      const r = await api<{ data: Coupon[] }>('/api/admin/coupons');
      setItems(r.data);
    } catch (e: any) { setErr(e.message); }
  }, []);

  useEffect(() => { load(); }, [load]);

  const toggle = async (c: Coupon) => {
    try {
      await api(`/api/admin/coupons/${c.id}`, { method: 'PATCH', body: { active: !c.active } });
      load();
    } catch (e: any) { alert(e.message); }
  };

  const remove = async (c: Coupon) => {
    if (!confirm(`Delete coupon ${c.code}?`)) return;
    try {
      await api(`/api/admin/coupons/${c.id}`, { method: 'DELETE' });
      load();
    } catch (e: any) { alert(e.message); }
  };

  return (
    <Shell>
      <div className="row" style={{ marginBottom: 24 }}>
        <div>
          <h1 className="page-title">Coupons</h1>
          <p className="page-sub" style={{ margin: 0 }}>Promo & discount codes</p>
        </div>
        <div className="spacer" />
        <button className="btn" onClick={() => setShowNew(true)}>+ New coupon</button>
      </div>

      {err && <div className="error">{err}</div>}

      <div className="panel">
        <table>
          <thead>
            <tr><th>Code</th><th>Discount</th><th>Used</th><th>Expires</th><th>Status</th><th></th></tr>
          </thead>
          <tbody>
            {items.map((c) => (
              <tr key={c.id}>
                <td><strong>{c.code}</strong>{c.description && <div className="muted">{c.description}</div>}</td>
                <td><span className="badge gold">{discountLabel(c)}</span></td>
                <td>{c.redeemedCount}{c.maxRedemptions != null ? ` / ${c.maxRedemptions}` : ''}</td>
                <td>{c.expiresAt ? new Date(c.expiresAt).toLocaleDateString() : '—'}</td>
                <td><span className={`badge ${c.active ? 'green' : 'gray'}`}>{c.active ? 'Active' : 'Inactive'}</span></td>
                <td>
                  <div className="row">
                    <button className="btn sm secondary" onClick={() => toggle(c)}>{c.active ? 'Disable' : 'Enable'}</button>
                    <button className="btn sm danger" onClick={() => remove(c)}>Delete</button>
                  </div>
                </td>
              </tr>
            ))}
            {items.length === 0 && <tr><td colSpan={6} className="empty">No coupons yet</td></tr>}
          </tbody>
        </table>
      </div>

      {showNew && <NewCouponModal onClose={() => setShowNew(false)} onDone={load} />}
    </Shell>
  );
}

function NewCouponModal({ onClose, onDone }: { onClose: () => void; onDone: () => void }) {
  const [code, setCode] = useState('');
  const [description, setDescription] = useState('');
  const [discountType, setDiscountType] = useState('PERCENT');
  const [discountValue, setDiscountValue] = useState('10');
  const [maxRedemptions, setMaxRedemptions] = useState('');
  const [expiresAt, setExpiresAt] = useState('');
  const [err, setErr] = useState('');
  const [saving, setSaving] = useState(false);

  const save = async () => {
    setSaving(true); setErr('');
    try {
      await api('/api/admin/coupons', {
        method: 'POST',
        body: {
          code: code.trim(),
          description: description.trim() || null,
          discountType,
          discountValue: Number(discountValue),
          maxRedemptions: maxRedemptions ? Number(maxRedemptions) : null,
          expiresAt: expiresAt || null,
        },
      });
      onDone(); onClose();
    } catch (e: any) { setErr(e.message); setSaving(false); }
  };

  return (
    <div className="modal-backdrop" onClick={onClose}>
      <div className="modal" onClick={(e) => e.stopPropagation()}>
        <h2>New coupon</h2>
        <div className="field"><label>Code</label><input value={code} onChange={(e) => setCode(e.target.value.toUpperCase())} placeholder="WELCOME10" /></div>
        <div className="field"><label>Description</label><input value={description} onChange={(e) => setDescription(e.target.value)} /></div>
        <div className="row">
          <div className="field" style={{ flex: 1 }}>
            <label>Type</label>
            <select value={discountType} onChange={(e) => setDiscountType(e.target.value)}>
              <option value="PERCENT">Percent off</option>
              <option value="FLAT">Flat (৳) off</option>
              <option value="PRO_DAYS">PRO days</option>
            </select>
          </div>
          <div className="field" style={{ flex: 1 }}>
            <label>Value</label>
            <input type="number" value={discountValue} onChange={(e) => setDiscountValue(e.target.value)} />
          </div>
        </div>
        <div className="row">
          <div className="field" style={{ flex: 1 }}>
            <label>Max redemptions</label>
            <input type="number" value={maxRedemptions} onChange={(e) => setMaxRedemptions(e.target.value)} placeholder="∞" />
          </div>
          <div className="field" style={{ flex: 1 }}>
            <label>Expires</label>
            <input type="date" value={expiresAt} onChange={(e) => setExpiresAt(e.target.value)} />
          </div>
        </div>
        {err && <div className="error">{err}</div>}
        <div className="row" style={{ marginTop: 18, justifyContent: 'flex-end' }}>
          <button className="btn secondary" onClick={onClose}>Cancel</button>
          <button className="btn" onClick={save} disabled={saving || !code}>{saving ? 'Creating…' : 'Create'}</button>
        </div>
      </div>
    </div>
  );
}
