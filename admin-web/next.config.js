/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  images: {
    // Local dev + production (uncomment when using deployed backend)
    domains: ['localhost'],
    // domains: ['localhost', '44.215.209.41'],
  },
  async rewrites() {
    // Backend URL for proxy (use NEXT_PUBLIC_BACKEND_URL + /api/v1, or fallback to NEXT_PUBLIC_API_URL)
    const backendApi =
      process.env.NEXT_PUBLIC_BACKEND_URL
        ? `${process.env.NEXT_PUBLIC_BACKEND_URL}/api/v1`
        : (process.env.NEXT_PUBLIC_API_URL || '').replace(/\/api\/v1\/?$/, '') + '/api/v1';
    const backendBase = process.env.NEXT_PUBLIC_BACKEND_URL || process.env.NEXT_PUBLIC_API_URL?.replace(/\/api\/v1\/?$/, '') || '';

    return [
      {
        /**
         * REVERSE PROXY:
         * Requests to /api/v1/* go through Vercel to your backend (avoids CORS).
         */
        source: '/api/v1/:path*',
        destination: `${backendApi || 'http://localhost:5000/api/v1'}/:path*`,
      },
      {
        /**
         * SOCKET.IO PROXY:
         * WebSocket handshake goes through Vercel to the backend.
         */
        source: '/socket.io/:path*',
        destination: `${backendBase || 'http://localhost:5000'}/socket.io/:path*`,
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