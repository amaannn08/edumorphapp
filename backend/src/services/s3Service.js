'use strict';

const { PutObjectCommand, DeleteObjectCommand, GetObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const { v4: uuidv4 } = require('uuid');
const s3Client = require('../config/s3');
const { S3_BUCKET_NAME, S3_PRESIGNED_URL_EXPIRES, AWS_REGION, CLOUDFRONT_DOMAIN } = require('../config/env');

/**
 * Generate a presigned PUT URL so the Flutter client can upload directly to S3.
 * @param {string} folder  e.g. 'videos', 'thumbnails', 'avatars'
 * @param {string} mimeType  e.g. 'video/mp4'
 * @returns {{ uploadUrl: string, key: string, publicUrl: string }}
 */
async function getPresignedUploadUrl(folder, mimeType) {
  const ext = mimeType.split('/')[1] || 'bin';
  const key = `${folder}/${uuidv4()}.${ext}`;

  const command = new PutObjectCommand({
    Bucket: S3_BUCKET_NAME,
    Key: key,
    ContentType: mimeType,
  });

  const uploadUrl = await getSignedUrl(s3Client, command, {
    expiresIn: S3_PRESIGNED_URL_EXPIRES,
  });

  const publicUrl = CLOUDFRONT_DOMAIN 
    ? `https://${CLOUDFRONT_DOMAIN}/${key}`
    : `https://${S3_BUCKET_NAME}.s3.${AWS_REGION}.amazonaws.com/${key}`;

  return { uploadUrl, key, publicUrl };
}

/**
 * Generate a presigned GET URL for private objects.
 */
async function getPresignedDownloadUrl(key) {
  const command = new GetObjectCommand({ Bucket: S3_BUCKET_NAME, Key: key });
  return getSignedUrl(s3Client, command, { expiresIn: S3_PRESIGNED_URL_EXPIRES });
}

/**
 * Delete an object from S3 by key.
 */
async function deleteObject(key) {
  const command = new DeleteObjectCommand({ Bucket: S3_BUCKET_NAME, Key: key });
  return s3Client.send(command);
}

/**
 * Build the public CDN/S3 URL for a given key.
 */
function publicUrl(key) {
  return CLOUDFRONT_DOMAIN 
    ? `https://${CLOUDFRONT_DOMAIN}/${key}`
    : `https://${S3_BUCKET_NAME}.s3.${AWS_REGION}.amazonaws.com/${key}`;
}

module.exports = { getPresignedUploadUrl, getPresignedDownloadUrl, deleteObject, publicUrl };
