'use strict';

const express = require('express');
const { body, validationResult } = require('express-validator');
const { v4: uuidv4 } = require('uuid');
const router = express.Router();

const db = require('../config/db');
const { hashPassword, comparePassword, signAccessToken, signRefreshToken, verifyRefreshToken } = require('../services/authService');
const { sendOtp, verifyOtp } = require('../services/otpService');
const { authenticate } = require('../middleware/auth');
const { AppError } = require('../middleware/errorHandler');

function validate(req) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    const err = new AppError(errors.array()[0].msg, 422);
    throw err;
  }
}

// ── POST /api/auth/signup ────────────────────────────────────────────────────
router.post('/signup', [
  body('name').trim().notEmpty().withMessage('Name is required'),
  body('email').isEmail().normalizeEmail().withMessage('Valid email required'),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 chars'),
  body('grade').optional().trim(),
], async (req, res, next) => {
  try {
    validate(req);
    const { name, email, password, grade } = req.body;

    const existing = await db.query('SELECT id FROM users WHERE email = $1', [email]);
    if (existing.rowCount > 0) throw new AppError('Email already registered', 409);

    const passwordHash = await hashPassword(password);
    const userId = uuidv4();

    const result = await db.query(
      `INSERT INTO users (id, name, email, password_hash, grade, role)
       VALUES ($1, $2, $3, $4, $5, 'student')
       RETURNING id, name, email, grade, role, xp, streak_days, created_at`,
      [userId, name, email, passwordHash, grade || null]
    );

    const user = result.rows[0];
    const accessToken = signAccessToken({ sub: user.id, email: user.email, role: user.role });
    const refreshToken = signRefreshToken({ sub: user.id });

    // Persist refresh token
    await db.query(
      'INSERT INTO refresh_tokens (user_id, token, expires_at) VALUES ($1, $2, NOW() + INTERVAL \'7 days\')',
      [user.id, refreshToken]
    );

    return res.status(201).json({ success: true, data: { user, accessToken, refreshToken } });
  } catch (err) { next(err); }
});

// ── POST /api/auth/login ─────────────────────────────────────────────────────
router.post('/login', [
  body('email').isEmail().normalizeEmail(),
  body('password').notEmpty(),
], async (req, res, next) => {
  try {
    validate(req);
    const { email, password } = req.body;

    const result = await db.query(
      'SELECT id, name, email, password_hash, grade, role, xp, streak_days FROM users WHERE email = $1',
      [email]
    );
    if (result.rowCount === 0) throw new AppError('Invalid credentials', 401);

    const user = result.rows[0];
    const valid = await comparePassword(password, user.password_hash);
    if (!valid) throw new AppError('Invalid credentials', 401);

    const accessToken = signAccessToken({ sub: user.id, email: user.email, role: user.role });
    const refreshToken = signRefreshToken({ sub: user.id });

    await db.query(
      'INSERT INTO refresh_tokens (user_id, token, expires_at) VALUES ($1, $2, NOW() + INTERVAL \'7 days\')',
      [user.id, refreshToken]
    );

    const { password_hash, ...safeUser } = user;
    return res.json({ success: true, data: { user: safeUser, accessToken, refreshToken } });
  } catch (err) { next(err); }
});

// ── POST /api/auth/otp/send ──────────────────────────────────────────────────
router.post('/otp/send', [
  body('email').isEmail().normalizeEmail(),
], async (req, res, next) => {
  try {
    validate(req);
    await sendOtp(req.body.email);
    return res.json({ success: true, message: 'OTP sent' });
  } catch (err) { next(err); }
});

// ── POST /api/auth/otp/verify ────────────────────────────────────────────────
router.post('/otp/verify', [
  body('email').isEmail().normalizeEmail(),
  body('otp').isLength({ min: 6, max: 6 }).withMessage('OTP must be 6 digits'),
], async (req, res, next) => {
  try {
    validate(req);
    const { email, otp } = req.body;
    const valid = await verifyOtp(email, otp);
    if (!valid) throw new AppError('Invalid or expired OTP', 400);

    // Mark email as verified
    await db.query('UPDATE users SET email_verified = true WHERE email = $1', [email]);

    return res.json({ success: true, message: 'Email verified' });
  } catch (err) { next(err); }
});

// ── POST /api/auth/refresh ───────────────────────────────────────────────────
router.post('/refresh', async (req, res, next) => {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) throw new AppError('Refresh token required', 400);

    const payload = verifyRefreshToken(refreshToken);

    const stored = await db.query(
      'SELECT user_id FROM refresh_tokens WHERE token = $1 AND expires_at > NOW()',
      [refreshToken]
    );
    if (stored.rowCount === 0) throw new AppError('Invalid refresh token', 401);

    const userResult = await db.query(
      'SELECT id, email, role FROM users WHERE id = $1',
      [payload.sub]
    );
    const user = userResult.rows[0];
    const newAccessToken = signAccessToken({ sub: user.id, email: user.email, role: user.role });

    return res.json({ success: true, data: { accessToken: newAccessToken } });
  } catch (err) { next(err); }
});

// ── POST /api/auth/logout ────────────────────────────────────────────────────
router.post('/logout', authenticate, async (req, res, next) => {
  try {
    const { refreshToken } = req.body;
    if (refreshToken) {
      await db.query('DELETE FROM refresh_tokens WHERE token = $1', [refreshToken]);
    }
    return res.json({ success: true, message: 'Logged out' });
  } catch (err) { next(err); }
});

module.exports = router;
