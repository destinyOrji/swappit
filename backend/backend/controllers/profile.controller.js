const db = require('../config/db');
const { cloudinary } = require('../config/cloudinary');

// ─── Get My Profile ──────────────────────────────────────
const getProfile = async (req, res) => {
  try {
    const [rows] = await db.execute(
      `SELECT u.id, u.name, u.email, u.phone, u.photo_url, u.bio, u.location,
              u.rating, u.completed_tasks, u.pending_tasks, u.verified, u.created_at
       FROM users u WHERE u.id = ?`,
      [req.user.id]
    );

    if (!rows.length) return res.status(404).json({ success: false, message: 'User not found' });

    const user = rows[0];

    // Get skills
    const [skills] = await db.execute(
      `SELECT s.id, s.name, us.type
       FROM user_skills us
       JOIN skills s ON s.id = us.skill_id
       WHERE us.user_id = ?`,
      [req.user.id]
    );

    user.skills_offered = skills.filter((s) => s.type === 'offer');
    user.skills_wanted = skills.filter((s) => s.type === 'want');

    return res.json({ success: true, user });
  } catch (err) {
    console.error('Get profile error:', err);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
};

// ─── Get Any User's Public Profile ───────────────────────
const getUserProfile = async (req, res) => {
  const { userId } = req.params;
  try {
    const [rows] = await db.execute(
      `SELECT id, name, photo_url, bio, location, rating, completed_tasks, verified
       FROM users WHERE id = ?`,
      [userId]
    );

    if (!rows.length) return res.status(404).json({ success: false, message: 'User not found' });

    const user = rows[0];
    const [skills] = await db.execute(
      `SELECT s.id, s.name, us.type FROM user_skills us JOIN skills s ON s.id = us.skill_id WHERE us.user_id = ?`,
      [userId]
    );

    user.skills_offered = skills.filter((s) => s.type === 'offer');
    user.skills_wanted = skills.filter((s) => s.type === 'want');

    // Ratings
    const [ratings] = await db.execute(
      `SELECT r.stars, r.comment, r.created_at, u.name as reviewer_name, u.photo_url as reviewer_photo
       FROM ratings r JOIN users u ON u.id = r.from_user_id
       WHERE r.to_user_id = ? ORDER BY r.created_at DESC LIMIT 10`,
      [userId]
    );
    user.recent_ratings = ratings;

    return res.json({ success: true, user });
  } catch (err) {
    return res.status(500).json({ success: false, message: 'Server error' });
  }
};

// ─── Update Profile ──────────────────────────────────────
const updateProfile = async (req, res) => {
  const { name, phone, bio, location } = req.body;
  try {
    await db.execute(
      'UPDATE users SET name = COALESCE(?, name), phone = COALESCE(?, phone), bio = COALESCE(?, bio), location = COALESCE(?, location) WHERE id = ?',
      [name || null, phone || null, bio || null, location || null, req.user.id]
    );

    const [rows] = await db.execute('SELECT * FROM users WHERE id = ?', [req.user.id]);
    return res.json({ success: true, message: 'Profile updated', user: rows[0] });
  } catch (err) {
    return res.status(500).json({ success: false, message: 'Server error' });
  }
};

// ─── Upload Profile Photo ─────────────────────────────────
const uploadPhoto = async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ success: false, message: 'No file uploaded' });

    const photoUrl = req.file.path; // Cloudinary URL
    await db.execute('UPDATE users SET photo_url = ? WHERE id = ?', [photoUrl, req.user.id]);

    return res.json({ success: true, message: 'Photo updated', photo_url: photoUrl });
  } catch (err) {
    return res.status(500).json({ success: false, message: 'Server error' });
  }
};

// ─── Add/Update Skills ────────────────────────────────────
const updateSkills = async (req, res) => {
  const { skills_offered = [], skills_wanted = [] } = req.body;
  // skills_offered/wanted are arrays of skill IDs

  const conn = await db.getConnection();
  try {
    await conn.beginTransaction();

    // Clear existing skills
    await conn.execute('DELETE FROM user_skills WHERE user_id = ?', [req.user.id]);

    // Insert offered
    for (const skillId of skills_offered) {
      await conn.execute(
        'INSERT IGNORE INTO user_skills (user_id, skill_id, type) VALUES (?, ?, ?)',
        [req.user.id, skillId, 'offer']
      );
    }

    // Insert wanted
    for (const skillId of skills_wanted) {
      await conn.execute(
        'INSERT IGNORE INTO user_skills (user_id, skill_id, type) VALUES (?, ?, ?)',
        [req.user.id, skillId, 'want']
      );
    }

    await conn.commit();
    return res.json({ success: true, message: 'Skills updated' });
  } catch (err) {
    await conn.rollback();
    return res.status(500).json({ success: false, message: 'Server error' });
  } finally {
    conn.release();
  }
};

module.exports = { getProfile, getUserProfile, updateProfile, uploadPhoto, updateSkills };
