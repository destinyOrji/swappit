const express = require('express');
const router = express.Router();
const { signup, verifyOTP, resendOTP, login, googleSignIn } = require('../controllers/auth.controller');

router.post('/signup', signup);
router.post('/login', login);
router.post('/verify-otp', verifyOTP);
router.post('/resend-otp', resendOTP);
router.post('/google', googleSignIn);

module.exports = router;
