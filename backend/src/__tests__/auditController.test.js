describe('auditController', () => {
  const OLD_ENV = process.env;

  beforeEach(() => {
    jest.resetModules();
    process.env = { ...OLD_ENV, JWT_SECRET: 'test-secret', QR_SECRET: 'test-secret', COOKIE_SECRET: 'test-secret', DB_CONNECTION: 'postgresql:///test' };
  });

  afterAll(() => {
    process.env = OLD_ENV;
  });

  function makeReqRes() {
    const req = { query: {}, user: { employee_id: '999999', is_admin: true }, log: { error: jest.fn() } };
    const res = { json: jest.fn(), setHeader: jest.fn(), send: jest.fn(), status: jest.fn().mockReturnThis() };
    const next = jest.fn();
    return { req, res, next };
  }

  describe('getAuditLogs', () => {
    it('returns paginated audit logs', async () => {
      const mockData = [{ audit_log_id: 1, action: 'approve' }];
      jest.mock('../services/auditService', () => ({
        query: jest.fn().mockResolvedValue({ data: mockData, total: 1 }),
        exportQuery: jest.fn(),
      }));

      const { getAuditLogs } = require('../controllers/auditController');
      const { req, res, next } = makeReqRes();
      req.query = { page: '1', limit: '10' };

      await getAuditLogs(req, res, next);

      expect(res.json).toHaveBeenCalledWith({
        success: true,
        data: mockData,
        pagination: { total: 1, page: 1, limit: 10, pages: 1 },
      });
    });

    it('calls next on error', async () => {
      jest.mock('../services/auditService', () => ({
        query: jest.fn().mockRejectedValue(new Error('DB error')),
        exportQuery: jest.fn(),
      }));

      const { getAuditLogs } = require('../controllers/auditController');
      const { req, res, next } = makeReqRes();

      await getAuditLogs(req, res, next);

      expect(next).toHaveBeenCalled();
    });
  });

  describe('exportAuditLogs', () => {
    it('returns CSV with correct headers', async () => {
      jest.mock('../services/auditService', () => ({
        query: jest.fn(),
        exportQuery: jest.fn().mockResolvedValue([
          { audit_log_id: 1, actor_id: '000011', actor_name: 'Ethan White', actor_role: 'supervisor', action: 'approve', entity: 'leave_request', entity_id: 'LV-001', description: 'Approved', ip_address: '127.0.0.1', created_at: '2026-07-27T00:00:00Z' },
        ]),
      }));

      const { exportAuditLogs } = require('../controllers/auditController');
      const { req, res, next } = makeReqRes();

      await exportAuditLogs(req, res, next);

      expect(res.setHeader).toHaveBeenCalledWith('Content-Type', 'text/csv');
      expect(res.setHeader).toHaveBeenCalledWith('Content-Disposition', 'attachment; filename="audit_log.csv"');
      expect(res.send).toHaveBeenCalledWith(expect.stringContaining('audit_log_id,actor_id,actor_name'));
      expect(res.send).toHaveBeenCalledWith(expect.stringContaining('Ethan White'));
    });
  });
});