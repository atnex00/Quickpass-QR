const pino = require('pino');

const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  ...(process.env.NODE_ENV === 'test' && { enabled: false }),
  redact: ['req.headers.cookie', 'req.headers.authorization'],
});

module.exports = logger;
