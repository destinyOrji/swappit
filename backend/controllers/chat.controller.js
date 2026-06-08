const db = require('../config/db');

// ─── Get All Chats (conversations) ───────────────────────
const getChats = async (req, res) => {
  try {
    const [chats] = await db.execute(
      `SELECT 
        m.id, m.message, m.created_at, m.sender_id, m.receiver_id,
        CASE WHEN m.sender_id = ? THEN m.receiver_id ELSE m.sender_id END as other_user_id,
        u.name as other_user_name, u.photo_url as other_user_photo,
        tr.id as trade_id, tr.status as trade_status,
        (SELECT COUNT(*) FROM messages m2 WHERE m2.receiver_id = ? AND m2.sender_id = u.id AND m2.is_read = FALSE) as unread_count
      FROM messages m
      JOIN users u ON u.id = (CASE WHEN m.sender_id = ? THEN m.receiver_id ELSE m.sender_id END)
      LEFT JOIN trade_requests tr ON tr.id = m.trade_id
      WHERE (m.sender_id = ? OR m.receiver_id = ?)
        AND m.id = (
          SELECT MAX(m3.id) FROM messages m3
          WHERE (m3.sender_id = m.sender_id AND m3.receiver_id = m.receiver_id)
             OR (m3.sender_id = m.receiver_id AND m3.receiver_id = m.sender_id)
        )
      ORDER BY m.created_at DESC`,
      [req.user.id, req.user.id, req.user.id, req.user.id, req.user.id]
    );

    return res.json({ success: true, chats });
  } catch (err) {
    console.error('Get chats error:', err);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
};

// ─── Get Messages in a Conversation ──────────────────────
const getMessages = async (req, res) => {
  const { otherUserId } = req.params;
  const page = parseInt(req.query.page) || 1;
  const limit = 30;
  const offset = (page - 1) * limit;

  try {
    const [messages] = await db.execute(
      `SELECT * FROM messages
       WHERE (sender_id = ? AND receiver_id = ?)
          OR (sender_id = ? AND receiver_id = ?)
       ORDER BY created_at DESC
       LIMIT ? OFFSET ?`,
      [req.user.id, otherUserId, otherUserId, req.user.id, limit, offset]
    );

    // Mark as read
    await db.execute(
      `UPDATE messages SET is_read = TRUE
       WHERE receiver_id = ? AND sender_id = ?`,
      [req.user.id, otherUserId]
    );

    return res.json({ success: true, messages: messages.reverse(), page });
  } catch (err) {
    return res.status(500).json({ success: false, message: 'Server error' });
  }
};

// ─── Send Message (REST fallback) ────────────────────────
const sendMessage = async (req, res) => {
  const { receiver_id, message, trade_id } = req.body;

  if (!receiver_id || !message) {
    return res.status(400).json({ success: false, message: 'receiver_id and message required' });
  }

  try {
    const [result] = await db.execute(
      'INSERT INTO messages (trade_id, sender_id, receiver_id, message) VALUES (?, ?, ?, ?)',
      [trade_id || null, req.user.id, receiver_id, message]
    );

    return res.status(201).json({
      success: true,
      message: { id: result.insertId, sender_id: req.user.id, receiver_id, message, created_at: new Date() },
    });
  } catch (err) {
    return res.status(500).json({ success: false, message: 'Server error' });
  }
};

module.exports = { getChats, getMessages, sendMessage };
