/**
 * Redis client configuration.
 * If REDIS_URL is not set, exports null - cache service will no-op.
 */
const { createClient } = require('redis');

let client = null;
let isConnected = false;

const redisUrl = process.env.REDIS_URL
  || (process.env.REDIS_HOST ? `redis://${process.env.REDIS_HOST}:${process.env.REDIS_PORT || 6379}` : null);

async function connect() {
  if (!redisUrl) {
    console.log('⚠️ Redis not configured (REDIS_URL not set). Caching disabled.');
    return null;
  }

  try {
    client = createClient({ url: redisUrl });

    client.on('error', (err) => {
      console.error('Redis client error:', err.message);
    });

    await client.connect();
    isConnected = true;
    console.log('✓ Redis connected');
    return client;
  } catch (err) {
    console.warn('Redis connection failed:', err.message, '- Caching disabled.');
    return null;
  }
}

function getClient() {
  return client;
}

function isRedisConnected() {
  return isConnected && client;
}

async function disconnect() {
  if (client) {
    await client.quit();
    client = null;
    isConnected = false;
  }
}

module.exports = {
  connect,
  getClient,
  isRedisConnected,
  disconnect,
};
