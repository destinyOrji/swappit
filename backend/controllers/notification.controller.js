const db = require('../config/db');

const getNotifications = async (req, res) => {
  try {
    const [notifications] = await db.execute(
      'SELECT * FROM notifications WHERE user_id = ? ORDER BY created_at DESC LIMIT 50',
      [req.user.id]
    );
    const [unread] = await db.execute(
      'SELECT COUNT(*) as count FROM notifications WHERE user_id = ? AND is_read = FALSE',
      [req.user.id]
    );
    return res.json({ success: true, notifications, unread_count: unread[0].count });
  } catch (err) {
    return res.status(500).json({ success: false, message: 'Server error' });
  }
};

const markAllRead = async (req, res) => {
  try {
    await db.execute('UPDATE notifications SET is_read = TRUE WHERE user_id = ?', [req.user.id]);
    return res.json({ success: true, message: 'All notifications marked as read' });
  } catch (err) {
    return res.status(500).json({ success: false, message: 'Server error' });
  }
};

module.exports = { getNotifications, markAllRead };
