const knex = require('knex');
const pg = require('pg');
const config = require('../../knexfile');

// Postgres `date` columns have no timezone — return them as plain "YYYY-MM-DD"
// strings instead of local-midnight Date objects (which JSON-serialize to a
// UTC-shifted ISO instant and cause off-by-one-day display bugs).
pg.types.setTypeParser(1082, (value) => value);

const environment = process.env.NODE_ENV || 'development';
const db = knex(config[environment]);

async function testConnection(maxRetries = 5, baseDelay = 1000) {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      await db.raw('SELECT 1');
      return;
    } catch (err) {
      if (attempt === maxRetries) throw err;
      const delay = Math.min(baseDelay * Math.pow(2, attempt - 1), 10000);
      await new Promise(r => setTimeout(r, delay));
    }
  }
}

module.exports = db;
module.exports.testConnection = testConnection;
