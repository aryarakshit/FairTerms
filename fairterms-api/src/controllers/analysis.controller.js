const firestoreService = require('../services/firestore.service');
const fairnessService = require('../services/fairness.service');
const geminiService = require('../services/gemini.service');
const reportEnrichmentService = require('../services/report-enrichment.service');

/**
 * Merges outputs from Gemini and the fairness engine into the final report shape.
 */
function mergeAnalysisResults(fairnessMetrics, agentResults, paymentTerms) {
  const { biasResults = {}, report = {}, grievance = {} } = agentResults;
  const benchmark = fairnessMetrics.benchmark || {};
  const metrics = fairnessMetrics.fairness_metrics || {};
  const counterfactuals = biasResults.counterfactuals || [];
  const factorMap = {
    pincode_region: 'location',
    industry: 'industry',
    firm_size: 'scale',
    firm_age: 'firm_age',
    state: 'region',
  };

  const mergedBiasFactors = (fairnessMetrics.bias_factors || []).map((factor) => {
    const agentVariable = factorMap[factor.factor];
    if (!agentVariable) {
      return {
        factor: factor.factor,
        impact: 'low',
        impact_score: 0,
        detail: 'Unmapped factor',
        counterfactual: null,
      };
    }
    const counterfactual = counterfactuals.find(
      (candidate) => candidate.variable_changed === agentVariable,
    );
    const detail = counterfactual
      ? [factor.detail, counterfactual.reasoning].filter(Boolean).join(' ')
      : factor.detail || '';

    return {
      factor: factor.factor,
      impact: factor.impact || 'low',
      impact_score: factor.impact_score || 0,
      detail,
      counterfactual: counterfactual
        ? `If ${counterfactual.variable_changed} were ${counterfactual.counterfactual_value}, estimated terms would be Net ${counterfactual.estimated_terms_days} instead of Net ${counterfactual.original_terms_days}`
        : null,
    };
  });

  const rawBias = Number(biasResults.overall_bias_score);
  const biasScore = Number.isFinite(rawBias) ? rawBias : 0.5;
  const overallFairnessScore = Math.max(0, Math.min(100, 100 - Math.round(biasScore * 100)));
  const verdict = biasScore > 0.65
    ? 'significant_bias_detected'
    : biasScore > 0.35
      ? 'moderate_bias_detected'
      : 'fair';

  return {
    overall_fairness_score: overallFairnessScore,
    verdict,
    bias_factors: mergedBiasFactors,
    benchmark_comparison: {
      your_terms_days: paymentTerms.payment_terms_days || 0,
      peer_average_days: benchmark.average_terms_days || 0,
      peer_median_days: benchmark.median_terms_days || 0,
      percentile: Math.round(benchmark.percentile || 0),
      peers_compared: benchmark.peers_found || 0,
      distribution: benchmark.distribution || {},
    },
    fairness_metrics: {
      statistical_parity_difference: metrics.statistical_parity_difference,
      disparate_impact_ratio: metrics.disparate_impact_ratio,
      equal_opportunity_difference: metrics.equal_opportunity_difference,
      theil_index: metrics.theil_index,
    },
    statistical_tests: fairnessMetrics.statistical_tests,
    explanation: {
      headline: report.headline,
      paragraphs: report.explanation_paragraphs || report.paragraphs || [],
      key_findings: report.key_findings || [],
      action_items: report.action_items || [],
      working_capital_impact: report.working_capital_impact || null,
    },
    grievance: { ...grievance },
    interest_calculation: reportEnrichmentService.buildInterestCalculation(paymentTerms),
    tax_alert: reportEnrichmentService.buildTaxAlert(paymentTerms),
  };
}

/**
 * POST /analysis/run
 * Trigger the full bias-analysis pipeline.
 */
async function runAnalysis(req, res) {
  const { profile_id, ...paymentTerms } = req.body;

  try {
    const smeProfile = await firestoreService.getOwnedSMEProfile(profile_id, req.user.uid);
    if (!smeProfile) {
      return res.status(404).json({
        success: false,
        error: 'NOT_FOUND',
        message: 'SME profile not found',
      });
    }

    const analysisId = await firestoreService.createAnalysis({
      profile_id,
      user_id: req.user.uid,
      buyer_info: {
        name: paymentTerms.buyer_name,
        type: paymentTerms.buyer_type,
        address: paymentTerms.buyer_address,
      },
      payment_terms: paymentTerms,
      status: 'processing',
    });

    (async () => {
      try {
        const fairnessMetrics = await fairnessService.computeFairnessMetrics(
          smeProfile,
          paymentTerms,
        );
        const agentResults = await geminiService.runMultiAgentPipeline(
          smeProfile,
          paymentTerms,
          fairnessMetrics,
        );
        const finalReport = mergeAnalysisResults(
          fairnessMetrics,
          agentResults,
          paymentTerms,
        );

        await firestoreService.updateAnalysis(analysisId, {
          ...finalReport,
          status: 'completed',
          completed_at: new Date().toISOString(),
        });
      } catch (error) {
        console.error(`Analysis ${analysisId} failed:`, error);
        await firestoreService.updateAnalysis(analysisId, {
          status: 'failed',
          error: error.message,
        });
      }
    })().catch((err) => {
      console.error(`Analysis ${analysisId} unhandled pipeline error:`, err);
    });

    return res.status(202).json({
      success: true,
      data: {
        analysis_id: analysisId,
        status: 'processing',
        estimated_time_seconds: 15,
      },
    });
  } catch (error) {
    console.error('runAnalysis controller failed:', error);
    return res.status(500).json({ success: false, error: 'INTERNAL_ERROR' });
  }
}

/**
 * GET /analysis/:id/status
 */
async function getAnalysisStatus(req, res) {
  const { id } = req.params;

  try {
    const analysis = await firestoreService.getOwnedAnalysis(id, req.user.uid);
    if (!analysis) {
      return res.status(404).json({ success: false, error: 'NOT_FOUND' });
    }

    return res.json({
      success: true,
      data: {
        analysis_id: analysis.analysis_id,
        status: analysis.status,
        completed_at: analysis.completed_at,
      },
    });
  } catch (error) {
    return res.status(500).json({ success: false, error: 'INTERNAL_ERROR' });
  }
}

/**
 * GET /analysis/:id/report
 */
async function getAnalysisReport(req, res) {
  const { id } = req.params;

  try {
    const analysis = await firestoreService.getOwnedAnalysis(id, req.user.uid);
    if (!analysis) {
      return res.status(404).json({ success: false, error: 'NOT_FOUND' });
    }
    if (analysis.status !== 'completed') {
      return res.status(400).json({
        success: false,
        error: 'ANALYSIS_NOT_READY',
        status: analysis.status,
      });
    }

    return res.json({
      success: true,
      data: {
        analysis_id: analysis.analysis_id,
        overall_fairness_score: analysis.overall_fairness_score,
        verdict: analysis.verdict,
        bias_factors: analysis.bias_factors,
        benchmark_comparison: analysis.benchmark_comparison,
        fairness_metrics: analysis.fairness_metrics,
        statistical_tests: analysis.statistical_tests,
        explanation: analysis.explanation,
        interest_calculation: analysis.interest_calculation || null,
        tax_alert: analysis.tax_alert || null,
      },
    });
  } catch (error) {
    return res.status(500).json({ success: false, error: 'INTERNAL_ERROR' });
  }
}

/**
 * GET /analysis/history
 * Returns all past analyses for the authenticated user.
 */
async function getAnalysisHistory(req, res) {
  try {
    const analyses = await firestoreService.getAnalysesByUser(req.user.uid);
    const data = analyses.map((analysis) => ({
      analysis_id: analysis.analysis_id,
      buyer_name: analysis.buyer_info?.name || '',
      created_at: analysis.created_at?.toDate
        ? analysis.created_at.toDate().toISOString()
        : (analysis.created_at || null),
      fairness_score: analysis.overall_fairness_score ?? null,
      status: analysis.status,
    }));

    return res.json({ success: true, data });
  } catch (error) {
    console.error('getAnalysisHistory failed:', error);
    return res.status(500).json({ success: false, error: 'INTERNAL_ERROR' });
  }
}

/**
 * DELETE /analysis/history
 * Permanently deletes every analysis owned by the authenticated user.
 */
async function clearAnalysisHistory(req, res) {
  try {
    const removed = await firestoreService.deleteAnalysesByUser(req.user.uid);
    return res.json({ success: true, data: { deleted: removed } });
  } catch (error) {
    console.error('clearAnalysisHistory failed:', error);
    return res.status(500).json({ success: false, error: 'INTERNAL_ERROR' });
  }
}

module.exports = {
  runAnalysis,
  getAnalysisStatus,
  getAnalysisReport,
  getAnalysisHistory,
  clearAnalysisHistory,
};
