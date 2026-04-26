const express = require('express');
const router = express.Router();
const analysisController = require('../controllers/analysis.controller');
const grievanceController = require('../controllers/grievance.controller');
const { authenticate } = require('../middleware/auth.middleware');
const { validateAnalysisRun, validateResourceIdParam } = require('../middleware/validate.middleware');

router.post('/run', authenticate, validateAnalysisRun, analysisController.runAnalysis);
// /history must be defined before /:id routes so Express doesn't treat "history" as an ID
router.get('/history', authenticate, analysisController.getAnalysisHistory);
router.get('/:id/status', authenticate, validateResourceIdParam, analysisController.getAnalysisStatus);
router.get('/:id/report', authenticate, validateResourceIdParam, analysisController.getAnalysisReport);
router.get('/:id/grievance', authenticate, validateResourceIdParam, grievanceController.getGrievance);

module.exports = router;
