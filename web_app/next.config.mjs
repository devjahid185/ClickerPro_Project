// Content-Security-Policy. Allows the CDNs the landing page uses (GSAP,
// Google Fonts) and same-origin API. Tighten further once inline scripts
// are eliminated. 'unsafe-eval' is required by GSAP.
const csp = [
  "default-src 'self'",
  "script-src 'self' 'unsafe-inline' 'unsafe-eval' https://cdnjs.cloudflare.com https://cdn.tailwindcss.com https://code.iconify.design",
  "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com",
  "font-src 'self' https://fonts.gstatic.com data:",
  "img-src 'self' data: https:",
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

// STATIC_EXPORT=1 produces a plain-HTML build in out/ that any static host
// (shared hosting / LiteSpeed) can serve — no Node/Passenger needed. Used for
// the landing-only deploy; headers/rewrites only exist on the Node server.
const isStaticExport = process.env.STATIC_EXPORT === '1';

/** @type {import('next').NextConfig} */
const nextConfig = {
  // Shared-hosting build fix: the type-check / lint build workers crash on
  // this host's Node ("id argument must be of type string"). Types + lint are
  // already validated locally, so skip them at build time here.
  typescript: { ignoreBuildErrors: true },
  eslint: { ignoreDuringBuilds: true },
  reactStrictMode: true,
  poweredByHeader: false,
  // Shared-hosting build fix: this host caps threads/processes hard
  // (pthread_create: Resource temporarily unavailable / SIGABRT during
  // "Collecting page data"). Force Next to use a single worker and no extra
  // worker threads so the build doesn't try to spawn a pool it can't.
  experimental: { workerThreads: false, cpus: 1 },
  ...(isStaticExport
    ? { output: 'export' }
    : {
        async headers() {
          return [
            { source: '/:path*', headers: securityHeaders },
            // No-store the HTML shell so a redeploy is picked up immediately
            // instead of a cached page loading a stale JS bundle. Hashed
            // /_next/static assets stay immutable.
            {
              source: '/((?!_next/static|_next/image|favicon.ico).*)',
              headers: [
                { key: 'Cache-Control', value: 'no-store, must-revalidate' },
              ],
            },
          ];
        },
        async rewrites() {
          // The browser calls same-origin /api/* and Next proxies it to the
          // backend (no CORS). Default to the LIVE API — NODE_ENV is not
          // reliably 'production' under Passenger/cPanel, so relying on it
          // sent register/login to a dead localhost:5000 → "Error 500".
          // For local dev, set API_URL=http://localhost:5000 explicitly.
          const target = process.env.API_URL || 'https://api.deyalghori.com';
          return [{ source: '/api/:path*', destination: `${target}/api/:path*` }];
        },
      }),
};

export default nextConfig;
