const logger = require('../config/logger');

function errorHandler(err, req, res, _next) {
  const isDev = process.env.NODE_ENV === 'development';
  const log = req?.log || logger;
  const statusCode = err.statusCode || 500;

  if (statusCode >= 500) {
    log.error({ err, statusCode }, err.message);
  } else if (statusCode !== 404) {
    log.warn({ err, statusCode }, err.message);
  }

  const showMessage = err.expose && statusCode < 500;
  const message = showMessage ? err.message : 'Internal server error';

  res.status(statusCode).json({
    success: false,
    message,
    ...(isDev && { stack: err.stack }),
  });
}

function createError(statusCode, message) {
  const err = new Error(message);
  err.statusCode = statusCode;
  err.expose = true;
  return err;
}

module.exports = { errorHandler, createError };
