const request = require('supertest');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');

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
  chain.raw = jest.fn((sql, ...args) => typeof sql === 'string' ? sql : sql);
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
  db.raw = jest.fn((sql, ...args) => typeof sql === 'string' ? sql : sql);
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

const app = require('../app');

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

describe('GET /api/admin/employees', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('lists all employees (admin)', async () => {
    mockAuth({ employee_id: '999999', is_admin: true, is_active: true });
    db.first.mockResolvedValueOnce({ count: 3 });
    db().resolve([
      { employee_id: '000001', full_name: 'Alice', department_name: 'Engineering', is_active: true },
      { employee_id: '000002', full_name: 'Bob', department_name: 'Engineering', is_active: true },
    ]);
    const res = await request(app)
      .get('/api/admin/employees')
      .set('Authorization', `Bearer ${adminToken()}`);
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body.data)).toBe(true);
  });
});

describe('POST /api/admin/employees', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('creates an employee', async () => {
    mockAuth({ employee_id: '999999', is_admin: true, is_active: true });
    db.first
      .mockResolvedValueOnce(null)
      .mockResolvedValueOnce({ employee_id: 'EMP-001', full_name: 'New User', position: 'Engineer', email: 'new@example.com', department_name: 'Engineering', is_active: true });
    const res = await request(app)
      .post('/api/admin/employees')
      .set('Authorization', `Bearer ${adminToken()}`)
      .send({
        employee_id: '123456',
        full_name: 'New User',
        position: 'Engineer',
        email: 'new@example.com',
        password: 'Password1',
        department_id: 'DEPT01',
      });
    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
  });

  it('returns 409 on duplicate email', async () => {
    mockAuth({ employee_id: '999999', is_admin: true, is_active: true });
    db.first.mockResolvedValueOnce({ employee_id: '000001' });
    const res = await request(app)
      .post('/api/admin/employees')
      .set('Authorization', `Bearer ${adminToken()}`)
      .send({
        employee_id: '123457',
        full_name: 'Duplicate',
        position: 'Engineer',
        email: 'existing@example.com',
        password: 'Password1',
        department_id: 'DEPT01',
      });
    expect(res.status).toBe(409);
  });
});

describe('PUT /api/admin/employees/:id/status', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('toggles employee active status', async () => {
    mockAuth({ employee_id: '999999', is_admin: true, is_active: true });
    db.first.mockResolvedValueOnce({ employee_id: '000001', is_active: true });
    const res = await request(app)
      .put('/api/admin/employees/000001/status')
      .set('Authorization', `Bearer ${adminToken()}`);
    expect(res.status).toBe(200);
    expect(res.body.message).toContain('deactivated');
  });

  it('returns 404 if employee not found', async () => {
    mockAuth({ employee_id: '999999', is_admin: true, is_active: true });
    db.first.mockResolvedValueOnce(null);
    const res = await request(app)
      .put('/api/admin/employees/999999/status')
      .set('Authorization', `Bearer ${adminToken()}`);
    expect(res.status).toBe(404);
  });
});

describe('GET /api/admin/departments', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('lists active departments', async () => {
    mockAuth({ employee_id: '999999', is_admin: true, is_active: true });
    db().resolve([
      { department_id: 'DEPT01', department_name: 'Engineering', is_active: true },
    ]);
    const res = await request(app)
      .get('/api/admin/departments')
      .set('Authorization', `Bearer ${adminToken()}`);
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body.data)).toBe(true);
  });
});

describe('POST /api/admin/departments', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('creates a department', async () => {
    mockAuth({ employee_id: '999999', is_admin: true, is_active: true });
    db.first
      .mockResolvedValueOnce(null)
      .mockResolvedValueOnce(null)
      .mockResolvedValueOnce({ department_id: 'DEPT03', department_name: 'New Dept', is_active: true });
    const res = await request(app)
      .post('/api/admin/departments')
      .set('Authorization', `Bearer ${adminToken()}`)
      .send({ department_id: 'DEPT03', department_name: 'New Dept' });
    expect(res.status).toBe(201);
  });

  it('returns 409 on duplicate name', async () => {
    mockAuth({ employee_id: '999999', is_admin: true, is_active: true });
    db.first.mockResolvedValueOnce({ department_id: 'DEPT01' });
    const res = await request(app)
      .post('/api/admin/departments')
      .set('Authorization', `Bearer ${adminToken()}`)
      .send({ department_id: 'DEPT01', department_name: 'Engineering' });
    expect(res.status).toBe(409);
  });
});

describe('DELETE /api/admin/departments/:id', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('returns 200 on deletion', async () => {
    mockAuth({ employee_id: '999999', is_admin: true, is_active: true });
    db.first
      .mockResolvedValueOnce({ department_id: 'DEPT02', department_name: 'HR' })
      .mockResolvedValueOnce({ count: 0 });
    const res = await request(app)
      .delete('/api/admin/departments/DEPT02')
      .set('Authorization', `Bearer ${adminToken()}`);
    expect(res.status).toBe(200);
  });

  it('returns 404 when not found', async () => {
    mockAuth({ employee_id: '999999', is_admin: true, is_active: true });
    db.first.mockResolvedValueOnce(null);
    const res = await request(app)
      .delete('/api/admin/departments/DEPT99')
      .set('Authorization', `Bearer ${adminToken()}`);
    expect(res.status).toBe(404);
  });
});

describe('GET /api/admin/reports', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('returns summary report data', async () => {
    mockAuth({ employee_id: '999999', is_admin: true, is_active: true });
    db().resolve([
      { leave_id: 'LV-001', status: 'approved', employee_name: 'Alice', department_name: 'Engineering' },
    ]);
    const res = await request(app)
      .get('/api/admin/reports')
      .set('Authorization', `Bearer ${adminToken()}`);
    expect(res.status).toBe(200);
    expect(res.body.data).toBeDefined();
  });

  it('returns department report', async () => {
    mockAuth({ employee_id: '999999', is_admin: true, is_active: true });
    db().resolve([
      { department_name: 'Engineering', department_id: 'DEPT01', total_requests: 10, approved: 5, rejected: 2, pending: 3, completed: 0 },
    ]);
    const res = await request(app)
      .get('/api/admin/reports')
      .query({ type: 'department' })
      .set('Authorization', `Bearer ${adminToken()}`);
    expect(res.status).toBe(200);
    expect(res.body.data).toBeDefined();
  });
});

describe('non-admin routes', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('rejects non-admin for employee listing', async () => {
    db.first
      .mockResolvedValueOnce({ is_active: true, session_id: 's1' })
      .mockResolvedValueOnce({ employee_id: '000001', is_admin: false, is_active: true });
    const userToken = jwt.sign(
      { employee_id: '000001', session_id: 's1', role: 'employee' },
      process.env.JWT_SECRET,
      { expiresIn: '1h' }
    );
    const res = await request(app)
      .get('/api/admin/employees')
      .set('Authorization', `Bearer ${userToken}`);
    expect(res.status).toBe(403);
  });
});
