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

jest.mock('../services/notificationService', () => ({
  sendToEmployee: jest.fn().mockResolvedValue(),
}));

const db = require('../config/database');
const qrService = require('../services/qrService');
const { getLocalDateString } = require('../utils/date');

process.env.JWT_SECRET = 'test-jwt-secret';
process.env.QR_SECRET = 'test-qr-secret';
process.env.NODE_ENV = 'test';

const app = require('../app');

const nowDate = new Date();
const today = getLocalDateString(nowDate);
const now = nowDate.toTimeString().split(' ')[0];

function currentQr(leaveId, employeeId, type) {
  const d = new Date();
  return qrService.encodeQrData(
    qrService.generateQrData(leaveId, employeeId, type, getLocalDateString(d), d.toTimeString().split(' ')[0])
  );
}

function pastQr(leaveId, employeeId, type, minutesAgo) {
  const d = new Date(Date.now() - minutesAgo * 60 * 1000);
  return qrService.encodeQrData(
    qrService.generateQrData(leaveId, employeeId, type, getLocalDateString(d), d.toTimeString().split(' ')[0])
  );
}

function futureQr(leaveId, employeeId, type, minutesAhead) {
  const d = new Date(Date.now() + minutesAhead * 60 * 1000);
  return qrService.encodeQrData(
    qrService.generateQrData(leaveId, employeeId, type, getLocalDateString(d), d.toTimeString().split(' ')[0])
  );
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
    const qr = currentQr('LV-001', '000001', 'OUT');
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

  it('returns 200 for valid IN scan on active leave', async () => {
    db.first
      .mockResolvedValueOnce({ is_active: true, session_id: 's1' })
      .mockResolvedValueOnce({ employee_id: '090901', is_security: true, is_active: true });
    const qr = currentQr('LV-002', '000001', 'IN');
    const leaveRow = { leave_id: 'LV-002', employee_id: '000001', status: 'active', employee_name: 'James Wilson', out_scan_time: today + ' 09:05', leave_date: today, start_time: '09:00', end_time: '17:00' };
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
    expect(res.body.data.new_status).toBe('completed');
  });

  it('returns 200 for early IN scan before scheduled time', async () => {
    db.first
      .mockResolvedValueOnce({ is_active: true, session_id: 's1' })
      .mockResolvedValueOnce({ employee_id: '090901', is_security: true, is_active: true });
    const qr = futureQr('LV-002', '000001', 'IN', 120);
    const leaveRow = { leave_id: 'LV-002', employee_id: '000001', status: 'active', employee_name: 'James Wilson', out_scan_time: today + ' 09:05', leave_date: today, start_time: '09:00', end_time: '17:00' };
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
    expect(res.body.data.new_status).toBe('completed');
  });

  it('returns 200 for IN scan long after scheduled time (no expiry)', async () => {
    db.first
      .mockResolvedValueOnce({ is_active: true, session_id: 's1' })
      .mockResolvedValueOnce({ employee_id: '090901', is_security: true, is_active: true });
    const qr = pastQr('LV-002', '000001', 'IN', 1800);
    const leaveRow = { leave_id: 'LV-002', employee_id: '000001', status: 'active', employee_name: 'James Wilson', out_scan_time: today + ' 09:05', leave_date: today, start_time: '09:00', end_time: '17:00' };
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
    expect(res.body.data.new_status).toBe('completed');
  });

  it('returns 400 for IN scan when leave was never activated (OUT QR expired unscanned)', async () => {
    db.first
      .mockResolvedValueOnce({ is_active: true, session_id: 's1' })
      .mockResolvedValueOnce({ employee_id: '090901', is_security: true, is_active: true });
    const qr = currentQr('LV-004', '000001', 'IN');
    const leaveRow = { leave_id: 'LV-004', employee_id: '000001', status: 'approved', employee_name: 'James Wilson', out_scan_time: null, leave_date: today, start_time: '09:00', end_time: '17:00' };
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
    expect(res.status).toBe(400);
    expect(res.body.message).toContain('Scan the OUT');
  });

  it('returns 400 for invalid QR signature (wrong length)', async () => {
    db.first
      .mockResolvedValueOnce({ is_active: true, session_id: 's1' })
      .mockResolvedValueOnce({ employee_id: '090901', is_security: true, is_active: true });
    const fakeQr = qrService.encodeQrData({ leave_id: 'LV-001', employee_id: '000001', type: 'OUT', timestamp: `${today}T${now}`, signature: 'badsig' });
    const res = await request(app)
      .post('/api/scan/validate')
      .set('Authorization', `Bearer ${secToken()}`)
      .send({ qr_data: fakeQr });
    expect(res.status).toBe(400);
    expect(res.body.message).toContain('signature');
  });

  it('returns 400 for tampered valid-length signature', async () => {
    db.first
      .mockResolvedValueOnce({ is_active: true, session_id: 's1' })
      .mockResolvedValueOnce({ employee_id: '090901', is_security: true, is_active: true });
    const d = new Date();
    const payload = qrService.generateQrData('LV-001', '000001', 'OUT', getLocalDateString(d), d.toTimeString().split(' ')[0]);
    const tampered = { ...payload, signature: (payload.signature[0] === 'a' ? 'b' : 'a') + payload.signature.slice(1) };
    const qr = qrService.encodeQrData(tampered);
    const res = await request(app)
      .post('/api/scan/validate')
      .set('Authorization', `Bearer ${secToken()}`)
      .send({ qr_data: qr });
    expect(res.status).toBe(400);
    expect(res.body.message).toContain('signature');
  });

  it('returns 400 for expired QR code', async () => {
    db.first
      .mockResolvedValueOnce({ is_active: true, session_id: 's1' })
      .mockResolvedValueOnce({ employee_id: '090901', is_security: true, is_active: true });
    const qr = pastQr('LV-001', '000001', 'OUT', 20);
    const res = await request(app)
      .post('/api/scan/validate')
      .set('Authorization', `Bearer ${secToken()}`)
      .send({ qr_data: qr });
    expect(res.status).toBe(400);
    expect(res.body.message).toContain('expired');
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

  it('returns 400 when QR was already scanned', async () => {
    db.first
      .mockResolvedValueOnce({ is_active: true, session_id: 's1' })
      .mockResolvedValueOnce({ employee_id: '090901', is_security: true, is_active: true });
    const qr = currentQr('LV-003', '000001', 'OUT');
    const leaveRow = { leave_id: 'LV-003', employee_id: '000001', status: 'approved', employee_name: 'James Wilson', out_scan_time: null, leave_date: today, start_time: '09:00', end_time: '17:00' };
    db.transaction.mockImplementationOnce((cb) => {
      const trx = makeChain();
      trx.fn = { now: jest.fn(() => 'NOW()') };
      trx.first
        .mockResolvedValueOnce(leaveRow)
        .mockResolvedValueOnce({ log_id: 1, leave_id: 'LV-003', qr_type: 'OUT' });
      return cb(trx);
    });
    const res = await request(app)
      .post('/api/scan/validate')
      .set('Authorization', `Bearer ${secToken()}`)
      .send({ qr_data: qr });
    expect(res.status).toBe(400);
    expect(res.body.message).toContain('already been scanned');
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
      { log_id: 1, leave_id: 'LV-001', scanned_by: '090901', qr_type: 'OUT', scan_time: now, employee_name: 'James Wilson', department_name: 'Technical Services', scanned_by_name: 'Mike Ross' },
    ]);
    const res = await request(app)
      .get('/api/scan/history')
      .set('Authorization', `Bearer ${secToken()}`);
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body.data)).toBe(true);
    expect(res.body.data[0]).toEqual(expect.objectContaining({
      department_name: 'Technical Services',
      scanned_by_name: 'Mike Ross',
    }));
  });

  it('filters scan history by department', async () => {
    db.first
      .mockResolvedValueOnce({ is_active: true, session_id: 's1' })
      .mockResolvedValueOnce({ employee_id: '090901', is_security: true, is_active: true })
      .mockResolvedValueOnce({ count: 1 });
    db().resolve([
      { log_id: 2, leave_id: 'LV-002', scanned_by: '090901', qr_type: 'IN', scan_time: now, employee_name: 'Ethan White', department_name: 'Technical Services' },
    ]);
    const res = await request(app)
      .get('/api/scan/history?department=Technical%20Services')
      .set('Authorization', `Bearer ${secToken()}`);
    expect(res.status).toBe(200);
    expect(res.body.data[0].department_name).toBe('Technical Services');
  });
});

describe('GET /api/scan/history/departments', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('returns scan counts grouped by department', async () => {
    db.first
      .mockResolvedValueOnce({ is_active: true, session_id: 's1' })
      .mockResolvedValueOnce({ employee_id: '090901', is_security: true, is_active: true });
    db().resolve([
      { department_name: 'Information Systems', department_code: 'ISD', scan_count: 2 },
      { department_name: 'Technical Services', department_code: 'TSD', scan_count: 1 },
    ]);
    const res = await request(app)
      .get('/api/scan/history/departments')
      .set('Authorization', `Bearer ${secToken()}`);
    expect(res.status).toBe(200);
    expect(res.body.data).toEqual([
      { department_name: 'Information Systems', department_code: 'ISD', scan_count: 2 },
      { department_name: 'Technical Services', department_code: 'TSD', scan_count: 1 },
    ]);
  });

  it('returns zero for departments without scans', async () => {
    db.first
      .mockResolvedValueOnce({ is_active: true, session_id: 's1' })
      .mockResolvedValueOnce({ employee_id: '090901', is_security: true, is_active: true });
    db().resolve([
      { department_name: 'Technical Services', department_code: 'TSD', scan_count: '0' },
    ]);
    const res = await request(app)
      .get('/api/scan/history/departments')
      .set('Authorization', `Bearer ${secToken()}`);
    expect(res.status).toBe(200);
    expect(res.body.data[0]).toEqual({
      department_name: 'Technical Services',
      department_code: 'TSD',
      scan_count: 0,
    });
  });

  it('rejects non-security users', async () => {
    db.first
      .mockResolvedValueOnce({ is_active: true, session_id: 's1' })
      .mockResolvedValueOnce({ employee_id: '000001', is_security: false, is_active: true });
    const res = await request(app)
      .get('/api/scan/history/departments')
      .set('Authorization', `Bearer ${jwt.sign({ employee_id: '000001', session_id: 's1' }, process.env.JWT_SECRET)}`);
    expect(res.status).toBe(403);
  });
});
