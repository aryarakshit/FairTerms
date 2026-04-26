const express = require('express');

const aggregationController = require('../controllers/aggregation.controller');
const { authenticate } = require('../middleware/auth.middleware');
const { validateLeaderboardQuery } = require('../middleware/validate.middleware');

const router = express.Router();

router.get('/', authenticate, validateLeaderboardQuery, aggregationController.getLeaderboard);

module.exports = router;
