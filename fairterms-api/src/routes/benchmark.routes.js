const express = require('express');
const router = express.Router();
const benchmarkController = require('../controllers/benchmark.controller');
const { authenticate } = require('../middleware/auth.middleware');
const { validateBenchmarkCompare } = require('../middleware/validate.middleware');

router.post('/compare', authenticate, validateBenchmarkCompare, benchmarkController.compareBenchmark);

module.exports = router;
