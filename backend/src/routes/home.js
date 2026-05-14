'use strict';

const express = require('express');
const router = express.Router();
const db = require('../config/db');

// ── GET /api/home ─────────────────────────────────────────────────────────────
// ?subject=All|Maths|Science|History|...
router.get('/', async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { subject } = req.query;

    // 1. Update last_active_at and recalculate streak
    const userRow = await db.query(
      `SELECT last_active_at, streak_days, name, avatar_url, xp
       FROM users WHERE id = $1`,
      [userId]
    );
    const u = userRow.rows[0];
    let streakDays = u.streak_days;

    if (u.last_active_at) {
      const lastDate = new Date(u.last_active_at);
      const today    = new Date();
      lastDate.setHours(0, 0, 0, 0);
      today.setHours(0, 0, 0, 0);
      const diffDays = Math.round((today - lastDate) / 86400000);
      if (diffDays === 1)      streakDays += 1; // consecutive day
      else if (diffDays > 1)  streakDays = 1;  // streak broken
      // diffDays === 0 → already counted today, no change
    } else {
      streakDays = 1; // first activity
    }

    await db.query(
      'UPDATE users SET last_active_at = NOW(), streak_days = $1 WHERE id = $2',
      [streakDays, userId]
    );

    // 2. Resume course (most recent watched)
    const resumeResult = await db.query(
      `SELECT c.id AS course_id, c.title, c.thumbnail_url, c.subject,
              up.progress_pct,
              l.title AS last_lesson_title
       FROM user_progress up
       JOIN courses c ON c.id = up.course_id
       LEFT JOIN lessons l ON l.id = up.lesson_id
       WHERE up.user_id = $1 AND up.progress_pct < 100
       ORDER BY up.last_watched_at DESC
       LIMIT 1`,
      [userId]
    );
    const resumeCourse = resumeResult.rows[0] || null;

    // 3. Trending courses with subject filter
    let sql = `
      SELECT c.id, c.title, c.subject, c.thumbnail_url, c.difficulty,
             c.total_lessons, c.duration_minutes,
             COALESCE(up.progress_pct, 0) AS progress_pct,
             (c.total_lessons > 0)        AS has_video,
             true                         AS has_quiz,
             false                        AS has_game
      FROM courses c
      LEFT JOIN user_progress up ON up.course_id = c.id AND up.user_id = $1
      WHERE c.is_published = true
    `;
    const params = [userId];
    if (subject && subject !== 'All') {
      sql += ` AND c.subject = $2`;
      params.push(subject);
    }
    sql += ` ORDER BY c.created_at DESC LIMIT 20`;

    const coursesResult = await db.query(sql, params);

    // Add grade field (derived from difficulty for now; extend when courses table has grade)
    const trendingCourses = coursesResult.rows.map(r => ({
      ...r,
      grade: null, // populated when course grade column is added
    }));

    return res.json({
      success: true,
      data: {
        streak_days: streakDays,
        xp: parseInt(u.xp),
        user: { name: u.name, avatar_url: u.avatar_url },
        resume_course: resumeCourse,
        trending_courses: trendingCourses,
      },
    });
  } catch (err) { next(err); }
});

module.exports = router;
