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

-- ═══════════════════════════════════════════════════════════════════════════
-- Phase 0 Migrations — added by build plan (all idempotent)
-- ═══════════════════════════════════════════════════════════════════════════

-- ── 0-A: Extend users ────────────────────────────────────────────────────────
ALTER TABLE users ADD COLUMN IF NOT EXISTS phone_number     VARCHAR(20)  UNIQUE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS phone_verified   BOOLEAN      NOT NULL DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS google_id        VARCHAR(100) UNIQUE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS language         VARCHAR(20);
ALTER TABLE users ADD COLUMN IF NOT EXISTS career_interests TEXT[]       DEFAULT '{}';

-- ── 0-B: Extend otp_codes (make email nullable, add phone) ───────────────────
-- Safe to run multiple times: IF NOT EXISTS / DROP NOT NULL is idempotent on pg
ALTER TABLE otp_codes ALTER COLUMN email DROP NOT NULL;
ALTER TABLE otp_codes ADD COLUMN IF NOT EXISTS phone VARCHAR(20);
CREATE INDEX IF NOT EXISTS idx_otp_phone ON otp_codes(phone);

-- ── 0-C: Extend lessons ──────────────────────────────────────────────────────
-- title already exists — only add new columns
ALTER TABLE lessons ADD COLUMN IF NOT EXISTS duration_minutes INTEGER;
ALTER TABLE lessons ADD COLUMN IF NOT EXISTS language_code    VARCHAR(5) DEFAULT 'en';
ALTER TABLE lessons ADD COLUMN IF NOT EXISTS description      TEXT;

-- ── 0-D: doubts ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS doubts (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES users(id)    ON DELETE CASCADE,
  course_id  UUID REFERENCES courses(id)           ON DELETE SET NULL,
  lesson_id  UUID REFERENCES lessons(id)           ON DELETE SET NULL,
  question   TEXT NOT NULL,
  status     VARCHAR(20) NOT NULL DEFAULT 'pending'
             CHECK (status IN ('pending', 'resolved')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_doubts_user ON doubts(user_id);

-- ── 0-E: bookmarks ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS bookmarks (
  user_id    UUID NOT NULL REFERENCES users(id)   ON DELETE CASCADE,
  lesson_id  UUID NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, lesson_id)
);

-- ── 0-F: notes ───────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS notes (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title      VARCHAR(200) NOT NULL,
  body       TEXT,
  subject    VARCHAR(80),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_notes_user_subject ON notes(user_id, subject);

-- ── 0-G: mind_maps ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS mind_maps (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title      VARCHAR(200) NOT NULL,
  subject    VARCHAR(80),
  svg_data   TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── 0-H: Battle tables ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS battle_rooms (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code        VARCHAR(10) UNIQUE NOT NULL,
  name        VARCHAR(200),
  subject     VARCHAR(80),
  host_id     UUID REFERENCES users(id) ON DELETE SET NULL,
  status      VARCHAR(20) NOT NULL DEFAULT 'waiting'
              CHECK (status IN ('waiting', 'active', 'finished')),
  max_players INTEGER NOT NULL DEFAULT 4,
  xp_reward   INTEGER NOT NULL DEFAULT 500,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS battle_participants (
  room_id   UUID NOT NULL REFERENCES battle_rooms(id) ON DELETE CASCADE,
  user_id   UUID NOT NULL REFERENCES users(id)        ON DELETE CASCADE,
  score     INTEGER NOT NULL DEFAULT 0,
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (room_id, user_id)
);

CREATE TABLE IF NOT EXISTS special_ops (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title       VARCHAR(200) NOT NULL,
  description TEXT,
  subject     VARCHAR(80),
  difficulty  VARCHAR(20)  CHECK (difficulty IN ('Easy', 'Medium', 'Hard')),
  xp_reward   INTEGER NOT NULL DEFAULT 200,
  cta_label   VARCHAR(50),
  cta_color   VARCHAR(20) NOT NULL DEFAULT 'primary',
  is_active   BOOLEAN NOT NULL DEFAULT true,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS special_op_attempts (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  op_id      UUID REFERENCES special_ops(id) ON DELETE CASCADE,
  user_id    UUID REFERENCES users(id)       ON DELETE CASCADE,
  score      INTEGER,
  completed  BOOLEAN NOT NULL DEFAULT false,
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- auto-update updated_at for notes
DO $$
BEGIN
  EXECUTE
    'DROP TRIGGER IF EXISTS trg_notes_updated_at ON notes;
     CREATE TRIGGER trg_notes_updated_at
     BEFORE UPDATE ON notes
     FOR EACH ROW EXECUTE FUNCTION update_updated_at();';
END;
$$;
