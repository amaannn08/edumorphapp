'use strict';

/**
 * Subjects routes — GET /api/subjects/*
 * Provides the top-level subject catalogue and its chapters with content counts.
 */

const express = require('express');
const router  = express.Router();
const db      = require('../config/db');

// ── GET /api/subjects ─────────────────────────────────────────────────────────
// Returns all active subjects with chapter_count and per-type content totals.
router.get('/', async (req, res, next) => {
  try {
    const result = await db.query(`
      SELECT
        s.id,
        s.name,
        s.icon,
        s.color_hex,
        s.display_order,
        COUNT(DISTINCT ch.id)                                              AS chapter_count,
        COUNT(ci.id) FILTER (WHERE ci.type = 'video'   AND ci.is_published) AS video_count,
        COUNT(ci.id) FILTER (WHERE ci.type = 'note'    AND ci.is_published) AS note_count,
        COUNT(ci.id) FILTER (WHERE ci.type = 'mindmap' AND ci.is_published) AS mindmap_count,
        COUNT(ci.id) FILTER (WHERE ci.type = 'formula' AND ci.is_published) AS formula_count
      FROM subjects s
      LEFT JOIN chapters ch      ON ch.subject_id = s.id AND ch.is_published = true
      LEFT JOIN content_items ci ON ci.chapter_id = ch.id
      WHERE s.is_active = true
      GROUP BY s.id
      ORDER BY s.display_order, s.name
    `);

    return res.json({ success: true, data: result.rows });
  } catch (err) { next(err); }
});

// ── GET /api/subjects/:id ─────────────────────────────────────────────────────
// Returns a single subject's detail.
router.get('/:id', async (req, res, next) => {
  try {
    const result = await db.query(
      'SELECT id, name, icon, color_hex, display_order FROM subjects WHERE id = $1 AND is_active = true',
      [req.params.id]
    );
    if (result.rowCount === 0) {
      return res.status(404).json({ success: false, message: 'Subject not found' });
    }
    return res.json({ success: true, data: result.rows[0] });
  } catch (err) { next(err); }
});

// ── GET /api/subjects/:id/chapters ────────────────────────────────────────────
// Returns all published chapters for a subject, each with per-type content counts.
router.get('/:id/chapters', async (req, res, next) => {
  try {
    const result = await db.query(`
      SELECT
        ch.id,
        ch.subject_id,
        ch.title,
        ch.chapter_order,
        COUNT(ci.id) FILTER (WHERE ci.type = 'video'   AND ci.is_published) AS videos_count,
        COUNT(ci.id) FILTER (WHERE ci.type = 'note'    AND ci.is_published) AS notes_count,
        COUNT(ci.id) FILTER (WHERE ci.type = 'mindmap' AND ci.is_published) AS mindmaps_count,
        COUNT(ci.id) FILTER (WHERE ci.type = 'formula' AND ci.is_published) AS formulas_count
      FROM chapters ch
      LEFT JOIN content_items ci ON ci.chapter_id = ch.id
      WHERE ch.subject_id = $1 AND ch.is_published = true
      GROUP BY ch.id
      ORDER BY ch.chapter_order
    `, [req.params.id]);

    return res.json({ success: true, data: result.rows });
  } catch (err) { next(err); }
});

module.exports = router;
