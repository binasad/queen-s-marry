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

/**
 * Delete a previously uploaded local file by its public URL.
 * @param {string} fileUrl - Public URL returned by uploadToLocal
 * @returns {Promise<boolean>} true if file was deleted
 */
async function deleteFromLocal(fileUrl) {
  if (!fileUrl) return false;

  let uploadsRelativePath = null;
  try {
    const parsed = new URL(fileUrl);
    const marker = '/uploads/';
    const idx = parsed.pathname.indexOf(marker);
    if (idx !== -1) uploadsRelativePath = parsed.pathname.slice(idx + marker.length);
  } catch (error) {
    const marker = '/uploads/';
    const idx = fileUrl.indexOf(marker);
    if (idx !== -1) uploadsRelativePath = fileUrl.slice(idx + marker.length);
  }

  if (!uploadsRelativePath) return false;

  const normalizedRelative = path.normalize(uploadsRelativePath).replace(/^([.][.][\\/])+/, '');
  const targetPath = path.join(UPLOADS_DIR, normalizedRelative);
  const resolvedUploadsDir = path.resolve(UPLOADS_DIR);
  const resolvedTargetPath = path.resolve(targetPath);

  if (!resolvedTargetPath.startsWith(resolvedUploadsDir)) {
    return false;
  }

  if (!fs.existsSync(resolvedTargetPath)) {
    return false;
  }

  fs.unlinkSync(resolvedTargetPath);
  return true;
}

module.exports = { uploadToLocal, deleteFromLocal, UPLOADS_DIR };
