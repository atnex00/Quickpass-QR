describe('sentry config', () => {
  const OLD_ENV = process.env;

  beforeEach(() => {
    jest.resetModules();
    process.env = { ...OLD_ENV };
  });

  afterAll(() => {
    process.env = OLD_ENV;
  });

  describe('init', () => {
    it('does nothing when SENTRY_DSN is not set', () => {
      delete process.env.SENTRY_DSN;

      const sentry = require('../config/sentry');
      expect(() => sentry.init()).not.toThrow();
    });

    it('initializes Sentry when SENTRY_DSN is set', () => {
      process.env.SENTRY_DSN = 'https://key@sentry.io/project';
      jest.mock('@sentry/node', () => ({
        init: jest.fn(),
        Handlers: { errorHandler: jest.fn() },
      }));

      const sentry = require('../config/sentry');
      sentry.init();

      expect(require('@sentry/node').init).toHaveBeenCalledWith(expect.objectContaining({
        dsn: 'https://key@sentry.io/project',
      }));
    });
  });

  describe('setupErrorHandler', () => {
    it('does not add handler when Sentry was not initialized', () => {
      delete process.env.SENTRY_DSN;

      const sentry = require('../config/sentry');
      const app = { use: jest.fn() };

      sentry.setupErrorHandler(app);

      expect(app.use).not.toHaveBeenCalled();
    });

    it('adds error handler when Sentry was initialized', () => {
      process.env.SENTRY_DSN = 'https://key@sentry.io/project';
      const mockHandler = jest.fn();
      jest.mock('@sentry/node', () => ({
        init: jest.fn(),
        Handlers: { errorHandler: () => mockHandler },
      }));

      const sentry = require('../config/sentry');
      sentry.init();

      const app = { use: jest.fn() };
      sentry.setupErrorHandler(app);

      expect(app.use).toHaveBeenCalled();
    });
  });
});