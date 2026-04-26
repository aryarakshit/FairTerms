/// Model representing an analysis run request and its response.
library;

/// Request payload for POST /analysis/run.
class AnalysisRequest {
  final String profileId;
  final String buyerName;
  final String buyerType;
  final String buyerAddress;
  final int paymentTermsDays;
  final int orderValueInr;
  final String paymentTermsOfferedToSme;
  final int smePaymentToSuppliersDays;
  final double interestRateOnShortTermLoan;
  final String? additionalContext;

  const AnalysisRequest({
    required this.profileId,
    required this.buyerName,
    required this.buyerType,
    required this.buyerAddress,
    required this.paymentTermsDays,
    required this.orderValueInr,
    required this.paymentTermsOfferedToSme,
    required this.smePaymentToSuppliersDays,
    required this.interestRateOnShortTermLoan,
    this.additionalContext,
  });

  /// Converts this request to a JSON map for the API.
  Map<String, dynamic> toJson() {
    return {
      'profile_id': profileId,
      'buyer_name': buyerName,
      'buyer_type': buyerType,
      'buyer_address': buyerAddress,
      'payment_terms_days': paymentTermsDays,
      'order_value_inr': orderValueInr,
      'payment_terms_offered_to_sme': paymentTermsOfferedToSme,
      'sme_payment_to_suppliers_days': smePaymentToSuppliersDays,
      'interest_rate_on_short_term_loan': interestRateOnShortTermLoan,
      if (additionalContext != null && additionalContext!.isNotEmpty)
        'additional_context': additionalContext,
    };
  }
}

/// Response from POST /analysis/run.
class AnalysisRunResponse {
  final String analysisId;
  final String status;
  final int? estimatedTimeSeconds;

  const AnalysisRunResponse({
    required this.analysisId,
    required this.status,
    this.estimatedTimeSeconds,
  });

  /// Creates an [AnalysisRunResponse] from a JSON map.
  factory AnalysisRunResponse.fromJson(Map<String, dynamic> json) {
    return AnalysisRunResponse(
      analysisId: json['analysis_id'] as String,
      status: json['status'] as String,
      estimatedTimeSeconds: json['estimated_time_seconds'] as int?,
    );
  }
}

/// Response from GET /analysis/:id/status.
class AnalysisStatusResponse {
  final String analysisId;
  final String status;
  final String? completedAt;

  const AnalysisStatusResponse({
    required this.analysisId,
    required this.status,
    this.completedAt,
  });

  /// Creates an [AnalysisStatusResponse] from a JSON map.
  factory AnalysisStatusResponse.fromJson(Map<String, dynamic> json) {
    return AnalysisStatusResponse(
      analysisId: json['analysis_id'] as String,
      status: json['status'] as String,
      completedAt: json['completed_at'] as String?,
    );
  }

  /// Whether this analysis has completed successfully.
  bool get isCompleted => status == 'completed';

  /// Whether this analysis is still processing.
  bool get isProcessing => status == 'processing';

  /// Whether this analysis has failed.
  bool get isFailed => status == 'failed';
}
