'use strict';

const express = require('express');
const { body, validationResult } = require('express-validator');
const router = express.Router();
const db = require('../config/db');
const { AppError } = require('../middleware/errorHandler');
const { AI_SUMMARY_API_KEY, AI_SUMMARY_MODEL } = require('../config/env');

function validate(req) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) throw new AppError(errors.array()[0].msg, 422);
}

// ── GET /api/vault ────────────────────────────────────────────────────────────
router.get('/', async (req, res, next) => {
  try {
    const userId = req.user.id;

    const [notesRes, doubtsRes, mapsRes] = await Promise.all([
      db.query(
        'SELECT id, title, body, subject, created_at, updated_at FROM notes WHERE user_id = $1 ORDER BY updated_at DESC',
        [userId]
      ),
      db.query(
        'SELECT id, question, status, course_id, lesson_id, created_at FROM doubts WHERE user_id = $1 ORDER BY created_at DESC',
        [userId]
      ),
      db.query(
        'SELECT id, title, subject, created_at FROM mind_maps WHERE user_id = $1 ORDER BY created_at DESC',
        [userId]
      ),
    ]);

    return res.json({
      success: true,
      data: {
        notes:     notesRes.rows,
        doubts:    doubtsRes.rows,
        mind_maps: mapsRes.rows,
      },
    });
  } catch (err) { next(err); }
});

// ── POST /api/vault/notes ─────────────────────────────────────────────────────
router.post('/notes', [
  body('title').trim().notEmpty().withMessage('Title is required'),
  body('body').optional().trim(),
  body('subject').optional().trim(),
], async (req, res, next) => {
  try {
    validate(req);
    const { title, body: noteBody, subject } = req.body;
    const result = await db.query(
      'INSERT INTO notes (user_id, title, body, subject) VALUES ($1, $2, $3, $4) RETURNING *',
      [req.user.id, title, noteBody || null, subject || null]
    );
    return res.status(201).json({ success: true, data: result.rows[0] });
  } catch (err) { next(err); }
});

// ── PUT /api/vault/notes/:id ──────────────────────────────────────────────────
router.put('/notes/:id', async (req, res, next) => {
  try {
    const owned = await db.query('SELECT id FROM notes WHERE id = $1 AND user_id = $2', [req.params.id, req.user.id]);
    if (owned.rowCount === 0) throw new AppError('Note not found', 404);

    const fields = [];
    const vals = [];
    let idx = 1;
    for (const col of ['title', 'body', 'subject']) {
      if (req.body[col] !== undefined) { fields.push(`${col} = $${idx++}`); vals.push(req.body[col]); }
    }
    if (fields.length === 0) return res.json({ success: true, message: 'No changes' });
    vals.push(req.params.id);

    const result = await db.query(
      `UPDATE notes SET ${fields.join(', ')}, updated_at = NOW() WHERE id = $${idx} RETURNING *`,
      vals
    );
    return res.json({ success: true, data: result.rows[0] });
  } catch (err) { next(err); }
});

// ── DELETE /api/vault/notes/:id ───────────────────────────────────────────────
router.delete('/notes/:id', async (req, res, next) => {
  try {
    const result = await db.query('DELETE FROM notes WHERE id = $1 AND user_id = $2 RETURNING id', [req.params.id, req.user.id]);
    if (result.rowCount === 0) throw new AppError('Note not found', 404);
    return res.json({ success: true, message: 'Note deleted' });
  } catch (err) { next(err); }
});

// ── POST /api/vault/mind-maps ─────────────────────────────────────────────────
router.post('/mind-maps', [
  body('title').trim().notEmpty().withMessage('Title is required'),
], async (req, res, next) => {
  try {
    validate(req);
    const { title, subject, svg_data } = req.body;
    const result = await db.query(
      'INSERT INTO mind_maps (user_id, title, subject, svg_data) VALUES ($1, $2, $3, $4) RETURNING *',
      [req.user.id, title, subject || null, svg_data || null]
    );
    return res.status(201).json({ success: true, data: result.rows[0] });
  } catch (err) { next(err); }
});

// ── DELETE /api/vault/mind-maps/:id ──────────────────────────────────────────
router.delete('/mind-maps/:id', async (req, res, next) => {
  try {
    const result = await db.query('DELETE FROM mind_maps WHERE id = $1 AND user_id = $2 RETURNING id', [req.params.id, req.user.id]);
    if (result.rowCount === 0) throw new AppError('Mind map not found', 404);
    return res.json({ success: true, message: 'Mind map deleted' });
  } catch (err) { next(err); }
});

// ── POST /api/vault/ai-summary ────────────────────────────────────────────────
router.post('/ai-summary', [
  body('note_ids').isArray({ min: 1 }).withMessage('note_ids must be a non-empty array'),
], async (req, res, next) => {
  try {
    validate(req);
    if (!AI_SUMMARY_API_KEY) throw new AppError('AI summary not configured', 503);

    const { note_ids } = req.body;
    const userId = req.user.id;

    // Fetch notes, assert ownership
    const notes = await db.query(
      'SELECT title, body FROM notes WHERE id = ANY($1) AND user_id = $2',
      [note_ids, userId]
    );
    if (notes.rowCount === 0) throw new AppError('No notes found', 404);

    const combined = notes.rows
      .map(n => `## ${n.title}\n${n.body || ''}`)
      .join('\n\n');

    // Call OpenAI
    const https = require('https');
    const payload = JSON.stringify({
      model: AI_SUMMARY_MODEL,
      messages: [
        { role: 'system', content: 'You are a helpful study assistant for Indian students. Summarize the following student notes concisely for revision. Use bullet points. Keep it under 200 words.' },
        { role: 'user',   content: combined },
      ],
      max_tokens: 400,
    });

    const summary = await new Promise((resolve, reject) => {
      const options = {
        hostname: 'api.openai.com',
        path: '/v1/chat/completions',
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${AI_SUMMARY_API_KEY}`,
          'Content-Length': Buffer.byteLength(payload),
        },
      };
      const req2 = https.request(options, (resp) => {
        let data = '';
        resp.on('data', c => { data += c; });
        resp.on('end', () => {
          try {
            const parsed = JSON.parse(data);
            resolve(parsed.choices?.[0]?.message?.content || 'Unable to generate summary.');
          } catch { reject(new Error('Invalid AI response')); }
        });
      });
      req2.on('error', reject);
      req2.write(payload);
      req2.end();
    });

    return res.json({ success: true, data: { summary } });
  } catch (err) { next(err); }
});

module.exports = router;
