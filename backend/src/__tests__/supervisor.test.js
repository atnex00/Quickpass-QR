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
  generateQrData: jest.fn(() => ({
    leave_id: 'LV-001', employee_id: '000001', type: 'OUT', timestamp: new Date().toISOString(), signature: 'abc',
  })),
  encodeQrData: jest.fn((d) => Buffer.from(JSON.stringify(d)).toString('base64')),
}));

jest.mock('../services/qrImageService', () => ({
  generateQrImage: jest.fn().mockResolvedValue('qr-image-data'),
  deleteQrImages: jest.fn(),
}));

const db = require('../config/database');

process.env.JWT_SECRET = 'test-jwt-secret';
process.env.QR_SECRET = 'test-qr-secret';
process.env.NODE_ENV = 'test';

const { getLocalDateString } = require('../utils/date');
const today = getLocalDateString();

const app = require('../app');

function supToken() {
  return jwt.sign(
    { employee_id: '000004', session_id: 's1', role: 'supervisor' },
    process.env.JWT_SECRET,
    { expiresIn: '1h' }
  );
}

function adminToken() {
  return jwt.sign(
    { employee_id: '999999', session_id: 's1', role: 'admin' },
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

describe('GET /api/supervisor/pending', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('returns pending requests for supervisor', async () => {
    mockAuth({ employee_id: '000004', department_id: 'DEPT01', is_supervisor: true, is_active: true });
    db().resolve([
      { leave_id: 'LV-001', status: 'pending', employee_name: 'Alice Chen' },
    ]);
    const res = await request(app)
      .get('/api/supervisor/pending')
      .set('Authorization', `Bearer ${supToken()}`);
    expect(res.status).toBe(200);
    expect(res.body.data).toHaveLength(1);
  });

  it('returns all pending for admin', async () => {
    mockAuth({ employee_id: '999999', is_admin: true, is_active: true });
    db().resolve([
      { leave_id: 'LV-001', status: 'pending', employee_name: 'Alice' },
      { leave_id: 'LV-002', status: 'pending', employee_name: 'Bob' },
    ]);
    const res = await request(app)
      .get('/api/supervisor/pending')
      .set('Authorization', `Bearer ${adminToken()}`);
    expect(res.status).toBe(200);
    expect(res.body.data).toHaveLength(2);
  });
});

describe('POST /api/supervisor/approve/:leaveId', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('returns 200 on successful approval', async () => {
    mockAuth({ employee_id: '000004', department_id: 'DEPT01', is_supervisor: true, is_active: true });
    db.first.mockResolvedValueOnce({
      leave_id: 'LV-001', employee_id: '000001', status: 'approved', employee_name: 'Alice Chen',
    });
    db.transaction.mockImplementationOnce((cb) => {
      const trx = makeChain();
      trx.fn = { now: jest.fn(() => 'NOW()') };
      trx.first.mockResolvedValueOnce({ leave_id: 'LV-001', employee_id: '000001', status: 'pending', supervisor_id: '000004', department_id: 'DEPT01', leave_date: today, start_time: '09:00', end_time: '17:00' });
      return cb(trx);
    });
    const res = await request(app)
      .post('/api/supervisor/approve/LV-001')
      .set('Authorization', `Bearer ${supToken()}`);
    expect(res.status).toBe(200);
  });

  it('returns 404 if leave not found', async () => {
    mockAuth({ employee_id: '000004', department_id: 'DEPT01', is_supervisor: true, is_active: true });
    db.transaction.mockImplementationOnce((cb) => {
      const trx = makeChain();
      trx.fn = { now: jest.fn(() => 'NOW()') };
      trx.first.mockResolvedValueOnce(null);
      return cb(trx);
    });
    const res = await request(app)
      .post('/api/supervisor/approve/LV-999')
      .set('Authorization', `Bearer ${supToken()}`);
    expect(res.status).toBe(404);
  });
});

describe('POST /api/supervisor/reject/:leaveId', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('returns 200 on successful rejection', async () => {
    mockAuth({ employee_id: '000004', department_id: 'DEPT01', is_supervisor: true, is_active: true });
    db.first
      .mockResolvedValueOnce({ leave_id: 'LV-001', employee_id: '000001', status: 'pending', supervisor_id: '000004', department_id: 'DEPT01', leave_date: today })
      .mockResolvedValueOnce({ leave_id: 'LV-001', employee_id: '000001', status: 'rejected', employee_name: 'Alice Chen' });
    const res = await request(app)
      .post('/api/supervisor/reject/LV-001')
      .set('Authorization', `Bearer ${supToken()}`)
      .send({ reason: 'Not enough staff' });
    expect(res.status).toBe(200);
  });

  it('returns 404 if leave not found', async () => {
    mockAuth({ employee_id: '000004', department_id: 'DEPT01', is_supervisor: true, is_active: true });
    db.first.mockResolvedValueOnce(null);
    const res = await request(app)
      .post('/api/supervisor/reject/LV-999')
      .set('Authorization', `Bearer ${supToken()}`)
      .send({ reason: 'Not enough staff' });
    expect(res.status).toBe(404);
  });
});

describe('POST /api/supervisor/revoke/:leaveId', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('returns 200 on successful revocation', async () => {
    mockAuth({ employee_id: '000004', department_id: 'DEPT01', is_supervisor: true, is_active: true });
    db.first
      .mockResolvedValueOnce({ leave_id: 'LV-001', employee_id: '000001', status: 'approved', supervisor_id: '000004', department_id: 'DEPT01', leave_date: today })
      .mockResolvedValueOnce({ leave_id: 'LV-001', employee_id: '000001', status: 'pending', employee_name: 'Alice Chen' });
    const res = await request(app)
      .post('/api/supervisor/revoke/LV-001')
      .set('Authorization', `Bearer ${supToken()}`);
    expect(res.status).toBe(200);
  });
});

describe('GET /api/supervisor/team-leaves', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('returns team leaves with date filter', async () => {
    mockAuth({ employee_id: '000004', department_id: 'DEPT01', is_supervisor: true, is_active: true });
    db().resolve([
      { leave_id: 'LV-001', status: 'approved', employee_name: 'Alice Chen' },
    ]);
    const res = await request(app)
      .get('/api/supervisor/team-leaves')
      .query({ date: today })
      .set('Authorization', `Bearer ${supToken()}`);
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body.data)).toBe(true);
  });
});
