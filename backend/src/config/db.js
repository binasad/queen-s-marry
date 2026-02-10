const { Pool } = require('pg');
const env = require('./env');

const pool = new Pool({
  host: env.db.host,
  port: env.db.port,
  database: env.db.name,
  user: env.db.user,
  password: env.db.password,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000, // Increased for cloud latency
  // Add SSL configuration here
  ssl: {
    rejectUnauthorized: false // Required for Supabase/Heroku/AWS RDS in most dev environments
  }
});

// Test database connection
pool.on('connect', () => {
  console.log('✓ Database connected successfully to Supabase');
});

pool.on('error', (err) => {
  console.error('Unexpected database error:', err);
  // Optional: Don't exit in dev if you want the server to stay up
  if (!env.isDevelopment) {
    process.exit(-1);
  }
});

// Query helper function
const query = async (text, params) => {
  const start = Date.now();
  try {
    const res = await pool.query(text, params);
    const duration = Date.now() - start;
    if (env.isDevelopment) {
      console.log('Executed query', { text, duration, rows: res.rowCount });
    }
    return res;
  } catch (error) {
    console.error('Database query error:', error);
    throw error;
  }
};

// Transaction helper
const transaction = async (callback) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const result = await callback(client);
    await client.query('COMMIT');
    return result;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};

module.exports = { pool, query, transaction };