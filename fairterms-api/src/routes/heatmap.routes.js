const express = require('express');

const aggregationController = require('../controllers/aggregation.controller');
const { authenticate } = require('../middleware/auth.middleware');
const { validateHeatmapQuery } = require('../middleware/validate.middleware');

const router = express.Router();

router.get('/national', authenticate, validateHeatmapQuery, aggregationController.getNationalHeatmap);

module.exports = router;
