'use strict';

/**
 * DB seed — initial data for battle features and subject content library.
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

    // ── Subjects ─────────────────────────────────────────────────────────────
    const subjectRows = await client.query(`
      INSERT INTO subjects (name, icon, color_hex, display_order, is_active)
      VALUES
        ('Physics',      '⚛️',  '#4F46E5', 0, true),
        ('Mathematics',  '📐',  '#7C3AED', 1, true),
        ('Chemistry',    '🧪',  '#059669', 2, true),
        ('Biology',      '🌱',  '#D97706', 3, true)
      ON CONFLICT (name) DO UPDATE
        SET icon = EXCLUDED.icon, color_hex = EXCLUDED.color_hex
      RETURNING id, name
    `);
    console.log('✅ Subjects seeded');

    const subjectMap = {};
    for (const row of subjectRows.rows) subjectMap[row.name] = row.id;

    // ── Chapters ─────────────────────────────────────────────────────────────
    const chapters = [
      // Physics
      { subject: 'Physics',     title: 'Laws of Motion',             order: 0 },
      { subject: 'Physics',     title: 'Work, Energy & Power',       order: 1 },
      { subject: 'Physics',     title: 'Waves & Oscillations',       order: 2 },
      { subject: 'Physics',     title: 'Electrostatics',             order: 3 },
      // Mathematics
      { subject: 'Mathematics', title: 'Limits & Continuity',        order: 0 },
      { subject: 'Mathematics', title: 'Differentiation',            order: 1 },
      { subject: 'Mathematics', title: 'Integration',                order: 2 },
      { subject: 'Mathematics', title: 'Matrices & Determinants',    order: 3 },
      // Chemistry
      { subject: 'Chemistry',   title: 'Atomic Structure',           order: 0 },
      { subject: 'Chemistry',   title: 'Chemical Bonding',           order: 1 },
      { subject: 'Chemistry',   title: 'Organic Chemistry Basics',   order: 2 },
      // Biology
      { subject: 'Biology',     title: 'Cell: Structure & Function', order: 0 },
      { subject: 'Biology',     title: 'Genetics & Heredity',        order: 1 },
      { subject: 'Biology',     title: 'Human Physiology',           order: 2 },
    ];

    const chapterMap = {};
    for (const ch of chapters) {
      const res = await client.query(`
        INSERT INTO chapters (subject_id, title, chapter_order, is_published)
        VALUES ($1, $2, $3, true)
        ON CONFLICT DO NOTHING
        RETURNING id, title
      `, [subjectMap[ch.subject], ch.title, ch.order]);
      if (res.rowCount > 0) chapterMap[ch.title] = res.rows[0].id;
    }
    // Re-fetch all chapter IDs to handle conflicts gracefully
    const allChapters = await client.query(
      'SELECT id, title FROM chapters WHERE subject_id = ANY($1)',
      [Object.values(subjectMap)]
    );
    for (const row of allChapters.rows) chapterMap[row.title] = row.id;
    console.log('✅ Chapters seeded');

    // ── Content Items ────────────────────────────────────────────────────────
    const contentItems = [
      // Laws of Motion — Physics
      { chapter: 'Laws of Motion', type: 'video',   title: "Newton's 3 Laws — Full Lecture",      order: 0, duration: 28, thumbnail: 'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=600' },
      { chapter: 'Laws of Motion', type: 'note',    title: 'Laws of Motion — Revision Notes',     order: 0, content: "Newton's First Law: An object remains at rest or in uniform motion unless acted upon by an external force.\n\nNewton's Second Law: F = ma\n\nNewton's Third Law: For every action there is an equal and opposite reaction." },
      { chapter: 'Laws of Motion', type: 'mindmap', title: 'Laws of Motion Mind Map',             order: 0 },
      { chapter: 'Laws of Motion', type: 'formula', title: 'Key Formulae — Laws of Motion',       order: 0, content: 'F = ma\nImpulse J = FΔt = Δp\nWork W = Fd·cosθ\nFriction f = μN' },
      // Work, Energy & Power — Physics
      { chapter: 'Work, Energy & Power', type: 'video',   title: 'Work-Energy Theorem Explained', order: 0, duration: 35, thumbnail: 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=600' },
      { chapter: 'Work, Energy & Power', type: 'note',    title: 'Energy Conservation Notes',     order: 0, content: 'Kinetic Energy: KE = ½mv²\nPotential Energy: PE = mgh\nConservation: KE + PE = constant (no friction)' },
      { chapter: 'Work, Energy & Power', type: 'formula', title: 'Work & Power Formulae',         order: 0, content: 'W = Fd cosθ\nKE = ½mv²\nPE = mgh\nP = W/t = Fv' },
      // Waves & Oscillations — Physics
      { chapter: 'Waves & Oscillations', type: 'video',   title: 'Simple Harmonic Motion',        order: 0, duration: 42, thumbnail: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600' },
      { chapter: 'Waves & Oscillations', type: 'mindmap', title: 'Wave Types Overview',           order: 0 },
      { chapter: 'Waves & Oscillations', type: 'formula', title: 'Wave & SHM Formulae',           order: 0, content: 'v = fλ\nT = 2π√(l/g)\nf = 1/T\nv = √(T/μ)' },
      // Electrostatics — Physics
      { chapter: 'Electrostatics', type: 'video',   title: "Coulomb's Law & Electric Field",      order: 0, duration: 38 },
      { chapter: 'Electrostatics', type: 'note',    title: "Gauss's Law — Quick Notes",           order: 0, content: 'Electric flux φ = E·A·cosθ\nGauss\'s Law: φ = Q_enc / ε₀' },
      { chapter: 'Electrostatics', type: 'formula', title: 'Electrostatics Formula Sheet',        order: 0, content: 'F = kq₁q₂/r²\nE = F/q = kQ/r²\nV = kQ/r\nC = Q/V' },
      // Limits & Continuity — Mathematics
      { chapter: 'Limits & Continuity', type: 'video',   title: 'Limits from First Principles',  order: 0, duration: 31 },
      { chapter: 'Limits & Continuity', type: 'note',    title: "L'Hôpital's Rule Notes",         order: 0, content: 'Use when limit gives 0/0 or ∞/∞ form.\nlim f(x)/g(x) = lim f\'(x)/g\'(x)' },
      { chapter: 'Limits & Continuity', type: 'formula', title: 'Standard Limits',                order: 0, content: 'lim(x→0) sinx/x = 1\nlim(x→0) (1+x)^(1/x) = e\nlim(x→∞) (1 + 1/x)^x = e' },
      // Differentiation — Mathematics
      { chapter: 'Differentiation', type: 'video',   title: 'Chain Rule & Product Rule',          order: 0, duration: 44 },
      { chapter: 'Differentiation', type: 'mindmap', title: 'Differentiation Rules Mind Map',     order: 0 },
      { chapter: 'Differentiation', type: 'formula', title: 'Derivative Formula Sheet',           order: 0, content: 'd/dx(xⁿ) = nxⁿ⁻¹\nd/dx(sinx) = cosx\nd/dx(eˣ) = eˣ\nd/dx(lnx) = 1/x' },
      // Integration — Mathematics
      { chapter: 'Integration', type: 'video',   title: 'Integration by Parts — Full Guide',      order: 0, duration: 52 },
      { chapter: 'Integration', type: 'note',    title: 'Integration Techniques Notes',           order: 0, content: "Substitution: ∫f(g(x))g'(x)dx\nBy Parts: ∫u dv = uv - ∫v du\nPartial Fractions: split rational functions" },
      { chapter: 'Integration', type: 'formula', title: 'Standard Integrals',                     order: 0, content: '∫xⁿdx = xⁿ⁺¹/(n+1)\n∫sinx dx = -cosx\n∫eˣdx = eˣ\n∫1/x dx = ln|x|' },
      // Atomic Structure — Chemistry
      { chapter: 'Atomic Structure', type: 'video',   title: 'Bohr Model & Quantum Numbers',      order: 0, duration: 29 },
      { chapter: 'Atomic Structure', type: 'note',    title: 'Quantum Numbers — Quick Reference', order: 0, content: 'n: principal, l: azimuthal (0 to n-1), m: magnetic (-l to +l), s: spin (+½ or -½)' },
      { chapter: 'Atomic Structure', type: 'mindmap', title: 'Atomic Models Timeline',            order: 0 },
      { chapter: 'Atomic Structure', type: 'formula', title: 'Atomic Structure Formulae',         order: 0, content: 'E = -13.6/n² eV\nλ = h/mv (de Broglie)\nΔxΔp ≥ h/4π (Heisenberg)' },
      // Chemical Bonding — Chemistry
      { chapter: 'Chemical Bonding', type: 'video',   title: 'Ionic vs Covalent Bonding',         order: 0, duration: 33 },
      { chapter: 'Chemical Bonding', type: 'note',    title: 'VSEPR Theory Notes',                order: 0, content: 'Electron pair repulsion determines molecular geometry.\nLinear: 2 pairs, Bent: 2 bond + 1 lone pair...' },
      { chapter: 'Chemical Bonding', type: 'formula', title: 'Bond Energy & Polarity',            order: 0, content: 'Formal charge = V - N - B/2\nElectronegativity diff > 1.7 → ionic' },
      // Cell: Structure & Function — Biology
      { chapter: 'Cell: Structure & Function', type: 'video',   title: 'Plant vs Animal Cell',    order: 0, duration: 26 },
      { chapter: 'Cell: Structure & Function', type: 'note',    title: 'Cell Organelles Notes',   order: 0, content: 'Mitochondria: powerhouse, ATP production.\nRibosome: protein synthesis.\nNucleus: DNA storage & control.' },
      { chapter: 'Cell: Structure & Function', type: 'mindmap', title: 'Cell Organelles Mind Map',order: 0 },
      // Genetics & Heredity — Biology
      { chapter: 'Genetics & Heredity', type: 'video',   title: "Mendel's Laws Explained",        order: 0, duration: 37 },
      { chapter: 'Genetics & Heredity', type: 'note',    title: 'Punnet Square & Ratios',         order: 0, content: 'Monohybrid cross: 3:1 phenotypic ratio\nDihybrid cross: 9:3:3:1 ratio' },
      { chapter: 'Genetics & Heredity', type: 'formula', title: 'Genetics Quick Reference',       order: 0, content: 'Hardy-Weinberg: p² + 2pq + q² = 1\np + q = 1' },
      // Human Physiology — Biology
      { chapter: 'Human Physiology', type: 'video',   title: 'Digestion & Absorption',            order: 0, duration: 41 },
      { chapter: 'Human Physiology', type: 'mindmap', title: 'Respiratory System Mind Map',       order: 0 },
      { chapter: 'Human Physiology', type: 'note',    title: 'Nervous System Notes',              order: 0, content: 'CNS: brain + spinal cord.\nPNS: somatic + autonomic.\nNeuron: dendrite → cell body → axon → synapse' },
    ];

    for (const item of contentItems) {
      const chId = chapterMap[item.chapter];
      if (!chId) { console.warn(`⚠️  Chapter not found for: ${item.chapter}`); continue; }
      await client.query(`
        INSERT INTO content_items (chapter_id, type, title, description, url, thumbnail_url, duration_min, content, item_order, is_published)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, true)
        ON CONFLICT DO NOTHING
      `, [chId, item.type, item.title, item.description || null, item.url || null, item.thumbnail || null, item.duration || null, item.content || null, item.order]);
    }
    console.log('✅ Content items seeded');

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
