const makeChain = () => {
  const chain = jest.fn(() => chain);
  chain.then = (onFulfilled) => {
    const v = chain._queue.shift();
    return Promise.resolve(v).then(onFulfilled);
  };
  chain._queue = [];
  chain.where = jest.fn().mockReturnValue(chain);
  chain.orderBy = jest.fn().mockReturnValue(chain);
  chain.clone = jest.fn().mockReturnValue(chain);
  chain.clearOrder = jest.fn().mockReturnValue(chain);
  chain.count = jest.fn().mockReturnValue(chain);
  chain.first = jest.fn(() => {
    const v = chain._queue.shift();
    return Promise.resolve(v);
  });
  chain.limit = jest.fn().mockReturnValue(chain);
  chain.offset = jest.fn().mockReturnValue(chain);
  chain.insert = jest.fn().mockResolvedValue(undefined);
  return chain;
};

jest.mock('../config/database', () => {
  const chain = makeChain();
  const db = jest.fn(() => chain);
  db.where = jest.fn().mockReturnValue(chain);
  db.first = chain.first;
  db.insert = chain.insert;
  db.orderBy = chain.orderBy;
  db.clone = chain.clone;
  db.clearOrder = chain.clearOrder;
  db.count = chain.count;
  db.limit = chain.limit;
  db.offset = chain.offset;
  db.fn = { now: jest.fn(() => 'NOW()') };
  db.raw = jest.fn((sql) => sql);
  return db;
});

const db = require('../config/database');

describe('auditService', () => {
  const OLD_ENV = process.env;

  beforeEach(() => {
    process.env = { ...OLD_ENV };
    const chain = db();
    chain._queue.length = 0;
    chain.insert.mockClear();
    chain.where.mockClear();
    chain.orderBy.mockClear();
    chain.first.mockClear();
    chain.limit.mockClear();
  });

  afterAll(() => {
    process.env = OLD_ENV;
  });

  describe('log', () => {
    it('inserts a row into audit_logs', async () => {
      const auditService = require('../services/auditService');

      await auditService.log({
        action: 'approve',
        actor: { id: '000011', name: 'Ethan White', role: 'supervisor' },
        entity: 'leave_request',
        entityId: 'LV-001',
        description: 'Approved leave for James Wilson',
        ip: '192.168.1.1',
      });

      expect(db.insert).toHaveBeenCalledWith({
        actor_id: '000011',
        actor_name: 'Ethan White',
        actor_role: 'supervisor',
        action: 'approve',
        entity: 'leave_request',
        entity_id: 'LV-001',
        description: 'Approved leave for James Wilson',
        ip_address: '192.168.1.1',
      });
    });
  });

  describe('query', () => {
    it('returns paginated results', async () => {
      const mockData = [{ audit_log_id: 1 }];
      const chain = db();
      chain._queue.push({ count: '1' });
      chain._queue.push(mockData);

      const auditService = require('../services/auditService');
      const result = await auditService.query({ page: 1, limit: 10 });

      expect(result.data).toEqual(mockData);
      expect(result.total).toBe(1);
    });

    it('filters by actorId when provided', async () => {
      const chain = db();
      chain._queue.push({ count: '0' });
      chain._queue.push([]);

      const auditService = require('../services/auditService');
      await auditService.query({ actorId: '000011' });

      expect(chain.where).toHaveBeenCalledWith('actor_id', '000011');
    });
  });

  describe('exportQuery', () => {
    it('returns all rows ordered by date', async () => {
      const mockRows = [{ audit_log_id: 1 }, { audit_log_id: 2 }];
      const chain = db();
      chain._queue.push(mockRows);

      const auditService = require('../services/auditService');
      const result = await auditService.exportQuery();

      expect(result).toEqual(mockRows);
    });
  });
});