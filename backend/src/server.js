const app = require('./app');
const env = require('./config/env');
const { pool } = require('./config/db');
const redis = require('./config/redis');
const { initFirebase } = require('./services/pushNotificationService');
const http = require('http');
const { Server } = require('socket.io');

initFirebase();

const PORT = env.port;

// Create HTTP server
const server = http.createServer(app);

// Initialize Socket.IO with permissive CORS for mobile apps
const io = new Server(server, {
  cors: {
    origin: ['https://admin-web-navy-three.vercel.app', 'http://localhost:3000'], // Allow all origins including mobile apps
    methods: ["GET", "POST"],
    credentials: true
  }
});

// Socket.IO connection handling
io.on('connection', (socket) => {
  console.log('🔌 User connected:', socket.id);

  // Join user-specific room for targeted updates
  socket.on('join-user', (userId) => {
    socket.join(`user_${userId}`);
    console.log(`👤 User ${userId} joined their room`);
  });

  // Join admin room for admin updates
  socket.on('join-admin', () => {
    socket.join('admin');
    console.log('👑 Admin joined admin room');
  });

  socket.on('disconnect', () => {
    console.log('🔌 User disconnected:', socket.id);
  });
});

// Make io available globally for controllers
global.io = io;

server.listen(PORT, '0.0.0.0', async () => {
  console.log(`\n🚀 Server running on port ${PORT}`);
  console.log(`📝 Environment: ${env.nodeEnv}`);
  console.log(`🔗 API Base URL: ${env.backendUrl}`);
  console.log(`🔌 WebSocket enabled`);

  // Connect Redis (optional - caching disabled if not configured)
  try {
    await redis.connect();
  } catch (_) { /* no-op */ }

  // Test database connection and run migrations
  try {
    await pool.query('SELECT NOW()');
    console.log('✓ Database connected successfully');

    if (process.env.STRIPE_WEBHOOK_SECRET) {
      console.log('✓ Stripe webhook secret configured – appointments will be created on payment success');
    }

    // Ensure payment_intent_id and offer_id columns exist (for Stripe webhook)
    try {
      await pool.query(`
        ALTER TABLE appointments
        ADD COLUMN IF NOT EXISTS payment_intent_id VARCHAR(255) UNIQUE
      `);
      try {
        await pool.query(`
          ALTER TABLE appointments
          ADD COLUMN IF NOT EXISTS offer_id UUID REFERENCES offers(id) ON DELETE SET NULL
        `);
      } catch (_) {
        /* offer_id may already exist - non-critical */
      }
      await pool.query(`
        ALTER TABLE users ADD COLUMN IF NOT EXISTS fcm_token TEXT
      `);
      console.log('✓ Appointments & users table migrations verified');
    } catch (migErr) {
      console.warn('⚠️ Migration check:', migErr.message);
    }
    console.log('');
  } catch (error) {
    console.error('⚠️ Database connection failed:', error.message);
    console.log('🔌 WebSocket server will continue running without database...\n');
    // Don't exit - WebSocket functionality doesn't require database
  }
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('\nSIGTERM received. Shutting down gracefully...');
  server.close(async () => {
    await redis.disconnect();
    await pool.end();
    console.log('✓ Server closed');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  console.log('\nSIGINT received. Shutting down gracefully...');
  server.close(async () => {
    await redis.disconnect();
    await pool.end();
    console.log('✓ Server closed');
    process.exit(0);
  });
});

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
  console.error('Uncaught Exception:', error);
  process.exit(1);
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
  process.exit(1);
});
