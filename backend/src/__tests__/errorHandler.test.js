const { errorHandler, createError } = require('../middleware/errorHandler');

describe('createError', () => {
  it('creates an error with statusCode and expose flag', () => {
    const err = createError(404, 'Not found');

    expect(err).toBeInstanceOf(Error);
    expect(err.message).toBe('Not found');
    expect(err.statusCode).toBe(404);
    expect(err.expose).toBe(true);
  });
});

describe('errorHandler middleware', () => {
  const OLD_ENV = process.env;

  afterEach(() => {
    process.env = OLD_ENV;
  });

  function setup() {
    const res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn(),
    };
    const next = jest.fn();
    return { res, next };
  }

  it('returns the exposed message and status code for createError', () => {
    const err = createError(400, 'Bad input');
    const { res, next } = setup();

    errorHandler(err, {}, res, next);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({
      success: false,
      message: 'Bad input',
    });
  });

  it('returns generic message for internal errors', () => {
    const err = new Error('Something broke');
    const { res, next } = setup();

    errorHandler(err, {}, res, next);

    expect(res.status).toHaveBeenCalledWith(500);
    expect(res.json).toHaveBeenCalledWith({
      success: false,
      message: 'Internal server error',
    });
  });

  it('includes stack trace in development mode', () => {
    process.env.NODE_ENV = 'development';
    const err = new Error('dev error');
    const { res, next } = setup();

    errorHandler(err, {}, res, next);

    expect(res.json).toHaveBeenCalledWith({
      success: false,
      message: 'Internal server error',
      stack: err.stack,
    });
  });
});
