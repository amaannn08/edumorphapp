'use strict';

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const compression = require('compression');

const { ALLOWED_ORIGINS, NODE_ENV } = require('./config/env');
const { apiLimiter, authLimiter } = require('./middleware/rateLimiter');
const { authenticate } = require('./middleware/auth');
const { errorHandler } = require('./middleware/errorHandler');
const logger = require('./services/logger');

// Routes
const authRoutes    = require('./routes/auth');
const courseRoutes  = require('./routes/courses');
const shortsRoutes  = require('./routes/shorts');
const quizRoutes    = require('./routes/quiz');
const profileRoutes = require('./routes/profile');
const uploadRoutes  = require('./routes/upload');
const homeRoutes    = require('./routes/home');
const vaultRoutes    = require('./routes/vault');
const battleRoutes   = require('./routes/battle');
const subjectRoutes  = require('./routes/subjects');
const chapterRoutes  = require('./routes/chapters');
const searchRoutes   = require('./routes/search');
const notifRoutes    = require('./routes/notifications');
const settingsRoutes = require('./routes/settings');

const app = express();

// ── Security & Parsing ────────────────────────────────────────────────────────
app.use(helmet());
app.use(cors({
  origin: (origin, callback) => {
    // Allow requests with no origin (mobile apps, Postman)
    if (!origin || ALLOWED_ORIGINS.includes(origin)) return callback(null, true);
    callback(new Error(`CORS: origin ${origin} not allowed`));
  },
  credentials: true,
}));
app.use(compression());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// ── Logging ───────────────────────────────────────────────────────────────────
app.use(morgan(NODE_ENV === 'production' ? 'combined' : 'dev', {
  stream: { write: (msg) => logger.http(msg.trim()) },
}));

// ── Health Check ──────────────────────────────────────────────────────────────
app.get('/health', (req, res) => {
  res.json({ success: true, status: 'ok', timestamp: new Date().toISOString() });
});

// ── API Routes ────────────────────────────────────────────────────────────────
app.use('/api/auth',    authLimiter, authRoutes);
app.use('/api/courses', apiLimiter,  courseRoutes);
app.use('/api/shorts',  apiLimiter,  shortsRoutes);
app.use('/api/quiz',    apiLimiter,  quizRoutes);
app.use('/api/profile', apiLimiter,  profileRoutes);
app.use('/api/upload',  apiLimiter,  uploadRoutes);
app.use('/api/home',    apiLimiter,  authenticate, homeRoutes);
app.use('/api/vault',    apiLimiter,  authenticate, vaultRoutes);
app.use('/api/battle',   apiLimiter,  authenticate, battleRoutes);
app.use('/api/subjects',       apiLimiter, authenticate, subjectRoutes);
app.use('/api/chapters',       apiLimiter, authenticate, chapterRoutes);
app.use('/api/search',         apiLimiter, authenticate, searchRoutes);
app.use('/api/notifications',  apiLimiter, authenticate, notifRoutes);
app.use('/api/settings',       apiLimiter, authenticate, settingsRoutes);

// ── 404 Handler ───────────────────────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ success: false, message: `Route ${req.method} ${req.path} not found` });
});

// ── Global Error Handler ──────────────────────────────────────────────────────
app.use(errorHandler);

module.exports = app;
