const { S3Client } = require('@aws-sdk/client-s3');
const env = require('./env');

const s3Client = new S3Client({
  region: env.s3.region,
  credentials: env.s3.accessKeyId && env.s3.secretAccessKey
    ? {
        accessKeyId: env.s3.accessKeyId,
        secretAccessKey: env.s3.secretAccessKey,
      }
    : undefined, // Will use IAM role or default credentials if not provided
});

module.exports = {
  s3Client,
  bucket: env.s3.bucket,
  baseUrl: env.s3.baseUrl,
};
