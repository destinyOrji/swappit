const db = require('../config/db');

// ─── Get All Skills ───────────────────────────────────────
const getAllSkills = async (req, res) => {
  try {
    const [skills] = await db.execute('SELECT * FROM skills ORDER BY name ASC');
    return res.json({ success: true, skills });
  } catch (err) {
    return res.status(500).json({ success: false, message: 'Server error' });
  }
};

// ─── Search Skills ────────────────────────────────────────
const searchSkills = async (req, res) => {
  const q = req.query.q || '';
  try {
    const [skills] = await db.execute(
      'SELECT * FROM skills WHERE name LIKE ? ORDER BY name ASC LIMIT 20',
      [`%${q}%`]
    );
    return res.json({ success: true, skills });
  } catch (err) {
    return res.status(500).json({ success: false, message: 'Server error' });
  }
};

// ─── Add New Skill (admin or user-suggested) ─────────────
const addSkill = async (req, res) => {
  const { name } = req.body;
  if (!name) return res.status(400).json({ success: false, message: 'Skill name required' });

  try {
    const [existing] = await db.execute('SELECT id FROM skills WHERE name = ?', [name.trim()]);
    if (existing.length) {
      return res.json({ success: true, message: 'Skill already exists', skill: existing[0] });
    }

    const [result] = await db.execute('INSERT INTO skills (name) VALUES (?)', [name.trim()]);
    return res.status(201).json({
      success: true,
      message: 'Skill added',
      skill: { id: result.insertId, name: name.trim() },
    });
  } catch (err) {
    return res.status(500).json({ success: false, message: 'Server error' });
  }
};

// ─── Search Users by Skill ────────────────────────────────
const searchUsersBySkill = async (req, res) => {
  const q = req.query.q || '';
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 10;
  const offset = (page - 1) * limit;

  try {
    const [users] = await db.execute(
      `SELECT DISTINCT u.id, u.name, u.photo_url, u.location, u.rating, u.bio
       FROM users u
       JOIN user_skills us ON us.user_id = u.id
       JOIN skills s ON s.id = us.skill_id
       WHERE s.name LIKE ? AND us.type = 'offer'
       ORDER BY u.rating DESC
       LIMIT ? OFFSET ?`,
      [`%${q}%`, limit, offset]
    );

    // Attach offered skills to each user
    for (const user of users) {
      const [skills] = await db.execute(
        `SELECT s.id, s.name FROM user_skills us JOIN skills s ON s.id = us.skill_id
         WHERE us.user_id = ? AND us.type = 'offer'`,
        [user.id]
      );
      user.skills_offered = skills;
    }

    return res.json({ success: true, users, page, limit });
  } catch (err) {
    return res.status(500).json({ success: false, message: 'Server error' });
  }
};

module.exports = { getAllSkills, searchSkills, addSkill, searchUsersBySkill };
