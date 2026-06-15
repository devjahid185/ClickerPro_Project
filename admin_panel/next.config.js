const isDev = process.env.NODE_ENV !== 'production';

// Admin panel is a pure Next app (no external CDNs), so the CSP can be tight.
// Next.js needs 'unsafe-eval' for its dev HMR runtime; dropped in production.
const csp = [
  "default-src 'self'",
  `script-src 'self' 'unsafe-inline'${isDev ? " 'unsafe-eval'" : ''}`,
  "style-src 'self' 'unsafe-inline'",
  "img-src 'self' data: https:",
  "font-src 'self' data:",
  "connect-src 'self'",
  "frame-ancestors 'none'",
  "base-uri 'self'",
  "form-action 'self'",
].join('; ');

const securityHeaders = [
  { key: 'X-Content-Type-Options', value: 'nosniff' },
  { key: 'X-Frame-Options', value: 'DENY' },
  { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
  { key: 'Permissions-Policy', value: 'geolocation=(), microphone=(), camera=()' },
  { key: 'Content-Security-Policy', value: csp },
];

/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  poweredByHeader: false,
  // Types + lint are validated locally; skip at build time — the shared
  // host's build worker crashes on them ("id argument must be of type string").
  typescript: { ignoreBuildErrors: true },
  eslint: { ignoreDuringBuilds: true },
  // Shared-hosting build fix: cap to a single worker / no worker threads so
  // `next build` doesn't try to spawn a thread pool the host forbids
  // (pthread_create: Resource temporarily unavailable / SIGABRT).
  experimental: { workerThreads: false, cpus: 1 },
  async headers() {
    return [{ source: '/:path*', headers: securityHeaders }];
  },
  // The admin panel talks to the Clicker Pro API. The browser calls
  // same-origin /api/* and Next proxies it to the backend (no CORS, and
  // the CSP can stay `connect-src 'self'`). In dev that's localhost:5000;
  // in production it's the live API. Override with API_PROXY_TARGET.
  async rewrites() {
    // Default to the LIVE API — NODE_ENV isn't reliably 'production' under
    // Passenger/cPanel. Set API_PROXY_TARGET=http://localhost:5000 for dev.
    const target = process.env.API_PROXY_TARGET || 'https://api.deyalghori.com';
    return [{ source: '/api/:path*', destination: `${target}/api/:path*` }];
  },
};

module.exports = nextConfig;
