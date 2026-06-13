const express = require('express');
const router = express.Router();
const { protect } = require('../middlewares/auth.middleware');
const { getDashboard } = require('../controllers/home.controller');

router.get('/dashboard', protect, getDashboard);

module.exports = router;
