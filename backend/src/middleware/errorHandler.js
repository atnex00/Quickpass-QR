function errorHandler(err, req, res, _next) {
  const isDev = process.env.NODE_ENV === 'development';
  console.error(`[ERROR] ${err.statusCode || 500} ${isDev ? err.stack : err.message}`);

  const statusCode = err.statusCode || 500;
  const message = err.expose ? err.message : 'Internal server error';

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
