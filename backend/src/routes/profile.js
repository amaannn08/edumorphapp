'use strict';

const express = require('express');
const { body, validationResult } = require('express-validator');
const router = express.Router();
const db = require('../config/db');
const { authenticate } = require('../middleware/auth');
const { AppError } = require('../middleware/errorHandler');

// ── GET /api/profile ──────────────────────────────────────────────────────────
router.get('/', authenticate, async (req, res, next) => {
  try {
    const userResult = await db.query(
      `SELECT id, name, email, username, grade, subjects, avatar_url,
              xp, streak_days, rank, email_verified, created_at
       FROM users WHERE id = $1`,
      [req.user.id]
    );
    if (userResult.rowCount === 0) throw new AppError('User not found', 404);

    // Recent course progress
    const progressResult = await db.query(
      `SELECT c.id, c.title, c.subject, c.thumbnail_url, up.progress_pct
       FROM user_progress up
       JOIN courses c ON c.id = up.course_id
       WHERE up.user_id = $1
       ORDER BY up.last_watched_at DESC
       LIMIT 5`,
      [req.user.id]
    );

    // Weekly activity (last 7 days XP / attempts)
    const activityResult = await db.query(
      `SELECT DATE(answered_at) AS day, SUM(score) AS xp_earned
       FROM quiz_attempts
       WHERE user_id = $1 AND answered_at >= NOW() - INTERVAL '7 days'
       GROUP BY day ORDER BY day`,
      [req.user.id]
    );

    return res.json({
      success: true,
      data: {
        user: userResult.rows[0],
        recentCourses: progressResult.rows,
        weeklyActivity: activityResult.rows,
      },
    });
  } catch (err) { next(err); }
});

// ── PUT /api/profile ──────────────────────────────────────────────────────────
router.put('/', authenticate, [
  body('name').optional().trim().notEmpty(),
  body('username').optional().trim().isAlphanumeric().isLength({ min: 3, max: 30 }),
  body('grade').optional().trim(),
  body('subjects').optional().isArray(),
  body('avatar_url').optional().isURL(),
], async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) throw new AppError(errors.array()[0].msg, 422);

    const { name, username, grade, subjects, avatar_url } = req.body;

    if (username) {
      const taken = await db.query(
        'SELECT id FROM users WHERE username = $1 AND id != $2',
        [username, req.user.id]
      );
      if (taken.rowCount > 0) throw new AppError('Username already taken', 409);
    }

    const result = await db.query(
      `UPDATE users SET
        name = COALESCE($1, name),
        username = COALESCE($2, username),
        grade = COALESCE($3, grade),
        subjects = COALESCE($4, subjects),
        avatar_url = COALESCE($5, avatar_url),
        updated_at = NOW()
       WHERE id = $6
       RETURNING id, name, email, username, grade, subjects, avatar_url, xp, streak_days`,
      [name, username, grade, subjects, avatar_url, req.user.id]
    );

    return res.json({ success: true, data: result.rows[0] });
  } catch (err) { next(err); }
});

module.exports = router;
