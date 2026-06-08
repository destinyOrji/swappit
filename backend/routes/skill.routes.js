const express = require('express');
const router = express.Router();
const { protect } = require('../middlewares/auth.middleware');
const { getAllSkills, searchSkills, addSkill, searchUsersBySkill } = require('../controllers/skill.controller');

router.get('/', protect, getAllSkills);
router.get('/search', protect, searchSkills);
router.post('/', protect, addSkill);
router.get('/users', protect, searchUsersBySkill);

module.exports = router;
