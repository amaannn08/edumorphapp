'use strict';

/**
 * Settings routes — /api/settings
 * GET  /              — fetch current user settings (profile + prefs)
 * PUT  /profile       — update name, username, grade, subjects, language
 * PUT  /notifications — update notification_prefs JSONB
 * PUT  /password      — change password (current + new)
 * DELETE /account     — delete account (soft tombstone)
 */

const express = require('express');
const { body, validationResult } = require('express-validator');
const bcrypt = require('bcryptjs');
const router = express.Router();
const db     = require('../config/db');
const { AppError } = require('../middleware/errorHandler');

function validate(req) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) throw new AppError(errors.array()[0].msg, 422);
}

const VALID_GRADES = [
  'Class 5', 'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10',
  'Class 11', 'Class 12', 'Undergraduate', 'Postgraduate',
];

// ── GET /api/settings ─────────────────────────────────────────────────────────
router.get('/', async (req, res, next) => {
  try {
    const r = await db.query(
      `SELECT id, name, email, username, grade, subjects, avatar_url,
              language, career_interests, notification_prefs, email_verified, created_at
       FROM users WHERE id = $1`,
      [req.user.id]
    );
    if (r.rowCount === 0) throw new AppError('User not found', 404);
    return res.json({ success: true, data: r.rows[0] });
  } catch (err) { next(err); }
});

// ── PUT /api/settings/profile ─────────────────────────────────────────────────
router.put('/profile', [
  body('name').optional().trim().notEmpty().withMessage('Name cannot be empty'),
  body('username').optional().trim().isAlphanumeric().isLength({ min: 3, max: 30 }),
  body('grade').optional().custom(v => {
    if (v && !VALID_GRADES.includes(v)) throw new Error(`grade must be one of: ${VALID_GRADES.join(', ')}`);
    return true;
  }),
  body('subjects').optional().isArray(),
  body('language').optional().trim().isLength({ max: 20 }),
], async (req, res, next) => {
  try {
    validate(req);
    const { name, username, grade, subjects, language } = req.body;

    if (username) {
      const taken = await db.query(
        'SELECT id FROM users WHERE username = $1 AND id != $2',
        [username, req.user.id]
      );
      if (taken.rowCount > 0) throw new AppError('Username already taken', 409);
    }

    const r = await db.query(
      `UPDATE users SET
         name     = COALESCE($1, name),
         username = COALESCE($2, username),
         grade    = COALESCE($3, grade),
         subjects = COALESCE($4, subjects),
         language = COALESCE($5, language),
         updated_at = NOW()
       WHERE id = $6
       RETURNING id, name, email, username, grade, subjects, language`,
      [name, username, grade, subjects, language, req.user.id]
    );
    return res.json({ success: true, data: r.rows[0] });
  } catch (err) { next(err); }
});

// ── PUT /api/settings/notifications ──────────────────────────────────────────
router.put('/notifications', [
  body('push_enabled').optional().isBoolean(),
  body('streak_reminder').optional().isBoolean(),
  body('new_content').optional().isBoolean(),
  body('xp_milestone').optional().isBoolean(),
], async (req, res, next) => {
  try {
    validate(req);
    const { push_enabled, streak_reminder, new_content, xp_milestone } = req.body;

    // Merge with existing prefs (JSONB || operator merges top-level keys)
    const updates = {};
    if (push_enabled    !== undefined) updates.push_enabled    = push_enabled;
    if (streak_reminder !== undefined) updates.streak_reminder = streak_reminder;
    if (new_content     !== undefined) updates.new_content     = new_content;
    if (xp_milestone    !== undefined) updates.xp_milestone    = xp_milestone;

    const r = await db.query(
      `UPDATE users SET notification_prefs = notification_prefs || $1::jsonb, updated_at = NOW()
       WHERE id = $2
       RETURNING notification_prefs`,
      [JSON.stringify(updates), req.user.id]
    );
    return res.json({ success: true, data: r.rows[0].notification_prefs });
  } catch (err) { next(err); }
});

// ── PUT /api/settings/password ────────────────────────────────────────────────
router.put('/password', [
  body('current_password').notEmpty().withMessage('Current password is required'),
  body('new_password').isLength({ min: 8 }).withMessage('New password must be ≥ 8 chars'),
], async (req, res, next) => {
  try {
    validate(req);
    const { current_password, new_password } = req.body;

    const r = await db.query('SELECT password_hash FROM users WHERE id = $1', [req.user.id]);
    if (r.rowCount === 0) throw new AppError('User not found', 404);

    const valid = await bcrypt.compare(current_password, r.rows[0].password_hash);
    if (!valid) throw new AppError('Current password is incorrect', 401);

    const hash = await bcrypt.hash(new_password, 12);
    await db.query('UPDATE users SET password_hash = $1, updated_at = NOW() WHERE id = $2', [hash, req.user.id]);

    return res.json({ success: true, message: 'Password updated' });
  } catch (err) { next(err); }
});

// ── DELETE /api/settings/account ─────────────────────────────────────────────
router.delete('/account', async (req, res, next) => {
  try {
    // Anonymise rather than hard-delete to preserve relational integrity
    await db.query(
      `UPDATE users SET
         name = 'Deleted User',
         email = 'deleted_' || id || '@deleted.local',
         password_hash = '',
         email_verified = false,
         updated_at = NOW()
       WHERE id = $1`,
      [req.user.id]
    );
    // Revoke all refresh tokens
    await db.query('DELETE FROM refresh_tokens WHERE user_id = $1', [req.user.id]);
    return res.json({ success: true, message: 'Account deleted' });
  } catch (err) { next(err); }
});

module.exports = router;
