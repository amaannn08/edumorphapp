'use strict';

const express = require('express');
const { body, validationResult } = require('express-validator');
const { v4: uuidv4 } = require('uuid');
const https = require('https');
const router = express.Router();

const db = require('../config/db');
const { hashPassword, comparePassword, signAccessToken, signRefreshToken, verifyRefreshToken } = require('../services/authService');
const { sendOtp, verifyOtp, sendPhoneOtp, verifyPhoneOtp } = require('../services/otpService');
const { authenticate } = require('../middleware/auth');
const { AppError } = require('../middleware/errorHandler');
const { phoneOtpLimiter } = require('../middleware/rateLimiter');
const { GOOGLE_CLIENT_ID } = require('../config/env');

function validate(req) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) throw new AppError(errors.array()[0].msg, 422);
}

async function issueTokens(userId, email, role) {
  const accessToken  = signAccessToken({ sub: userId, email, role });
  const refreshToken = signRefreshToken({ sub: userId });
  await db.query(
    "INSERT INTO refresh_tokens (user_id, token, expires_at) VALUES ($1, $2, NOW() + INTERVAL '7 days')",
    [userId, refreshToken]
  );
  return { accessToken, refreshToken };
}

// ── POST /api/auth/signup ────────────────────────────────────────────────────
// Now returns { user } only — tokens issued after phone OTP verify
router.post('/signup', [
  body('name').trim().notEmpty().withMessage('Name is required'),
  body('email').isEmail().normalizeEmail().withMessage('Valid email required'),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 chars'),
  body('phone_number').notEmpty().withMessage('Phone number is required'),
], async (req, res, next) => {
  try {
    validate(req);
    const { name, email, password, phone_number } = req.body;

    const existing = await db.query(
      'SELECT id FROM users WHERE email = $1 OR phone_number = $2',
      [email, phone_number]
    );
    if (existing.rowCount > 0) throw new AppError('Email or phone already registered', 409);

    const passwordHash = await hashPassword(password);
    const userId = uuidv4();

    const result = await db.query(
      `INSERT INTO users (id, name, email, password_hash, phone_number, role)
       VALUES ($1, $2, $3, $4, $5, 'student')
       RETURNING id, name, email, phone_number, grade, role, xp, streak_days`,
      [userId, name, email, passwordHash, phone_number]
    );

    const user = result.rows[0];

    // Trigger phone OTP (non-blocking — don't fail signup if SMS errors)
    try { await sendPhoneOtp(phone_number); } catch (e) { /* logged inside */ }

    return res.status(201).json({ success: true, data: { user } });
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

    const { accessToken, refreshToken } = await issueTokens(user.id, user.email, user.role);
    const { password_hash, ...safeUser } = user;
    return res.json({ success: true, data: { user: safeUser, accessToken, refreshToken } });
  } catch (err) { next(err); }
});

// ── POST /api/auth/otp/send (email) ─────────────────────────────────────────
router.post('/otp/send', [
  body('email').isEmail().normalizeEmail(),
], async (req, res, next) => {
  try {
    validate(req);
    await sendOtp(req.body.email);
    return res.json({ success: true, message: 'OTP sent' });
  } catch (err) { next(err); }
});

// ── POST /api/auth/otp/verify (email) ────────────────────────────────────────
router.post('/otp/verify', [
  body('email').isEmail().normalizeEmail(),
  body('otp').isLength({ min: 6, max: 6 }).withMessage('OTP must be 6 digits'),
], async (req, res, next) => {
  try {
    validate(req);
    const { email, otp } = req.body;
    const valid = await verifyOtp(email, otp);
    if (!valid) throw new AppError('Invalid or expired OTP', 400);

    await db.query('UPDATE users SET email_verified = true WHERE email = $1', [email]);
    return res.json({ success: true, message: 'Email verified' });
  } catch (err) { next(err); }
});

// ── POST /api/auth/otp/send-phone ─────────────────────────────────────────────
router.post('/otp/send-phone', phoneOtpLimiter, [
  body('phone_number').notEmpty().withMessage('Phone number is required'),
], async (req, res, next) => {
  try {
    validate(req);
    await sendPhoneOtp(req.body.phone_number);
    return res.json({ success: true, message: 'OTP sent' });
  } catch (err) { next(err); }
});

// ── POST /api/auth/otp/verify-phone ──────────────────────────────────────────
router.post('/otp/verify-phone', [
  body('phone_number').notEmpty().withMessage('Phone number is required'),
  body('otp').isLength({ min: 4, max: 4 }).withMessage('OTP must be 4 digits'),
], async (req, res, next) => {
  try {
    validate(req);
    const { phone_number, otp } = req.body;
    const valid = await verifyPhoneOtp(phone_number, otp);
    if (!valid) throw new AppError('Invalid or expired OTP', 400);

    // Mark phone as verified and get user
    const result = await db.query(
      `UPDATE users SET phone_verified = true
       WHERE phone_number = $1
       RETURNING id, name, email, phone_number, grade, role, xp, streak_days, avatar_url`,
      [phone_number]
    );
    if (result.rowCount === 0) throw new AppError('Phone number not found', 404);

    const user = result.rows[0];
    const { accessToken, refreshToken } = await issueTokens(user.id, user.email, user.role);
    return res.json({ success: true, data: { user, accessToken, refreshToken } });
  } catch (err) { next(err); }
});

// ── POST /api/auth/google ─────────────────────────────────────────────────────
router.post('/google', [
  body('id_token').notEmpty().withMessage('Google id_token required'),
], async (req, res, next) => {
  try {
    validate(req);
    if (!GOOGLE_CLIENT_ID) throw new AppError('Google SSO not configured', 503);

    const { id_token } = req.body;

    // Verify token with Google
    const googleData = await new Promise((resolve, reject) => {
      https.get(
        `https://oauth2.googleapis.com/tokeninfo?id_token=${id_token}`,
        (resp) => {
          let data = '';
          resp.on('data', (chunk) => { data += chunk; });
          resp.on('end', () => {
            try { resolve(JSON.parse(data)); } catch { reject(new Error('Invalid Google response')); }
          });
        }
      ).on('error', reject);
    });

    if (googleData.aud !== GOOGLE_CLIENT_ID) throw new AppError('Invalid Google token audience', 401);
    if (googleData.error) throw new AppError('Invalid Google token', 401);

    const { email, name, sub: google_id, picture } = googleData;

    // Upsert user
    const result = await db.query(
      `INSERT INTO users (id, name, email, google_id, email_verified, avatar_url, password_hash, role)
       VALUES ($1, $2, $3, $4, true, $5, 'google_sso', 'student')
       ON CONFLICT (google_id) DO UPDATE SET
         last_active_at = NOW(),
         email_verified = true
       RETURNING id, name, email, grade, role, xp, streak_days, avatar_url`,
      [uuidv4(), name, email, google_id, picture]
    );

    const user = result.rows[0];
    const { accessToken, refreshToken } = await issueTokens(user.id, user.email, user.role);
    return res.json({ success: true, data: { user, accessToken, refreshToken } });
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

    const userResult = await db.query('SELECT id, email, role FROM users WHERE id = $1', [payload.sub]);
    const user = userResult.rows[0];
    const newAccessToken = signAccessToken({ sub: user.id, email: user.email, role: user.role });

    return res.json({ success: true, data: { accessToken: newAccessToken } });
  } catch (err) { next(err); }
});

// ── POST /api/auth/logout ────────────────────────────────────────────────────
router.post('/logout', authenticate, async (req, res, next) => {
  try {
    const { refreshToken } = req.body;
    if (refreshToken) await db.query('DELETE FROM refresh_tokens WHERE token = $1', [refreshToken]);
    return res.json({ success: true, message: 'Logged out' });
  } catch (err) { next(err); }
});

module.exports = router;
