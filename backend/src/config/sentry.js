let Sentry = null;

function init() {
  if (!process.env.SENTRY_DSN) {
    return;
  }
  try {
    Sentry = require('@sentry/node');
    Sentry.init({
      dsn: process.env.SENTRY_DSN,
      environment: process.env.NODE_ENV || 'development',
      tracesSampleRate: parseFloat(process.env.SENTRY_SAMPLE_RATE || '0.1'),
      maxBreadcrumbs: 50,
    });
  } catch {
    // @sentry/node not installed
  }
}

function setupErrorHandler(app) {
  if (Sentry) {
    app.use(Sentry.Handlers.errorHandler());
  }
}

module.exports = { init, setupErrorHandler };