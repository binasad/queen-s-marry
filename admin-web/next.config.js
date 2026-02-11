/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  images: {
    // Allows images to be loaded from localhost and your AWS EC2 IP
    domains: ['localhost', '44.215.209.41'], 
  },
  async rewrites() {
    return [
      {
        /**
         * REVERSE PROXY: 
         * This intercepts any request to /api/v1/... and sends it to your AWS EC2.
         * The browser thinks it's talking to HTTPS (Vercel), so the Mixed Content 
         * error is bypassed.
         */
        source: '/api/v1/:path*',
        destination: 'http://44.215.209.41:5000/api/v1/:path*',
      },
      {
        /**
         * SOCKET.IO PROXY:
         * If you are using WebSockets for real-time notifications in the salon app,
         * this ensures the handshake also goes through the secure Vercel tunnel.
         */
        source: '/socket.io/:path*',
        destination: 'http://44.215.209.41:5000/socket.io/:path*',
      },
    ];
  },
  env: {
    /**
     * Use a relative path so the browser targets the Vercel domain.
     * Vercel will then use the 'rewrites' above to forward to AWS.
     */
    NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL || '/api/v1',
  },
}

module.exports = nextConfig;