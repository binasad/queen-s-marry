/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  images: {
    // Local dev + production (uncomment when using deployed backend)
    domains: ['localhost'],
    // domains: ['localhost', '44.215.209.41'],
  },
  async rewrites() {
    // Production backend – hard-coded so rewrites always resolve to an absolute URL,
    // even when env vars are missing at build time on Vercel.
    const PROD_BACKEND = 'https://aztrosyssalonappapi.ddns.net';

    // Resolve an *absolute* backend base URL (must start with http)
    const candidates = [
      process.env.NEXT_PUBLIC_BACKEND_URL,
      process.env.NEXT_PUBLIC_API_URL?.replace(/\/api\/v1\/?$/, ''),
    ].filter((u) => u && /^https?:\/\//.test(u));

    const backendBase = candidates[0] || (process.env.NODE_ENV === 'production' ? PROD_BACKEND : 'http://localhost:5000');

    console.log('[next.config] rewrite destination →', backendBase);

    return [
      {
        /**
         * REVERSE PROXY:
         * Requests to /api/v1/* go through Vercel to your backend (avoids CORS).
         */
        source: '/api/v1/:path*',
        destination: `${backendBase}/api/v1/:path*`,
      },
      {
        /**
         * SOCKET.IO PROXY:
         * WebSocket handshake goes through Vercel to the backend.
         */
        source: '/socket.io/:path*',
        destination: `${backendBase}/socket.io/:path*`,
      },
    ];
  },
  env: {
    /**
     * Use relative /api/v1 when NEXT_PUBLIC_BACKEND_URL is set so requests go through
     * the rewrite (same-origin, no CORS). Otherwise use NEXT_PUBLIC_API_URL for direct backend.
     */
    NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_BACKEND_URL ? '/api/v1' : (process.env.NEXT_PUBLIC_API_URL || '/api/v1'),
  },
}

module.exports = nextConfig;