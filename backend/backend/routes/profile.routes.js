const express = require('express');
const router = express.Router();
const { protect } = require('../middlewares/auth.middleware');
const { upload } = require('../config/cloudinary');
const {
  getProfile,
  getUserProfile,
  updateProfile,
  uploadPhoto,
  updateSkills,
} = require('../controllers/profile.controller');

router.get('/', protect, getProfile);
router.put('/', protect, updateProfile);
router.post('/photo', protect, upload.single('photo'), uploadPhoto);
router.post('/skills', protect, updateSkills);
router.get('/:userId', protect, getUserProfile);

module.exports = router;
