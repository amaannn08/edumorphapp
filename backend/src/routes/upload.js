'use strict';

const express = require('express');
const { body, validationResult } = require('express-validator');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const { getPresignedUploadUrl } = require('../services/s3Service');
const { AppError } = require('../middleware/errorHandler');

const ALLOWED_FOLDERS = ['videos', 'thumbnails', 'avatars', 'resources'];
const ALLOWED_MIME_TYPES = [
  'video/mp4', 'video/webm',
  'image/jpeg', 'image/png', 'image/webp',
  'application/pdf',
];

// ── POST /api/upload/presigned ────────────────────────────────────────────────
// Body: { folder: 'videos' | 'thumbnails' | 'avatars' | 'resources', mimeType: 'video/mp4' }
// Returns: { uploadUrl, key, publicUrl } — Flutter uploads directly to S3
router.post('/presigned', authenticate, [
  body('folder').isIn(ALLOWED_FOLDERS).withMessage(`folder must be one of: ${ALLOWED_FOLDERS.join(', ')}`),
  body('mimeType').isIn(ALLOWED_MIME_TYPES).withMessage('Unsupported MIME type'),
], async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) throw new AppError(errors.array()[0].msg, 422);

    const { folder, mimeType } = req.body;
    const result = await getPresignedUploadUrl(folder, mimeType);

    return res.json({
      success: true,
      data: result,
      message: 'PUT to uploadUrl directly from the client. Save publicUrl to DB after upload.',
    });
  } catch (err) { next(err); }
});

module.exports = router;
