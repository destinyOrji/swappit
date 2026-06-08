require('dotenv').config();
const express = require('express');
const http = require('http');
const cors = require('cors');
const { Server } = require('socket.io');
const db = require('./config/db');
const socketHandler = require('./config/socket');

// Route imports
const authRoutes = require('./routes/auth.routes');
const profileRoutes = require('./routes/profile.routes');
const skillRoutes = require('./routes/skill.routes');
const tradeRoutes = require('./routes/trade.routes');
const chatRoutes = require('./routes/chat.routes');
const notificationRoutes = require('./routes/notification.routes');
const homeRoutes = require('./routes/home.routes');

const app = express();
const server = http.createServer(app);

// Socket.io setup
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST'],
  },
});
socketHandler(io);

// Middleware
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', app: 'Swappit API', version: '1.0.0' });
});

// Routes
app.use('/auth', authRoutes);
app.use('/profile', profileRoutes);
app.use('/skills', skillRoutes);
app.use('/trade', tradeRoutes);
app.use('/chats', chatRoutes);
app.use('/notifications', notificationRoutes);
app.use('/home', homeRoutes);

// 404 handler
app.use((req, res) => {
  res.status(404).json({ success: false, message: 'Route not found' });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(err.statusCode || 500).json({
    success: false,
    message: err.message || 'Internal server error',
  });
});

const PORT = process.env.PORT || 5000;
server.listen(PORT, () => {
  console.log(`🚀 Swappit server running on port ${PORT}`);
});
