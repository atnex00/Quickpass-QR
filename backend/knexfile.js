const path = require('path');
const fs = require('fs');
const dotenv = require('dotenv');

function loadEnv() {
  const baseEnv = path.join(__dirname, '.env');
  const envFile = path.join(__dirname, `.env.${process.env.NODE_ENV || 'dev'}`);
  if (fs.existsSync(baseEnv)) {
    dotenv.config({ path: baseEnv });
  }
  if (fs.existsSync(envFile) && envFile !== baseEnv) {
    dotenv.config({ path: envFile });
  }
}

loadEnv();

module.exports = {
  dev: {
    client: 'pg',
    connection: {
      connectionString: process.env.DB_CONNECTION,
      ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
    },
    migrations: {
      directory: '../database/migrations',
      extension: 'js',
    },
    seeds: {
      directory: '../database/seeds',
      extension: 'js',
    },
    pool: {
      min: 2,
      max: 10,
    },
  },

  development: {
    client: 'pg',
    connection: {
      connectionString: process.env.DB_CONNECTION,
      ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
    },
    migrations: {
      directory: '../database/migrations',
      extension: 'js',
    },
    seeds: {
      directory: '../database/seeds',
      extension: 'js',
    },
    pool: {
      min: 2,
      max: 10,
    },
  },

  test: {
    client: 'pg',
    connection: {
      connectionString: process.env.DB_CONNECTION,
      ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
    },
    migrations: {
      directory: '../database/migrations',
      extension: 'js',
    },
    seeds: {
      directory: '../database/seeds',
      extension: 'js',
    },
    pool: {
      min: 2,
      max: 5,
    },
  },

  production: {
    client: 'pg',
    connection: {
      connectionString: process.env.DB_CONNECTION,
      ssl: { rejectUnauthorized: true },
    },
    migrations: {
      directory: '../database/migrations',
      extension: 'js',
    },
    seeds: {
      directory: '../database/seeds',
      extension: 'js',
    },
    pool: {
      min: 2,
      max: 20,
      acquireTimeoutMillis: 30000,
      createTimeoutMillis: 5000,
      idleTimeoutMillis: 600000,
      reapIntervalMillis: 1000,
    },
  },
};
