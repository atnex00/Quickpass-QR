const request = require('supertest');
const jwt = require('jsonwebtoken');

jest.mock('uuid', () => ({ v4: () => 'mock-uuid' }));

const makeChain = () => {
  let resolveValue;
  const chain = jest.fn(() => chain);
  chain.then = (onFulfilled) => {
    const v = resolveValue;
    resolveValue = undefined;
    return Promise.resolve(v).then(onFulfilled);
  };
  chain.resolve = (v) => { resolveValue = v; };
  chain.where = jest.fn().mockReturnValue(chain);
  chain.andWhere = jest.fn().mockReturnValue(chain);
  chain.orWhere = jest.fn().mockReturnValue(chain);
  chain.whereNot = jest.fn().mockReturnValue(chain);
  chain.whereIn = jest.fn().mockReturnValue(chain);
  chain.whereNotIn = jest.fn().mockReturnValue(chain);
  chain.whereBetween = jest.fn().mockReturnValue(chain);
  chain.leftJoin = jest.fn().mockReturnValue(chain);
  chain.join = jest.fn().mockReturnValue(chain);
  chain.select = jest.fn().mockReturnValue(chain);
  chain.clearSelect = jest.fn().mockReturnValue(chain);
  chain.orderBy = jest.fn().mockReturnValue(chain);
  chain.limit = jest.fn().mockReturnValue(chain);
  chain.offset = jest.fn().mockReturnValue(chain);
  chain.forUpdate = jest.fn().mockReturnValue(chain);
  chain.modify = jest.fn((fn) => { fn(chain); return chain; });
  chain.groupBy = jest.fn().mockReturnValue(chain);
  chain.first = jest.fn();
  chain.insert = jest.fn();
  chain.update = jest.fn();
  chain.del = jest.fn();
  chain.count = jest.fn().mockReturnValue(chain);
  chain.clone = jest.fn().mockReturnValue(chain);
  chain.raw = jest.fn((sql) => sql);
  return chain;
};

jest.mock('../config/database', () => {
  const chain = makeChain();
  const db = jest.fn(() => chain);
  db.where = jest.fn().mockReturnValue(chain);
  db.leftJoin = jest.fn().mockReturnValue(chain);
  db.join = jest.fn().mockReturnValue(chain);
  db.select = jest.fn().mockReturnValue(chain);
  db.orderBy = jest.fn().mockReturnValue(chain);
  db.modify = jest.fn((fn) => { fn(chain); return chain; });
  db.andWhere = jest.fn().mockReturnValue(chain);
  db.first = chain.first;
  db.insert = chain.insert;
  db.update = chain.update;
  db.del = chain.del;
  db.count = jest.fn(() => chain);
  db.fn = { now: jest.fn(() => 'NOW()') };
  db.raw = jest.fn((sql) => sql);
  db.table = db;
  db.transaction = jest.fn((cb) => {
    const trx = makeChain();
    trx.fn = { now: jest.fn(() => 'NOW()') };
    return cb(trx);
  });
  return db;
});

jest.mock('../services/qrService', () => ({
  decodeQrData: jest.fn((data) => {
    try {
      const json = Buffer.from(data, 'base64').toString('utf8');
      return JSON.parse(json);
    } catch { return null; }
  }),
  verifySignature: jest.fn((leaveId, empId, type, timestamp, sig, secret) => {
    const crypto = require('crypto');
    const expected = crypto.createHmac('sha256', secret || process.env.QR_SECRET || 'test-qr-secret')
      .update(JSON.stringify({ leave_id: leaveId, employee_id: empId, type, timestamp }))
      .digest('hex');
    return sig === expected;
  }),
  isWithinTimeWindow: jest.fn(() => true),
}));

jest.mock('../services/notificationService', () => ({
  sendToEmployee: jest.fn().mockResolvedValue(),
}));

const db = require('../config/database');

process.env.JWT_SECRET = 'test-jwt-secret';
process.env.QR_SECRET = 'test-qr-secret';
process.env.NODE_ENV = 'test';

const app = require('../app');

const today = new Date().toISOString().split('T')[0];
const now = new Date().toISOString();

function signQR(payload) {
  const crypto = require('crypto');
  const data = JSON.stringify({ leave_id: payload.leave_id, employee_id: payload.employee_id, type: payload.type, timestamp: payload.timestamp });
  const signature = crypto.createHmac('sha256', process.env.QR_SECRET).update(data).digest('hex');
  return Buffer.from(JSON.stringify({ ...payload, signature })).toString('base64');
}

function secToken() {
  return jwt.sign(
    { employee_id: '090901', session_id: 's1', role: 'security' },
    process.env.JWT_SECRET,
    { expiresIn: '1h' }
  );
}

describe('POST /api/scan/validate', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('returns 400 when QR data is empty', async () => {
    db.first
      .mockResolvedValueOnce({ is_active: true, session_id: 's1' })
      .mockResolvedValueOnce({ employee_id: '090901', is_security: true, is_active: true });
    const res = await request(app)
      .post('/api/scan/validate')
      .set('Authorization', `Bearer ${secToken()}`)
      .send({ qr_data: '' });
    expect(res.status).toBe(400);
  });

  it('returns 200 for valid OUT scan', async () => {
    db.first
      .mockResolvedValueOnce({ is_active: true, session_id: 's1' })
      .mockResolvedValueOnce({ employee_id: '090901', is_security: true, is_active: true });
    const qr = signQR({ leave_id: 'LV-001', employee_id: '000001', type: 'OUT', timestamp: now });
    const leaveRow = { leave_id: 'LV-001', employee_id: '000001', status: 'approved', employee_name: 'James Wilson', out_scan_time: null, leave_date: today, start_time: '09:00', end_time: '17:00' };
    db.transaction.mockImplementationOnce((cb) => {
      const trx = makeChain();
      trx.fn = { now: jest.fn(() => 'NOW()') };
      trx.first
        .mockResolvedValueOnce(leaveRow)
        .mockResolvedValueOnce(null);
      return cb(trx);
    });
    const res = await request(app)
      .post('/api/scan/validate')
      .set('Authorization', `Bearer ${secToken()}`)
      .send({ qr_data: qr });
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
  });

  it('returns 400 for invalid QR signature', async () => {
    db.first
      .mockResolvedValueOnce({ is_active: true, session_id: 's1' })
      .mockResolvedValueOnce({ employee_id: '090901', is_security: true, is_active: true });
    const fakeQr = Buffer.from(JSON.stringify({ leave_id: 'LV-001', employee_id: '000001', type: 'OUT', timestamp: now, signature: 'badsig' })).toString('base64');
    const res = await request(app)
      .post('/api/scan/validate')
      .set('Authorization', `Bearer ${secToken()}`)
      .send({ qr_data: fakeQr });
    expect(res.status).toBe(400);
    expect(res.body.message).toContain('signature');
  });

  it('returns 400 for invalid base64', async () => {
    db.first
      .mockResolvedValueOnce({ is_active: true, session_id: 's1' })
      .mockResolvedValueOnce({ employee_id: '090901', is_security: true, is_active: true });
    const res = await request(app)
      .post('/api/scan/validate')
      .set('Authorization', `Bearer ${secToken()}`)
      .send({ qr_data: '!!!not-valid-b64!!!' });
    expect(res.status).toBe(400);
    expect(res.body.message).toContain('Invalid QR');
  });
});

describe('GET /api/scan/history', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('returns scan history', async () => {
    db.first
      .mockResolvedValueOnce({ is_active: true, session_id: 's1' })
      .mockResolvedValueOnce({ employee_id: '090901', is_security: true, is_active: true })
      .mockResolvedValueOnce({ count: 2 });
    db().resolve([
      { log_id: 1, leave_id: 'LV-001', scanned_by: '090901', qr_type: 'OUT', scan_time: now, employee_name: 'James Wilson' },
    ]);
    const res = await request(app)
      .get('/api/scan/history')
      .set('Authorization', `Bearer ${secToken()}`);
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body.data)).toBe(true);
  });
});
