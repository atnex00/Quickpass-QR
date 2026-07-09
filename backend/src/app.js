const envFile = `.env.${process.env.NODE_ENV || 'dev'}`;
require('dotenv').config({ path: require('path').join(__dirname, '..', envFile) });

const express = require('express');
const https = require('https');
const fs = require('fs');
const path = require('path');
const helmet = require('helmet');
const cors = require('cors');
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
app.use(cors({ origin: process.env.CORS_ORIGIN || '*' }));
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

// Serve built frontend in production
const webDist = path.join(__dirname, '../../web/dist');
app.use(express.static(webDist));

// Routes
app.use('/api/auth/login', loginLimiter);
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

app.listen(PORT, () => {
  console.log(`Quickpass API running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
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
      console.log(`Quickpass HTTPS running on port ${httpsPort}`);
    });
  }
} catch (_) {
  // HTTPS setup is optional
}

module.exports = app;
