-- Shiksha Verse — Neon PostgreSQL Schema
-- Run: psql $DATABASE_URL -f src/db/schema.sql
-- Or paste into the Neon SQL console

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ── Users ────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name            VARCHAR(120)  NOT NULL,
  email           VARCHAR(255)  NOT NULL UNIQUE,
  username        VARCHAR(50)   UNIQUE,
  password_hash   TEXT          NOT NULL,
  grade           VARCHAR(50),
  subjects        TEXT[]        DEFAULT '{}',
  avatar_url      TEXT,
  role            VARCHAR(20)   NOT NULL DEFAULT 'student' CHECK (role IN ('student', 'instructor', 'admin')),
  email_verified  BOOLEAN       NOT NULL DEFAULT false,
  xp              INTEGER       NOT NULL DEFAULT 0,
  streak_days     INTEGER       NOT NULL DEFAULT 0,
  rank            INTEGER       NOT NULL DEFAULT 9999,
  last_active_at  TIMESTAMPTZ,
  created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

-- ── Refresh Tokens ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS refresh_tokens (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token       TEXT NOT NULL UNIQUE,
  expires_at  TIMESTAMPTZ NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user ON refresh_tokens(user_id);

-- ── OTP Codes ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS otp_codes (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email       VARCHAR(255) NOT NULL,
  code_hash   TEXT NOT NULL,
  expires_at  TIMESTAMPTZ NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_otp_email ON otp_codes(email);

-- ── Courses ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS courses (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title            VARCHAR(200) NOT NULL,
  description      TEXT,
  subject          VARCHAR(80)  NOT NULL,
  difficulty       VARCHAR(20)  NOT NULL CHECK (difficulty IN ('Beginner', 'Intermediate', 'Advanced')),
  thumbnail_url    TEXT,
  instructor_name  VARCHAR(120),
  instructor_id    UUID REFERENCES users(id) ON DELETE SET NULL,
  total_lessons    INTEGER      NOT NULL DEFAULT 0,
  duration_minutes INTEGER      NOT NULL DEFAULT 0,
  is_published     BOOLEAN      NOT NULL DEFAULT false,
  created_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_courses_subject ON courses(subject);
CREATE INDEX IF NOT EXISTS idx_courses_published ON courses(is_published);

-- ── Lessons ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS lessons (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id        UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  title            VARCHAR(200) NOT NULL,
  video_url        TEXT,
  thumbnail_url    TEXT,
  duration_seconds INTEGER NOT NULL DEFAULT 0,
  lesson_order     INTEGER NOT NULL DEFAULT 0,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_lessons_course ON lessons(course_id);

-- ── User Progress ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS user_progress (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  course_id        UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  lesson_id        UUID REFERENCES lessons(id) ON DELETE SET NULL,
  progress_pct     NUMERIC(5,2) NOT NULL DEFAULT 0 CHECK (progress_pct BETWEEN 0 AND 100),
  last_watched_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, course_id)
);
CREATE INDEX IF NOT EXISTS idx_progress_user ON user_progress(user_id);

-- ── Shorts ────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS shorts (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title            VARCHAR(200) NOT NULL,
  subject          VARCHAR(80)  NOT NULL,
  video_url        TEXT,
  thumbnail_url    TEXT,
  instructor_name  VARCHAR(120),
  instructor_id    UUID REFERENCES users(id) ON DELETE SET NULL,
  duration_seconds INTEGER      NOT NULL DEFAULT 60,
  views            INTEGER      NOT NULL DEFAULT 0,
  is_published     BOOLEAN      NOT NULL DEFAULT false,
  created_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_shorts_subject ON shorts(subject);
CREATE INDEX IF NOT EXISTS idx_shorts_published ON shorts(is_published);

-- ── Short Likes ───────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS short_likes (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  short_id   UUID NOT NULL REFERENCES shorts(id) ON DELETE CASCADE,
  user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (short_id, user_id)
);

-- ── Quiz Questions ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS quiz_questions (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question      TEXT NOT NULL,
  options       TEXT[] NOT NULL,
  correct_index INTEGER NOT NULL,
  explanation   TEXT,
  subject       VARCHAR(80)  NOT NULL,
  difficulty    VARCHAR(20)  NOT NULL DEFAULT 'Intermediate',
  created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_quiz_subject ON quiz_questions(subject);

-- ── Quiz Attempts ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS quiz_attempts (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  subject          VARCHAR(80),
  score            INTEGER NOT NULL DEFAULT 0,
  total_questions  INTEGER NOT NULL,
  answered_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_attempts_user ON quiz_attempts(user_id);
CREATE INDEX IF NOT EXISTS idx_attempts_date ON quiz_attempts(answered_at);

-- ── Trigger: auto-update updated_at ──────────────────────────────────────────
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY['users', 'courses'] LOOP
    EXECUTE format(
      'DROP TRIGGER IF EXISTS trg_%I_updated_at ON %I;
       CREATE TRIGGER trg_%I_updated_at
       BEFORE UPDATE ON %I
       FOR EACH ROW EXECUTE FUNCTION update_updated_at();', t, t, t, t
    );
  END LOOP;
END;
$$;
