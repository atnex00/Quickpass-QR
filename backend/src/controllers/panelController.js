const path = require('path');
const fs = require('fs');
const db = require('../config/database');
const logger = require('../config/logger');

const logFile = path.join(__dirname, '../../logs/app.log');

async function getStatus(req, res) {
  const mem = process.memoryUsage();
  let dbStatus = 'disconnected';
  try {
    await db.raw('SELECT 1');
    dbStatus = 'connected';
  } catch (e) {
    // DB unreachable — leave as disconnected
  }
  res.json({
    success: true,
    data: {
      db: dbStatus,
      uptime: process.uptime(),
      memory: { rss: mem.rss, heapUsed: mem.heapUsed, heapTotal: mem.heapTotal },
      nodeVersion: process.version,
      env: process.env.NODE_ENV || 'development',
      pid: process.pid,
    },
  });
}

async function runMigrate(req, res, next) {
  try {
    const [batch, migrations] = await db.migrate.latest();
    logger.info({ batch, count: migrations.length }, 'Migration run via panel');
    res.json({
      success: true,
      data: { batch, migrations: migrations || [] },
    });
  } catch (err) {
    next(err);
  }
}

async function runSeed(req, res, next) {
  try {
    const [result] = await db.seed.run();
    logger.info({ count: result?.length || 0 }, 'Seed run via panel');
    res.json({
      success: true,
      data: { seeds: result || [] },
    });
  } catch (err) {
    next(err);
  }
}

async function getLogs(req, res) {
  try {
    if (!fs.existsSync(logFile)) {
      return res.json({ success: true, data: { lines: [] } });
    }
    const content = fs.readFileSync(logFile, 'utf-8');
    const lines = content.trim().split('\n').filter(Boolean);
    const tail = lines.slice(-100);
    res.json({ success: true, data: { lines: tail } });
  } catch {
    res.json({ success: true, data: { lines: [] } });
  }
}

function getMetrics(req, res) {
  const metrics = req.app.locals.metrics || { requests: 0, errors: 0, totalTime: 0 };
  res.json({
    success: true,
    data: {
      totalRequests: metrics.requests,
      totalErrors: metrics.errors,
      avgResponseTime: metrics.requests > 0 ? (metrics.totalTime / metrics.requests).toFixed(1) : 0,
      errorRate: metrics.requests > 0 ? ((metrics.errors / metrics.requests) * 100).toFixed(2) : 0,
    },
  });
}

function restartServer(req, res) {
  logger.info('Restart requested via panel');
  res.json({ success: true, message: 'Server restarting...' });
  setTimeout(() => process.exit(0), 500);
}

module.exports = { getStatus, runMigrate, runSeed, getLogs, getMetrics, restartServer };