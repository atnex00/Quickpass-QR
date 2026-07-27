const request = require('supertest');
const jwt = require('jsonwebtoken');

jest.mock('uuid', () => ({ v4: () => 'mock-uuid' }));

jest.mock('../config/database', () => {
  const chain = {
    where: jest.fn().mockReturnThis(),
    andWhere: jest.fn().mockReturnThis(),
    orWhere: jest.fn().mockReturnThis(),
    whereNot: jest.fn().mockReturnThis(),
    whereIn: jest.fn().mockReturnThis(),
    whereNotIn: jest.fn().mockReturnThis(),
    leftJoin: jest.fn().mockReturnThis(),
    join: jest.fn().mockReturnThis(),
    select: jest.fn().mockReturnThis(),
    clearSelect: jest.fn().mockReturnThis(),
    orderBy: jest.fn().mockReturnThis(),
    limit: jest.fn().mockReturnThis(),
    offset: jest.fn().mockReturnThis(),
    modify: jest.fn((fn) => { fn(chain); return chain; }),
    groupBy: jest.fn().mockReturnThis(),
    first: jest.fn(),
    insert: jest.fn(),
    update: jest.fn(),
    del: jest.fn(),
    count: jest.fn().mockReturnThis(),
    clone: jest.fn().mockReturnThis(),
    raw: jest.fn((sql) => sql),
  };
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

jest.mock('../services/notificationService', () => ({
  sendToEmployee: jest.fn().mockResolvedValue(),
}));

const db = require('../config/database');

process.env.JWT_SECRET = 'test-jwt-secret';
process.env.QR_SECRET = 'test-qr-secret';
process.env.NODE_ENV = 'test';

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

describe('GET /api/health', () => {
  it('returns health status', async () => {
    const res = await request(app).get('/api/health');
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
  });
});

describe('POST /api/auth/login', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('returns 400 if employee_id is missing', async () => {
    const res = await request(app).post('/api/auth/login').send({ password: 'pass1234' });
    expect(res.status).toBe(400);
  });

  it('returns 400 if employee_id is not 6 digits', async () => {
    const res = await request(app).post('/api/auth/login').send({ employee_id: '123', password: 'pass1234' });
    expect(res.status).toBe(400);
  });

  it('returns 401 if employee not found', async () => {
    db.first.mockResolvedValueOnce(null);
    const res = await request(app).post('/api/auth/login').send({ employee_id: '000001', password: 'pass1234' });
    expect(res.status).toBe(401);
    expect(res.body.message).toContain('Invalid employee ID or password');
  });
});

describe('GET /api/auth/profile', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('returns 401 without token', async () => {
    const res = await request(app).get('/api/auth/profile');
    expect(res.status).toBe(401);
  });

  it('returns user profile with valid token', async () => {
    mockAuth({
      employee_id: '000001',
      full_name: 'James Wilson',
      position: 'Software Engineer',
      is_active: true,
      is_supervisor: false,
      is_admin: false,
      is_security: false,
      department_name: 'TSD · Technical Services Department',
    });

    const res = await request(app)
      .get('/api/auth/profile')
      .set('Authorization', `Bearer ${authToken()}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.employee_id).toBe('000001');
  });
});

describe('GET /api/admin/employees', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('returns 403 if user is not admin', async () => {
    mockAuth({
      employee_id: '000002',
      is_active: true,
      is_admin: false,
      is_supervisor: false,
      is_security: false,
    });

    const res = await request(app)
      .get('/api/admin/employees')
      .set('Authorization', `Bearer ${authToken({ employee_id: '000002' })}`);

    expect(res.status).toBe(403);
    expect(res.body.message).toContain('Admin access required');
  });
});

describe('POST /api/scan/validate', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('returns 403 if user is not security', async () => {
    mockAuth({
      employee_id: '000001',
      is_active: true,
      is_admin: false,
      is_security: false,
    });

    const res = await request(app)
      .post('/api/scan/validate')
      .set('Authorization', `Bearer ${authToken()}`)
      .send({ qr_data: 'test' });

    expect(res.status).toBe(403);
  });
});

describe('GET /api/supervisor/pending', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('returns 403 if user is not supervisor', async () => {
    mockAuth({
      employee_id: '000001',
      is_active: true,
      is_admin: false,
      is_supervisor: false,
      is_security: false,
    });

    const res = await request(app)
      .get('/api/supervisor/pending')
      .set('Authorization', `Bearer ${authToken()}`);

    expect(res.status).toBe(403);
  });
});
