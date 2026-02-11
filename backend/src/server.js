const app = require('./app');
const env = require('./config/env');
const { pool } = require('./config/db');
const http = require('http');
const { Server } = require('socket.io');

const PORT = env.port;

// Create HTTP server
const server = http.createServer(app);

// Initialize Socket.IO with permissive CORS for mobile apps
const io = new Server(server, {
  cors: {
    origin: '*', // Allow all origins including mobile apps
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

  // Test database connection
  try {
    await pool.query('SELECT NOW()');
    console.log('✓ Database connected successfully\n');
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
    await pool.end();
    console.log('✓ Server closed');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  console.log('\nSIGINT received. Shutting down gracefully...');
  server.close(async () => {
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
