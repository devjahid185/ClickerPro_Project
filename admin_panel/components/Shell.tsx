'use client';

import { useEffect, useState } from 'react';
import { usePathname, useRouter } from 'next/navigation';
import Link from 'next/link';
import { getToken, clearToken } from '@/lib/api';

const NAV = [
  { href: '/', label: 'Dashboard', icon: '📊' },
  { href: '/users', label: 'Users', icon: '👥' },
  { href: '/bookings', label: 'Bookings', icon: '📅' },
  { href: '/subscription', label: 'Subscription', icon: '💎' },
  { href: '/payments', label: 'Payments', icon: '💳' },
  { href: '/coupons', label: 'Coupons', icon: '🎟️' },
  { href: '/files', label: 'Files', icon: '📂' },
  { href: '/broadcasts', label: 'Broadcasts', icon: '📢' },
  { href: '/support', label: 'Support & FAQ', icon: '💬' },
  { href: '/security', label: 'Security', icon: '🔐' },
  { href: '/audit', label: 'Audit Log', icon: '📋' },
  { href: '/settings', label: 'Settings', icon: '⚙️' },
];

// Wraps every authed page: redirects to /login if no token, renders the
// sidebar + main content area.
export default function Shell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const [ready, setReady] = useState(false);

  useEffect(() => {
    if (!getToken()) {
      router.replace('/login');
    } else {
      setReady(true);
    }
  }, [router]);

  if (!ready) return null;

  const logout = () => {
    clearToken();
    router.replace('/login');
  };

  return (
    <div className="shell">
      <aside className="sidebar">
        <div className="brand">📷 Clicker Pro</div>
        <nav className="nav">
          {NAV.map((n) => {
            const active = n.href === '/' ? pathname === '/' : pathname.startsWith(n.href);
            return (
              <Link key={n.href} href={n.href} className={active ? 'active' : ''}>
                <span>{n.icon}</span> {n.label}
              </Link>
            );
          })}
        </nav>
        <div className="sidebar-foot">
          <button className="btn secondary" style={{ width: '100%' }} onClick={logout}>
            Sign out
          </button>
        </div>
      </aside>
      <main className="main">{children}</main>
    </div>
  );
}
