/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  // The admin panel talks to the Clicker Pro API. In dev we proxy /api/*
  // to the backend so the browser never hits CORS and the token cookie
  // stays same-origin. Override the target with API_PROXY_TARGET.
  async rewrites() {
    const target = process.env.API_PROXY_TARGET || 'http://localhost:5000';
    return [{ source: '/api/:path*', destination: `${target}/api/:path*` }];
  },
};

module.exports = nextConfig;
