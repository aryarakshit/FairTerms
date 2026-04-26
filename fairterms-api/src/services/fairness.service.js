const axios = require('axios');

const FAIRNESS_ENGINE_COMPUTE_URL =
  process.env.FAIRNESS_ENGINE_URL || 'http://fairness-engine:8080/compute';
const FAIRNESS_ENGINE_BASE_URL =
  process.env.FAIRNESS_ENGINE_BASE_URL ||
  FAIRNESS_ENGINE_COMPUTE_URL.replace(/\/compute\/?$/, '');
const FAIRNESS_ENGINE_TIMEOUT_MS = Number(
  process.env.FAIRNESS_ENGINE_TIMEOUT_MS || 10000,
);
const USE_MOCK_FAIRNESS_DATA = process.env.USE_MOCK_FAIRNESS_DATA === 'true';

const MOCK_FAIRNESS_RESPONSE = {
  benchmark: {
    peers_found: 147,
    average_terms_days: 52,
    median_terms_days: 45,
    std_dev: 18.5,
    percentile: 92,
    distribution: { '0-30': 18, '31-45': 52, '46-60': 43, '61-90': 28, '90+': 6 },
  },
  fairness_metrics: {
    statistical_parity_difference: -0.34,
    disparate_impact_ratio: 0.58,
    equal_opportunity_difference: -0.28,
    theil_index: 0.42,
  },
  bias_factors: [
    {
      factor: 'pincode_region',
      impact: 'high',
      impact_score: 0.82,
      detail: 'Geographic bias detected in peer comparison',
    },
    {
      factor: 'industry',
      impact: 'medium',
      impact_score: 0.54,
      detail: 'Industry-based disparity found in payment terms',
    },
  ],
  statistical_tests: {
    mann_whitney_u_pvalue: 0.003,
    chi_square_pvalue: 0.008,
    interpretation: 'Differences are statistically significant (p < 0.05)',
  },
};

const MOCK_HEATMAP_RESPONSE = {
  states: [
    {
      state: 'Bihar',
      state_code: 'BR',
      avg_payment_terms_days: 87,
      avg_fairness_score: 18,
      total_analyses: 62,
      bias_level: 'severe',
    },
    {
      state: 'West Bengal',
      state_code: 'WB',
      avg_payment_terms_days: 78,
      avg_fairness_score: 31,
      total_analyses: 45,
      bias_level: 'severe',
    },
    {
      state: 'Maharashtra',
      state_code: 'MH',
      avg_payment_terms_days: 44,
      avg_fairness_score: 74,
      total_analyses: 89,
      bias_level: 'fair',
    },
  ],
  industry_filter: 'all',
  last_updated: '2026-04-13T10:00:00Z',
};

const MOCK_LEADERBOARD_RESPONSE = {
  buyers: [
    {
      buyer_name: 'Infosys',
      fairness_score: 88,
      avg_payment_terms_days: 32,
      total_smes_served: 34,
      rank: 1,
      badge: 'gold',
    },
    {
      buyer_name: 'Reliance Retail',
      fairness_score: 29,
      avg_payment_terms_days: 87,
      total_smes_served: 56,
      rank: 15,
      badge: 'red_flag',
    },
  ],
  total_buyers: 15,
  last_updated: '2026-04-13T10:00:00Z',
};

/**
 * Returns true when the service should respond with bundled mock data.
 */
function shouldUseMockData() {
  return USE_MOCK_FAIRNESS_DATA;
}

/**
 * Returns true when the error is transient (connection refused, timeout, or 5xx).
 * 4xx and parse errors are NOT transient and should be reraised.
 */
function isTransientError(error) {
  if (!error) return false;
  const code = error.code;
  if (code === 'ECONNREFUSED' || code === 'ETIMEDOUT' || code === 'ECONNRESET') return true;
  const status = error.response?.status;
  return status != null && status >= 500;
}

/**
 * Calls the fairness engine compute endpoint.
 */
async function computeFairnessMetrics(smeProfile, paymentTerms) {
  try {
    if (shouldUseMockData()) {
      return MOCK_FAIRNESS_RESPONSE;
    }

    const response = await axios.post(
      FAIRNESS_ENGINE_COMPUTE_URL,
      {
        sme_profile: {
          pincode: smeProfile.pincode,
          state: smeProfile.state,
          industry: smeProfile.industry,
          annual_revenue_inr: smeProfile.annual_revenue_inr,
          employee_count: smeProfile.employee_count,
          years_in_operation: smeProfile.years_in_operation,
        },
        payment_terms_days: paymentTerms.payment_terms_days,
        order_value_inr: paymentTerms.order_value_inr,
        buyer_industry: paymentTerms.buyer_type || 'General',
      },
      {
        timeout: FAIRNESS_ENGINE_TIMEOUT_MS,
      },
    );

    return response.data;
  } catch (error) {
    console.error('Fairness engine compute call failed:', { message: error.message, code: error.code, status: error.response?.status });
    if (isTransientError(error) && USE_MOCK_FAIRNESS_DATA) {
      console.warn('Transient fairness engine error — returning mock data (USE_MOCK_FAIRNESS_DATA=true).');
      return { ...MOCK_FAIRNESS_RESPONSE, _fallback: true };
    }
    throw error;
  }
}

/**
 * Calls the fairness engine heatmap aggregate endpoint.
 */
async function getNationalHeatmap(industry = 'all') {
  try {
    if (shouldUseMockData()) {
      return {
        ...MOCK_HEATMAP_RESPONSE,
        industry_filter: industry || 'all',
      };
    }

    const response = await axios.get(
      `${FAIRNESS_ENGINE_BASE_URL}/aggregate/heatmap`,
      {
        params: { industry: industry || 'all' },
        timeout: FAIRNESS_ENGINE_TIMEOUT_MS,
      },
    );

    return response.data;
  } catch (error) {
    console.error('Fairness engine heatmap call failed:', error.message);
    if (shouldFallbackOnError()) {
      console.warn('Returning mock heatmap data due to connection error.');
      return {
        ...MOCK_HEATMAP_RESPONSE,
        industry_filter: industry || 'all',
      };
    }
    throw error;
  }
}

/**
 * Calls the fairness engine leaderboard aggregate endpoint.
 */
async function getBuyerLeaderboard({
  sort = 'fairness_score',
  order = 'desc',
  limit = 50,
} = {}) {
  try {
    if (shouldUseMockData()) {
      return {
        ...MOCK_LEADERBOARD_RESPONSE,
        buyers: MOCK_LEADERBOARD_RESPONSE.buyers.slice(0, limit),
      };
    }

    const response = await axios.get(
      `${FAIRNESS_ENGINE_BASE_URL}/aggregate/leaderboard`,
      {
        params: {
          sort,
          order,
          limit,
        },
        timeout: FAIRNESS_ENGINE_TIMEOUT_MS,
      },
    );

    return response.data;
  } catch (error) {
    console.error('Fairness engine leaderboard call failed:', error.message);
    if (shouldFallbackOnError()) {
      console.warn('Returning mock leaderboard data due to connection error.');
      return {
        ...MOCK_LEADERBOARD_RESPONSE,
        buyers: MOCK_LEADERBOARD_RESPONSE.buyers.slice(0, limit),
      };
    }
    throw error;
  }
}

module.exports = {
  computeFairnessMetrics,
  getNationalHeatmap,
  getBuyerLeaderboard,
};
