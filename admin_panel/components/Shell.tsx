'use client';

import { useEffect } from 'react';
import { usePathname, useRouter } from 'next/navigation';
import Link from 'next/link';
import { getToken, clearToken } from '@/lib/api';

type NavItem = { href: string; label: string; icon: string };

const NAV_GROUPS: { label: string; items: NavItem[] }[] = [
  {
    label: 'Overview',
    items: [
      { href: '/',          label: 'Dashboard',     icon: '◈' },
      { href: '/analytics', label: 'Analytics',     icon: '↗' },
    ],
  },
  {
    label: 'Users',
    items: [
      { href: '/users',   label: 'All Users',  icon: '⊙' },
      { href: '/studios', label: 'Businesses', icon: '⬡' },
    ],
  },
  {
    label: 'Operations',
    items: [
      { href: '/bookings',     label: 'Bookings',      icon: '▦' },
      { href: '/finance',      label: 'Finance',       icon: '◎' },
      { href: '/payments',     label: 'Payments',      icon: '◇' },
      { href: '/subscription', label: 'Subscriptions', icon: '◈' },
      { href: '/coupons',      label: 'Coupons',       icon: '⊕' },
    ],
  },
  {
    label: 'Engagement',
    items: [
      { href: '/broadcasts', label: 'Notifications', icon: '◉' },
      { href: '/files',      label: 'Files',          icon: '▣' },
      { href: '/support',    label: 'Support & FAQ',  icon: '◌' },
    ],
  },
  {
    label: 'System',
    items: [
      { href: '/security', label: 'Security',   icon: '⊛' },
      { href: '/audit',    label: 'Audit Log',  icon: '≡' },
      { href: '/settings', label: 'Settings',   icon: '⊞' },
    ],
  },
];

export default function Shell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();

  // Auth gate runs AFTER mount only. We must NOT branch the render on a
  // client-only value (token / a useEffect flag) — under App Router SSR the
  // server renders one tree and the client's first render must match it
  // exactly, or React throws #418 (hydration mismatch) and the whole page
  // blanks with "client-side exception". So the markup below is identical on
  // server and first client render; an unauthenticated user is bounced to
  // /login by the effect a tick later.
  useEffect(() => {
    if (!getToken()) {
      router.replace('/login');
    }
  }, [router]);

  const logout = () => {
    clearToken();
    router.replace('/login');
  };

  const isActive = (href: string) =>
    href === '/' ? pathname === '/' : pathname.startsWith(href);

  return (
    <div className="shell">
      <aside className="sidebar">
        {/* Brand */}
        <div className="brand">
          <div className="brand-icon">📷</div>
          <span>Clicker Pro</span>
        </div>

        {/* Nav */}
        <nav className="nav">
          {NAV_GROUPS.map((group) => (
            <div key={group.label}>
              <div className="nav-section-label">{group.label}</div>
              {group.items.map((n) => (
                <Link key={n.href} href={n.href} className={isActive(n.href) ? 'active' : ''}>
                  <span className="nav-icon">{n.icon}</span>
                  {n.label}
                </Link>
              ))}
            </div>
          ))}
        </nav>

        {/* Footer */}
        <div className="sidebar-foot">
          <button className="btn secondary" style={{ width: '100%', justifyContent: 'center' }} onClick={logout}>
            Sign out
          </button>
        </div>
      </aside>

      <main className="main">{children}</main>
    </div>
  );
}
