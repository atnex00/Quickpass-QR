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

const db = require('../config/database');

process.env.JWT_SECRET = 'test-jwt-secret';
process.env.QR_SECRET = 'test-qr-secret';
process.env.NODE_ENV = 'test';

const { getLocalDateString } = require('../utils/date');
const today = getLocalDateString();

const app = require('../app');

function authToken(overrides = {}) {
  return jwt.sign(
    { employee_id: '000001', session_id: 's1', role: 'employee', ...overrides },
    process.env.JWT_SECRET,
    { expiresIn: '1h' }
  );
}

function mockAuth(employee) {
  db.first
    .mockReset()
    .mockResolvedValueOnce({ is_active: true, session_id: 's1' })
    .mockResolvedValueOnce(employee);
}

describe('POST /api/leave/request', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('returns 400 if Joi validation fails', async () => {
    mockAuth({ employee_id: '000001', is_active: true });
    const res = await request(app)
      .post('/api/leave/request')
      .set('Authorization', `Bearer ${authToken()}`)
      .send({ leave_date: 'not-a-date', start_time: '09:00', end_time: '17:00', reason: 'Reason enough here' });
    expect(res.status).toBe(400);
  });

  it('returns 409 on time conflict', async () => {
    mockAuth({ is_active: true });
    db.first
      .mockResolvedValueOnce({ employee_id: '000001', department_id: 'DEPT01', is_admin: false })
      .mockResolvedValueOnce({ leave_id: 'LV-001' });
    const res = await request(app)
      .post('/api/leave/request')
      .set('Authorization', `Bearer ${authToken()}`)
      .send({ leave_date: today, start_time: '09:00', end_time: '17:00', reason: 'Medical appointment' });
    expect(res.status).toBe(409);
  });

  it('returns 422 if no supervisor found and not admin', async () => {
    mockAuth({ employee_id: '000001', is_active: true });
    db.first
      .mockResolvedValueOnce(null);
    db().resolve([]);
    const res = await request(app)
      .post('/api/leave/request')
      .set('Authorization', `Bearer ${authToken()}`)
      .send({ leave_date: today, start_time: '09:00', end_time: '17:00', reason: 'Family event' });
    expect(res.status).toBe(422);
    expect(res.body.message).toContain('No supervisor found');
  });

  it('returns 201 on successful submission', async () => {
    mockAuth({ employee_id: '000001', is_active: true });
    db.first
      .mockResolvedValueOnce(null)
      .mockResolvedValueOnce({
        leave_id: 'LV-MOCK', employee_id: '000001', status: 'pending', employee_name: 'Alice Chen',
      });
    db().resolve([{ employee_id: '000004' }]);
    const res = await request(app)
      .post('/api/leave/request')
      .set('Authorization', `Bearer ${authToken()}`)
      .send({ leave_date: today, start_time: '09:00', end_time: '17:00', reason: 'Medical appointment' });
    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
  });
});

describe('GET /api/leave/history', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('returns leave history', async () => {
    mockAuth({ employee_id: '000001', is_active: true });
    db.first.mockResolvedValueOnce({ count: 2 });
    const leaves = [
      { leave_id: 'LV-001', status: 'approved', employee_name: 'Alice Chen' },
      { leave_id: 'LV-002', status: 'pending', employee_name: 'Alice Chen' },
    ];
    db().resolve(leaves);
    const res = await request(app)
      .get('/api/leave/history')
      .set('Authorization', `Bearer ${authToken()}`);
    expect(res.status).toBe(200);
    expect(res.body.data).toHaveLength(2);
  });
});

describe('GET /api/leave/active', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('returns active leave when found', async () => {
    mockAuth({ employee_id: '000001', is_active: true });
    db.first.mockResolvedValueOnce({
      leave_id: 'LV-001', status: 'approved', employee_name: 'Alice Chen',
    });
    const res = await request(app)
      .get('/api/leave/active')
      .set('Authorization', `Bearer ${authToken()}`);
    expect(res.status).toBe(200);
    expect(res.body.data.leave_id).toBe('LV-001');
  });

  it('returns 404 when no active leave', async () => {
    mockAuth({ employee_id: '000001', is_active: true });
    db.first.mockResolvedValueOnce(null);
    const res = await request(app)
      .get('/api/leave/active')
      .set('Authorization', `Bearer ${authToken()}`);
    expect(res.status).toBe(404);
  });
});

describe('GET /api/leave/:id', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('returns leave by id for own leave', async () => {
    mockAuth({ employee_id: '000001', is_active: true });
    db.first.mockResolvedValueOnce({
      leave_id: 'LV-001', employee_id: '000001', department_id: 'DEPT01', employee_name: 'Alice Chen',
    });
    const res = await request(app)
      .get('/api/leave/LV-001')
      .set('Authorization', `Bearer ${authToken()}`);
    expect(res.status).toBe(200);
    expect(res.body.data.leave_id).toBe('LV-001');
  });

  it('returns 404 when not found', async () => {
    mockAuth({ employee_id: '000001', is_active: true });
    db.first.mockResolvedValueOnce(null);
    const res = await request(app)
      .get('/api/leave/LV-999')
      .set('Authorization', `Bearer ${authToken()}`);
    expect(res.status).toBe(404);
  });
});

describe('POST /api/leave/:id/cancel', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('returns 404 when leave not found', async () => {
    mockAuth({ employee_id: '000001', is_active: true });
    db.first.mockResolvedValueOnce(null);
    const res = await request(app)
      .post('/api/leave/LV-999/cancel')
      .set('Authorization', `Bearer ${authToken()}`);
    expect(res.status).toBe(404);
  });
});
