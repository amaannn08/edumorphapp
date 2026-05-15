'use strict';

/**
 * Chapters routes — GET /api/chapters/:id/content
 * Returns content items for a chapter, optionally filtered by type.
 */

const express = require('express');
const router  = express.Router();
const db      = require('../config/db');
const { AppError } = require('../middleware/errorHandler');

// ── GET /api/chapters/:id/content ─────────────────────────────────────────────
// Query params: type = 'video' | 'note' | 'mindmap' | 'formula'  (optional)
// Returns all published content items for the chapter, ordered by item_order.
router.get('/:id/content', async (req, res, next) => {
  try {
    const validTypes = ['video', 'note', 'mindmap', 'formula'];
    const { type } = req.query;

    if (type && !validTypes.includes(type)) {
      throw new AppError(`Invalid type. Must be one of: ${validTypes.join(', ')}`, 400);
    }

    const params = [req.params.id];
    let sql = `
      SELECT
        ci.id,
        ci.chapter_id,
        ci.type,
        ci.title,
        ci.description,
        ci.url,
        ci.thumbnail_url,
        ci.duration_min,
        ci.content,
        ci.item_order
      FROM content_items ci
      WHERE ci.chapter_id = $1 AND ci.is_published = true
    `;

    if (type) {
      params.push(type);
      sql += ` AND ci.type = $${params.length}`;
    }

    sql += ' ORDER BY ci.item_order, ci.created_at';

    const result = await db.query(sql, params);
    return res.json({ success: true, data: result.rows });
  } catch (err) { next(err); }
});

module.exports = router;
