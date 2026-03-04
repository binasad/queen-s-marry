require('dotenv').config();

const emailPort = parseInt(process.env.EMAIL_PORT || process.env.SMTP_PORT || '587', 10);
const emailSecureExplicit = process.env.EMAIL_SECURE;
const emailSecure =
  emailSecureExplicit !== undefined
    ? emailSecureExplicit === 'true' || emailSecureExplicit === true
    : emailPort === 465;

const env = {
  // Server
  nodeEnv: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.PORT || '5000', 10),
  apiVersion: process.env.API_VERSION || 'v1',

  // Database
  db: {
    host: process.env.DB_HOST, // No default 'localhost' to force env usage
    port: parseInt(process.env.DB_PORT || '5432', 10),
    name: process.env.DB_NAME || 'postgres', // Supabase default is 'postgres'
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD,
    // Constructing a full URI for convenience
    url: process.env.DATABASE_URL || `postgresql://${process.env.DB_USER}:${process.env.DB_PASSWORD}@${process.env.DB_HOST}:${process.env.DB_PORT}/${process.env.DB_NAME}`
  },

  // JWT (from .env - set JWT_SECRET and JWT_REFRESH_SECRET)
  jwt: {
    secret: process.env.JWT_SECRET,
    expiresIn: process.env.JWT_EXPIRES_IN || process.env.JWT_EXPIRE || '7d',
    refreshSecret: process.env.JWT_REFRESH_SECRET,
    refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || process.env.JWT_REFRESH_EXPIRE || '30d',
  },

  // Rate Limiting
  rateLimit: {
    windowMs: parseInt(process.env.RATE_LIMIT_WINDOW || '15', 10) * 60 * 1000,
    maxRequests: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS || '100', 10),
  },

  // Email
  email: {
    host: process.env.EMAIL_HOST || process.env.SMTP_HOST,
    port: emailPort,
    secure: emailSecure,
    user: process.env.EMAIL_USER || process.env.SMTP_USER,
    password: process.env.EMAIL_PASSWORD || process.env.SMTP_PASS || process.env.SMTP_PASSWORD,
    from: process.env.EMAIL_FROM || process.env.SMTP_FROM || 'noreply@salon.com',
  },

  // Google Sign-In (Web OAuth client ID for idToken verification)
  googleWebClientId: process.env.GOOGLE_WEB_CLIENT_ID?.trim() || '',

  // URLs (from .env - local: http://192.168.18.112:5000)
  frontendUrl: process.env.FRONTEND_URL || 'http://localhost:3000',
  adminWebUrl: process.env.ADMIN_WEB_URL || 'http://localhost:3001',
  backendUrl: process.env.BACKEND_URL || 'http://localhost:5000',

  // AWS S3 (from .env - optional)
  s3: {
    region: process.env.AWS_REGION,
    bucket: process.env.AWS_S3_BUCKET,
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
    baseUrl: process.env.AWS_S3_BASE_URL,
  },

  get isDevelopment() { return this.nodeEnv === 'development'; },
  get isProduction() { return this.nodeEnv === 'production'; },
};

module.exports = env;