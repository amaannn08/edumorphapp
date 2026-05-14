'use strict';

const express = require('express');
const { body, validationResult } = require('express-validator');
const router = express.Router();
const db = require('../config/db');
const { authenticate } = require('../middleware/auth');
const { AppError } = require('../middleware/errorHandler');

function validate(req) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) throw new AppError(errors.array()[0].msg, 422);
}

// ── GET /api/courses ─────────────────────────────────────────────────────────
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

    if (subject && subject !== 'All') { sql += ` AND c.subject = $${paramIdx++}`; params.push(subject); }
    if (difficulty)                   { sql += ` AND c.difficulty = $${paramIdx++}`; params.push(difficulty); }

    sql += ` ORDER BY c.created_at DESC LIMIT $${paramIdx++} OFFSET $${paramIdx}`;
    params.push(parseInt(limit), offset);

    const result = await db.query(sql, params);
    return res.json({ success: true, data: result.rows });
  } catch (err) { next(err); }
});

// ── GET /api/courses/:id ──────────────────────────────────────────────────────
router.get('/:id', authenticate, async (req, res, next) => {
  try {
    const userId = req.user.id;
    const courseId = req.params.id;

    const courseResult = await db.query(
      `SELECT c.*,
              COALESCE(up.progress_pct, 0) AS progress,
              EXISTS(SELECT 1 FROM bookmarks b
                     JOIN lessons l ON l.id = b.lesson_id
                     WHERE b.user_id = $2 AND l.course_id = $1) AS is_bookmarked
       FROM courses c
       LEFT JOIN user_progress up ON up.course_id = c.id AND up.user_id = $2
       WHERE c.id = $1 AND c.is_published = true`,
      [courseId, userId]
    );
    if (courseResult.rowCount === 0) throw new AppError('Course not found', 404);

    const lessonsResult = await db.query(
      `SELECT l.id, l.title, l.duration_minutes, l.language_code, l.video_url,
              l.thumbnail_url, l.lesson_order, l.description,
              COALESCE(up.progress_pct, 0) AS progress_pct,
              EXISTS(SELECT 1 FROM bookmarks b WHERE b.user_id = $2 AND b.lesson_id = l.id) AS is_bookmarked
       FROM lessons l
       LEFT JOIN user_progress up ON up.course_id = $1 AND up.user_id = $2 AND up.lesson_id = l.id
       WHERE l.course_id = $1
       ORDER BY l.lesson_order`,
      [courseId, userId]
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

// ── POST /api/courses/:id/bookmark ────────────────────────────────────────────
router.post('/:id/bookmark', authenticate, [
  body('lesson_id').notEmpty().withMessage('lesson_id is required'),
], async (req, res, next) => {
  try {
    validate(req);
    await db.query(
      'INSERT INTO bookmarks (user_id, lesson_id) VALUES ($1, $2) ON CONFLICT DO NOTHING',
      [req.user.id, req.body.lesson_id]
    );
    return res.json({ success: true, data: { bookmarked: true } });
  } catch (err) { next(err); }
});

// ── DELETE /api/courses/:id/bookmark ─────────────────────────────────────────
router.delete('/:id/bookmark', authenticate, [
  body('lesson_id').notEmpty().withMessage('lesson_id is required'),
], async (req, res, next) => {
  try {
    validate(req);
    await db.query(
      'DELETE FROM bookmarks WHERE user_id = $1 AND lesson_id = $2',
      [req.user.id, req.body.lesson_id]
    );
    return res.json({ success: true, data: { bookmarked: false } });
  } catch (err) { next(err); }
});

// ── POST /api/doubts ──────────────────────────────────────────────────────────
router.post('/doubts', authenticate, [
  body('question').trim().isLength({ min: 10 }).withMessage('Question must be at least 10 characters'),
  body('course_id').optional().isUUID(),
  body('lesson_id').optional().isUUID(),
], async (req, res, next) => {
  try {
    validate(req);
    const { question, course_id, lesson_id } = req.body;
    const result = await db.query(
      'INSERT INTO doubts (user_id, course_id, lesson_id, question) VALUES ($1, $2, $3, $4) RETURNING id, status',
      [req.user.id, course_id || null, lesson_id || null, question]
    );
    return res.status(201).json({ success: true, data: result.rows[0] });
  } catch (err) { next(err); }
});

// ── GET /api/doubts ───────────────────────────────────────────────────────────
router.get('/doubts', authenticate, async (req, res, next) => {
  try {
    const { course_id } = req.query;
    let sql = 'SELECT * FROM doubts WHERE user_id = $1';
    const params = [req.user.id];
    if (course_id) { sql += ' AND course_id = $2'; params.push(course_id); }
    sql += ' ORDER BY created_at DESC';
    const result = await db.query(sql, params);
    return res.json({ success: true, data: result.rows });
  } catch (err) { next(err); }
});

module.exports = router;
