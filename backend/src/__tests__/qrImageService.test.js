jest.mock('qrcode', () => ({
  toBuffer: jest.fn().mockResolvedValue(Buffer.from('qr-buffer')),
}));

jest.mock('sharp', () => jest.fn().mockReturnValue({
  metadata: jest.fn().mockResolvedValue({ width: 100, height: 100 }),
  png: jest.fn().mockReturnThis(),
  resize: jest.fn().mockReturnThis(),
  composite: jest.fn().mockReturnThis(),
  toBuffer: jest.fn().mockResolvedValue(Buffer.from('logo-buffer')),
  toFile: jest.fn().mockResolvedValue({}),
}));

const fs = require('fs');
const QRCode = require('qrcode');
const qrImageService = require('../services/qrImageService');

describe('qrImageService', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('generateQrImage', () => {
    it('uses a dark blue OUT color for scanning', async () => {
      await qrImageService.generateQrImage('data', 'OUT', 'LV-20260804-ABCD1234');
      expect(QRCode.toBuffer).toHaveBeenCalledWith('data', expect.objectContaining({
        color: { dark: '#1E40AF', light: '#ffffff' },
      }));
    });

    it('uses a dark green IN color for scanning', async () => {
      await qrImageService.generateQrImage('data', 'IN', 'LV-20260804-ABCD1234');
      expect(QRCode.toBuffer).toHaveBeenCalledWith('data', expect.objectContaining({
        color: { dark: '#16A34A', light: '#ffffff' },
      }));
    });

    it('writes the image with H error correction and a white background', async () => {
      await qrImageService.generateQrImage('data', 'OUT', 'LV-20260804-ABCD1234');
      expect(QRCode.toBuffer).toHaveBeenCalledWith('data', expect.objectContaining({
        errorCorrectionLevel: 'H',
        type: 'png',
      }));
    });
  });

  describe('getQrImagePath', () => {
    it('returns a path for a valid leave id', () => {
      const p = qrImageService.getQrImagePath('LV-20260804-ABCD1234', 'out');
      expect(p).toContain('qr_codes');
      expect(p.endsWith('LV-20260804-ABCD1234_out.png')).toBe(true);
    });

    it('returns an empty string for a malformed leave id', () => {
      expect(qrImageService.getQrImagePath('../../etc/passwd', 'out')).toBe('');
      expect(qrImageService.getQrImagePath('LV-1', 'out')).toBe('');
      expect(qrImageService.getQrImagePath(12345, 'out')).toBe('');
    });
  });

  describe('deleteQrImages', () => {
    it('does not touch the filesystem for a malformed leave id', () => {
      const existsSpy = jest.spyOn(fs, 'existsSync');
      qrImageService.deleteQrImages('../secrets');
      expect(existsSpy).not.toHaveBeenCalled();
      existsSpy.mockRestore();
    });
  });
});