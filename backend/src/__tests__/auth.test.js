const jwt = require('jsonwebtoken');

jest.mock('../config/database', () => {
  const chain = {
    where: jest.fn().mockReturnThis(),
    andWhere: jest.fn().mockReturnThis(),
    orWhere: jest.fn().mockReturnThis(),
    leftJoin: jest.fn().mockReturnThis(),
    select: jest.fn().mockReturnThis(),
    orderBy: jest.fn().mockReturnThis(),
    limit: jest.fn().mockReturnThis(),
    offset: jest.fn().mockReturnThis(),
    first: jest.fn(),
    insert: jest.fn(),
    update: jest.fn(),
    del: jest.fn(),
    count: jest.fn().mockReturnThis(),
    modify: jest.fn((fn) => { fn(chain); return chain; }),
    raw: jest.fn((sql) => sql),
  };
  const db = jest.fn(() => chain);
  db.where = jest.fn().mockReturnValue(chain);
  db.leftJoin = jest.fn().mockReturnValue(chain);
  db.select = jest.fn().mockReturnValue(chain);
  db.orderBy = jest.fn().mockReturnValue(chain);
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

const db = require('../config/database');
const { authenticate, requireSupervisor, requireAdmin, requireSecurity } = require('../middleware/auth');

function mockReqRes(headers, user) {
  const req = {
    headers: headers || {},
    user: user || {},
  };
  const res = {
    status: jest.fn().mockReturnThis(),
    json: jest.fn(),
  };
  const next = jest.fn();
  return { req, res, next };
}

describe('authenticate middleware', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    process.env.JWT_SECRET = 'test-jwt-secret';
  });

  it('returns 401 if no token provided', async () => {
    const { req, res, next } = mockReqRes({});
    await authenticate(req, res, next);
    expect(res.status).toHaveBeenCalledWith(401);
    expect(res.json).toHaveBeenCalledWith({ success: false, message: 'No token provided' });
    expect(next).not.toHaveBeenCalled();
  });

  it('returns 401 if token format is invalid', async () => {
    const { req, res, next } = mockReqRes({ authorization: 'Invalid' });
    await authenticate(req, res, next);
    expect(res.status).toHaveBeenCalledWith(401);
    expect(next).not.toHaveBeenCalled();
  });

  it('returns 401 if token is expired', async () => {
    const expiredToken = jwt.sign(
      { employee_id: '000001', session_id: 's1' },
      process.env.JWT_SECRET,
      { expiresIn: '0s' }
    );
    const { req, res, next } = mockReqRes({ authorization: `Bearer ${expiredToken}` });
    await authenticate(req, res, next);
    expect(res.status).toHaveBeenCalledWith(401);
    expect(res.json).toHaveBeenCalledWith({ success: false, message: 'Token expired' });
  });

  it('returns 401 if session not found', async () => {
    const token = jwt.sign(
      { employee_id: '000001', session_id: 'nonexistent' },
      process.env.JWT_SECRET,
      { expiresIn: '1h' }
    );
    db.first.mockResolvedValueOnce(null);

    const { req, res, next } = mockReqRes({ authorization: `Bearer ${token}` });
    await authenticate(req, res, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(res.json).toHaveBeenCalledWith({ success: false, message: 'Session expired' });
  });

  it('returns 401 if employee not found', async () => {
    const token = jwt.sign(
      { employee_id: '000001', session_id: 's1' },
      process.env.JWT_SECRET,
      { expiresIn: '1h' }
    );
    db.first
      .mockResolvedValueOnce({ is_active: true, session_id: 's1' })
      .mockResolvedValueOnce(null);

    const { req, res, next } = mockReqRes({ authorization: `Bearer ${token}` });
    await authenticate(req, res, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(res.json).toHaveBeenCalledWith({ success: false, message: 'Invalid token' });
  });

  it('returns 401 if account deactivated', async () => {
    const token = jwt.sign(
      { employee_id: '000001', session_id: 's1' },
      process.env.JWT_SECRET,
      { expiresIn: '1h' }
    );
    db.first
      .mockResolvedValueOnce({ is_active: true, session_id: 's1' })
      .mockResolvedValueOnce({ employee_id: '000001', is_active: false });

    const { req, res, next } = mockReqRes({ authorization: `Bearer ${token}` });
    await authenticate(req, res, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(res.json).toHaveBeenCalledWith({ success: false, message: 'Invalid token' });
  });

  it('sets req.user and calls next on success', async () => {
    const token = jwt.sign(
      { employee_id: '000001', session_id: 's1' },
      process.env.JWT_SECRET,
      { expiresIn: '1h' }
    );
    const mockEmployee = {
      employee_id: '000001',
      full_name: 'James Wilson',
      is_active: true,
      department_name: 'TSD · Technical Services Department',
    };
    db.first
      .mockResolvedValueOnce({ is_active: true, session_id: 's1' })
      .mockResolvedValueOnce(mockEmployee);

    const { req, res, next } = mockReqRes({ authorization: `Bearer ${token}` });
    await authenticate(req, res, next);

    expect(req.user).toEqual(mockEmployee);
    expect(req.session_id).toBe('s1');
    expect(next).toHaveBeenCalled();
  });
});

describe('requireSupervisor', () => {
  it('calls next if user is supervisor', () => {
    const { req, res, next } = mockReqRes({}, { is_supervisor: true });
    requireSupervisor(req, res, next);
    expect(next).toHaveBeenCalled();
  });

  it('calls next if user is admin', () => {
    const { req, res, next } = mockReqRes({}, { is_admin: true });
    requireSupervisor(req, res, next);
    expect(next).toHaveBeenCalled();
  });

  it('returns 403 if user is not supervisor or admin', () => {
    const { req, res, next } = mockReqRes({}, { is_supervisor: false, is_admin: false });
    requireSupervisor(req, res, next);
    expect(res.status).toHaveBeenCalledWith(403);
  });
});

describe('requireAdmin', () => {
  it('calls next if user is admin', () => {
    const { req, res, next } = mockReqRes({}, { is_admin: true });
    requireAdmin(req, res, next);
    expect(next).toHaveBeenCalled();
  });

  it('returns 403 if user is not admin', () => {
    const { req, res, next } = mockReqRes({}, { is_admin: false });
    requireAdmin(req, res, next);
    expect(res.status).toHaveBeenCalledWith(403);
  });
});

describe('requireSecurity', () => {
  it('calls next if user is security', () => {
    const { req, res, next } = mockReqRes({}, { is_security: true });
    requireSecurity(req, res, next);
    expect(next).toHaveBeenCalled();
  });

  it('calls next if user is admin', () => {
    const { req, res, next } = mockReqRes({}, { is_admin: true });
    requireSecurity(req, res, next);
    expect(next).toHaveBeenCalled();
  });

  it('returns 403 if user is neither security nor admin', () => {
    const { req, res, next } = mockReqRes({}, { is_security: false, is_admin: false });
    requireSecurity(req, res, next);
    expect(res.status).toHaveBeenCalledWith(403);
  });
});
