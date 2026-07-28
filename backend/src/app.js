const path = require('path');
const fs = require('fs');
const crypto = require('crypto');
const dotenv = require('dotenv');
const compression = require('compression');
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

function exitOrThrow(message) {
  if (process.env.NODE_ENV === 'test') {
    throw new Error(message);
  }
  logger.error(message);
  process.exit(1);
}

function requireEnv(name) {
  const value = process.env[name];
  if (!value) {
    exitOrThrow(`${name} is required. Set it in your backend/.env file.`);
  }
  return value;
}

requireEnv('DB_CONNECTION');
requireEnv('JWT_SECRET');
requireEnv('COOKIE_SECRET');
requireEnv('QR_SECRET');

function parseCorsOrigins(origin) {
  if (!origin) return undefined;
  const origins = origin.split(',').map(s => s.trim()).filter(Boolean);
  if (origins.length === 1) return origins[0];
  return origins;
}

const corsOrigin = parseCorsOrigins(process.env.CORS_ORIGIN);
if (corsOrigin === '' || corsOrigin === undefined) {
  logger.warn('CORS_ORIGIN is not set — CORS will be disabled');
}
if (corsOrigin === '*') {
  logger.warn('CORS_ORIGIN is set to wildcard — this is insecure and incompatible with cookie auth. Set a specific origin in production.');
}
if (process.env.NODE_ENV === 'production' && !corsOrigin) {
  exitOrThrow('CORS_ORIGIN is required in production. Set it in your backend/.env file.');
}

const express = require('express');
const https = require('https');
const jwt = require('jsonwebtoken');
const helmet = require('helmet');
const cors = require('cors');
const cookieParser = require('cookie-parser');
const rateLimit = require('express-rate-limit');
const { initFirebase } = require('./config/firebase');
const sentry = require('./config/sentry');
const { errorHandler } = require('./middleware/errorHandler');
const routes = require('./routes');
const db = require('./config/database');

const app = express();
const PORT = process.env.PORT || 3000;

// Initialize Firebase
initFirebase();

// Initialize Sentry (optional, skips if SENTRY_DSN not set)
sentry.init();

// Middleware
app.use(helmet());
app.use(compression());
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

// Global rate limit — per-user when authenticated, per-IP otherwise
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => {
    if (req.user) return `user:${req.user.employee_id}`;
    const auth = req.headers.authorization;
    if (auth && auth.startsWith('Bearer ')) {
      try {
        const decoded = jwt.verify(auth.split(' ')[1], process.env.JWT_SECRET, { algorithms: ['HS256'] });
        if (decoded && decoded.employee_id) return `user:${decoded.employee_id}`;
      } catch {
        // Token invalid or expired — fall through to IP-based key
      }
    }
    return `ip:${req.ip}`;
  },
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

// Sentry error handler (must be after all other middleware/controllers)
sentry.setupErrorHandler(app);

process.on('uncaughtException', (err) => {
  logger.fatal({ err }, 'Uncaught exception — shutting down');
  process.exit(1);
});

process.on('unhandledRejection', (reason) => {
  logger.error({ err: reason }, 'Unhandled promise rejection');
  if (process.env.NODE_ENV === 'production') {
    process.exit(1);
  }
});

async function cleanupStartup() {
  const expiredSessions = await db('sessions')
    .where('expires_at', '<', db.fn.now())
    .where('is_active', true)
    .update({ is_active: false });
  if (expiredSessions > 0) {
    logger.info({ count: expiredSessions }, 'Expired stale sessions on startup');
  }
}

if (require.main === module) {
  let server;

  async function start() {
    await db.testConnection();
    await cleanupStartup();

    server = app.listen(PORT, () => {
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

  start().catch((err) => {
    logger.fatal({ err }, 'Failed to start server');
    process.exit(1);
  });

  const shutdown = async (signal) => {
    logger.info({ signal }, 'Shutting down gracefully');
    if (server) {
      server.close(() => {
        db.destroy().then(() => process.exit(0)).catch(() => process.exit(1));
      });
      setTimeout(() => process.exit(1), 10000).unref();
    } else {
      process.exit(0);
    }
  };

  process.on('SIGTERM', () => shutdown('SIGTERM'));
  process.on('SIGINT', () => shutdown('SIGINT'));
}

module.exports = app;
