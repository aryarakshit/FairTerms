const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth.middleware');
const adminAuthMiddleware = require('../middleware/adminAuth.middleware');
const adminController = require('../controllers/admin.controller');

// All admin routes require authentication + admin role
router.use(authenticate, adminAuthMiddleware);

router.get('/overview', adminController.getOverview);
router.get('/users', adminController.getUsers);
router.get('/users/:uid', adminController.getUserInfo);
router.delete('/users/:uid', adminController.deactivateUser);
router.get('/analyses', adminController.getAllAnalyses);
router.get('/activity', adminController.getActivity);
router.get('/health', adminController.getHealth);

// Seed endpoints
router.post('/seed/regenerate', adminController.regenerateSeed);
router.get('/seed/stats', adminController.getSeedStats);
router.delete('/seed/reset', adminController.resetSeed);

// Buyer management
router.get('/buyers', adminController.getBuyers);

module.exports = router;
