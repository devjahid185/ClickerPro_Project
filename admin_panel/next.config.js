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
  async headers() {
    return [{ source: '/:path*', headers: securityHeaders }];
  },
  // The admin panel talks to the Clicker Pro API. The browser calls
  // same-origin /api/* and Next proxies it to the backend (no CORS, and
  // the CSP can stay `connect-src 'self'`). In dev that's localhost:5000;
  // in production it's the live API. Override with API_PROXY_TARGET.
  async rewrites() {
    const target =
      process.env.API_PROXY_TARGET ||
      (isDev ? 'http://localhost:5000' : 'https://api.deyalghori.com');
    return [{ source: '/api/:path*', destination: `${target}/api/:path*` }];
  },
};

module.exports = nextConfig;
