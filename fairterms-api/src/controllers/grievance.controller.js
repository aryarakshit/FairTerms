const firestoreService = require('../services/firestore.service');

/**
 * GET /analysis/:id/grievance
 */
async function getGrievance(req, res) {
  const { id } = req.params;
  try {
    const analysis = await firestoreService.getOwnedAnalysis(id, req.user.uid);
    if (!analysis) {
      return res.status(404).json({ success: false, error: 'NOT_FOUND' });
    }
    if (analysis.status !== 'completed' || !analysis.grievance) {
      return res.status(400).json({ success: false, error: 'GRIEVANCE_NOT_READY' });
    }
    
    return res.json({
      success: true,
      data: analysis.grievance
    });
  } catch (error) {
    console.error('getGrievance failed:', error);
    return res.status(500).json({ success: false, error: 'INTERNAL_ERROR' });
  }
}

module.exports = {
  getGrievance
};
