'use strict';

/**
 * Notifications routes — /api/notifications
 * GET    /               — list notifications (paginated)
 * GET    /unread-count   — count of unread notifications
 * PUT    /:id/read       — mark one notification as read
 * PUT    /read-all       — mark all as read
 * DELETE /:id            — delete a notification
 */

const express = require('express');
const router  = express.Router();
const db      = require('../config/db');
const { AppError } = require('../middleware/errorHandler');

// ── GET /api/notifications ────────────────────────────────────────────────────
router.get('/', async (req, res, next) => {
  try {
    const { page = '1', limit = '20' } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);

    const [rows, countRow] = await Promise.all([
      db.query(
        `SELECT id, type, title, body, icon, action_url, is_read, created_at
         FROM notifications
         WHERE user_id = $1
         ORDER BY created_at DESC
         LIMIT $2 OFFSET $3`,
        [req.user.id, parseInt(limit), offset]
      ),
      db.query(
        'SELECT COUNT(*) AS total, COUNT(*) FILTER (WHERE NOT is_read) AS unread FROM notifications WHERE user_id = $1',
        [req.user.id]
      ),
    ]);

    return res.json({
      success: true,
      data: rows.rows,
      meta: {
        total:  parseInt(countRow.rows[0].total),
        unread: parseInt(countRow.rows[0].unread),
        page:   parseInt(page),
        limit:  parseInt(limit),
      },
    });
  } catch (err) { next(err); }
});

// ── GET /api/notifications/unread-count ──────────────────────────────────────
router.get('/unread-count', async (req, res, next) => {
  try {
    const r = await db.query(
      'SELECT COUNT(*) AS count FROM notifications WHERE user_id = $1 AND is_read = false',
      [req.user.id]
    );
    return res.json({ success: true, data: { count: parseInt(r.rows[0].count) } });
  } catch (err) { next(err); }
});

// ── PUT /api/notifications/read-all ──────────────────────────────────────────
// Must be placed BEFORE /:id to avoid route collision
router.put('/read-all', async (req, res, next) => {
  try {
    const r = await db.query(
      'UPDATE notifications SET is_read = true WHERE user_id = $1 AND is_read = false RETURNING id',
      [req.user.id]
    );
    return res.json({ success: true, data: { updated: r.rowCount } });
  } catch (err) { next(err); }
});

// ── PUT /api/notifications/:id/read ──────────────────────────────────────────
router.put('/:id/read', async (req, res, next) => {
  try {
    const r = await db.query(
      'UPDATE notifications SET is_read = true WHERE id = $1 AND user_id = $2 RETURNING id',
      [req.params.id, req.user.id]
    );
    if (r.rowCount === 0) throw new AppError('Notification not found', 404);
    return res.json({ success: true });
  } catch (err) { next(err); }
});

// ── DELETE /api/notifications/:id ────────────────────────────────────────────
router.delete('/:id', async (req, res, next) => {
  try {
    const r = await db.query(
      'DELETE FROM notifications WHERE id = $1 AND user_id = $2 RETURNING id',
      [req.params.id, req.user.id]
    );
    if (r.rowCount === 0) throw new AppError('Notification not found', 404);
    return res.json({ success: true });
  } catch (err) { next(err); }
});

module.exports = router;
