const db = require('../config/db');

// ─── Home Dashboard ───────────────────────────────────────
const getDashboard = async (req, res) => {
  try {
    const userId = req.user.id;

    // Get user's wanted skills
    const [wantedSkills] = await db.execute(
      `SELECT s.id, s.name FROM user_skills us JOIN skills s ON s.id = us.skill_id
       WHERE us.user_id = ? AND us.type = 'want'`,
      [userId]
    );

    const wantedSkillIds = wantedSkills.map((s) => s.id);

    // Find users who offer what this user wants
    let recommended = [];
    if (wantedSkillIds.length > 0) {
      const placeholders = wantedSkillIds.map(() => '?').join(',');
      const [rows] = await db.execute(
        `SELECT DISTINCT u.id, u.name, u.photo_url, u.location, u.rating, u.bio,
                s.name as matching_skill
         FROM users u
         JOIN user_skills us ON us.user_id = u.id
         JOIN skills s ON s.id = us.skill_id
         WHERE us.skill_id IN (${placeholders}) AND us.type = 'offer' AND u.id != ?
         ORDER BY u.rating DESC LIMIT 10`,
        [...wantedSkillIds, userId]
      );
      recommended = rows;
    } else {
      // Fallback: top rated users
      const [rows] = await db.execute(
        `SELECT id, name, photo_url, location, rating, bio FROM users
         WHERE id != ? ORDER BY rating DESC LIMIT 10`,
        [userId]
      );
      recommended = rows;
    }

    // Stats
    const [stats] = await db.execute(
      'SELECT completed_tasks, pending_tasks, rating FROM users WHERE id = ?',
      [userId]
    );

    // Recent activity
    const [recentTrades] = await db.execute(
      `SELECT tr.id, tr.status, tr.created_at,
              u.name as partner_name, u.photo_url as partner_photo,
              os.name as offered_skill, rs.name as requested_skill
       FROM trade_requests tr
       JOIN users u ON u.id = (CASE WHEN tr.from_user_id = ? THEN tr.to_user_id ELSE tr.from_user_id END)
       JOIN skills os ON os.id = tr.offered_skill_id
       JOIN skills rs ON rs.id = tr.requested_skill_id
       WHERE tr.from_user_id = ? OR tr.to_user_id = ?
       ORDER BY tr.created_at DESC LIMIT 5`,
      [userId, userId, userId]
    );

    // Unread notifications count
    const [notifCount] = await db.execute(
      'SELECT COUNT(*) as count FROM notifications WHERE user_id = ? AND is_read = FALSE',
      [userId]
    );

    return res.json({
      success: true,
      dashboard: {
        stats: stats[0] || { completed_tasks: 0, pending_tasks: 0, rating: 4.0 },
        recommended_users: recommended,
        recent_trades: recentTrades,
        unread_notifications: notifCount[0].count,
        wanted_skills: wantedSkills,
      },
    });
  } catch (err) {
    console.error('Dashboard error:', err);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
};

module.exports = { getDashboard };
