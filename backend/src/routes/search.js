'use strict';

/**
 * Search route — GET /api/search
 * Full-text search across subjects, chapters, content_items, and shorts.
 * Query params:
 *   q      (required) — search query, min 2 chars
 *   type   (optional) — 'all' | 'subject' | 'chapter' | 'content' | 'short'  (default: 'all')
 *   limit  (optional) — per-type limit, default 5
 */

const express = require('express');
const router  = express.Router();
const db      = require('../config/db');
const { AppError } = require('../middleware/errorHandler');

router.get('/', async (req, res, next) => {
  try {
    const { q, type = 'all', limit = '5' } = req.query;

    if (!q || q.trim().length < 2) {
      throw new AppError('Query must be at least 2 characters', 400);
    }

    const query  = `%${q.trim().toLowerCase()}%`;
    const lim    = Math.min(parseInt(limit) || 5, 20);
    const results = {};

    // ── Subjects ─────────────────────────────────────────────────────────────
    if (type === 'all' || type === 'subject') {
      const r = await db.query(
        `SELECT id, name, icon, color_hex,
                (SELECT COUNT(*) FROM chapters WHERE subject_id = s.id AND is_published) AS chapter_count
         FROM subjects s
         WHERE is_active = true AND LOWER(name) LIKE $1
         LIMIT $2`,
        [query, lim]
      );
      results.subjects = r.rows;
    }

    // ── Chapters ─────────────────────────────────────────────────────────────
    if (type === 'all' || type === 'chapter') {
      const r = await db.query(
        `SELECT ch.id, ch.title, ch.subject_id, s.name AS subject_name, s.icon AS subject_icon
         FROM chapters ch
         JOIN subjects s ON s.id = ch.subject_id
         WHERE ch.is_published = true AND LOWER(ch.title) LIKE $1
         LIMIT $2`,
        [query, lim]
      );
      results.chapters = r.rows;
    }

    // ── Content Items ─────────────────────────────────────────────────────────
    if (type === 'all' || type === 'content') {
      const r = await db.query(
        `SELECT ci.id, ci.title, ci.type, ci.thumbnail_url, ci.duration_min,
                ch.title AS chapter_title, s.name AS subject_name
         FROM content_items ci
         JOIN chapters ch ON ch.id = ci.chapter_id
         JOIN subjects  s ON s.id  = ch.subject_id
         WHERE ci.is_published = true
           AND (LOWER(ci.title) LIKE $1 OR LOWER(ci.description) LIKE $1)
         LIMIT $2`,
        [query, lim]
      );
      results.content = r.rows;
    }

    // ── Shorts ────────────────────────────────────────────────────────────────
    if (type === 'all' || type === 'short') {
      const r = await db.query(
        `SELECT id, title, subject, thumbnail_url, duration_seconds, instructor_name
         FROM shorts
         WHERE is_published = true AND LOWER(title) LIKE $1
         LIMIT $2`,
        [query, lim]
      );
      results.shorts = r.rows;
    }

    const totalCount =
      (results.subjects?.length ?? 0) +
      (results.chapters?.length ?? 0) +
      (results.content?.length  ?? 0) +
      (results.shorts?.length   ?? 0);

    return res.json({ success: true, query: q, total: totalCount, data: results });
  } catch (err) { next(err); }
});

module.exports = router;
