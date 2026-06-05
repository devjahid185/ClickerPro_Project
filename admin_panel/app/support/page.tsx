'use client';

import { useEffect, useState, useCallback } from 'react';
import Shell from '@/components/Shell';
import { api } from '@/lib/api';

type Ticket = {
  id: string;
  userId: string;
  subject: string;
  message: string;
  priority: string;
  status: string;
  createdAt: string;
};

type Faq = {
  id: string;
  question: string;
  answer: string;
  category: string;
  order: number;
};

const TICKET_STATUSES = ['OPEN', 'IN_PROGRESS', 'CLOSED'];

export default function SupportPage() {
  const [tab, setTab] = useState<'tickets' | 'faq'>('tickets');
  return (
    <Shell>
      <h1 className="page-title">Support & FAQ</h1>
      <div className="toolbar">
        <button
          className={`btn ${tab === 'tickets' ? '' : 'secondary'}`}
          onClick={() => setTab('tickets')}
        >
          Tickets
        </button>
        <button
          className={`btn ${tab === 'faq' ? '' : 'secondary'}`}
          onClick={() => setTab('faq')}
        >
          FAQ
        </button>
      </div>
      {tab === 'tickets' ? <Tickets /> : <Faqs />}
    </Shell>
  );
}

function Tickets() {
  const [items, setItems] = useState<Ticket[]>([]);
  const [filter, setFilter] = useState('');
  const [err, setErr] = useState('');

  const load = useCallback(async () => {
    setErr('');
    const q = filter ? `?status=${filter}` : '';
    try {
      const r = await api<{ data: Ticket[] }>(`/api/admin/tickets${q}`);
      setItems(r.data);
    } catch (e: any) { setErr(e.message); }
  }, [filter]);

  useEffect(() => { load(); }, [load]);

  const setStatus = async (t: Ticket, status: string) => {
    try {
      await api(`/api/admin/tickets/${t.id}`, { method: 'PATCH', body: { status } });
      load();
    } catch (e: any) { alert(e.message); }
  };

  return (
    <>
      <div className="toolbar">
        <select value={filter} onChange={(e) => setFilter(e.target.value)}>
          <option value="">All statuses</option>
          {TICKET_STATUSES.map((s) => <option key={s} value={s}>{s}</option>)}
        </select>
      </div>
      {err && <div className="error">{err}</div>}
      <div className="panel">
        <table>
          <thead>
            <tr><th>Subject</th><th>Priority</th><th>Status</th><th></th></tr>
          </thead>
          <tbody>
            {items.map((t) => (
              <tr key={t.id}>
                <td>
                  <strong>{t.subject}</strong>
                  <div className="muted">{t.message.slice(0, 70)}{t.message.length > 70 ? '…' : ''}</div>
                </td>
                <td><span className="badge gold">{t.priority}</span></td>
                <td>
                  <span className={`badge ${t.status === 'OPEN' ? 'orange' : t.status === 'CLOSED' ? 'gray' : 'teal'}`}>
                    {t.status}
                  </span>
                </td>
                <td>
                  <select value={t.status} onChange={(e) => setStatus(t, e.target.value)} style={{ width: 150 }}>
                    {TICKET_STATUSES.map((s) => <option key={s} value={s}>{s}</option>)}
                  </select>
                </td>
              </tr>
            ))}
            {items.length === 0 && <tr><td colSpan={4} className="empty">No tickets</td></tr>}
          </tbody>
        </table>
      </div>
    </>
  );
}

function Faqs() {
  const [items, setItems] = useState<Faq[]>([]);
  const [err, setErr] = useState('');
  const [showNew, setShowNew] = useState(false);

  const load = useCallback(async () => {
    setErr('');
    try {
      const r = await api<{ data: Faq[] }>('/api/admin/faqs');
      setItems(r.data);
    } catch (e: any) { setErr(e.message); }
  }, []);

  useEffect(() => { load(); }, [load]);

  const remove = async (f: Faq) => {
    if (!confirm(`Delete "${f.question}"?`)) return;
    try {
      await api(`/api/admin/faqs/${f.id}`, { method: 'DELETE' });
      load();
    } catch (e: any) { alert(e.message); }
  };

  return (
    <>
      <div className="toolbar">
        <div className="spacer" />
        <button className="btn" onClick={() => setShowNew(true)}>+ New FAQ</button>
      </div>
      {err && <div className="error">{err}</div>}
      <div className="panel">
        <table>
          <thead>
            <tr><th>Question</th><th>Category</th><th>Order</th><th></th></tr>
          </thead>
          <tbody>
            {items.map((f) => (
              <tr key={f.id}>
                <td>
                  <strong>{f.question}</strong>
                  <div className="muted">{f.answer.slice(0, 70)}{f.answer.length > 70 ? '…' : ''}</div>
                </td>
                <td><span className="badge teal">{f.category}</span></td>
                <td>{f.order}</td>
                <td><button className="btn sm danger" onClick={() => remove(f)}>Delete</button></td>
              </tr>
            ))}
            {items.length === 0 && <tr><td colSpan={4} className="empty">No FAQs yet</td></tr>}
          </tbody>
        </table>
      </div>
      {showNew && <NewFaqModal onClose={() => setShowNew(false)} onDone={load} />}
    </>
  );
}

function NewFaqModal({ onClose, onDone }: { onClose: () => void; onDone: () => void }) {
  const [question, setQuestion] = useState('');
  const [answer, setAnswer] = useState('');
  const [category, setCategory] = useState('General');
  const [order, setOrder] = useState('0');
  const [err, setErr] = useState('');
  const [saving, setSaving] = useState(false);

  const save = async () => {
    setSaving(true);
    setErr('');
    try {
      await api('/api/admin/faqs', {
        method: 'POST',
        body: { question: question.trim(), answer: answer.trim(), category, order: Number(order) },
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
        <h2>New FAQ</h2>
        <div className="field">
          <label>Question</label>
          <input value={question} onChange={(e) => setQuestion(e.target.value)} />
        </div>
        <div className="field">
          <label>Answer</label>
          <textarea rows={4} value={answer} onChange={(e) => setAnswer(e.target.value)} />
        </div>
        <div className="row">
          <div className="field" style={{ flex: 2 }}>
            <label>Category</label>
            <input value={category} onChange={(e) => setCategory(e.target.value)} />
          </div>
          <div className="field" style={{ flex: 1 }}>
            <label>Order</label>
            <input type="number" value={order} onChange={(e) => setOrder(e.target.value)} />
          </div>
        </div>
        {err && <div className="error">{err}</div>}
        <div className="row" style={{ marginTop: 18, justifyContent: 'flex-end' }}>
          <button className="btn secondary" onClick={onClose}>Cancel</button>
          <button className="btn" onClick={save} disabled={saving || !question || !answer}>
            {saving ? 'Saving…' : 'Save'}
          </button>
        </div>
      </div>
    </div>
  );
}
