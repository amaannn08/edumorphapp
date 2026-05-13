'use strict';

const crypto = require('crypto');
const nodemailer = require('nodemailer');
const { query } = require('../config/db');
const { SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, EMAIL_FROM, OTP_EXPIRES_MINUTES } = require('../config/env');
const logger = require('./logger');

const transporter = nodemailer.createTransport({
  host: SMTP_HOST,
  port: SMTP_PORT,
  secure: false,
  auth: { user: SMTP_USER, pass: SMTP_PASS },
});

function generateOtp() {
  return crypto.randomInt(100000, 999999).toString();
}

async function sendOtp(email) {
  const otp = generateOtp();
  const expiresAt = new Date(Date.now() + OTP_EXPIRES_MINUTES * 60 * 1000);

  // Invalidate any existing OTP for this email
  await query('DELETE FROM otp_codes WHERE email = $1', [email]);

  // Store new OTP (hashed)
  const bcrypt = require('bcryptjs');
  const hashedOtp = await bcrypt.hash(otp, 6);
  await query(
    'INSERT INTO otp_codes (email, code_hash, expires_at) VALUES ($1, $2, $3)',
    [email, hashedOtp, expiresAt]
  );

  // Send email
  await transporter.sendMail({
    from: `"Shiksha Verse" <${EMAIL_FROM}>`,
    to: email,
    subject: 'Your Shiksha Verse verification code',
    html: `
      <div style="font-family:Inter,sans-serif;max-width:480px;margin:auto;padding:32px;background:#f8f9ff;border-radius:12px;">
        <div style="text-align:center;margin-bottom:24px;">
          <div style="background:#4F46E5;color:#fff;font-size:28px;font-weight:800;width:60px;height:60px;border-radius:14px;display:inline-flex;align-items:center;justify-content:center;">SV</div>
        </div>
        <h2 style="color:#0b1c30;margin:0 0 8px;">Your verification code</h2>
        <p style="color:#464555;margin:0 0 24px;">Use this code to verify your Shiksha Verse account. It expires in ${OTP_EXPIRES_MINUTES} minutes.</p>
        <div style="background:#fff;border:2px solid #4F46E5;border-radius:12px;text-align:center;padding:24px;">
          <span style="font-size:42px;font-weight:800;color:#4F46E5;letter-spacing:8px;">${otp}</span>
        </div>
        <p style="color:#777587;font-size:12px;margin-top:24px;text-align:center;">If you didn't request this, you can safely ignore this email.</p>
      </div>
    `,
  });

  logger.info('OTP sent', { email: email.replace(/(.{2}).*@/, '$1***@') });
  return true;
}

async function verifyOtp(email, inputOtp) {
  const result = await query(
    'SELECT code_hash, expires_at FROM otp_codes WHERE email = $1 ORDER BY created_at DESC LIMIT 1',
    [email]
  );

  if (result.rowCount === 0) return false;
  const { code_hash, expires_at } = result.rows[0];

  if (new Date() > new Date(expires_at)) {
    await query('DELETE FROM otp_codes WHERE email = $1', [email]);
    return false;
  }

  const bcrypt = require('bcryptjs');
  const valid = await bcrypt.compare(inputOtp, code_hash);
  if (valid) {
    await query('DELETE FROM otp_codes WHERE email = $1', [email]);
  }
  return valid;
}

module.exports = { sendOtp, verifyOtp };
