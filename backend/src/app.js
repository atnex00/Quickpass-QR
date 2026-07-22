const path = require('path');
const fs = require('fs');
const crypto = require('crypto');
const dotenv = require('dotenv');
const logger = require('./config/logger');

function loadEnv() {
  const baseEnv = path.join(__dirname, '..', '.env');
  const envFile = path.join(__dirname, '..', `.env.${process.env.NODE_ENV || 'dev'}`);
  if (fs.existsSync(baseEnv)) {
    dotenv.config({ path: baseEnv });
  }
  if (fs.existsSync(envFile) && envFile !== baseEnv) {
    dotenv.config({ path: envFile });
  }
}

loadEnv();

function requireEnv(name) {
  const value = process.env[name];
  if (!value) {
    logger.error(`${name} is required. Set it in your backend/.env file.`);
    process.exit(1);
  }
  return value;
}

function secret(name) {
  const value = process.env[name];
  if (value) return value;
  if (process.env.NODE_ENV === 'production') {
    logger.error(`${name} is required in production. Set it in your backend/.env file.`);
    process.exit(1);
  }
  const generated = crypto.randomBytes(64).toString('hex');
  logger.warn(`${name} is not set. Set it in your backend/.env file. Generated a random value for this session.`);
  return generated;
}

requireEnv('DB_CONNECTION');
process.env.JWT_SECRET = secret('JWT_SECRET');
process.env.COOKIE_SECRET = secret('COOKIE_SECRET');
process.env.QR_SECRET = secret('QR_SECRET');

const corsOrigin = process.env.CORS_ORIGIN || undefined;
if (corsOrigin === '') {
  logger.warn('CORS_ORIGIN is set but empty — CORS will be disabled');
}
if (process.env.NODE_ENV === 'production' && !corsOrigin) {
  logger.error('CORS_ORIGIN is required in production. Set it in your backend/.env file.');
  process.exit(1);
}

const express = require('express');
const https = require('https');
const helmet = require('helmet');
const cors = require('cors');
const cookieParser = require('cookie-parser');
const rateLimit = require('express-rate-limit');
const { initFirebase } = require('./config/firebase');
const { errorHandler } = require('./middleware/errorHandler');
const routes = require('./routes');

const app = express();
const PORT = process.env.PORT || 3000;

// Initialize Firebase
initFirebase();

// Middleware
app.use(helmet());
if (corsOrigin) {
  app.use(helmet.contentSecurityPolicy({
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'", "'unsafe-inline'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      imgSrc: ["'self'", "data:", "https:"],
      connectSrc: ["'self'", corsOrigin],
      fontSrc: ["'self'", "https://fonts.gstatic.com"],
      objectSrc: ["'none'"],
      frameAncestors: ["'none'"],
    },
  }));
}
app.use(cors({ origin: corsOrigin || false, credentials: true }));

// Request ID tracing
app.use((req, res, next) => {
  req.id = crypto.randomUUID();
  res.setHeader('X-Request-Id', req.id);
  req.log = logger.child({ reqId: req.id, method: req.method, url: req.url });
  next();
});

app.use(cookieParser(process.env.COOKIE_SECRET));
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true }));

// Trust proxy for rate limiting behind reverse proxy
app.set('trust proxy', 1);

// Global rate limit
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, message: 'Too many requests, please try again later' },
});
app.use(limiter);

// Stricter rate limit for login
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, message: 'Too many login attempts, please try again later' },
});

// Rate limit for auth endpoints (refresh, etc.)
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 30,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, message: 'Too many requests, please try again later' },
});

// Stricter rate limit for bulk import
const importLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, message: 'Too many import requests, please try again later' },
});

// Serve built frontend in production
const webDist = path.join(__dirname, '../../web/dist');
app.use(express.static(webDist));

// Serve uploaded files
const uploadsDir = path.join(__dirname, '../uploads');
app.use('/uploads', express.static(uploadsDir));

// Routes
app.use('/api/auth/login', loginLimiter);
app.use('/api/auth/refresh', authLimiter);
app.use('/api/admin/import/hr', importLimiter);
app.use('/api', routes);

// SPA fallback — serve index.html for any non-API, non-static route
app.use((req, res, next) => {
  if (req.method === 'GET' && !req.path.startsWith('/api')) {
    return res.sendFile(path.join(webDist, 'index.html'));
  }
  next();
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ success: false, message: `Route ${req.originalUrl} not found` });
});

// Error handler
app.use(errorHandler);

process.on('uncaughtException', (err) => {
  logger.fatal({ err }, 'Uncaught exception — shutting down');
  process.exit(1);
});

process.on('unhandledRejection', (reason) => {
  logger.error({ err: reason }, 'Unhandled promise rejection');
});

if (require.main === module) {
  app.listen(PORT, () => {
    logger.info({ port: PORT, env: process.env.NODE_ENV || 'development' }, 'Quickpass API started');
  });

  // HTTPS server for camera access on mobile
  const keyPath = process.env.HTTPS_KEY || '/tmp/quickpass-key.pem';
  const certPath = process.env.HTTPS_CERT || '/tmp/quickpass-cert.pem';
  try {
    if (fs.existsSync(keyPath) && fs.existsSync(certPath)) {
      const httpsPort = parseInt(process.env.HTTPS_PORT || '3443');
      https.createServer({
        key: fs.readFileSync(keyPath),
        cert: fs.readFileSync(certPath),
      }, app).listen(httpsPort, () => {
        logger.info({ port: httpsPort }, 'Quickpass HTTPS running');
      });
    }
  } catch {
    // HTTPS setup is optional
  }
}

module.exports = app;
