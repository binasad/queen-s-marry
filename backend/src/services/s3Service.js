const { PutObjectCommand } = require('@aws-sdk/client-s3');
const { s3Client, bucket, baseUrl } = require('../config/s3');
const path = require('path');
const crypto = require('crypto');

class S3Service {
  /**
   * Upload a file to S3
   * @param {Buffer} fileBuffer - File buffer
   * @param {string} originalName - Original filename
   * @param {string} folder - Folder path in S3 (e.g., 'categories', 'services', 'assets')
   * @param {string} contentType - MIME type (e.g., 'image/jpeg', 'image/png')
   * @returns {Promise<string>} Public URL of the uploaded file
   */
  async uploadFile(fileBuffer, originalName, folder = 'assets', contentType = 'image/jpeg') {
    try {
      // Generate unique filename
      const ext = path.extname(originalName).toLowerCase();
      const uniqueName = `${crypto.randomUUID()}${ext}`;
      const key = `${folder}/${uniqueName}`;

      // Upload to S3
      // Note: ACL is deprecated if bucket has "Bucket owner enforced" setting
      // Files will be public if bucket policy allows s3:GetObject for public
      const command = new PutObjectCommand({
        Bucket: bucket,
        Key: key,
        Body: fileBuffer,
        ContentType: contentType,
        // ACL: 'public-read' - Removed as bucket uses bucket policy for public access
      });

      await s3Client.send(command);

      // Return public URL
      const publicUrl = `${baseUrl}/${key}`;
      return publicUrl;
    } catch (error) {
      console.error('S3 upload error:', error);
      throw new Error(`Failed to upload file to S3: ${error.message}`);
    }
  }

  /**
   * Upload an image file (with validation)
   * @param {Buffer} fileBuffer - File buffer
   * @param {string} originalName - Original filename
   * @param {string} folder - Folder path in S3
   * @returns {Promise<string>} Public URL of the uploaded image
   */
  async uploadImage(fileBuffer, originalName, folder = 'assets') {
    // Validate image type
    const ext = path.extname(originalName).toLowerCase();
    const allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
    
    if (!allowedExtensions.includes(ext)) {
      throw new Error(`Invalid image type. Allowed: ${allowedExtensions.join(', ')}`);
    }

    // Determine content type
    const contentTypeMap = {
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.png': 'image/png',
      '.gif': 'image/gif',
      '.webp': 'image/webp',
    };
    const contentType = contentTypeMap[ext] || 'image/jpeg';

    return this.uploadFile(fileBuffer, originalName, folder, contentType);
  }
}

module.exports = new S3Service();
