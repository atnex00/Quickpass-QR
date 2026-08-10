const qrService = require('../services/qrService');
const { getLocalDateString } = require('../utils/date');

describe('qrService', () => {
  const OLD_ENV = process.env;

  beforeEach(() => {
    jest.resetModules();
    process.env = { ...OLD_ENV, QR_SECRET: 'test-secret' };
  });

  afterAll(() => {
    process.env = OLD_ENV;
  });

  describe('createSignature / verifySignature', () => {
    it('creates a hex signature', () => {
      const sig = qrService.createSignature('LV-001', '000001', 'OUT', '2025-01-01T08:00:00+08:00');
      expect(sig).toMatch(/^[a-f0-9]{64}$/);
    });

    it('verifies a valid signature', () => {
      const sig = qrService.createSignature('LV-001', '000001', 'OUT', '2025-01-01T08:00:00+08:00');
      expect(qrService.verifySignature('LV-001', '000001', 'OUT', '2025-01-01T08:00:00+08:00', sig)).toBe(true);
    });

    it('rejects an invalid signature', () => {
      const sig = qrService.createSignature('LV-001', '000001', 'OUT', '2025-01-01T08:00:00+08:00');
      expect(qrService.verifySignature('LV-001', '000001', 'IN', '2025-01-01T08:00:00+08:00', sig)).toBe(false);
    });
  });

  describe('encodeQrData / decodeQrData', () => {
    it('encodes to base64url and decodes back', () => {
      const data = { leave_id: 'LV-001', employee_id: '000001', type: 'OUT' };
      const encoded = qrService.encodeQrData(data);
      expect(encoded).toEqual(expect.any(String));
      const decoded = qrService.decodeQrData(encoded);
      expect(decoded).toMatchObject(data);
    });

    it('returns null for invalid base64url', () => {
      expect(qrService.decodeQrData('not-valid-base64url!')).toBeNull();
    });
  });

  describe('generateQrData', () => {
    it('produces a valid payload with signature', () => {
      const result = qrService.generateQrData('LV-001', '000001', 'OUT', '2025-01-01', '08:00');
      expect(result).toMatchObject({
        leave_id: 'LV-001',
        employee_id: '000001',
        type: 'OUT',
      });
      expect(result.timestamp).toContain('2025-01-01T');
      expect(result.signature).toMatch(/^[a-f0-9]{64}$/);
    });

    it('pads time with :00 if needed', () => {
      const result = qrService.generateQrData('LV-001', '000001', 'OUT', '2025-01-01', '08:00');
      expect(result.timestamp).toContain('T08:00:00');
    });
  });

  describe('isWithinTimeWindow', () => {
    it('returns true for a recent timestamp', () => {
      const now = new Date().toISOString();
      expect(qrService.isWithinTimeWindow(now, 15)).toBe(true);
    });

    it('returns false for an old timestamp', () => {
      const old = new Date(Date.now() - 30 * 60 * 1000).toISOString();
      expect(qrService.isWithinTimeWindow(old, 15)).toBe(false);
    });

    it('defaults to 15 minutes when windowMinutes is not provided', () => {
      const recent = new Date(Date.now() - 5 * 60 * 1000).toISOString();
      expect(qrService.isWithinTimeWindow(recent)).toBe(true);
    });
  });

  describe('getQrTimestamp', () => {
    it('decodes the timestamp from a QR payload', () => {
      const data = qrService.generateQrData('LV-001', '000001', 'OUT', '2026-08-10', '09:00');
      const qr = qrService.encodeQrData(data);
      const ts = qrService.getQrTimestamp(qr);
      expect(ts).toBeInstanceOf(Date);
      expect(ts.getTime()).toBe(new Date(data.timestamp).getTime());
    });

    it('returns null for missing or invalid payloads', () => {
      expect(qrService.getQrTimestamp(null)).toBeNull();
      expect(qrService.getQrTimestamp('')).toBeNull();
      expect(qrService.getQrTimestamp('!!!bad!!!')).toBeNull();
      expect(qrService.getQrTimestamp(qrService.encodeQrData({ leave_id: 'LV-1' }))).toBeNull();
      expect(qrService.getQrTimestamp(qrService.encodeQrData({ leave_id: 'LV-1', timestamp: 'not-a-date' }))).toBeNull();
    });
  });

  describe('isOutQrExpired', () => {
    function expiredQr(minutesAgo) {
      const d = new Date(Date.now() - minutesAgo * 60 * 1000);
      const data = qrService.generateQrData('LV-001', '000001', 'OUT', getLocalDateString(d), d.toTimeString().split(' ')[0]);
      return qrService.encodeQrData(data);
    }

    it('returns false for non-approved statuses', () => {
      const qr = expiredQr(60);
      expect(qrService.isOutQrExpired({ status: 'pending', out_qr_code: qr })).toBe(false);
      expect(qrService.isOutQrExpired({ status: 'active', out_qr_code: qr })).toBe(false);
      expect(qrService.isOutQrExpired({ status: 'completed', out_qr_code: qr })).toBe(false);
    });

    it('returns true once the validity window has passed', () => {
      expect(qrService.isOutQrExpired({ status: 'approved', out_qr_code: expiredQr(60) })).toBe(true);
    });

    it('returns false while inside the validity window', () => {
      expect(qrService.isOutQrExpired({ status: 'approved', out_qr_code: expiredQr(5) }, new Date())).toBe(false);
    });

    it('respects the exact window boundary through a fixed now', () => {
      const data = qrService.generateQrData('LV-001', '000001', 'OUT', '2026-08-10', '09:00');
      const qr = qrService.encodeQrData(data);
      const ts = new Date(data.timestamp).getTime();
      const atWindow = new Date(ts + 15 * 60 * 1000);
      const afterWindow = new Date(ts + 15 * 60 * 1000 + 1);
      expect(qrService.isOutQrExpired({ status: 'approved', out_qr_code: qr }, atWindow)).toBe(false);
      expect(qrService.isOutQrExpired({ status: 'approved', out_qr_code: qr }, afterWindow)).toBe(true);
    });

    it('falls back to scheduled time when the QR code is missing', () => {
      const yesterday = getLocalDateString(new Date(Date.now() - 24 * 60 * 60 * 1000));
      expect(qrService.isOutQrExpired({ status: 'approved', out_qr_code: null, leave_date: yesterday, start_time: '09:00' })).toBe(true);
    });
  });
});
