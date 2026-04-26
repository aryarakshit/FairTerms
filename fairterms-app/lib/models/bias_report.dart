/// Model representing the complete bias analysis report.
library;

/// Top-level bias report returned by GET /analysis/:id/report.
class BiasReport {
  final String analysisId;
  final int overallFairnessScore;
  final String verdict;
  final List<BiasFactor> biasFactors;
  final BenchmarkComparison benchmarkComparison;
  final FairnessMetrics fairnessMetrics;
  final StatisticalTests? statisticalTests;
  final ReportExplanation explanation;
  final InterestCalculation? interestCalculation;
  final TaxAlert? taxAlert;

  const BiasReport({
    required this.analysisId,
    required this.overallFairnessScore,
    required this.verdict,
    required this.biasFactors,
    required this.benchmarkComparison,
    required this.fairnessMetrics,
    this.statisticalTests,
    required this.explanation,
    this.interestCalculation,
    this.taxAlert,
  });

  /// Creates a [BiasReport] from a JSON map.
  factory BiasReport.fromJson(Map<String, dynamic> json) {
    return BiasReport(
      analysisId: json['analysis_id'] as String,
      overallFairnessScore: json['overall_fairness_score'] as int,
      verdict: json['verdict'] as String,
      biasFactors: (json['bias_factors'] as List<dynamic>)
          .map((e) => BiasFactor.fromJson(e as Map<String, dynamic>))
          .toList(),
      benchmarkComparison: BenchmarkComparison.fromJson(
          json['benchmark_comparison'] as Map<String, dynamic>),
      fairnessMetrics: FairnessMetrics.fromJson(
          json['fairness_metrics'] as Map<String, dynamic>),
      statisticalTests: json['statistical_tests'] != null
          ? StatisticalTests.fromJson(
              json['statistical_tests'] as Map<String, dynamic>)
          : null,
      explanation: ReportExplanation.fromJson(
          json['explanation'] as Map<String, dynamic>),
      interestCalculation: json['interest_calculation'] != null
          ? InterestCalculation.fromJson(
              json['interest_calculation'] as Map<String, dynamic>)
          : null,
      taxAlert: json['tax_alert'] != null
          ? TaxAlert.fromJson(json['tax_alert'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Converts this report to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'analysis_id': analysisId,
      'overall_fairness_score': overallFairnessScore,
      'verdict': verdict,
      'bias_factors': biasFactors.map((e) => e.toJson()).toList(),
      'benchmark_comparison': benchmarkComparison.toJson(),
      'fairness_metrics': fairnessMetrics.toJson(),
      if (statisticalTests != null)
        'statistical_tests': statisticalTests!.toJson(),
      'explanation': explanation.toJson(),
      if (interestCalculation != null)
        'interest_calculation': interestCalculation!.toJson(),
      if (taxAlert != null) 'tax_alert': taxAlert!.toJson(),
    };
  }

  /// Whether significant bias was detected.
  bool get isSignificantBias => verdict == 'significant_bias_detected';

  /// Whether moderate bias was detected.
  bool get isModerateBias => verdict == 'moderate_bias_detected';

  /// Whether the terms are fair.
  bool get isFair => verdict == 'fair';
}

/// A single factor contributing to bias in the analysis.
class BiasFactor {
  final String factor;
  final String impact;
  final double impactScore;
  final String detail;
  final String? counterfactual;

  const BiasFactor({
    required this.factor,
    required this.impact,
    required this.impactScore,
    required this.detail,
    this.counterfactual,
  });

  /// Creates a [BiasFactor] from a JSON map.
  factory BiasFactor.fromJson(Map<String, dynamic> json) {
    return BiasFactor(
      factor: json['factor'] as String,
      impact: json['impact'] as String,
      impactScore: (json['impact_score'] as num).toDouble(),
      detail: json['detail'] as String,
      counterfactual: json['counterfactual'] as String?,
    );
  }

  /// Converts this factor to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'factor': factor,
      'impact': impact,
      'impact_score': impactScore,
      'detail': detail,
      if (counterfactual != null) 'counterfactual': counterfactual,
    };
  }

  /// Returns a human-readable display name for this factor.
  String get displayName {
    return factor
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty
            ? word
            : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  /// Whether this is a high-impact factor.
  bool get isHighImpact => impact == 'high';

  /// Whether this is a medium-impact factor.
  bool get isMediumImpact => impact == 'medium';

  /// Whether this is a low-impact factor.
  bool get isLowImpact => impact == 'low';
}

/// Peer benchmark comparison data for the analysis.
class BenchmarkComparison {
  final int yourTermsDays;
  final double peerAverageDays;
  final double peerMedianDays;
  final int percentile;
  final int peersCompared;
  final Map<String, int> distribution;

  const BenchmarkComparison({
    required this.yourTermsDays,
    required this.peerAverageDays,
    required this.peerMedianDays,
    required this.percentile,
    required this.peersCompared,
    required this.distribution,
  });

  /// Creates a [BenchmarkComparison] from a JSON map.
  factory BenchmarkComparison.fromJson(Map<String, dynamic> json) {
    final rawDist = json['distribution'] as Map<String, dynamic>;
    return BenchmarkComparison(
      yourTermsDays: json['your_terms_days'] as int,
      peerAverageDays: (json['peer_average_days'] as num).toDouble(),
      peerMedianDays: (json['peer_median_days'] as num).toDouble(),
      percentile: json['percentile'] as int,
      peersCompared: json['peers_compared'] as int,
      distribution: rawDist.map((k, v) => MapEntry(k, (v as num).toInt())),
    );
  }

  /// Converts this comparison to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'your_terms_days': yourTermsDays,
      'peer_average_days': peerAverageDays,
      'peer_median_days': peerMedianDays,
      'percentile': percentile,
      'peers_compared': peersCompared,
      'distribution': distribution,
    };
  }
}

/// Formal fairness metrics for the analysis.
class FairnessMetrics {
  final double statisticalParityDifference;
  final double disparateImpactRatio;
  final double equalOpportunityDifference;
  final double? theilIndex;

  const FairnessMetrics({
    required this.statisticalParityDifference,
    required this.disparateImpactRatio,
    required this.equalOpportunityDifference,
    this.theilIndex,
  });

  /// Creates [FairnessMetrics] from a JSON map.
  factory FairnessMetrics.fromJson(Map<String, dynamic> json) {
    return FairnessMetrics(
      statisticalParityDifference:
          (json['statistical_parity_difference'] as num).toDouble(),
      disparateImpactRatio:
          (json['disparate_impact_ratio'] as num).toDouble(),
      equalOpportunityDifference:
          (json['equal_opportunity_difference'] as num).toDouble(),
      theilIndex: json['theil_index'] != null
          ? (json['theil_index'] as num).toDouble()
          : null,
    );
  }

  /// Converts these metrics to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'statistical_parity_difference': statisticalParityDifference,
      'disparate_impact_ratio': disparateImpactRatio,
      'equal_opportunity_difference': equalOpportunityDifference,
      if (theilIndex != null) 'theil_index': theilIndex,
    };
  }
}

/// Plain-language explanation section of the report.
class ReportExplanation {
  final String headline;
  final List<String> paragraphs;
  final List<KeyFinding> keyFindings;
  final List<String> actionItems;
  final WorkingCapitalImpact? workingCapitalImpact;

  const ReportExplanation({
    required this.headline,
    required this.paragraphs,
    required this.keyFindings,
    required this.actionItems,
    this.workingCapitalImpact,
  });

  /// Creates a [ReportExplanation] from a JSON map.
  factory ReportExplanation.fromJson(Map<String, dynamic> json) {
    return ReportExplanation(
      headline: json['headline'] as String,
      paragraphs: (json['paragraphs'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      keyFindings: (json['key_findings'] as List<dynamic>)
          .map((e) => KeyFinding.fromJson(e as Map<String, dynamic>))
          .toList(),
      actionItems: (json['action_items'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      workingCapitalImpact: json['working_capital_impact'] != null
          ? WorkingCapitalImpact.fromJson(
              json['working_capital_impact'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Converts this explanation to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'headline': headline,
      'paragraphs': paragraphs,
      'key_findings': keyFindings.map((e) => e.toJson()).toList(),
      'action_items': actionItems,
      if (workingCapitalImpact != null)
        'working_capital_impact': workingCapitalImpact!.toJson(),
    };
  }
}

/// A single key finding with an icon and description.
class KeyFinding {
  final String icon;
  final String title;
  final String description;

  const KeyFinding({
    required this.icon,
    required this.title,
    required this.description,
  });

  /// Creates a [KeyFinding] from a JSON map.
  factory KeyFinding.fromJson(Map<String, dynamic> json) {
    return KeyFinding(
      icon: json['icon'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
    );
  }

  /// Converts this finding to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'icon': icon,
      'title': title,
      'description': description,
    };
  }
}

/// Working capital impact data from the report.
class WorkingCapitalImpact {
  final int annualInterestCostInr;
  final String explanation;

  const WorkingCapitalImpact({
    required this.annualInterestCostInr,
    required this.explanation,
  });

  /// Creates a [WorkingCapitalImpact] from a JSON map.
  factory WorkingCapitalImpact.fromJson(Map<String, dynamic> json) {
    return WorkingCapitalImpact(
      annualInterestCostInr: json['annual_interest_cost_inr'] as int,
      explanation: json['explanation'] as String,
    );
  }

  /// Converts this impact to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'annual_interest_cost_inr': annualInterestCostInr,
      'explanation': explanation,
    };
  }
}

/// Statistical significance test results from the fairness engine.
class StatisticalTests {
  final double mannWhitneyUPvalue;
  final double chiSquarePvalue;
  final String interpretation;

  const StatisticalTests({
    required this.mannWhitneyUPvalue,
    required this.chiSquarePvalue,
    required this.interpretation,
  });

  /// Creates [StatisticalTests] from a JSON map.
  factory StatisticalTests.fromJson(Map<String, dynamic> json) {
    return StatisticalTests(
      mannWhitneyUPvalue:
          (json['mann_whitney_u_pvalue'] as num).toDouble(),
      chiSquarePvalue: (json['chi_square_pvalue'] as num).toDouble(),
      interpretation: json['interpretation'] as String,
    );
  }

  /// Converts these tests to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'mann_whitney_u_pvalue': mannWhitneyUPvalue,
      'chi_square_pvalue': chiSquarePvalue,
      'interpretation': interpretation,
    };
  }

  /// Whether results are statistically significant (p < 0.05).
  bool get isSignificant =>
      mannWhitneyUPvalue < 0.05 || chiSquarePvalue < 0.05;
}

/// A summary item for listing analyses in history/dashboard.
class AnalysisSummary {
  final String analysisId;
  final String buyerName;
  final String? createdAt;
  final int? fairnessScore;
  final String status;

  const AnalysisSummary({
    required this.analysisId,
    required this.buyerName,
    this.createdAt,
    this.fairnessScore,
    required this.status,
  });

  /// Creates an [AnalysisSummary] from a JSON map.
  factory AnalysisSummary.fromJson(Map<String, dynamic> json) {
    return AnalysisSummary(
      analysisId: json['analysis_id'] as String,
      buyerName: json['buyer_name'] as String,
      createdAt: json['created_at'] as String?,
      fairnessScore: json['fairness_score'] as int?,
      status: json['status'] as String,
    );
  }

  /// Converts this summary to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'analysis_id': analysisId,
      'buyer_name': buyerName,
      if (createdAt != null) 'created_at': createdAt,
      if (fairnessScore != null) 'fairness_score': fairnessScore,
      'status': status,
    };
  }

  /// Whether this analysis is completed.
  bool get isCompleted => status == 'completed';

  /// Whether this analysis is still processing.
  bool get isProcessing => status == 'processing';

  /// Whether this analysis has failed.
  bool get isFailed => status == 'failed';
}

/// MSMED Act Section 16 interest owed to the SME by the buyer.
class InterestCalculation {
  final int principalInr;
  final int delayDays;
  final double rbiBankRate;
  final double applicableRate;
  final int compoundInterestInr;
  final int totalOwedInr;
  final int dailyAccrualInr;
  final String legalBasis;
  final String calculatedAt;

  const InterestCalculation({
    required this.principalInr,
    required this.delayDays,
    required this.rbiBankRate,
    required this.applicableRate,
    required this.compoundInterestInr,
    required this.totalOwedInr,
    required this.dailyAccrualInr,
    required this.legalBasis,
    required this.calculatedAt,
  });

  factory InterestCalculation.fromJson(Map<String, dynamic> json) {
    return InterestCalculation(
      principalInr: (json['principal_inr'] as num).toInt(),
      delayDays: (json['delay_days'] as num).toInt(),
      rbiBankRate: (json['rbi_bank_rate'] as num).toDouble(),
      applicableRate: (json['applicable_rate'] as num).toDouble(),
      compoundInterestInr: (json['compound_interest_inr'] as num).toInt(),
      totalOwedInr: (json['total_owed_inr'] as num).toInt(),
      dailyAccrualInr: (json['daily_accrual_inr'] as num).toInt(),
      legalBasis: json['legal_basis'] as String,
      calculatedAt: json['calculated_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'principal_inr': principalInr,
      'delay_days': delayDays,
      'rbi_bank_rate': rbiBankRate,
      'applicable_rate': applicableRate,
      'compound_interest_inr': compoundInterestInr,
      'total_owed_inr': totalOwedInr,
      'daily_accrual_inr': dailyAccrualInr,
      'legal_basis': legalBasis,
      'calculated_at': calculatedAt,
    };
  }
}

/// Section 43B(h) tax-deduction alert generated for the buyer.
class TaxAlert {
  final String section;
  final int nonDeductibleAmountInr;
  final double estimatedBuyerTaxRate;
  final int taxDeductionLostInr;
  final String alertText;
  final String? noticePdfUrl;

  const TaxAlert({
    required this.section,
    required this.nonDeductibleAmountInr,
    required this.estimatedBuyerTaxRate,
    required this.taxDeductionLostInr,
    required this.alertText,
    this.noticePdfUrl,
  });

  factory TaxAlert.fromJson(Map<String, dynamic> json) {
    return TaxAlert(
      section: json['section'] as String,
      nonDeductibleAmountInr:
          (json['non_deductible_amount_inr'] as num).toInt(),
      estimatedBuyerTaxRate:
          (json['estimated_buyer_tax_rate'] as num).toDouble(),
      taxDeductionLostInr: (json['tax_deduction_lost_inr'] as num).toInt(),
      alertText: json['alert_text'] as String,
      noticePdfUrl: json['notice_pdf_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'section': section,
      'non_deductible_amount_inr': nonDeductibleAmountInr,
      'estimated_buyer_tax_rate': estimatedBuyerTaxRate,
      'tax_deduction_lost_inr': taxDeductionLostInr,
      'alert_text': alertText,
      'notice_pdf_url': noticePdfUrl,
    };
  }
}

/// Aggregated bias data for one state on the national heatmap.
class HeatmapState {
  final String state;
  final String stateCode;
  final double avgPaymentTermsDays;
  final double avgFairnessScore;
  final int totalAnalyses;
  final String biasLevel;

  const HeatmapState({
    required this.state,
    required this.stateCode,
    required this.avgPaymentTermsDays,
    required this.avgFairnessScore,
    required this.totalAnalyses,
    required this.biasLevel,
  });

  factory HeatmapState.fromJson(Map<String, dynamic> json) {
    return HeatmapState(
      state: json['state'] as String,
      stateCode: json['state_code'] as String,
      avgPaymentTermsDays:
          (json['avg_payment_terms_days'] as num).toDouble(),
      avgFairnessScore: (json['avg_fairness_score'] as num).toDouble(),
      totalAnalyses: (json['total_analyses'] as num).toInt(),
      biasLevel: json['bias_level'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'state': state,
      'state_code': stateCode,
      'avg_payment_terms_days': avgPaymentTermsDays,
      'avg_fairness_score': avgFairnessScore,
      'total_analyses': totalAnalyses,
      'bias_level': biasLevel,
    };
  }

  /// Whether this state is classified as fair.
  bool get isFair => biasLevel == 'fair';

  /// Whether this state is classified as moderate bias.
  bool get isModerate => biasLevel == 'moderate';

  /// Whether this state is classified as severe bias.
  bool get isSevere => biasLevel == 'severe';
}

/// Full heatmap response with per-state stats.
class HeatmapData {
  final List<HeatmapState> states;
  final String industryFilter;
  final String? lastUpdated;

  const HeatmapData({
    required this.states,
    required this.industryFilter,
    this.lastUpdated,
  });

  factory HeatmapData.fromJson(Map<String, dynamic> json) {
    return HeatmapData(
      states: (json['states'] as List<dynamic>)
          .map((e) => HeatmapState.fromJson(e as Map<String, dynamic>))
          .toList(),
      industryFilter: json['industry_filter'] as String? ?? 'all',
      lastUpdated: json['last_updated'] as String?,
    );
  }
}

/// A single ranked buyer on the fairness leaderboard.
class LeaderboardEntry {
  final String buyerName;
  final int fairnessScore;
  final double avgPaymentTermsDays;
  final int totalSmesServed;
  final int rank;
  final String badge;

  const LeaderboardEntry({
    required this.buyerName,
    required this.fairnessScore,
    required this.avgPaymentTermsDays,
    required this.totalSmesServed,
    required this.rank,
    required this.badge,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      buyerName: json['buyer_name'] as String,
      fairnessScore: (json['fairness_score'] as num).toInt(),
      avgPaymentTermsDays:
          (json['avg_payment_terms_days'] as num).toDouble(),
      totalSmesServed: (json['total_smes_served'] as num).toInt(),
      rank: (json['rank'] as num).toInt(),
      badge: json['badge'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'buyer_name': buyerName,
      'fairness_score': fairnessScore,
      'avg_payment_terms_days': avgPaymentTermsDays,
      'total_smes_served': totalSmesServed,
      'rank': rank,
      'badge': badge,
    };
  }

  bool get isGold => badge == 'gold';
  bool get isSilver => badge == 'silver';
  bool get isBronze => badge == 'bronze';
  bool get isRedFlag => badge == 'red_flag';
}

/// Full leaderboard response.
class LeaderboardData {
  final List<LeaderboardEntry> buyers;
  final int totalBuyers;
  final String? lastUpdated;

  const LeaderboardData({
    required this.buyers,
    required this.totalBuyers,
    this.lastUpdated,
  });

  factory LeaderboardData.fromJson(Map<String, dynamic> json) {
    return LeaderboardData(
      buyers: (json['buyers'] as List<dynamic>)
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalBuyers: (json['total_buyers'] as num?)?.toInt() ??
          (json['buyers'] as List<dynamic>).length,
      lastUpdated: json['last_updated'] as String?,
    );
  }
}
