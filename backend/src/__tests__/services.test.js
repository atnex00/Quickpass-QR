const Joi = require('joi');

describe('qrService', () => {
  const OLD_ENV = process.env;

  beforeEach(() => {
    jest.resetModules();
    process.env = { ...OLD_ENV, QR_SECRET: 'test-secret' };
  });

  afterAll(() => {
    process.env = OLD_ENV;
  });

  describe('createSignature / verifySignature', () => {
    it('creates and verifies a signature', () => {
      const qrService = require('../services/qrService');
      const sig = qrService.createSignature('LV-001', '000001', 'OUT', '2026-07-22T09:00:00+08:00');
      expect(sig).toMatch(/^[a-f0-9]{64}$/);
      const valid = qrService.verifySignature('LV-001', '000001', 'OUT', '2026-07-22T09:00:00+08:00', sig);
      expect(valid).toBe(true);
    });

    it('fails verification with wrong payload', () => {
      const qrService = require('../services/qrService');
      const sig = qrService.createSignature('LV-001', '000001', 'OUT', '2026-07-22T09:00:00+08:00');
      const valid = qrService.verifySignature('LV-002', '000001', 'OUT', '2026-07-22T09:00:00+08:00', sig);
      expect(valid).toBe(false);
    });
  });

  describe('encodeQrData / decodeQrData', () => {
    it('encodes and decodes QR data', () => {
      const qrService = require('../services/qrService');
      const data = { leave_id: 'LV-001', employee_id: '000001', type: 'OUT', timestamp: '2026-07-22T09:00:00+08:00', signature: 'abc' };
      const encoded = qrService.encodeQrData(data);
      expect(typeof encoded).toBe('string');
      const decoded = qrService.decodeQrData(encoded);
      expect(decoded.leave_id).toBe('LV-001');
    });

    it('returns null for invalid input', () => {
      const qrService = require('../services/qrService');
      expect(qrService.decodeQrData('!!!not-valid!!!')).toBeNull();
    });
  });

  describe('generateQrData', () => {
    it('generates QR data with signature', () => {
      const qrService = require('../services/qrService');
      const data = qrService.generateQrData('LV-001', '000001', 'OUT', '2026-07-22', '09:00');
      expect(data.leave_id).toBe('LV-001');
      expect(data.type).toBe('OUT');
      expect(data.signature).toMatch(/^[a-f0-9]{64}$/);
    });
  });

  describe('isWithinTimeWindow', () => {
    it('returns true for recent timestamp', () => {
      const qrService = require('../services/qrService');
      const recent = new Date().toISOString();
      expect(qrService.isWithinTimeWindow(recent, 15)).toBe(true);
    });

    it('returns false for old timestamp', () => {
      const qrService = require('../services/qrService');
      const old = new Date(Date.now() - 30 * 60 * 1000).toISOString();
      expect(qrService.isWithinTimeWindow(old, 15)).toBe(false);
    });
  });
});

describe('validate middleware', () => {
  const { validate, validateQuery } = require('../middleware/validate');

  function mockReqRes(body) {
    const req = { body, query: {} };
    const res = { status: jest.fn().mockReturnThis(), json: jest.fn() };
    const next = jest.fn();
    return { req, res, next };
  }

  describe('validate', () => {
    it('calls next when validation passes', () => {
      const schema = Joi.object({ name: Joi.string().required() });
      const middleware = validate(schema);
      const { req, res, next } = mockReqRes({ name: 'Alice' });
      middleware(req, res, next);
      expect(next).toHaveBeenCalled();
      expect(req.body.name).toBe('Alice');
    });

    it('returns 400 when validation fails', () => {
      const schema = Joi.object({ name: Joi.string().required() });
      const middleware = validate(schema);
      const { req, res, next } = mockReqRes({});
      middleware(req, res, next);
      expect(res.status).toHaveBeenCalledWith(400);
      expect(next).not.toHaveBeenCalled();
    });

    it('strips unknown fields', () => {
      const schema = Joi.object({ name: Joi.string().required() });
      const middleware = validate(schema);
      const { req, res, next } = mockReqRes({ name: 'Alice', extra: 'should be stripped' });
      middleware(req, res, next);
      expect(req.body.extra).toBeUndefined();
    });
  });

  describe('validateQuery', () => {
    it('calls next when validation passes', () => {
      const schema = Joi.object({ page: Joi.number().default(1) });
      const middleware = validateQuery(schema);
      const { req, res, next } = mockReqRes({});
      req.query = { page: '2' };
      middleware(req, res, next);
      expect(next).toHaveBeenCalled();
      expect(req.query.page).toBe(2);
    });
  });
});

describe('getLocalDateString', () => {
  it('returns date string in YYYY-MM-DD format', () => {
    const { getLocalDateString } = require('../utils/date');
    const d = new Date('2026-07-22T12:00:00');
    const result = getLocalDateString(d);
    expect(result).toMatch(/^\d{4}-\d{2}-\d{2}$/);
  });
});
