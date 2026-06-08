'use client';
import { useEffect, useState, ReactNode } from 'react';
import { useRouter } from 'next/router';
import Link from 'next/link';
import { getToken, logout, getUser } from '@/lib/api';

type NavItem = { href: string; label: string; icon: string };
const NAV: { group: string; items: NavItem[] }[] = [
  {
    group: 'Overview',
    items: [
      { href: '/app', label: 'Dashboard', icon: '◈' },
      { href: '/app/calendar', label: 'Calendar', icon: '▦' },
      { href: '/app/search', label: 'Search', icon: '⊘' },
    ],
  },
  {
    group: 'Bookings',
    items: [
      { href: '/app/bookings', label: 'Bookings', icon: '📅' },
      { href: '/app/clients', label: 'Clients', icon: '👤' },
      { href: '/app/packages', label: 'Packages', icon: '📦' },
      { href: '/app/waitlist', label: 'Waitlist', icon: '⏳' },
    ],
  },
  {
    group: 'Finance',
    items: [
      { href: '/app/finance', label: 'Finance', icon: '💰' },
      { href: '/app/invoices', label: 'Invoices', icon: '🧾' },
      { href: '/app/payments', label: 'Payments', icon: '💳' },
      { href: '/app/expenses', label: 'Expenses', icon: '💸' },
      { href: '/app/petty-cash', label: 'Petty Cash', icon: '🪙' },
      { href: '/app/freelancer', label: 'Freelancer', icon: '🎯' },
    ],
  },
  {
    group: 'Workspace',
    items: [
      { href: '/app/team', label: 'Team', icon: '👥' },
      { href: '/app/gear', label: 'Gear', icon: '📷' },
      { href: '/app/rent', label: 'Rental', icon: '🔄' },
      { href: '/app/chat', label: 'Chat', icon: '💬' },
      { href: '/app/reports', label: 'Reports', icon: '📈' },
    ],
  },
  {
    group: 'More',
    items: [
      { href: '/app/reminders', label: 'Reminders', icon: '🔔' },
      { href: '/app/followup', label: 'Follow-ups', icon: '📌' },
      { href: '/app/announcements', label: 'Announcements', icon: '📣' },
      { href: '/app/support', label: 'Support', icon: '🎫' },
      { href: '/app/help', label: 'Help', icon: '❓' },
      { href: '/app/activity', label: 'My Activity', icon: '🕑' },
      { href: '/app/notifications', label: 'Notifications', icon: '📢' },
      { href: '/app/settings', label: 'Settings', icon: '⚙️' },
    ],
  },
];

export default function AppShell({ children }: { children: ReactNode }) {
  const router = useRouter();
  const [ready, setReady] = useState(false);
  const [user, setUser] = useState<any>(null);
  const [sidebarOpen, setSidebarOpen] = useState(false);

  useEffect(() => {
    if (!getToken()) { router.replace('/login'); return; }
    setUser(getUser());
    setReady(true);
  }, [router]);

  // Lock body scroll while the mobile drawer is open.
  useEffect(() => {
    document.body.style.overflow = sidebarOpen ? 'hidden' : '';
    return () => { document.body.style.overflow = ''; };
  }, [sidebarOpen]);

  if (!ready) return null;

  const isActive = (href: string) =>
    href === '/app' ? router.pathname === '/app' : router.pathname.startsWith(href);

  const handleLogout = () => { logout(); router.replace('/login'); };

  const initials = user?.name
    ? user.name.split(' ').map((w: string) => w[0]).join('').slice(0, 2).toUpperCase()
    : 'U';

  return (
    <div className="app-shell">
      {/* Mobile top bar — only shown on small screens via CSS */}
      <header className="app-topbar">
        <button className="hamburger" aria-label="Open menu" onClick={() => setSidebarOpen(true)}>
          <span /><span /><span />
        </button>
        <Link href="/app" className="brand-logo">Clicker<span>Pro</span></Link>
        <span style={{ flex: 1 }} />
        <Link href="/app/settings" className="avatar avatar-sm" aria-label="Settings">{initials}</Link>
      </header>

      {/* Mobile overlay */}
      {sidebarOpen && (
        <div className="app-overlay" onClick={() => setSidebarOpen(false)} />
      )}

      {/* Sidebar */}
      <aside className={`app-sidebar${sidebarOpen ? ' open' : ''}`}>
        <div className="app-sidebar-brand">
          <Link href="/app" style={{ display: 'flex', alignItems: 'center', gap: 8 }} onClick={() => setSidebarOpen(false)}>
            <span className="brand-logo">Clicker<span>Pro</span></span>
          </Link>
          <span className="spacer" />
          <span style={{ fontSize: 9, fontFamily: 'JetBrains Mono, monospace', letterSpacing: '0.1em', color: 'var(--film-muted)', background: 'var(--orange-dim)', padding: '2px 6px', borderRadius: 4 }}>WEB</span>
          <button className="sidebar-close" aria-label="Close menu" onClick={() => setSidebarOpen(false)}>×</button>
        </div>

        <nav className="app-nav">
          {NAV.map((group) => (
            <div key={group.group}>
              <div className="nav-group-label">{group.group}</div>
              {group.items.map((n) => (
                <Link key={n.href} href={n.href} className={isActive(n.href) ? 'active' : ''} onClick={() => setSidebarOpen(false)}>
                  <span className="nav-icon">{n.icon}</span>
                  {n.label}
                </Link>
              ))}
            </div>
          ))}
        </nav>

        <div className="app-sidebar-foot">
          <div className="row" style={{ marginBottom: 12 }}>
            <div className="avatar avatar-md">{initials}</div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 13, fontWeight: 600, color: 'var(--film)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                {user?.name || 'User'}
              </div>
              <div style={{ fontSize: 10, color: 'var(--film-muted)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', fontFamily: 'JetBrains Mono, monospace' }}>
                {user?.role || 'OWNER'}
              </div>
            </div>
          </div>
          <div className="row" style={{ gap: 8 }}>
            <Link href="/app/settings" className="btn ghost sm" style={{ flex: 1, justifyContent: 'center', fontSize: 11 }}>
              Settings
            </Link>
            <button className="btn danger sm" style={{ flex: 1, justifyContent: 'center', fontSize: 11 }} onClick={handleLogout}>
              Sign out
            </button>
          </div>
        </div>
      </aside>

      <main className="app-main">{children}</main>
    </div>
  );
}
