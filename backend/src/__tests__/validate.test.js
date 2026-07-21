const Joi = require('joi');
const { validate } = require('../middleware/validate');

function mockReqRes(body) {
  const req = { body };
  const res = {
    status: jest.fn().mockReturnThis(),
    json: jest.fn(),
  };
  const next = jest.fn();
  return { req, res, next };
}

describe('validate middleware', () => {
  it('calls next when validation passes', () => {
    const schema = Joi.object({ name: Joi.string().required() });
    const middleware = validate(schema);
    const { req, res, next } = mockReqRes({ name: 'Alice' });

    middleware(req, res, next);

    expect(next).toHaveBeenCalled();
    expect(res.status).not.toHaveBeenCalled();
  });

  it('strips unknown fields', () => {
    const schema = Joi.object({ name: Joi.string().required() });
    const middleware = validate(schema);
    const { req, res, next } = mockReqRes({ name: 'Alice', extra: 'should-be-stripped' });

    middleware(req, res, next);

    expect(next).toHaveBeenCalled();
    expect(req.body).toEqual({ name: 'Alice' });
  });

  it('returns 400 with error messages when validation fails', () => {
    const schema = Joi.object({ name: Joi.string().required() });
    const middleware = validate(schema);
    const { req, res, next } = mockReqRes({});

    middleware(req, res, next);

    expect(next).not.toHaveBeenCalled();
    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({
      success: false,
      message: expect.stringContaining('name'),
    });
  });

  it('joins multiple errors with semicolons', () => {
    const schema = Joi.object({
      name: Joi.string().required(),
      age: Joi.number().min(0).required(),
    });
    const middleware = validate(schema);
    const { req, res, next } = mockReqRes({});

    middleware(req, res, next);

    expect(res.json).toHaveBeenCalledWith({
      success: false,
      message: expect.stringMatching(/.*;.*/),
    });
  });
});
