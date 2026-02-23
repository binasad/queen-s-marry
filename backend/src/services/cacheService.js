/**
 * Redis cache service.
 * Gracefully no-ops when Redis is not configured or unavailable.
 */
const redis = require('../config/redis');

const DEFAULT_TTL = 300; // 5 minutes

async function get(key) {
  const client = redis.getClient();
  if (!client) return null;
  try {
    const val = await client.get(key);
    return val ? JSON.parse(val) : null;
  } catch {
    return null;
  }
}

async function set(key, value, ttlSeconds = DEFAULT_TTL) {
  const client = redis.getClient();
  if (!client) return false;
  try {
    const serialized = JSON.stringify(value);
    await client.setEx(key, ttlSeconds, serialized);
    return true;
  } catch {
    return false;
  }
}

async function del(key) {
  const client = redis.getClient();
  if (!client) return false;
  try {
    await client.del(key);
    return true;
  } catch {
    return false;
  }
}

async function delPattern(pattern) {
  const client = redis.getClient();
  if (!client) return false;
  try {
    const keys = await client.keys(pattern);
    if (keys.length > 0) await client.del(keys);
    return true;
  } catch {
    return false;
  }
}

const CacheKeys = {
  categories: 'categories',
  servicesByCategory: (catId, page, limit) => `services:cat:${catId}:p:${page}:l:${limit}`,
  offersActive: (page, limit) => `offers:active:p:${page}:l:${limit}`,
  offersActivePattern: 'offers:active:*',
};

module.exports = {
  get,
  set,
  del,
  delPattern,
  CacheKeys,
  DEFAULT_TTL,
};
