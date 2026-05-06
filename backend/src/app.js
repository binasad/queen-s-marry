const express = require('express');
const path = require('path');
const fs = require('fs');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const env = require('./config/env');
const { pool } = require('./config/db');

const API_VERSION = env.apiVersion || 'v1';

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
const jazzcashRoutes = require('./modules/payments/jazzcash.routes');
const blogsRoutes = require('./modules/blogs/blogs.routes');
const reportsRoutes = require('./modules/reports/reports.routes');
const reviewsRoutes = require('./modules/reviews/reviews.routes');
const favoritesRoutes = require('./modules/favorites/favorites.routes');

// Handle missing dashboard routes dynamically to prevent 404s
let dashboardRoutes = null;
try {
  dashboardRoutes = require('./modules/dashboard/dashboard.routes');
} catch (error) {
  console.log('⚠️ Dashboard routes not found. Create ./modules/dashboard/dashboard.routes.js to fix /dashboard 404s.');
}

const app = express();

// Trust proxy (Crucial for Nginx reverse proxy)
app.set('trust proxy', 1);
app.disable('x-powered-by'); 

// Middleware
app.use(helmet({
  referrerPolicy: { policy: 'no-referrer' },
  contentSecurityPolicy: false, 
  crossOriginEmbedderPolicy: false,
}));

// --- CORS Configuration ---
const allowedOrigins = [
  env.frontendUrl,
  env.adminWebUrl,
  env.backendUrl,
  'http://localhost:5173', // React Vite default port
  'https://api.queensmarrybeautysaloon.com',
  'https://aztrosyssalonappapi.ddns.net',
  'https://queensmarrybeautysaloon.com',
  'https://www.queensmarrybeautysaloon.com',
].filter(Boolean);

const corsOptions = {
  origin: (origin, callback) => {
    // Allow mobile apps (no origin)
    if (!origin) return callback(null, true);

    // Allow local development (localhost, 127.0.0.1, Android emulator 10.0.2.2, local network)
    if (origin.startsWith('http://localhost') || origin.startsWith('http://127.0.0.1') || origin.startsWith('http://10.0.2.2') || origin.startsWith('http://10.') || origin.startsWith('http://192.168.')) {
      return callback(null, true);
    }

    // Allow Vercel deployments and whitelisted URLs
    if (origin.endsWith('.vercel.app') || allowedOrigins.includes(origin)) {
      return callback(null, true);
    }

    console.log('❌ Blocking origin:', origin);
    return callback(new Error('Not allowed by CORS'));
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
  exposedHeaders: ['Content-Range', 'X-Content-Range'],
};

app.use(cors(corsOptions));
app.options('*', cors(corsOptions)); 
app.use(compression()); 

// --- Webhooks (Must be before express.json for raw body parsing) ---
const paymentsController = require('./modules/payments/payments.controller');
app.get(`/api/${API_VERSION}/payments/webhook`, (req, res) => {
  const baseUrl = (req.protocol || 'https') + '://' + (req.get('host') || 'YOUR_SERVER');
  res.json({ ok: true, webhookUrl: `${baseUrl}/api/${API_VERSION}/payments/webhook` });
});
app.post(`/api/${API_VERSION}/payments/webhook`, express.raw({ type: 'application/json' }), paymentsController.handleWebhook);

// --- Body Parsers ---
app.use(express.json({ limit: '10mb' })); 
app.use(express.urlencoded({ extended: true, limit: '10mb' })); 

// --- Logging ---
app.use((req, res, next) => {
  console.log(`\n📥 ${new Date().toISOString()} - ${req.method} ${req.path}`);
  console.log(`   Origin: ${req.headers.origin || 'None (mobile app)'}`);
  if (req.body && Object.keys(req.body).length > 0) {
    const safeBody = { ...req.body };
    if (safeBody.password) safeBody.password = '***HIDDEN***'; // Keep logs secure
    console.log(`   Body: ${JSON.stringify(safeBody).substring(0, 200)}`);
  }
  next();
});
app.use(morgan(env.isDevelopment ? 'dev' : 'combined'));

// --- Rate Limiting ---
const limiter = rateLimit({
  windowMs: env.rateLimit?.windowMs || 15 * 60 * 1000,
  max: env.rateLimit?.maxRequests || 100,
  standardHeaders: true,
  legacyHeaders: false,
  skip: (req) => {
    const origin = req.headers.origin || '';
    return origin === env.adminWebUrl || origin.endsWith('.vercel.app') || origin.includes('localhost');
  },
  handler: (req, res) => res.status(429).json({ success: false, message: 'Too many requests.' }),
});
app.use('/api/', limiter);

// --- Static Files ---
const uploadsDir = path.join(process.cwd(), 'uploads');
if (!fs.existsSync(uploadsDir)) fs.mkdirSync(uploadsDir, { recursive: true });
// Override Helmet's default Cross-Origin-Resource-Policy: same-origin so that
// cross-origin pages (admin, mobile) can load uploaded images in <img> tags.
app.use(`/api/${API_VERSION}/uploads`, (req, res, next) => {
  res.setHeader('Cross-Origin-Resource-Policy', 'cross-origin');
  next();
}, express.static(uploadsDir));

// --- Utility Routes ---
app.get('/', (req, res) => res.json({ success: true, message: 'Salon Booking API', version: API_VERSION }));
app.get('/health', (req, res) => res.json({ success: true, message: 'Server is running' }));
app.get(`/api/${API_VERSION}/health`, (req, res) => res.json({ success: true, message: 'API is healthy' }));

// Disable caching on auth routes
const noCache = (req, res, next) => {
  res.set('Cache-Control', 'no-store');
  res.set('Pragma', 'no-cache');
  next();
};

// --- Mount API Routes ---
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
app.use(`/api/${API_VERSION}/payments/jazzcash`, jazzcashRoutes);
app.use(`/api/${API_VERSION}`, offersRoutes);
app.use(`/api/${API_VERSION}`, blogsRoutes);
app.use(`/api/${API_VERSION}/reports`, reportsRoutes);
app.use(`/api/${API_VERSION}`, reviewsRoutes);
app.use(`/api/${API_VERSION}`, favoritesRoutes);

// Mount dashboard routes safely
if (dashboardRoutes) {
  app.use(`/api/${API_VERSION}/dashboard`, dashboardRoutes);
}

// --- 404 Handler ---
app.use((req, res) => {
  console.log(`❌ 404 - Route not found: ${req.method} ${req.path}`);
  res.status(404).json({ success: false, message: 'Route not found', path: req.path });
});

// --- Global Error Handler ---
app.use((err, req, res, next) => {
  console.error(`❌ Error [${req.method} ${req.path}]:`, err.message);
  res.status(err.status || 500).json({
    success: false,
    message: err.message || 'Internal server error',
    ...(env.isDevelopment && { stack: err.stack }),
  });
});

module.exports = app;