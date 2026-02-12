const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const env = require('./config/env');
const { pool } = require('./config/db');

// Import routes
const authRoutes = require('./modules/auth/auth.routes');
const usersRoutes = require('./modules/users/users.routes');
const servicesRoutes = require('./modules/services/services.routes');
const appointmentsRoutes = require('./modules/appointments/appointments.routes');
const rolesRoutes = require('./modules/roles/roles.routes');
const coursesRoutes = require('./modules/courses/courses.routes');
const expertsRoutes = require('./modules/experts/experts.routes');
const supportRoutes = require('./modules/support/support.routes');
const notificationsRoutes = require('./modules/notifications/notifications.routes');
const offersRoutes = require('./modules/offers/offers.routes');
const paymentRoutes = require('./modules/payments/payments.routes');
const blogsRoutes = require('./modules/blogs/blogs.routes');

const app = express();

// Trust proxy
app.set('trust proxy', 1);
app.disable('x-powered-by'); // Hide Express signature

// Middleware
app.use(helmet({
  referrerPolicy: { policy: 'no-referrer' },
  contentSecurityPolicy: false, // APIs typically don't need CSP; can tighten later
  crossOriginEmbedderPolicy: false,
}));

// CORS configuration - more permissive in development
const allowedOrigins = [
  env.frontendUrl,
  env.adminWebUrl,
  'https://admin-web-navy-three.vercel.app'
].filter(Boolean);
const corsOptions = {
  origin: (origin, callback) => {
    // Mobile apps (Android/iOS) don't send origin header - always allow
    if (!origin) {
      console.log('📱 Request from mobile app (no origin header) - allowing');
      return callback(null, true);
    }
    
    console.log(`🌐 CORS check - Origin: ${origin}`);
    
    // In development, allow all localhost origins and common mobile/emulator IPs
    if (env.isDevelopment) {
      if (origin.startsWith('http://localhost') || 
          origin.startsWith('http://127.0.0.1') ||
          origin.startsWith('http://10.0.2.2')) {
        console.log('✅ Allowing origin (development):', origin);
        return callback(null, true);
      }
    }

    // Allow all Vercel deployments (*.vercel.app - production + preview URLs)
    if (origin.endsWith('.vercel.app')) {
      console.log('✅ Allowing origin (Vercel):', origin);
      return callback(null, true);
    }
    
    // Production: check explicit whitelist
    if (allowedOrigins.includes(origin)) {
      console.log('✅ Allowing origin (whitelist):', origin);
      return callback(null, true);
    }
    
    console.log('❌ Blocking origin:', origin);
    return callback(new Error('Not allowed by CORS'));
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
};
app.use(cors(corsOptions));
app.options('*', cors(corsOptions));
app.use(compression()); // Compress responses
app.use(express.json({ limit: '10mb' })); // Parse JSON bodies
app.use(express.urlencoded({ extended: true, limit: '10mb' })); // Parse URL-encoded bodies

// Enhanced logging middleware
app.use((req, res, next) => {
  console.log(`\n📥 ${new Date().toISOString()} - ${req.method} ${req.path}`);
  console.log(`   IP: ${req.ip || req.connection.remoteAddress}`);
  console.log(`   Origin: ${req.headers.origin || 'None (mobile app)'}`);
  console.log(`   User-Agent: ${req.headers['user-agent'] || 'Unknown'}`);
  if (req.body && Object.keys(req.body).length > 0) {
    console.log(`   Body: ${JSON.stringify(req.body).substring(0, 200)}...`);
  }
  next();
});

app.use(morgan(env.isDevelopment ? 'dev' : 'combined')); // Logging

// Rate limiting
const limiter = rateLimit({
  windowMs: env.rateLimit.windowMs,
  max: env.rateLimit.maxRequests,
  message: 'Too many requests from this IP, please try again later.',
  standardHeaders: true,
  legacyHeaders: false,
});
app.use('/api/', limiter);

// Health check endpoint (root and versioned)
app.get('/health', (req, res) => {
  console.log('🏥 Health check requested');
  res.json({
    success: true,
    message: 'Server is running',
    timestamp: new Date().toISOString(),
    environment: env.nodeEnv,
    apiVersion: env.apiVersion,
  });
});
app.get(`/api/${env.apiVersion}/health`, (req, res) => {
  console.log('🏥 API v1 health check requested');
  res.json({
    success: true,
    message: 'API v1 is healthy',
    timestamp: new Date().toISOString(),
    environment: env.nodeEnv,
    apiVersion: env.apiVersion,
  });
});

// Test endpoint for connectivity
app.get('/test', (req, res) => {
  console.log('🧪 Test endpoint called');
  res.json({
    success: true,
    message: 'Backend is reachable!',
    timestamp: new Date().toISOString(),
    clientIP: req.ip || req.connection.remoteAddress,
    headers: {
      origin: req.headers.origin || 'None',
      'user-agent': req.headers['user-agent'] || 'Unknown',
    },
  });
});

// API Routes
const API_VERSION = env.apiVersion;

// API root endpoint - shows available routes
app.get(`/api/${API_VERSION}`, (req, res) => {
  res.json({
    success: true,
    message: 'Salon Booking API',
    version: API_VERSION,
    endpoints: {
      auth: {
        register: `POST /api/${API_VERSION}/auth/register`,
        login: `POST /api/${API_VERSION}/auth/login`,
        verifyEmail: `POST /api/${API_VERSION}/auth/verify-email`,
        resendVerification: `POST /api/${API_VERSION}/auth/resend-verification`,
        forgotPassword: `POST /api/${API_VERSION}/auth/forgot-password`,
        resetPassword: `POST /api/${API_VERSION}/auth/reset-password`,
        refreshToken: `POST /api/${API_VERSION}/auth/refresh-token`,
        changePassword: `POST /api/${API_VERSION}/auth/change-password`,
        sendChangePasswordOtp: `POST /api/${API_VERSION}/auth/send-change-password-otp`,
        changePasswordOtp: `POST /api/${API_VERSION}/auth/change-password-otp`,
      },
      users: {
        profile: `GET /api/${API_VERSION}/profile`,
        updateProfile: `PUT /api/${API_VERSION}/profile`,
      },
      services: {
        categories: `GET /api/${API_VERSION}/categories`,
        allServices: `GET /api/${API_VERSION}/services`,
        serviceById: `GET /api/${API_VERSION}/services/:id`,
        experts: `GET /api/${API_VERSION}/experts`,
      },
      appointments: {
        create: `POST /api/${API_VERSION}/appointments`,
        myAppointments: `GET /api/${API_VERSION}/appointments/my`,
        allAppointments: `GET /api/${API_VERSION}/appointments`,
        cancel: `DELETE /api/${API_VERSION}/appointments/:id/cancel`,
      },
      health: `GET /health`,
      test: `GET /test`,
    },
    timestamp: new Date().toISOString(),
  });
});

// Disable caching on auth routes to reduce token exposure
const noCache = (req, res, next) => {
  res.set('Cache-Control', 'no-store');
  res.set('Pragma', 'no-cache');
  next();
};

app.use(`/api/${API_VERSION}/auth`, noCache, authRoutes);
app.use(`/api/${API_VERSION}`, usersRoutes);
app.use(`/api/${API_VERSION}`, servicesRoutes);
app.use(`/api/${API_VERSION}`, appointmentsRoutes);
app.use(`/api/${API_VERSION}`, rolesRoutes);
app.use(`/api/${API_VERSION}`, coursesRoutes);
app.use(`/api/${API_VERSION}`, expertsRoutes);
app.use(`/api/${API_VERSION}`, supportRoutes);
app.use(`/api/${API_VERSION}`, notificationsRoutes);

app.use(`/api/${API_VERSION}/payments`, paymentRoutes);
app.use(`/api/${API_VERSION}`, offersRoutes);
app.use(`/api/${API_VERSION}`, blogsRoutes);

// 404 handler
app.use((req, res) => {
  console.log(`❌ 404 - Route not found: ${req.method} ${req.path}`);
  console.log("hello");
  res.status(404).json({
    success: false,
    message: 'Route not found',
    path: req.path,
    method: req.method,
  });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error('❌ Global error handler triggered');
  console.error('   Path:', req.path);
  console.error('   Method:', req.method);
  console.error('   Error:', err.message);
  if (env.isDevelopment) {
    console.error('   Stack:', err.stack);
  }
  res.status(err.status || 500).json({
    success: false,
    message: err.message || 'Internal server error',
    ...(env.isDevelopment && { stack: err.stack }),
  });
});

module.exports = app;
