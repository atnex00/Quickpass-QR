process.env.DB_CONNECTION = process.env.DB_CONNECTION || 'sqlite::memory:';
process.env.JWT_SECRET = process.env.JWT_SECRET || 'test-jwt-secret';
process.env.COOKIE_SECRET = process.env.COOKIE_SECRET || 'test-cookie-secret';
process.env.QR_SECRET = process.env.QR_SECRET || 'test-qr-secret';
process.env.NODE_ENV = 'test';
