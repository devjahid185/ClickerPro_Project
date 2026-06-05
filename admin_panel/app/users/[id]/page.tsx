'use client';

import { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import Shell from '@/components/Shell';
import { api } from '@/lib/api';

type Detail = {
  user: {
    id: string;
    email: string;
    fullName: string;
    phone: string | null;
    whatsapp: string | null;
    role: string;
    plan: string;
    businessName: string | null;
    businessAddress: string | null;
    createdAt: string;
  };
  stats: {
    bookings: number;
    clients: number;
    paymentsCount: number;
    paymentsTotal: number;
  };
  bookings: {
    id: string;
    title: string;
    type: string;
    date: string;
    status: string;
    venue: string;
    client: { name: string } | null;
  }[];
};

function statusBadge(s: string) {
  const map: Record<string, string> = {
    PENDING: 'gold',
    CONFIRMED: 'teal',
    IN_PROGRESS: 'orange',
    SHOT_COMPLETE: 'teal',
    DELIVERED: 'green',
    COMPLETED: 'green',
    CANCELLED: 'red',
  };
  return <span className={`badge ${map[s] || 'gray'}`}>{s}</span>;
}

export default function UserDetailPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const [data, setData] = useState<Detail | null>(null);
  const [err, setErr] = useState('');

  useEffect(() => {
    api<{ data: Detail }>(`/api/admin/users/${id}`)
      .then((r) => setData(r.data))
      .catch((e) => setErr(e.message));
  }, [id]);

  return (
    <Shell>
      <button className="btn secondary sm" onClick={() => router.push('/users')} style={{ marginBottom: 16 }}>
        ← Back to users
      </button>

      {err && <div className="error">{err}</div>}
      {!data && !err && <p className="muted">Loading…</p>}

      {data && (
        <>
          <div className="row" style={{ alignItems: 'flex-start', marginBottom: 8 }}>
            <div>
              <h1 className="page-title">{data.user.fullName}</h1>
              <p className="page-sub" style={{ margin: 0 }}>{data.user.email}</p>
            </div>
            <div className="spacer" />
            <span className={`badge ${data.user.role.toUpperCase() === 'ADMIN' ? 'red' : 'orange'}`}>
              {data.user.role.toUpperCase()}
            </span>
            <span className={`badge ${data.user.plan === 'PRO' ? 'gold' : 'gray'}`} style={{ marginLeft: 8 }}>
              {data.user.plan}
            </span>
          </div>

          {/* Contact / business */}
          <div className="panel" style={{ padding: 18, marginBottom: 20 }}>
            <div className="cards" style={{ gridTemplateColumns: 'repeat(auto-fill, minmax(220px,1fr))' }}>
              <Info label="Phone" value={data.user.phone || '—'} />
              <Info label="WhatsApp" value={data.user.whatsapp || '—'} />
              <Info label="Business" value={data.user.businessName || '—'} />
              <Info label="Address" value={data.user.businessAddress || '—'} />
              <Info label="Joined" value={new Date(data.user.createdAt).toLocaleDateString()} />
            </div>
          </div>

          {/* Stat cards */}
          <div className="cards" style={{ marginBottom: 24 }}>
            <Stat label="Bookings" value={data.stats.bookings} />
            <Stat label="Clients" value={data.stats.clients} />
            <Stat label="Payments" value={data.stats.paymentsCount} />
            <Stat label="Payment total" value={`৳${data.stats.paymentsTotal.toLocaleString()}`} />
          </div>

          {/* Bookings */}
          <h2 style={{ marginBottom: 12 }}>Recent bookings</h2>
          <div className="panel">
            <table>
              <thead>
                <tr><th>Title</th><th>Client</th><th>Date</th><th>Venue</th><th>Status</th></tr>
              </thead>
              <tbody>
                {data.bookings.map((b) => (
                  <tr key={b.id}>
                    <td><strong>{b.title}</strong><div className="muted">{b.type}</div></td>
                    <td>{b.client?.name || '—'}</td>
                    <td>{new Date(b.date).toLocaleDateString()}</td>
                    <td>{b.venue}</td>
                    <td>{statusBadge(b.status)}</td>
                  </tr>
                ))}
                {data.bookings.length === 0 && (
                  <tr><td colSpan={5} className="empty">No bookings</td></tr>
                )}
              </tbody>
            </table>
          </div>
        </>
      )}
    </Shell>
  );
}

function Info({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <div className="label" style={{ fontSize: 11, color: 'var(--film-dim)', fontWeight: 600, textTransform: 'uppercase' }}>{label}</div>
      <div style={{ fontWeight: 600, marginTop: 2 }}>{value}</div>
    </div>
  );
}

function Stat({ label, value }: { label: string; value: string | number }) {
  return (
    <div className="card">
      <div className="label">{label}</div>
      <div className="value">{value}</div>
    </div>
  );
}
