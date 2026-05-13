'use strict';

const express = require('express');
const router = express.Router();
const db = require('../config/db');
const { authenticate } = require('../middleware/auth');
const { AppError } = require('../middleware/errorHandler');

// ── GET /api/courses ─────────────────────────────────────────────────────────
// Query params: subject, difficulty, page, limit
router.get('/', authenticate, async (req, res, next) => {
  try {
    const { subject, difficulty, page = 1, limit = 20 } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);

    let sql = `
      SELECT c.id, c.title, c.description, c.subject, c.difficulty,
             c.thumbnail_url, c.instructor_name, c.total_lessons, c.duration_minutes,
             COALESCE(up.progress_pct, 0) AS progress,
             c.created_at
      FROM courses c
      LEFT JOIN user_progress up ON up.course_id = c.id AND up.user_id = $1
      WHERE c.is_published = true
    `;
    const params = [req.user.id];
    let paramIdx = 2;

    if (subject && subject !== 'All') {
      sql += ` AND c.subject = $${paramIdx++}`;
      params.push(subject);
    }
    if (difficulty) {
      sql += ` AND c.difficulty = $${paramIdx++}`;
      params.push(difficulty);
    }

    sql += ` ORDER BY c.created_at DESC LIMIT $${paramIdx++} OFFSET $${paramIdx}`;
    params.push(parseInt(limit), offset);

    const result = await db.query(sql, params);
    return res.json({ success: true, data: result.rows });
  } catch (err) { next(err); }
});

// ── GET /api/courses/:id ──────────────────────────────────────────────────────
router.get('/:id', authenticate, async (req, res, next) => {
  try {
    const courseResult = await db.query(
      `SELECT c.*, COALESCE(up.progress_pct, 0) AS progress
       FROM courses c
       LEFT JOIN user_progress up ON up.course_id = c.id AND up.user_id = $2
       WHERE c.id = $1 AND c.is_published = true`,
      [req.params.id, req.user.id]
    );
    if (courseResult.rowCount === 0) throw new AppError('Course not found', 404);

    const lessonsResult = await db.query(
      `SELECT id, title, duration_seconds, video_url, thumbnail_url, lesson_order
       FROM lessons WHERE course_id = $1 ORDER BY lesson_order`,
      [req.params.id]
    );

    return res.json({
      success: true,
      data: { ...courseResult.rows[0], lessons: lessonsResult.rows },
    });
  } catch (err) { next(err); }
});

// ── POST /api/courses/:id/progress ───────────────────────────────────────────
router.post('/:id/progress', authenticate, async (req, res, next) => {
  try {
    const { lesson_id, progress_pct } = req.body;
    await db.query(
      `INSERT INTO user_progress (user_id, course_id, lesson_id, progress_pct, last_watched_at)
       VALUES ($1, $2, $3, $4, NOW())
       ON CONFLICT (user_id, course_id) DO UPDATE
       SET lesson_id = EXCLUDED.lesson_id,
           progress_pct = GREATEST(user_progress.progress_pct, EXCLUDED.progress_pct),
           last_watched_at = NOW()`,
      [req.user.id, req.params.id, lesson_id, progress_pct]
    );
    return res.json({ success: true });
  } catch (err) { next(err); }
});

module.exports = router;
