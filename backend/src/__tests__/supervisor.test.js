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
    const trx = jest.fn(() => chain);
    trx.where = jest.fn().mockReturnValue(chain);
    trx.andWhere = jest.fn().mockReturnValue(chain);
    trx.orWhere = jest.fn().mockReturnValue(chain);
    trx.whereNot = jest.fn().mockReturnValue(chain);
    trx.leftJoin = jest.fn().mockReturnValue(chain);
    trx.join = jest.fn().mockReturnValue(chain);
    trx.select = jest.fn().mockReturnValue(chain);
    trx.orderBy = jest.fn().mockReturnValue(chain);
    trx.limit = jest.fn().mockReturnValue(chain);
    trx.offset = jest.fn().mockReturnValue(chain);
    trx.first = chain.first;
    trx.insert = chain.insert;
    trx.update = chain.update;
    trx.del = chain.del;
    trx.count = jest.fn(() => chain);
    trx.fn = { now: jest.fn(() => 'NOW()') };
    trx.forUpdate = jest.fn().mockReturnValue(chain);
    trx.raw = jest.fn((sql) => sql);
    trx.modify = jest.fn((fn) => { fn(trx); return trx; });
    trx.whereBetween = jest.fn().mockReturnValue(chain);
    trx.groupBy = jest.fn().mockReturnValue(chain);
    trx.clearSelect = jest.fn().mockReturnValue(chain);
    trx.clone = jest.fn().mockReturnValue(trx);
    return cb(trx);
  });
  return db;
});

jest.mock('../services/qrService', () => ({
  generateQrData: jest.fn(() => ({
    leave_id: 'LV-001', employee_id: '000001', type: 'OUT', timestamp: new Date().toISOString(), signature: 'abc',
  })),
  encodeQrData: jest.fn((d) => Buffer.from(JSON.stringify(d)).toString('base64')),
  isOutQrExpired: jest.fn(() => false),
}));

jest.mock('../services/qrImageService', () => ({
  generateQrImage: jest.fn().mockResolvedValue('qr-image-data'),
  deleteQrImages: jest.fn(),
}));

jest.mock('../services/notificationService', () => ({
  sendToEmployee: jest.fn().mockResolvedValue(),
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
    { employee_id: '000015', session_id: 's1', role: 'supervisor' },
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
    mockAuth({ employee_id: '000015', department_id: 'DEP-001', is_supervisor: true, is_active: true });
    db().resolve([
      { leave_id: 'LV-001', status: 'pending', employee_name: 'James Wilson' },
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
      { leave_id: 'LV-001', status: 'pending', employee_name: 'James' },
      { leave_id: 'LV-002', status: 'pending', employee_name: 'Maria' },
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
    mockAuth({ employee_id: '000015', department_id: 'DEP-001', is_supervisor: true, is_active: true });
    db.first.mockResolvedValueOnce({
      leave_id: 'LV-001', employee_id: '000001', status: 'approved', employee_name: 'James Wilson',
    });
    db.transaction.mockImplementationOnce((cb) => {
      const trx = makeChain();
      trx.fn = { now: jest.fn(() => 'NOW()') };
      trx.first.mockResolvedValueOnce({ leave_id: 'LV-001', employee_id: '000001', status: 'pending', supervisor_id: '000015', department_id: 'DEP-001', leave_date: today, start_time: '09:00', end_time: '17:00' });
      return cb(trx);
    });
    const res = await request(app)
      .post('/api/supervisor/approve/LV-001')
      .set('Authorization', `Bearer ${supToken()}`);
    expect(res.status).toBe(200);
  });

  it('returns 404 if leave not found', async () => {
    mockAuth({ employee_id: '000015', department_id: 'DEP-001', is_supervisor: true, is_active: true });
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
    mockAuth({ employee_id: '000015', department_id: 'DEP-001', is_supervisor: true, is_active: true });
    db.first
      .mockResolvedValueOnce({ leave_id: 'LV-001', employee_id: '000001', status: 'pending', supervisor_id: '000015', department_id: 'DEP-001', leave_date: today })
      .mockResolvedValueOnce({ leave_id: 'LV-001', employee_id: '000001', status: 'rejected', employee_name: 'James Wilson' });
    const res = await request(app)
      .post('/api/supervisor/reject/LV-001')
      .set('Authorization', `Bearer ${supToken()}`)
      .send({ reason: 'Not enough staff' });
    expect(res.status).toBe(200);
  });

  it('returns 404 if leave not found', async () => {
    mockAuth({ employee_id: '000015', department_id: 'DEP-001', is_supervisor: true, is_active: true });
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
    mockAuth({ employee_id: '000015', department_id: 'DEP-001', is_supervisor: true, is_active: true });
    db.first
      .mockResolvedValueOnce({ leave_id: 'LV-001', employee_id: '000001', status: 'approved', supervisor_id: '000015', department_id: 'DEP-001', leave_date: today })
      .mockResolvedValueOnce({ leave_id: 'LV-001', employee_id: '000001', status: 'pending', employee_name: 'James Wilson' });
    const res = await request(app)
      .post('/api/supervisor/revoke/LV-001')
      .set('Authorization', `Bearer ${supToken()}`);
    expect(res.status).toBe(200);
  });

  it('returns 400 when the leave pass has expired', async () => {
    const qrService = require('../services/qrService');
    qrService.isOutQrExpired.mockReturnValueOnce(true);
    mockAuth({ employee_id: '000015', department_id: 'DEP-001', is_supervisor: true, is_active: true });
    db.transaction.mockImplementationOnce((cb) => {
      const trx = makeChain();
      trx.fn = { now: jest.fn(() => 'NOW()') };
      trx.first.mockResolvedValueOnce({
        leave_id: 'LV-001', employee_id: '000001', status: 'approved',
        supervisor_id: '000015', department_id: 'DEP-001', leave_date: today,
      });
      return cb(trx);
    });
    const res = await request(app)
      .post('/api/supervisor/revoke/LV-001')
      .set('Authorization', `Bearer ${supToken()}`);
    expect(res.status).toBe(400);
    expect(res.body.message).toContain('expired');
  });
});

describe('GET /api/supervisor/approved', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('annotates is_expired on approved leaves', async () => {
    const qrService = require('../services/qrService');
    qrService.isOutQrExpired.mockReturnValueOnce(true).mockReturnValueOnce(false);
    mockAuth({ employee_id: '999999', is_admin: true, is_active: true });
    db().resolve([
      { leave_id: 'LV-001', status: 'approved', employee_name: 'James Wilson' },
      { leave_id: 'LV-002', status: 'approved', employee_name: 'Maria' },
    ]);
    const res = await request(app)
      .get('/api/supervisor/approved')
      .set('Authorization', `Bearer ${adminToken()}`);
    expect(res.status).toBe(200);
    expect(res.body.data[0].is_expired).toBe(true);
    expect(res.body.data[1].is_expired).toBe(false);
  });
});

describe('GET /api/supervisor/history', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('returns approved and rejected leaves with decided_at for supervisor', async () => {
    mockAuth({ employee_id: '000015', department_id: 'DEP-001', is_supervisor: true, is_active: true });
    db().resolve([
      {
        leave_id: 'LV-001', status: 'rejected', supervisor_id: '000015',
        rejection_reason: 'Lack of coverage', employee_name: 'James Wilson',
        approved_at: null, updated_at: '2026-07-20T02:00:00.000Z',
        leave_date: '2026-07-25',
      },
      {
        leave_id: 'LV-002', status: 'approved', supervisor_id: '000015',
        approved_by: '000015', employee_name: 'Maria',
        approved_at: '2026-07-21T02:00:00.000Z', updated_at: '2026-07-21T02:00:00.000Z',
        leave_date: '2026-07-26',
      },
    ]);
    const res = await request(app)
      .get('/api/supervisor/history')
      .set('Authorization', `Bearer ${supToken()}`);
    expect(res.status).toBe(200);
    expect(res.body.data).toHaveLength(2);
    expect(res.body.data[0].decided_at).toBe('2026-07-21T02:00:00.000Z');
    expect(res.body.data[0].status).toBe('approved');
    expect(res.body.data[1].decided_at).toBe('2026-07-20T02:00:00.000Z');
    expect(res.body.data[1].status).toBe('rejected');
    expect(res.body.data[1].rejection_reason).toBe('Lack of coverage');
  });

  it('returns all decided leaves for admin', async () => {
    mockAuth({ employee_id: '999999', is_admin: true, is_active: true });
    db().resolve([
      {
        leave_id: 'LV-003', status: 'completed', approved_by: '000011',
        employee_name: 'Anna', approved_at: '2026-07-22T02:00:00.000Z',
        updated_at: '2026-07-23T02:00:00.000Z', leave_date: '2026-07-27',
      },
    ]);
    const res = await request(app)
      .get('/api/supervisor/history')
      .set('Authorization', `Bearer ${adminToken()}`);
    expect(res.status).toBe(200);
    expect(res.body.data).toHaveLength(1);
    expect(res.body.data[0].decided_at).toBe('2026-07-22T02:00:00.000Z');
  });

  it('returns 401 without token', async () => {
    const res = await request(app).get('/api/supervisor/history');
    expect(res.status).toBe(401);
  });
});

describe('GET /api/supervisor/team-leaves', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('returns team leaves with date filter', async () => {
    mockAuth({ employee_id: '000015', department_id: 'DEP-001', is_supervisor: true, is_active: true });
    db().resolve([
      { leave_id: 'LV-001', status: 'approved', employee_name: 'James Wilson' },
    ]);
    const res = await request(app)
      .get('/api/supervisor/team-leaves')
      .query({ date: today })
      .set('Authorization', `Bearer ${supToken()}`);
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body.data)).toBe(true);
  });
});
