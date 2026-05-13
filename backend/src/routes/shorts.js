'use strict';

const express = require('express');
const router = express.Router();
const db = require('../config/db');
const { authenticate } = require('../middleware/auth');

// ── GET /api/shorts ───────────────────────────────────────────────────────────
// Paginated vertical feed — newest first
router.get('/', authenticate, async (req, res, next) => {
  try {
    const { subject, page = 1, limit = 10 } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);
    const params = [req.user.id];
    let paramIdx = 2;
    let subjectClause = '';

    if (subject && subject !== 'All') {
      subjectClause = `AND s.subject = $${paramIdx++}`;
      params.push(subject);
    }

    params.push(parseInt(limit), offset);
    const limitIdx = paramIdx++;
    const offsetIdx = paramIdx;

    const result = await db.query(
      `SELECT s.id, s.title, s.subject, s.video_url, s.thumbnail_url,
              s.instructor_name, s.views, s.duration_seconds,
              EXISTS(
                SELECT 1 FROM short_likes sl WHERE sl.short_id = s.id AND sl.user_id = $1
              ) AS is_liked,
              (SELECT COUNT(*) FROM short_likes sl2 WHERE sl2.short_id = s.id) AS like_count
       FROM shorts s
       WHERE s.is_published = true ${subjectClause}
       ORDER BY s.created_at DESC
       LIMIT $${limitIdx} OFFSET $${offsetIdx}`,
      params
    );

    return res.json({ success: true, data: result.rows });
  } catch (err) { next(err); }
});

// ── POST /api/shorts/:id/like ─────────────────────────────────────────────────
router.post('/:id/like', authenticate, async (req, res, next) => {
  try {
    const existing = await db.query(
      'SELECT id FROM short_likes WHERE short_id = $1 AND user_id = $2',
      [req.params.id, req.user.id]
    );

    if (existing.rowCount > 0) {
      await db.query('DELETE FROM short_likes WHERE short_id = $1 AND user_id = $2',
        [req.params.id, req.user.id]);
      return res.json({ success: true, liked: false });
    } else {
      await db.query('INSERT INTO short_likes (short_id, user_id) VALUES ($1, $2)',
        [req.params.id, req.user.id]);
      // Bump view count
      await db.query('UPDATE shorts SET views = views + 1 WHERE id = $1', [req.params.id]);
      return res.json({ success: true, liked: true });
    }
  } catch (err) { next(err); }
});

module.exports = router;
