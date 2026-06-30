const envFile = `.env.${process.env.NODE_ENV || 'dev'}`;
require('dotenv').config({ path: require('path').join(__dirname, envFile) });

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
    },
  },
};
