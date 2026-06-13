const express = require('express');
const router = express.Router();
const { protect } = require('../middlewares/auth.middleware');
const { getNotifications, markAllRead } = require('../controllers/notification.controller');

router.get('/', protect, getNotifications);
router.put('/read-all', protect, markAllRead);

module.exports = router;
