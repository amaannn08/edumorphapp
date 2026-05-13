'use strict';

const { Pool } = require('pg');
const { DATABASE_URL, IS_PROD } = require('./env');
const logger = require('../services/logger');

const pool = new Pool({
  connectionString: DATABASE_URL,
  ssl: { rejectUnauthorized: IS_PROD }, // Neon requires SSL
  max: 10,               // max connections in pool
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
});

pool.on('connect', () => logger.debug('DB: new client connected'));
pool.on('error', (err) => logger.error('DB pool error', { error: err.message }));

/**
 * Execute a parameterised query.
 * @param {string} text  SQL with $1, $2 placeholders
 * @param {any[]}  params Query parameters
 */
async function query(text, params) {
  const start = Date.now();
  try {
    const result = await pool.query(text, params);
    const duration = Date.now() - start;
    logger.debug('DB query', { text: text.substring(0, 80), duration, rows: result.rowCount });
    return result;
  } catch (err) {
    logger.error('DB query error', { text: text.substring(0, 80), error: err.message });
    throw err;
  }
}

/**
 * Run multiple queries in a single transaction.
 * @param {(client: PoolClient) => Promise<T>} fn  Async function receiving a client
 */
async function transaction(fn) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const result = await fn(client);
    await client.query('COMMIT');
    return result;
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

module.exports = { query, transaction, pool };
