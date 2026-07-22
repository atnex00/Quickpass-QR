const logger = require('../config/logger');

function errorHandler(err, req, res, _next) {
  const isDev = process.env.NODE_ENV === 'development';
  const log = req?.log || logger;
  log.error({ err, statusCode: err.statusCode || 500 }, err.message);

  const statusCode = err.statusCode || 500;
  const isPrivileged = req.user && (req.user.is_admin || req.user.is_supervisor);
  const showMessage = err.expose && (isPrivileged || statusCode < 500);
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
