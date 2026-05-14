'use strict';

/**
 * DB seed — initial data for battle features.
 * Run once: node src/db/seed.js
 */

const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../../../.env') });
const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

async function seed() {
  const client = await pool.connect();
  try {
    console.log('▶ Seeding database...');

    // ── Special Ops ─────────────────────────────────────────────────────────
    await client.query(`
      INSERT INTO special_ops (title, description, subject, difficulty, xp_reward, cta_label, cta_color, is_active)
      VALUES
        ('Physics Blitz', '10 rapid-fire questions on Mechanics, Thermodynamics, and Waves', 'Physics', 'Hard', 500, 'Attack!', 'primary', true),
        ('Math Flashpoint', 'Solve 10 calculus and algebra questions under 20 seconds each', 'Mathematics', 'Medium', 350, 'Engage!', 'amber', true),
        ('Chemistry Raid', 'NCERT-level organic & inorganic questions — beat the clock', 'Chemistry', 'Easy', 200, 'Raid!', 'primary', true)
      ON CONFLICT DO NOTHING
    `);
    console.log('✅ Special Ops seeded');

    // ── Sample Battle Rooms ──────────────────────────────────────────────────
    await client.query(`
      INSERT INTO battle_rooms (code, name, subject, max_players, xp_reward, status)
      VALUES
        ('#001', 'Physics Warriors', 'Physics', 4, 500, 'waiting'),
        ('#002', 'Math Maniacs', 'Mathematics', 2, 300, 'waiting')
      ON CONFLICT DO NOTHING
    `);
    console.log('✅ Battle rooms seeded');

    console.log('🎉 Seeding complete');
  } catch (err) {
    console.error('❌ Seed failed:', err.message);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

seed();
