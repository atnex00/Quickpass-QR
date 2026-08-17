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
  return db;
});

jest.mock('../services/qrService', () => ({
  generateQrData: jest.fn(() => ({
    leave_id: 'LV-001', employee_id: '000001', type: 'OUT', timestamp: new Date().toISOString(), signature: 'abc',
  })),
  encodeQrData: jest.fn((d) => Buffer.from(JSON.stringify(d)).toString('base64')),
  isOutQrExpired: jest.fn(() => false),
}));

jest.mock('../services/notificationService', () => ({
  sendToEmployee: jest.fn().mockResolvedValue(),
}));

const db = require('../config/database');

process.env.JWT_SECRET = 'test-jwt-secret';
process.env.QR_SECRET = 'test-qr-secret';
process.env.NODE_ENV = 'test';

const app = require('../app');

function token(employeeId, role) {
  return jwt.sign(
    { employee_id: employeeId, session_id: 's1', role },
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

describe('GET /api/team', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('returns 401 without token', async () => {
    const res = await request(app).get('/api/team');
    expect(res.status).toBe(401);
  });

  it('returns department employees with leave counts', async () => {
    mockAuth({
      employee_id: '000011',
      full_name: 'Ethan White',
      department_id: 'DEP-002',
      is_active: true,
      is_supervisor: true,
    });
    db('employees').resolve([
      { employee_id: '000001', full_name: 'James Wilson', position: 'Software Engineer', department_id: 'DEP-002', department_name: 'TSD · Technical Services Department', department_code: 'TSD', is_supervisor: false, profile_photo: null, leave_count: 3 },
      { employee_id: '000011', full_name: 'Ethan White', position: 'TSD Manager', department_id: 'DEP-002', department_name: 'TSD · Technical Services Department', department_code: 'TSD', is_supervisor: true, profile_photo: null, leave_count: 1 },
    ]);

    const res = await request(app)
      .get('/api/team')
      .set('Authorization', `Bearer ${token('000011', 'supervisor')}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toHaveLength(2);
    expect(res.body.data[0].employee_id).toBe('000001');
    expect(res.body.data[0].leave_count).toBe(3);
    const chain = db('employees');
    expect(chain.select).toHaveBeenCalledWith(
      'count(leave_requests.leave_id)::int as leave_count'
    );
  });
});

describe('GET /api/directory', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('returns 401 without token', async () => {
    const res = await request(app).get('/api/directory');
    expect(res.status).toBe(401);
  });

  it('returns only same-department employees for non-admin users', async () => {
    mockAuth({
      employee_id: '000001',
      full_name: 'James Wilson',
      department_id: 'DEP-002',
      is_active: true,
    });
    db('employees').resolve([
      { employee_id: '000001', full_name: 'James Wilson', position: 'Software Engineer', department_id: 'DEP-002', department_name: 'TSD · Technical Services Department', department_code: 'TSD', is_supervisor: false, profile_photo: null },
      { employee_id: '000015', full_name: 'Liam Thomas', position: 'ISD Supervisor', department_id: 'DEP-001', department_name: 'ISD · Institutional Services Department', department_code: 'ISD', is_supervisor: true, profile_photo: null },
    ]);

    const res = await request(app)
      .get('/api/directory')
      .set('Authorization', `Bearer ${token('000001', 'employee')}`);

    expect(res.status).toBe(200);
    expect(db('employees').where).toHaveBeenCalledWith(
      'employees.department_id',
      'DEP-002'
    );
  });

  it('returns all active employees for admin users', async () => {
    mockAuth({
      employee_id: '999999',
      full_name: 'System Admin',
      department_id: null,
      is_active: true,
      is_admin: true,
    });
    db('employees').resolve([
      { employee_id: '000001', full_name: 'James Wilson', position: 'Software Engineer', department_id: 'DEP-002', department_name: 'TSD · Technical Services Department', department_code: 'TSD', is_supervisor: false, profile_photo: null },
    ]);

    const res = await request(app)
      .get('/api/directory')
      .set('Authorization', `Bearer ${token('999999', 'admin')}`);

    expect(res.status).toBe(200);
    expect(db('employees').where).not.toHaveBeenCalledWith(
      'employees.department_id',
      expect.anything()
    );
  });

  it('returns all active employees for security users', async () => {
    mockAuth({
      employee_id: '090901',
      full_name: 'Mike Ross',
      department_id: 'DEP-001',
      is_active: true,
      is_security: true,
    });
    db('employees').resolve([
      { employee_id: '090901', full_name: 'Mike Ross', position: 'Head of Security', department_id: 'DEP-001', department_name: 'ISD · Institutional Services Department', department_code: 'ISD', is_supervisor: false, profile_photo: null },
    ]);

    const res = await request(app)
      .get('/api/directory')
      .set('Authorization', `Bearer ${token('090901', 'security')}`);

    expect(res.status).toBe(200);
    expect(db('employees').where).not.toHaveBeenCalledWith(
      'employees.department_id',
      expect.anything()
    );
  });
});

describe('GET /api/team/:employeeId/leaves', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('returns 401 without token', async () => {
    const res = await request(app).get('/api/team/000001/leaves');
    expect(res.status).toBe(401);
  });

  it('returns 404 when the employee does not exist', async () => {
    mockAuth({
      employee_id: '000011',
      full_name: 'Ethan White',
      department_id: 'DEP-002',
      is_active: true,
      is_supervisor: true,
    });
    db.first.mockResolvedValueOnce(undefined);

    const res = await request(app)
      .get('/api/team/000001/leaves')
      .set('Authorization', `Bearer ${token('000011', 'supervisor')}`);

    expect(res.status).toBe(404);
  });

  it('returns 403 for employees outside the caller department', async () => {
    mockAuth({
      employee_id: '000011',
      full_name: 'Ethan White',
      department_id: 'DEP-002',
      is_active: true,
      is_supervisor: true,
    });
    db.first.mockResolvedValueOnce({
      employee_id: '000015',
      full_name: 'Liam Thomas',
      position: 'ISD Supervisor',
      department_id: 'DEP-001',
      department_name: 'ISD · Institutional Services Department',
      department_code: 'ISD',
      is_supervisor: true,
      profile_photo: null,
      is_active: true,
    });

    const res = await request(app)
      .get('/api/team/000015/leaves')
      .set('Authorization', `Bearer ${token('000011', 'supervisor')}`);

    expect(res.status).toBe(403);
  });

  it('returns the employee leave history with QR payloads nulled', async () => {
    mockAuth({
      employee_id: '000011',
      full_name: 'Ethan White',
      department_id: 'DEP-002',
      is_active: true,
      is_supervisor: true,
    });
    db.first.mockResolvedValueOnce({
      employee_id: '000001',
      full_name: 'James Wilson',
      position: 'Software Engineer',
      department_id: 'DEP-002',
      department_name: 'TSD · Technical Services Department',
      department_code: 'TSD',
      is_supervisor: false,
      profile_photo: null,
      is_active: true,
    });
    db('leave_requests').resolve([
      {
        leave_id: 'LV-00000001-ABCD1234',
        employee_id: '000001',
        leave_date: '2026-08-10',
        start_time: '09:00',
        end_time: '17:00',
        status: 'approved',
        reason: 'Personal errand',
        out_qr_code: 'secret-payload',
        in_qr_code: 'secret-payload',
        employee_name: 'James Wilson',
        employee_position: 'Software Engineer',
        employee_photo: null,
        supervisor_name: 'Ethan White',
      },
    ]);

    const res = await request(app)
      .get('/api/team/000001/leaves')
      .set('Authorization', `Bearer ${token('000011', 'supervisor')}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.employee.employee_id).toBe('000001');
    expect(res.body.data).toHaveLength(1);
    expect(res.body.data[0].out_qr_code).toBeNull();
    expect(res.body.data[0].in_qr_code).toBeNull();
    expect(res.body.data[0].employee_name).toBe('James Wilson');
  });
});