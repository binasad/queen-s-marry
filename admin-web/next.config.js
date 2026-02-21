/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  images: {
    // Allows Next.js to optimize images from your backend domain and localhost
    domains: ['localhost', 'aztrosyssalonappapi.ddns.net'],
  },
  async rewrites() {
    return [
      {
        /**
         * REVERSE PROXY:
         * Intercepts any request your frontend makes to /api/v1/...
         * and secretly forwards it to your EC2 backend from the Vercel server.
         * This bypasses the browser's CORS checks entirely.
         */
        source: '/api/v1/:path*',
        destination: 'https://aztrosyssalonappapi.ddns.net/api/v1/:path*',
      },
      {
        /**
         * SOCKET.IO PROXY:
         * Forwards the initial WebSocket polling requests through Vercel.
         */
        source: '/socket.io/:path*',
        destination: 'https://aztrosyssalonappapi.ddns.net/socket.io/:path*',
      },
    ];
  },
  env: {
    /**
     * ENVIRONMENT OVERRIDE:
     * By hardcoding this to a relative path, we force Axios and other
     * fetch requests to hit the rewrites above instead of trying to 
     * contact the EC2 server directly from the user's browser.
     */
    NEXT_PUBLIC_API_URL: '/api/v1',
  },
}

module.exports = nextConfig;