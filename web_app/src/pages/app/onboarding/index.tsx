import { useEffect, useState } from 'react';
import Link from 'next/link';
import AppShell from '@/components/AppShell';
import { api } from '@/lib/api';

type Step = {
  title: string;
  description: string;
  done: boolean;
  href: string;
  optional?: boolean;
};

const toArray = (res: any): any[] => (Array.isArray(res) ? res : res?.data ?? []);

export default function OnboardingPage() {
  const [steps, setSteps] = useState<Step[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    let cancelled = false;
    (async () => {
      setLoading(true);
      setError('');
      try {
        const [profileRes, bookingsRes, clientsRes, packagesRes] = await Promise.all([
          api<any>('/api/profile').catch(() => null),
          api<any>('/api/bookings?limit=1').catch(() => null),
          api<any>('/api/clients').catch(() => null),
          api<any>('/api/packages').catch(() => null),
        ]);

        const profile = profileRes?.data ?? profileRes ?? {};
        const bookings = toArray(bookingsRes);
        const clients = toArray(clientsRes);
        const packages = toArray(packagesRes);

        const built: Step[] = [
          {
            title: 'Complete your profile',
            description: 'Add your business name and contact details so clients recognise you.',
            done: !!profile?.business_name,
            href: '/app/settings',
          },
          {
            title: 'Add your first client',
            description: 'Create a client record to start tracking bookings and payments.',
            done: clients.length > 0,
            href: '/app/clients',
          },
          {
            title: 'Create a package',
            description: 'Define your service packages with pricing for faster bookings.',
            done: packages.length > 0,
            href: '/app/packages',
          },
          {
            title: 'Add your first booking',
            description: 'Schedule a shoot and keep your calendar organised.',
            done: bookings.length > 0,
            href: '/app/bookings',
          },
          {
            title: 'Invite your team',
            description: 'Bring photographers and editors on board to collaborate.',
            done: false,
            href: '/app/team',
            optional: true,
          },
        ];

        if (!cancelled) setSteps(built);
      } catch (e: any) {
        if (!cancelled) setError(e.message);
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  const completed = steps.filter((s) => s.done).length;
  const total = steps.length || 5;
  const pct = total > 0 ? Math.round((completed / total) * 100) : 0;

  return (
    <AppShell>
      <div style={{ padding: 24 }}>
        <h1 className="page-title">Get Started</h1>
        <p className="page-sub">Complete these steps to set up your ClickerPro account</p>

        {error && <div className="error" style={{ marginBottom: 12 }}>{error}</div>}

        {loading && (
          <div style={{ display: 'grid', gap: 12 }}>
            <div className="shimmer" style={{ height: 60, borderRadius: 8 }} />
            {[...Array(5)].map((_, i) => (
              <div key={i} className="shimmer" style={{ height: 80, borderRadius: 8 }} />
            ))}
          </div>
        )}

        {!loading && !error && (
          <>
            {/* Progress bar */}
            <div className="card" style={{ marginBottom: 20 }}>
              <div className="row" style={{ justifyContent: 'space-between', marginBottom: 10 }}>
                <span style={{ fontWeight: 700, fontSize: 15 }}>
                  {completed} of {total} complete
                </span>
                <span className="muted text-sm">{pct}%</span>
              </div>
              <div
                style={{
                  height: 10,
                  width: '100%',
                  background: 'var(--surface-3)',
                  borderRadius: 999,
                  overflow: 'hidden',
                }}
              >
                <div
                  style={{
                    height: '100%',
                    width: `${pct}%`,
                    background: 'var(--orange)',
                    borderRadius: 999,
                    transition: 'width 0.3s ease',
                  }}
                />
              </div>
            </div>

            {/* Checklist */}
            <div style={{ display: 'grid', gap: 12 }}>
              {steps.map((s, i) => (
                <div key={i} className="card">
                  <div className="row" style={{ alignItems: 'center', gap: 14 }}>
                    <div
                      style={{
                        flex: '0 0 auto',
                        width: 28,
                        height: 28,
                        borderRadius: '50%',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        fontSize: 16,
                        fontWeight: 700,
                        background: s.done ? 'var(--green, #2ecc71)' : 'transparent',
                        color: s.done ? '#000' : 'var(--film-muted)',
                        border: s.done ? 'none' : '2px solid var(--surface-3)',
                      }}
                    >
                      {s.done ? '✓' : ''}
                    </div>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div className="row" style={{ alignItems: 'center', gap: 8, marginBottom: 2 }}>
                        <span style={{ fontWeight: 700, fontSize: 15 }}>{s.title}</span>
                        {s.optional && <span className="badge gray">Optional</span>}
                      </div>
                      <div className="muted text-sm">{s.description}</div>
                    </div>
                    <div style={{ flex: '0 0 auto' }}>
                      {s.done ? (
                        <span className="btn ghost sm" style={{ opacity: 0.6, pointerEvents: 'none' }}>
                          Done
                        </span>
                      ) : (
                        <Link href={s.href} className="btn sm" style={{ background: 'var(--orange)', color: '#000' }}>
                          Go →
                        </Link>
                      )}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </>
        )}
      </div>
    </AppShell>
  );
}
