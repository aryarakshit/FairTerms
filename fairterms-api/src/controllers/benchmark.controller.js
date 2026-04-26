const axios = require('axios');

const FAIRNESS_ENGINE_URL = process.env.FAIRNESS_ENGINE_URL || 'http://fairness-engine:8080/compute';
const FAIRNESS_ENGINE_TIMEOUT_MS = Number(process.env.FAIRNESS_ENGINE_TIMEOUT_MS || 10000);

/**
 * POST /benchmark/compare
 * Calls the fairness engine to compute real benchmark data against peer pool.
 */
async function compareBenchmark(req, res) {
  try {
    const { industry, annual_revenue_min, annual_revenue_max, state, payment_terms_days } = req.body;

    if (!industry || !payment_terms_days) {
      return res.status(400).json({ success: false, error: 'INVALID_INPUT', message: 'industry and payment_terms_days are required' });
    }

    // Build a synthetic SME profile from the benchmark request params for the fairness engine
    const midRevenue = Math.round(((annual_revenue_min || 1000000) + (annual_revenue_max || 10000000)) / 2);

    const response = await axios.post(FAIRNESS_ENGINE_URL, {
      sme_profile: {
        pincode: '400001',
        state: state || 'Maharashtra',
        industry,
        annual_revenue_inr: midRevenue,
        employee_count: 10,
        years_in_operation: 5,
      },
      payment_terms_days,
      order_value_inr: 250000,
      buyer_industry: 'General',
    }, {
      timeout: FAIRNESS_ENGINE_TIMEOUT_MS,
    });

    const bm = response.data.benchmark || {};

    return res.json({
      success: true,
      data: {
        peers_found: bm.peers_found || 0,
        average_terms_days: bm.average_terms_days || 0,
        median_terms_days: bm.median_terms_days || 0,
        your_percentile: Math.round(bm.percentile || 0),
        distribution: bm.distribution || {}
      }
    });
  } catch (error) {
    console.error('compareBenchmark failed:', error.message);
    // Fallback mock data for development
    if (process.env.NODE_ENV === 'development') {
      return res.json({
        success: true,
        data: {
          peers_found: 147,
          average_terms_days: 52,
          median_terms_days: 45,
          your_percentile: 92,
          distribution: { '0-30': 18, '31-45': 52, '46-60': 43, '61-90': 28, '90+': 6 }
        }
      });
    }
    return res.status(500).json({ success: false, error: 'INTERNAL_ERROR' });
  }
}

module.exports = {
  compareBenchmark
};
