const db = require('../config/db');

// ─── Send Trade Request ───────────────────────────────────
const sendTradeRequest = async (req, res) => {
  const { to_user_id, offered_skill_id, requested_skill_id } = req.body;
  const from_user_id = req.user.id;

  if (!to_user_id || !offered_skill_id || !requested_skill_id) {
    return res.status(400).json({ success: false, message: 'Missing required fields' });
  }

  if (from_user_id === parseInt(to_user_id)) {
    return res.status(400).json({ success: false, message: 'Cannot trade with yourself' });
  }

  try {
    // Check if pending request already exists
    const [existing] = await db.execute(
      `SELECT id FROM trade_requests
       WHERE from_user_id = ? AND to_user_id = ? AND status = 'pending'`,
      [from_user_id, to_user_id]
    );
    if (existing.length) {
      return res.status(409).json({ success: false, message: 'Pending request already exists' });
    }

    const [result] = await db.execute(
      `INSERT INTO trade_requests (from_user_id, to_user_id, offered_skill_id, requested_skill_id)
       VALUES (?, ?, ?, ?)`,
      [from_user_id, to_user_id, offered_skill_id, requested_skill_id]
    );

    // Create notification for receiver
    await db.execute(
      `INSERT INTO notifications (user_id, title, message) VALUES (?, ?, ?)`,
      [to_user_id, 'New Trade Request', `${req.user.name} wants to swap skills with you!`]
    );

    // Update sender's pending_tasks count
    await db.execute('UPDATE users SET pending_tasks = pending_tasks + 1 WHERE id = ?', [from_user_id]);

    return res.status(201).json({
      success: true,
      message: 'Trade request sent',
      tradeId: result.insertId,
    });
  } catch (err) {
    console.error('Trade request error:', err);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
};

// ─── Respond to Trade Request ─────────────────────────────
const respondToTrade = async (req, res) => {
  const { tradeId } = req.params;
  const { action } = req.body; // 'accepted' or 'rejected'

  if (!['accepted', 'rejected'].includes(action)) {
    return res.status(400).json({ success: false, message: 'Action must be accepted or rejected' });
  }

  try {
    const [rows] = await db.execute(
      'SELECT * FROM trade_requests WHERE id = ? AND to_user_id = ?',
      [tradeId, req.user.id]
    );

    if (!rows.length) {
      return res.status(404).json({ success: false, message: 'Trade request not found' });
    }

    if (rows[0].status !== 'pending') {
      return res.status(400).json({ success: false, message: 'Request already handled' });
    }

    await db.execute('UPDATE trade_requests SET status = ? WHERE id = ?', [action, tradeId]);

    const notifMsg =
      action === 'accepted'
        ? `${req.user.name} accepted your trade request!`
        : `${req.user.name} declined your trade request.`;

    await db.execute(
      `INSERT INTO notifications (user_id, title, message) VALUES (?, ?, ?)`,
      [rows[0].from_user_id, 'Trade Update', notifMsg]
    );

    if (action === 'accepted') {
      await db.execute('UPDATE users SET pending_tasks = pending_tasks + 1 WHERE id = ?', [req.user.id]);
    } else {
      await db.execute(
        'UPDATE users SET pending_tasks = GREATEST(pending_tasks - 1, 0) WHERE id = ?',
        [rows[0].from_user_id]
      );
    }

    return res.json({ success: true, message: `Trade request ${action}` });
  } catch (err) {
    return res.status(500).json({ success: false, message: 'Server error' });
  }
};

// ─── Complete a Trade ─────────────────────────────────────
const completeTrade = async (req, res) => {
  const { tradeId } = req.params;

  try {
    const [rows] = await db.execute(
      `SELECT * FROM trade_requests WHERE id = ? AND status = 'accepted'
       AND (from_user_id = ? OR to_user_id = ?)`,
      [tradeId, req.user.id, req.user.id]
    );

    if (!rows.length) {
      return res.status(404).json({ success: false, message: 'Active trade not found' });
    }

    const trade = rows[0];
    await db.execute('UPDATE trade_requests SET status = ? WHERE id = ?', ['completed', tradeId]);

    // Update completed_tasks and reduce pending for both parties
    const userIds = [trade.from_user_id, trade.to_user_id];
    for (const uid of userIds) {
      await db.execute(
        'UPDATE users SET completed_tasks = completed_tasks + 1, pending_tasks = GREATEST(pending_tasks - 1, 0) WHERE id = ?',
        [uid]
      );
    }

    return res.json({ success: true, message: 'Trade marked as completed' });
  } catch (err) {
    return res.status(500).json({ success: false, message: 'Server error' });
  }
};

// ─── Get My Trades ────────────────────────────────────────
const getMyTrades = async (req, res) => {
  const { status } = req.query;
  try {
    let query = `
      SELECT tr.*, 
        fu.name as from_name, fu.photo_url as from_photo,
        tu.name as to_name, tu.photo_url as to_photo,
        os.name as offered_skill, rs.name as requested_skill
      FROM trade_requests tr
      JOIN users fu ON fu.id = tr.from_user_id
      JOIN users tu ON tu.id = tr.to_user_id
      JOIN skills os ON os.id = tr.offered_skill_id
      JOIN skills rs ON rs.id = tr.requested_skill_id
      WHERE (tr.from_user_id = ? OR tr.to_user_id = ?)
    `;
    const params = [req.user.id, req.user.id];

    if (status) {
      query += ' AND tr.status = ?';
      params.push(status);
    }

    query += ' ORDER BY tr.created_at DESC';

    const [trades] = await db.execute(query, params);
    return res.json({ success: true, trades });
  } catch (err) {
    return res.status(500).json({ success: false, message: 'Server error' });
  }
};

// ─── Rate After Trade ─────────────────────────────────────
const rateTrade = async (req, res) => {
  const { tradeId } = req.params;
  const { stars, comment } = req.body;

  if (!stars || stars < 1 || stars > 5) {
    return res.status(400).json({ success: false, message: 'Stars must be between 1 and 5' });
  }

  try {
    const [rows] = await db.execute(
      `SELECT * FROM trade_requests WHERE id = ? AND status = 'completed'
       AND (from_user_id = ? OR to_user_id = ?)`,
      [tradeId, req.user.id, req.user.id]
    );

    if (!rows.length) {
      return res.status(404).json({ success: false, message: 'Completed trade not found' });
    }

    const trade = rows[0];
    const toUserId = trade.from_user_id === req.user.id ? trade.to_user_id : trade.from_user_id;

    // Check if already rated
    const [existing] = await db.execute(
      'SELECT id FROM ratings WHERE from_user_id = ? AND trade_id = ?',
      [req.user.id, tradeId]
    );
    if (existing.length) {
      return res.status(409).json({ success: false, message: 'Already rated this trade' });
    }

    await db.execute(
      'INSERT INTO ratings (from_user_id, to_user_id, trade_id, stars, comment) VALUES (?, ?, ?, ?, ?)',
      [req.user.id, toUserId, tradeId, stars, comment || null]
    );

    // Recalculate average rating
    const [avg] = await db.execute(
      'SELECT AVG(stars) as avg_rating FROM ratings WHERE to_user_id = ?',
      [toUserId]
    );
    await db.execute('UPDATE users SET rating = ? WHERE id = ?', [avg[0].avg_rating, toUserId]);

    return res.json({ success: true, message: 'Rating submitted' });
  } catch (err) {
    return res.status(500).json({ success: false, message: 'Server error' });
  }
};

module.exports = { sendTradeRequest, respondToTrade, completeTrade, getMyTrades, rateTrade };
