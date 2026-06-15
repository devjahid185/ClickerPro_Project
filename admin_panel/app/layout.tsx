import './globals.css';
import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Clicker Pro — Admin',
  description: 'Platform administration for Clicker Pro',
};

// Shared-hosting build fix: this host hard-caps threads/processes, so the
// `next/font/google` build-time font optimizer (Rust/rayon) crashed the build
// worker with SIGABRT ("global thread pool not initialized / Resource
// temporarily unavailable"). We use a system font stack instead — no
// build-time native font pipeline, no external request, and the tight admin
// CSP (`font-src 'self'`) stays untouched.
//
// `force-dynamic` also skips App-Router static prerendering (another
// worker-spawning step). Every admin page is a token-authenticated,
// client-rendered dashboard, so there is nothing to statically prerender.
export const dynamic = 'force-dynamic';

export default function RootLayout({ children }: { children: React.ReactNode }) {
  // Font comes from globals.css (system stack) — no inline style, so the
  // server-rendered and client-rendered <body> markup match exactly (avoids
  // the React #418 hydration mismatch).
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
