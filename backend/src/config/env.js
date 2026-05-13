'use strict';

const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../../.env') });

/**
 * Validates and exports all environment variables.
 * Throws at startup if any required var is missing — fail fast.
 */

function required(name) {
  const val = process.env[name];
  if (!val) throw new Error(`Missing required env var: ${name}`);
  return val;
}

function optional(name, defaultVal = '') {
  return process.env[name] || defaultVal;
}

module.exports = {
  // Server
  PORT: parseInt(optional('PORT', '3000'), 10),
  NODE_ENV: optional('NODE_ENV', 'development'),
  IS_PROD: optional('NODE_ENV', 'development') === 'production',

  // Database
  DATABASE_URL: required('DATABASE_URL'),

  // JWT
  JWT_SECRET: required('JWT_SECRET'),
  JWT_REFRESH_SECRET: required('JWT_REFRESH_SECRET'),
  JWT_EXPIRES_IN: optional('JWT_EXPIRES_IN', '15m'),
  JWT_REFRESH_EXPIRES_IN: optional('JWT_REFRESH_EXPIRES_IN', '7d'),

  // AWS S3
  AWS_REGION: required('AWS_REGION'),
  AWS_ACCESS_KEY_ID: required('AWS_ACCESS_KEY_ID'),
  AWS_SECRET_ACCESS_KEY: required('AWS_SECRET_ACCESS_KEY'),
  S3_BUCKET_NAME: required('S3_BUCKET_NAME'),
  S3_PRESIGNED_URL_EXPIRES: parseInt(optional('S3_PRESIGNED_URL_EXPIRES', '3600'), 10),
  CLOUDFRONT_DOMAIN: optional('CLOUDFRONT_DOMAIN'),

  // Email
  SMTP_HOST: optional('SMTP_HOST', 'smtp.gmail.com'),
  SMTP_PORT: parseInt(optional('SMTP_PORT', '587'), 10),
  SMTP_USER: optional('SMTP_USER'),
  SMTP_PASS: optional('SMTP_PASS'),
  EMAIL_FROM: optional('EMAIL_FROM', 'noreply@shikshaverse.com'),

  // OTP
  OTP_EXPIRES_MINUTES: parseInt(optional('OTP_EXPIRES_MINUTES', '10'), 10),

  // CORS
  ALLOWED_ORIGINS: optional('ALLOWED_ORIGINS', 'http://localhost:3000').split(','),

  // Rate Limit
  RATE_LIMIT_WINDOW_MS: parseInt(optional('RATE_LIMIT_WINDOW_MS', '900000'), 10),
  RATE_LIMIT_MAX: parseInt(optional('RATE_LIMIT_MAX', '100'), 10),
};
