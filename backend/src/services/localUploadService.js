const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const env = require('../config/env');

const UPLOADS_DIR = path.join(process.cwd(), 'uploads');

/**
 * Upload file to local disk (fallback when S3 is not configured)
 * @param {Buffer} fileBuffer - File buffer
 * @param {string} originalName - Original filename
 * @param {string} folder - Folder path (e.g., 'profiles', 'categories', 'services')
 * @returns {Promise<string>} Public URL of the uploaded file
 */
async function uploadToLocal(fileBuffer, originalName, folder = 'assets') {
  const uploadDir = path.join(UPLOADS_DIR, folder);
  if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir, { recursive: true });
  }

  const ext = path.extname(originalName).toLowerCase() || '.jpg';
  const uniqueName = `${crypto.randomUUID()}${ext}`;
  const filePath = path.join(uploadDir, uniqueName);

  fs.writeFileSync(filePath, fileBuffer);

  // Use full BACKEND_URL so /api/v1/uploads is included (works behind reverse proxy)
  const backendUrl = env.backendUrl || process.env.BACKEND_URL || '';
  const baseUrl = backendUrl.replace(/\/$/, '') || `http://localhost:${env.port}/api/v1`;
  const publicUrl = `${baseUrl}/uploads/${folder}/${uniqueName}`;

  return publicUrl;
}

module.exports = { uploadToLocal, UPLOADS_DIR };
