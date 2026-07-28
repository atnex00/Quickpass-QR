const pino = require('pino');
const path = require('path');
const fs = require('fs');

const logDir = path.join(__dirname, '../../logs');
if (!fs.existsSync(logDir)) fs.mkdirSync(logDir, { recursive: true });

const fileDest = pino.destination(path.join(logDir, 'app.log'));
const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  ...(process.env.NODE_ENV === 'test' && { enabled: false }),
  redact: ['req.headers.cookie', 'req.headers.authorization'],
}, pino.multistream([
  { stream: process.stdout },
  { stream: fileDest },
]));

module.exports = logger;
