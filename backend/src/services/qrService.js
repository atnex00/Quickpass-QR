const crypto = require('crypto');

function getSecret() {
  if (!process.env.QR_SECRET) {
    throw new Error('QR_SECRET environment variable is required');
  }
  return process.env.QR_SECRET;
}

function localTzOffset() {
  const offset = -new Date().getTimezoneOffset();
  const h = String(Math.floor(Math.abs(offset) / 60)).padStart(2, '0');
  const m = String(Math.abs(offset) % 60).padStart(2, '0');
  return (offset >= 0 ? '+' : '-') + h + ':' + m;
}

function generateQrData(leaveId, employeeId, type, date, time) {
  const timePart = time.split(':').length === 3 ? time : time + ':00';
  const timestamp = `${date}T${timePart}${localTzOffset()}`;
  const signature = createSignature(leaveId, employeeId, type, timestamp);

  return {
    leave_id: leaveId,
    employee_id: employeeId,
    type,
    timestamp,
    signature,
  };
}

function createSignature(leaveId, employeeId, type, timestamp) {
  const payload = `${leaveId}:${employeeId}:${type}:${timestamp}`;
  return crypto.createHmac('sha256', getSecret()).update(payload).digest('hex');
}

function verifySignature(leaveId, employeeId, type, timestamp, signature) {
  const expected = createSignature(leaveId, employeeId, type, timestamp);
  if (typeof signature !== 'string' || signature.length !== expected.length) {
    return false;
  }
  return crypto.timingSafeEqual(Buffer.from(expected), Buffer.from(signature));
}

function encodeQrData(data) {
  const json = JSON.stringify(data);
  return Buffer.from(json).toString('base64url');
}

function decodeQrData(encoded) {
  try {
    const json = Buffer.from(encoded, 'base64url').toString('utf8');
    return JSON.parse(json);
  } catch {
    return null;
  }
}

function isWithinTimeWindow(timestamp, windowMinutes) {
  const qrTime = new Date(timestamp);
  const now = new Date();
  const diffMs = Math.abs(now.getTime() - qrTime.getTime());
  const windowMs = (parseInt(windowMinutes) || 15) * 60 * 1000;
  return diffMs <= windowMs;
}

module.exports = {
  generateQrData,
  createSignature,
  verifySignature,
  encodeQrData,
  decodeQrData,
  isWithinTimeWindow,
};
