'use strict';

const express = require('express');
const router = express.Router();
const db = require('../config/db');
const { authenticate } = require('../middleware/auth');
const { AppError } = require('../middleware/errorHandler');

// ── GET /api/quiz ─────────────────────────────────────────────────────────────
// Query params: subject, limit (default 10)
router.get('/', authenticate, async (req, res, next) => {
  try {
    const { subject, limit = 10 } = req.query;
    const params = [];
    let subjectClause = '';
    if (subject) {
      subjectClause = 'WHERE subject = $1';
      params.push(subject);
    }
    params.push(parseInt(limit));

    const result = await db.query(
      `SELECT id, question, options, correct_index, explanation, subject, difficulty
       FROM quiz_questions ${subjectClause}
       ORDER BY RANDOM()
       LIMIT $${params.length}`,
      params
    );

    return res.json({ success: true, data: result.rows });
  } catch (err) { next(err); }
});

// ── POST /api/quiz/attempt ────────────────────────────────────────────────────
// Body: { answers: [{ question_id, selected_index }], subject }
router.post('/attempt', authenticate, async (req, res, next) => {
  try {
    const { answers, subject } = req.body;
    if (!answers || !Array.isArray(answers)) throw new AppError('answers array required', 400);

    // Fetch correct answers for submitted question IDs
    const ids = answers.map((a) => a.question_id);
    const qResult = await db.query(
      'SELECT id, correct_index FROM quiz_questions WHERE id = ANY($1)',
      [ids]
    );
    const correctMap = Object.fromEntries(qResult.rows.map((r) => [r.id, r.correct_index]));

    let score = 0;
    const results = answers.map((a) => {
      const isCorrect = correctMap[a.question_id] === a.selected_index;
      if (isCorrect) score += 10;
      return { question_id: a.question_id, is_correct: isCorrect };
    });

    // Save attempt
    await db.query(
      `INSERT INTO quiz_attempts (user_id, subject, score, total_questions, answered_at)
       VALUES ($1, $2, $3, $4, NOW())`,
      [req.user.id, subject || 'General', score, answers.length]
    );

    // Update XP
    await db.query(
      'UPDATE users SET xp = xp + $1 WHERE id = $2',
      [score, req.user.id]
    );

    return res.json({ success: true, data: { score, total: answers.length * 10, results } });
  } catch (err) { next(err); }
});

module.exports = router;
