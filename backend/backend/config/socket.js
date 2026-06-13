const db = require('./db');

module.exports = (io) => {
  // Map userId -> socketId
  const onlineUsers = new Map();

  io.on('connection', (socket) => {
    console.log(`🔌 Socket connected: ${socket.id}`);

    // Register user as online
    socket.on('register', (userId) => {
      onlineUsers.set(String(userId), socket.id);
      console.log(`👤 User ${userId} is online`);
    });

    // Join a chat room (trade_id based)
    socket.on('join_room', (roomId) => {
      socket.join(`room_${roomId}`);
    });

    // Send message in a room
    socket.on('send_message', async (data) => {
      const { trade_id, sender_id, receiver_id, message } = data;

      try {
        const [result] = await db.execute(
          `INSERT INTO messages (trade_id, sender_id, receiver_id, message) VALUES (?, ?, ?, ?)`,
          [trade_id || null, sender_id, receiver_id, message]
        );

        const payload = {
          id: result.insertId,
          trade_id,
          sender_id,
          receiver_id,
          message,
          created_at: new Date(),
        };

        // Emit to room if trade_id exists
        if (trade_id) {
          io.to(`room_${trade_id}`).emit('new_message', payload);
        }

        // Also emit directly to receiver if online
        const receiverSocket = onlineUsers.get(String(receiver_id));
        if (receiverSocket) {
          io.to(receiverSocket).emit('new_message', payload);
        }
      } catch (err) {
        socket.emit('error', { message: 'Failed to send message' });
      }
    });

    // Typing indicator
    socket.on('typing', ({ room_id, sender_id }) => {
      socket.to(`room_${room_id}`).emit('user_typing', { sender_id });
    });

    socket.on('disconnect', () => {
      for (const [userId, socketId] of onlineUsers.entries()) {
        if (socketId === socket.id) {
          onlineUsers.delete(userId);
          console.log(`👤 User ${userId} went offline`);
          break;
        }
      }
    });
  });
};
