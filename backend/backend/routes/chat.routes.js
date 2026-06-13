const express = require('express');
const router = express.Router();
const { protect } = require('../middlewares/auth.middleware');
const { getChats, getMessages, sendMessage } = require('../controllers/chat.controller');

router.get('/', protect, getChats);
router.get('/:otherUserId/messages', protect, getMessages);
router.post('/messages', protect, sendMessage);

module.exports = router;
