const fairnessService = require('../services/fairness.service');

/**
 * GET /heatmap/national
 */
async function getNationalHeatmap(req, res) {
  try {
    const data = await fairnessService.getNationalHeatmap(req.query.industry || 'all');
    return res.json({ success: true, data });
  } catch (error) {
    console.error('getNationalHeatmap failed:', error);
    return res.status(500).json({ success: false, error: 'INTERNAL_ERROR' });
  }
}

/**
 * GET /leaderboard
 */
async function getLeaderboard(req, res) {
  try {
    const data = await fairnessService.getBuyerLeaderboard({
      sort: req.query.sort,
      order: req.query.order,
      limit: req.query.limit,
    });
    return res.json({ success: true, data });
  } catch (error) {
    console.error('getLeaderboard failed:', error);
    return res.status(500).json({ success: false, error: 'INTERNAL_ERROR' });
  }
}

module.exports = {
  getNationalHeatmap,
  getLeaderboard,
};
