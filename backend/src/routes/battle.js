'use strict';

const express = require('express');
const { body, validationResult } = require('express-validator');
const router = express.Router();
const db = require('../config/db');
const { AppError } = require('../middleware/errorHandler');

function validate(req) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) throw new AppError(errors.array()[0].msg, 422);
}

function generateRoomCode() {
  return '#' + String(Math.floor(Math.random() * 999)).padStart(3, '0');
}

// ── GET /api/battle ───────────────────────────────────────────────────────────
router.get('/', async (req, res, next) => {
  try {
    const userId = req.user.id;

    const [lbRes, roomsRes, opsRes] = await Promise.all([
      // Global leaderboard top 10
      db.query(
        `SELECT name, username, xp, avatar_url,
                ROW_NUMBER() OVER (ORDER BY xp DESC) AS rank
         FROM users ORDER BY xp DESC LIMIT 10`
      ),
      // Open battle rooms
      db.query(
        `SELECT r.id, r.code, r.name, r.subject, r.max_players, r.xp_reward, r.status,
                COUNT(p.user_id)::int AS player_count
         FROM battle_rooms r
         LEFT JOIN battle_participants p ON p.room_id = r.id
         WHERE r.status = 'waiting'
         GROUP BY r.id
         ORDER BY r.created_at DESC`
      ),
      // Special ops with user progress
      db.query(
        `SELECT ops.*,
                COALESCE(att.score, 0)::float /
                  GREATEST(ops.xp_reward, 1) * 100 AS user_progress_pct
         FROM special_ops ops
         LEFT JOIN special_op_attempts att
           ON att.op_id = ops.id AND att.user_id = $1
         WHERE ops.is_active = true
         ORDER BY ops.created_at`,
        [userId]
      ),
    ]);

    // Countdown: next tournament at next 4:00 AM UTC (simple hardcoded approach)
    const now = new Date();
    const nextTournament = new Date(now);
    nextTournament.setUTCHours(4, 0, 0, 0);
    if (nextTournament <= now) nextTournament.setUTCDate(nextTournament.getUTCDate() + 1);
    const countdownSeconds = Math.round((nextTournament - now) / 1000);

    return res.json({
      success: true,
      data: {
        leaderboard:       lbRes.rows,
        open_rooms:        roomsRes.rows,
        special_ops:       opsRes.rows,
        countdown_seconds: countdownSeconds,
      },
    });
  } catch (err) { next(err); }
});

// ── POST /api/battle/rooms ────────────────────────────────────────────────────
router.post('/rooms', [
  body('name').trim().notEmpty().withMessage('Room name required'),
  body('subject').trim().notEmpty().withMessage('Subject required'),
  body('max_players').optional().isInt({ min: 2, max: 8 }),
], async (req, res, next) => {
  try {
    validate(req);
    const { name, subject, max_players = 4 } = req.body;

    // Generate unique code
    let code, attempts = 0;
    do {
      code = generateRoomCode();
      const exists = await db.query('SELECT id FROM battle_rooms WHERE code = $1', [code]);
      if (exists.rowCount === 0) break;
    } while (++attempts < 10);

    const room = await db.query(
      `INSERT INTO battle_rooms (code, name, subject, host_id, max_players)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [code, name, subject, req.user.id, max_players]
    );

    // Auto-join host
    await db.query(
      'INSERT INTO battle_participants (room_id, user_id) VALUES ($1, $2) ON CONFLICT DO NOTHING',
      [room.rows[0].id, req.user.id]
    );

    return res.status(201).json({ success: true, data: { ...room.rows[0], player_count: 1 } });
  } catch (err) { next(err); }
});

// ── POST /api/battle/rooms/:id/join ──────────────────────────────────────────
router.post('/rooms/:id/join', async (req, res, next) => {
  try {
    await db.query(
      'INSERT INTO battle_participants (room_id, user_id) VALUES ($1, $2) ON CONFLICT DO NOTHING',
      [req.params.id, req.user.id]
    );
    const count = await db.query(
      'SELECT COUNT(*)::int AS cnt FROM battle_participants WHERE room_id = $1',
      [req.params.id]
    );
    return res.json({ success: true, player_count: count.rows[0].cnt });
  } catch (err) { next(err); }
});

// ── GET /api/battle/rooms/:id ─────────────────────────────────────────────────
router.get('/rooms/:id', async (req, res, next) => {
  try {
    const room = await db.query('SELECT * FROM battle_rooms WHERE id = $1', [req.params.id]);
    if (room.rowCount === 0) throw new AppError('Room not found', 404);

    const participants = await db.query(
      `SELECT u.id, u.name, u.username, u.avatar_url, bp.score, bp.joined_at
       FROM battle_participants bp
       JOIN users u ON u.id = bp.user_id
       WHERE bp.room_id = $1 ORDER BY bp.score DESC`,
      [req.params.id]
    );

    return res.json({ success: true, data: { ...room.rows[0], participants: participants.rows } });
  } catch (err) { next(err); }
});

// ── POST /api/battle/rooms/:id/submit ────────────────────────────────────────
router.post('/rooms/:id/submit', [
  body('answers').isArray().withMessage('answers must be an array'),
], async (req, res, next) => {
  try {
    validate(req);
    const { answers } = req.body;

    // Score the answers
    const questionIds = answers.map(a => a.question_id);
    const questions = await db.query(
      'SELECT id, correct_index FROM quiz_questions WHERE id = ANY($1)',
      [questionIds]
    );
    const correctMap = {};
    questions.rows.forEach(q => { correctMap[q.id] = q.correct_index; });

    let correct = 0;
    answers.forEach(a => {
      if (correctMap[a.question_id] === a.selected_index) correct++;
    });

    const xpEarned = correct * 10;

    // Update participant score
    await db.query(
      'UPDATE battle_participants SET score = $1 WHERE room_id = $2 AND user_id = $3',
      [xpEarned, req.params.id, req.user.id]
    );

    // Award XP
    await db.query('UPDATE users SET xp = xp + $1 WHERE id = $2', [xpEarned, req.user.id]);

    return res.json({ success: true, data: { score: xpEarned, correct, total: answers.length } });
  } catch (err) { next(err); }
});

// ── POST /api/battle/special-ops/:id/start ────────────────────────────────────
router.post('/special-ops/:id/start', async (req, res, next) => {
  try {
    const op = await db.query('SELECT * FROM special_ops WHERE id = $1', [req.params.id]);
    if (op.rowCount === 0) throw new AppError('Special op not found', 404);

    const attempt = await db.query(
      'INSERT INTO special_op_attempts (op_id, user_id) VALUES ($1, $2) RETURNING id',
      [req.params.id, req.user.id]
    );

    // Fetch quiz questions for this op's subject
    const questions = await db.query(
      `SELECT id, question, options, subject, difficulty
       FROM quiz_questions WHERE subject = $1 ORDER BY RANDOM() LIMIT 10`,
      [op.rows[0].subject]
    );

    return res.json({
      success: true,
      data: { attempt_id: attempt.rows[0].id, questions: questions.rows },
    });
  } catch (err) { next(err); }
});

// ── POST /api/battle/special-ops/:id/complete ─────────────────────────────────
router.post('/special-ops/:id/complete', [
  body('attempt_id').notEmpty(),
  body('answers').isArray(),
], async (req, res, next) => {
  try {
    validate(req);
    const { attempt_id, answers } = req.body;

    // Verify attempt ownership
    const attempt = await db.query(
      'SELECT * FROM special_op_attempts WHERE id = $1 AND user_id = $2',
      [attempt_id, req.user.id]
    );
    if (attempt.rowCount === 0) throw new AppError('Attempt not found', 404);

    const questionIds = answers.map(a => a.question_id);
    const questions = await db.query(
      'SELECT id, correct_index FROM quiz_questions WHERE id = ANY($1)',
      [questionIds]
    );
    const correctMap = {};
    questions.rows.forEach(q => { correctMap[q.id] = q.correct_index; });

    let correct = 0;
    answers.forEach(a => { if (correctMap[a.question_id] === a.selected_index) correct++; });

    const op = await db.query('SELECT xp_reward FROM special_ops WHERE id = $1', [req.params.id]);
    const xpAwarded = Math.round((correct / Math.max(answers.length, 1)) * op.rows[0].xp_reward);

    await Promise.all([
      db.query(
        'UPDATE special_op_attempts SET score = $1, completed = true WHERE id = $2',
        [xpAwarded, attempt_id]
      ),
      db.query('UPDATE users SET xp = xp + $1 WHERE id = $2', [xpAwarded, req.user.id]),
    ]);

    return res.json({ success: true, data: { score: correct, xp_awarded: xpAwarded } });
  } catch (err) { next(err); }
});

module.exports = router;
