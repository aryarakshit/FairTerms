const express = require('express');
const router = express.Router();
const smeController = require('../controllers/sme.controller');
const { authenticate } = require('../middleware/auth.middleware');
const { validateProfile, validateResourceIdParam } = require('../middleware/validate.middleware');

router.post('/profile', authenticate, validateProfile, smeController.createOrUpdateProfile);
// /profile/me must come BEFORE /profile/:id so "me" isn't treated as an ID param
router.get('/profile/me', authenticate, smeController.getMyProfile);
router.get('/profile/:id', authenticate, validateResourceIdParam, smeController.getProfile);

module.exports = router;
