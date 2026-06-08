import { useEffect, useState, useRef } from 'react';
import Link from 'next/link';
import AppShell from '@/components/AppShell';
import { api } from '@/lib/api';
import { tk } from '@/lib/format';

const fmtDate = (d: string) =>
  d ? new Date(d).toLocaleDateString('en-BD', { day: 'numeric', month: 'short', year: 'numeric' }) : '—';

function statusBadge(s: string) {
  const map: Record<string, string> = {
    PENDING: 'gold', CONFIRMED: 'teal', IN_PROGRESS: 'orange',
    SHOT_COMPLETE: 'blue', DELIVERED: 'purple', COMPLETED: 'green', CANCELLED: 'red',
  };
  return <span className={`badge ${map[s] || 'gray'}`}>{s.replace(/_/g, ' ')}</span>;
}

const initials = (name: string) =>
  (name || '?').split(' ').map((w) => w[0]).join('').slice(0, 2).toUpperCase();

export default function SearchPage() {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<{ bookings: any[]; clients: any[]; payments: any[] }>({ bookings: [], clients: [], payments: [] });
  const [loading, setLoading] = useState(false);
  const [searched, setSearched] = useState(false);
  const [error, setError] = useState('');
  const inputRef = useRef<HTMLInputElement>(null);
  const debounceRef = useRef<NodeJS.Timeout | null>(null);

  useEffect(() => { inputRef.current?.focus(); }, []);

  useEffect(() => {
    if (debounceRef.current) clearTimeout(debounceRef.current);
    if (!query.trim()) { setResults({ bookings: [], clients: [], payments: [] }); setSearched(false); return; }

    debounceRef.current = setTimeout(async () => {
      setLoading(true); setError(''); setSearched(false);
      try {
        const res = await api<any>(`/api/search?q=${encodeURIComponent(query)}`);
        setResults({
          bookings: Array.isArray(res?.bookings) ? res.bookings : [],
          clients: Array.isArray(res?.clients) ? res.clients : [],
          payments: Array.isArray(res?.payments) ? res.payments : [],
        });
        setSearched(true);
      } catch (e: any) { setError(e.message); }
      finally { setLoading(false); }
    }, 400);

    return () => { if (debounceRef.current) clearTimeout(debounceRef.current); };
  }, [query]);

  const getDate = (b: any) => b.date?.split('T')[0] || b.event_date?.split('T')[0] || '';
  const getName = (b: any) => b.clientName || b.client_name || b.client?.name || '—';

  const hasResults = results.bookings.length > 0 || results.clients.length > 0 || results.payments.length > 0;
  const totalCount = results.bookings.length + results.clients.length + results.payments.length;

  const Shimmer = () => (
    <div style={{ marginBottom: 24 }}>
      <div className="shimmer" style={{ height: 14, width: 100, borderRadius: 4, marginBottom: 12 }} />
      {[...Array(3)].map((_, i) => <div key={i} className="shimmer" style={{ height: 52, borderRadius: 6, marginBottom: 8 }} />)}
    </div>
  );

  return (
    <AppShell>
      <div style={{ padding: 24 }}>
        <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 24, marginBottom: 20 }}>Search</div>

        {/* Search Input */}
        <div style={{ position: 'relative', marginBottom: 28 }}>
          <input
            ref={inputRef}
            className="field"
            style={{ width: '100%', padding: '14px 48px 14px 16px', fontSize: 18, borderRadius: 8 }}
            placeholder="Search bookings, clients, payments..."
            value={query}
            onChange={(e) => setQuery(e.target.value)}
          />
          {loading && (
            <div style={{ position: 'absolute', right: 14, top: '50%', transform: 'translateY(-50%)', width: 18, height: 18, border: '2px solid var(--orange)', borderTopColor: 'transparent', borderRadius: '50%', animation: 'spin 0.6s linear infinite' }} />
          )}
          {!loading && query && (
            <button style={{ position: 'absolute', right: 14, top: '50%', transform: 'translateY(-50%)', background: 'none', border: 'none', cursor: 'pointer', color: 'var(--film-muted)', fontSize: 18 }} onClick={() => setQuery('')}>×</button>
          )}
        </div>

        {error && <div className="error" style={{ marginBottom: 12 }}>{error}</div>}

        {/* Empty state - no query */}
        {!query && !loading && (
          <div className="empty" style={{ paddingTop: 60 }}>
            <div style={{ fontSize: 48, marginBottom: 12 }}>⊘</div>
            <div>Start typing to search across all data</div>
          </div>
        )}

        {/* Loading skeletons */}
        {loading && (
          <div>
            <Shimmer />
            <Shimmer />
          </div>
        )}

        {/* No results */}
        {searched && !hasResults && !loading && (
          <div className="empty" style={{ paddingTop: 40 }}>
            <div style={{ marginBottom: 8 }}>No results for &ldquo;{query}&rdquo;</div>
            <div className="muted text-sm">Try different keywords or check the spelling</div>
          </div>
        )}

        {/* Results */}
        {searched && hasResults && !loading && (
          <>
            <div className="muted text-sm" style={{ marginBottom: 20 }}>
              {totalCount} result{totalCount !== 1 ? 's' : ''} for &ldquo;{query}&rdquo;
            </div>

            {/* Bookings */}
            {results.bookings.length > 0 && (
              <div style={{ marginBottom: 28 }}>
                <div className="row" style={{ gap: 8, marginBottom: 12 }}>
                  <span style={{ fontFamily: 'JetBrains Mono, monospace', fontSize: 11, textTransform: 'uppercase', letterSpacing: '0.08em', color: 'var(--film-muted)' }}>Bookings</span>
                  <span className="badge gray">{results.bookings.length}</span>
                </div>
                {results.bookings.map((b) => (
                  <Link key={b.id} href={`/app/bookings/${b.id}`} style={{ textDecoration: 'none', display: 'block' }}>
                    <div style={{ padding: '12px 16px', background: 'var(--surface-3)', borderRadius: 6, marginBottom: 8, borderLeft: '3px solid var(--orange)', transition: 'background 0.15s' }}>
                      <div className="row" style={{ justifyContent: 'space-between', marginBottom: 4 }}>
                        <span style={{ fontWeight: 700, fontSize: 15, color: 'var(--film)' }}>{b.title || b.eventType || 'Booking'}</span>
                        {statusBadge(b.status)}
                      </div>
                      <div className="row" style={{ gap: 12 }}>
                        <span className="muted text-sm">{getName(b)}</span>
                        <span className="muted text-sm">{fmtDate(getDate(b))}</span>
                        {b.price && <span style={{ fontSize: 12, color: 'var(--orange)' }}>{tk(Number(b.price))}</span>}
                      </div>
                    </div>
                  </Link>
                ))}
              </div>
            )}

            {/* Clients */}
            {results.clients.length > 0 && (
              <div style={{ marginBottom: 28 }}>
                <div className="row" style={{ gap: 8, marginBottom: 12 }}>
                  <span style={{ fontFamily: 'JetBrains Mono, monospace', fontSize: 11, textTransform: 'uppercase', letterSpacing: '0.08em', color: 'var(--film-muted)' }}>Clients</span>
                  <span className="badge gray">{results.clients.length}</span>
                </div>
                {results.clients.map((c) => (
                  <Link key={c.id} href={`/app/clients/${c.id}`} style={{ textDecoration: 'none', display: 'block' }}>
                    <div style={{ padding: '12px 16px', background: 'var(--surface-3)', borderRadius: 6, marginBottom: 8, borderLeft: '3px solid var(--blue)', transition: 'background 0.15s' }}>
                      <div className="row" style={{ gap: 12 }}>
                        <div className="avatar avatar-sm">{initials(c.name || '?')}</div>
                        <div style={{ flex: 1 }}>
                          <div style={{ fontWeight: 700, fontSize: 14, color: 'var(--film)' }}>{c.name}</div>
                          <div className="row" style={{ gap: 12, marginTop: 2 }}>
                            {c.phone && <span className="muted text-sm">{c.phone}</span>}
                            {c.email && <span className="muted text-sm">{c.email}</span>}
                          </div>
                        </div>
                      </div>
                    </div>
                  </Link>
                ))}
              </div>
            )}

            {/* Payments */}
            {results.payments.length > 0 && (
              <div style={{ marginBottom: 28 }}>
                <div className="row" style={{ gap: 8, marginBottom: 12 }}>
                  <span style={{ fontFamily: 'JetBrains Mono, monospace', fontSize: 11, textTransform: 'uppercase', letterSpacing: '0.08em', color: 'var(--film-muted)' }}>Payments</span>
                  <span className="badge gray">{results.payments.length}</span>
                </div>
                {results.payments.map((p: any, i: number) => (
                  <div key={p.id || i} style={{ padding: '12px 16px', background: 'var(--surface-3)', borderRadius: 6, marginBottom: 8, borderLeft: '3px solid var(--green)' }}>
                    <div className="row" style={{ justifyContent: 'space-between' }}>
                      <div>
                        <div className="row" style={{ gap: 8, marginBottom: 4 }}>
                          <span className="badge teal">{p.kind}</span>
                          <span className="badge gray">{p.method}</span>
                        </div>
                        <div className="muted text-sm">{p.booking?.title || p.bookingId || '—'} · {fmtDate(p.createdAt || p.paid_at)}</div>
                      </div>
                      <div style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 24, color: 'var(--green)' }}>{tk(Number(p.amount) || 0)}</div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </>
        )}
      </div>

      <style>{`
        @keyframes spin { to { transform: translateY(-50%) rotate(360deg); } }
      `}</style>
    </AppShell>
  );
}
