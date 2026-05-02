/// API service for all FairTerms backend calls.
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sme_profile.dart';
import '../models/analysis_request.dart';
import '../models/bias_report.dart';
import '../models/grievance.dart';
import '../utils/constants.dart';
import 'auth_service.dart';

/// Custom exception for API errors returned by the FairTerms backend.
class ApiException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;

  const ApiException({
    required this.message,
    this.code,
    this.statusCode,
  });

  @override
  String toString() =>
      'ApiException(code: $code, status: $statusCode): $message';
}

/// Singleton service that handles all HTTP communication with the FairTerms API.
///
/// Automatically attaches the Firebase ID token as a Bearer token to every request.
class ApiService {
  ApiService._();

  static final ApiService _instance = ApiService._();

  /// Singleton instance of [ApiService].
  static ApiService get instance => _instance;

  final http.Client _client = http.Client();

  /// Closes the underlying HTTP client. Call when the app is terminating.
  void dispose() => _client.close();

  /// Builds the full URL for the given [path].
  Uri _buildUri(String path) => Uri.parse('${AppConstants.apiBaseUrl}$path');

  /// When true, we use bundled mock data instead of calling the real API.
  /// This happens if debug mode is active OR if no user is signed in (Guest Mode).
  bool get _shouldUseOffline =>
      AppConstants.debugOfflineMode || !AuthService.instance.isSignedIn;

  /// Returns the Authorization header with the current user's ID token.
  /// Throws [ApiException] if the user is not authenticated.
  Future<Map<String, String>> _buildHeaders() async {
    final token = await AuthService.instance.getIdToken();
    if (token == null) {
      throw const ApiException(
        message: 'Sign in required to access this feature.',
        code: 'AUTH_REQUIRED',
        statusCode: 401,
      );
    }
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Parses an API response and throws [ApiException] if the request failed.
  Map<String, dynamic> _parseResponse(http.Response response) {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw ApiException(
        message: 'Server returned an invalid response. Please try again later.',
        code: 'INVALID_JSON',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final success = body['success'] as bool? ?? false;
      if (success) {
        return body['data'] as Map<String, dynamic>? ?? body;
      }
    }

    throw ApiException(
      message: body['message'] as String? ??
          body['error'] as String? ??
          'Unknown API error',
      code: body['error'] as String? ?? body['code'] as String?,
      statusCode: response.statusCode,
    );
  }

  /// Creates a new SME profile.
  ///
  /// Returns the profile ID and created_at timestamp.
  Future<Map<String, dynamic>> createProfile(SmeProfile profile) async {
    if (_shouldUseOffline) {
      return {
        'profile_id': 'offline_profile_123',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };
    }
    final headers = await _buildHeaders();
    final response = await _client.post(
      _buildUri('/sme/profile'),
      headers: headers,
      body: jsonEncode(profile.toJson()),
    );
    return _parseResponse(response);
  }

  /// Fetches the current user's own most-recent profile.
  /// Returns null when no profile exists yet (404) or in offline mode.
  Future<SmeProfile?> getMyProfile() async {
    if (_shouldUseOffline) return null;
    final headers = await _buildHeaders();
    final response = await _client
        .get(_buildUri('/sme/profile/me'), headers: headers)
        .timeout(const Duration(seconds: 6));
    if (response.statusCode == 404) return null;
    final data = _parseResponse(response);
    return SmeProfile.fromJson(data);
  }

  /// Fetches an SME profile by [profileId].
  Future<SmeProfile> getProfile(String profileId) async {
    if (_shouldUseOffline) {
      return SmeProfile(
        profileId: profileId,
        businessName: 'Offline Demo Business',
        ownerName: 'Guest User',
        pincode: '400001',
        city: 'Mumbai',
        state: 'Maharashtra',
        industry: 'manufacturing',
        annualRevenueInr: 50000000,
        employeeCount: 25,
        yearsInOperation: 5,
        createdAt: DateTime.now().toUtc().toIso8601String(),
      );
    }
    final headers = await _buildHeaders();
    final response = await _client.get(
      _buildUri('/sme/profile/$profileId'),
      headers: headers,
    );
    final data = _parseResponse(response);
    return SmeProfile.fromJson(data);
  }

  /// Runs a bias analysis for the given [request].
  ///
  /// Returns the [AnalysisRunResponse] containing the analysis ID and initial status.
  Future<AnalysisRunResponse> runAnalysis(AnalysisRequest request) async {
    if (_shouldUseOffline) {
      return const AnalysisRunResponse(
        analysisId: 'offline_1',
        status: 'completed',
      );
    }
    final headers = await _buildHeaders();
    final response = await _client.post(
      _buildUri('/analysis/run'),
      headers: headers,
      body: jsonEncode(request.toJson()),
    );
    final data = _parseResponse(response);
    return AnalysisRunResponse.fromJson(data);
  }

  /// Polls the status of an analysis by [analysisId].
  Future<AnalysisStatusResponse> getAnalysisStatus(String analysisId) async {
    if (_shouldUseOffline || analysisId.startsWith('offline_')) {
      return AnalysisStatusResponse(
        analysisId: analysisId,
        status: 'completed',
      );
    }
    final headers = await _buildHeaders();
    final response = await _client.get(
      _buildUri('/analysis/$analysisId/status'),
      headers: headers,
    );
    final data = _parseResponse(response);
    return AnalysisStatusResponse.fromJson(data);
  }

  /// Fetches the full bias report for a completed analysis.
  ///
  /// Only call this after the analysis status is "completed".
  Future<BiasReport> getAnalysisReport(String analysisId) async {
    if (_shouldUseOffline || analysisId.startsWith('offline_')) return offlineReport(analysisId);
    final headers = await _buildHeaders();
    final response = await _client
        .get(
          _buildUri('/analysis/$analysisId/report'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 6));
    final data = _parseResponse(response);
    return BiasReport.fromJson(data);
  }

  /// Fetches grievance letter and RTI template for an analysis.
  Future<GrievanceData> getGrievanceData(String analysisId) async {
    if (_shouldUseOffline || analysisId.startsWith('offline_')) return offlineGrievanceData();
    final headers = await _buildHeaders();
    final response = await _client.get(
      _buildUri('/analysis/$analysisId/grievance'),
      headers: headers,
    );
    final data = _parseResponse(response);
    return GrievanceData.fromJson(data);
  }

  /// Fetches a list of all past analyses for the current user.
  ///
  /// Returns a list of [AnalysisSummary] objects sorted by date descending.
  Future<List<AnalysisSummary>> getAnalysisHistory() async {
    if (_shouldUseOffline) return offlineHistory();
    final headers = await _buildHeaders();
    final response = await _client
        .get(
          _buildUri('/analysis/history'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 6));

    final Map<String, dynamic> body =
        jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final success = body['success'] as bool? ?? false;
      if (success) {
        final data = body['data'];
        if (data is List) {
          return data
              .map((e) => AnalysisSummary.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    }

    throw ApiException(
      message: body['error'] as String? ?? 'Failed to fetch history',
      code: body['code'] as String?,
      statusCode: response.statusCode,
    );
  }

  /// Permanently deletes all analyses for the current user.
  /// Returns the number of records removed.
  Future<int> clearAnalysisHistory() async {
    if (_shouldUseOffline) return 0;
    final headers = await _buildHeaders();
    final response = await _client.delete(
      _buildUri('/analysis/history'),
      headers: headers,
    );
    final data = _parseResponse(response);
    return (data['deleted'] as num?)?.toInt() ?? 0;
  }

  List<AnalysisSummary> offlineHistory() {
    return [
      AnalysisSummary(
        analysisId: 'offline_1',
        buyerName: 'Reliance Retail',
        status: 'completed',
        createdAt: DateTime.now()
            .subtract(const Duration(days: 2))
            .toUtc()
            .toIso8601String(),
        fairnessScore: 18,
      ),
      AnalysisSummary(
        analysisId: 'offline_2',
        buyerName: 'Tata Motors',
        status: 'completed',
        createdAt: DateTime.now()
            .subtract(const Duration(days: 5))
            .toUtc()
            .toIso8601String(),
        fairnessScore: 58,
      ),
      AnalysisSummary(
        analysisId: 'offline_3',
        buyerName: 'Infosys',
        status: 'completed',
        createdAt: DateTime.now()
            .subtract(const Duration(days: 10))
            .toUtc()
            .toIso8601String(),
        fairnessScore: 82,
      ),
    ];
  }

  /// Fetches aggregated national bias heatmap data.
  ///
  /// [industry] filters by a specific industry, or 'all' for unfiltered.
  Future<HeatmapData> getHeatmap({String industry = 'all'}) async {
    if (_shouldUseOffline) return offlineHeatmap(industry);
    final headers = await _buildHeaders();
    final response = await _client
        .get(
          _buildUri('/heatmap/national?industry=$industry'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 6));
    final data = _parseResponse(response);
    return HeatmapData.fromJson(data);
  }

  /// Fetches the buyer fairness leaderboard.
  Future<LeaderboardData> getLeaderboard({
    String sort = 'fairness_score',
    String order = 'desc',
    int limit = 50,
  }) async {
    if (_shouldUseOffline) return offlineLeaderboard(limit);
    final headers = await _buildHeaders();
    final response = await _client
        .get(
          _buildUri('/leaderboard?sort=$sort&order=$order&limit=$limit'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 6));
    final data = _parseResponse(response);
    return LeaderboardData.fromJson(data);
  }

  BiasReport offlineReport(String analysisId) {
    return BiasReport(
      analysisId: analysisId,
      buyerName: 'Reliance Retail',
      overallFairnessScore: 42,
      verdict: 'significant_bias_detected',
      biasFactors: [
        const BiasFactor(
          factor: 'extended_credit_period',
          impact: 'high',
          impactScore: -25,
          detail:
              'Payment terms are unilaterally set to 75 days, which significantly exceeds the MSME standard of 45 days.',
        ),
        const BiasFactor(
          factor: 'late_payment_interest_waiver',
          impact: 'medium',
          impactScore: -12,
          detail:
              'Contract lacks explicit provision for mandatory statutory interest on late payments.',
        ),
      ],
      benchmarkComparison: const BenchmarkComparison(
        yourTermsDays: 75,
        peerAverageDays: 48.5,
        peerMedianDays: 45.0,
        percentile: 15,
        peersCompared: 124,
        distribution: {
          '0-30': 18,
          '31-45': 42,
          '46-60': 35,
          '61-90': 21,
          '90+': 8
        },
      ),
      fairnessMetrics: const FairnessMetrics(
        statisticalParityDifference: 0.32,
        disparateImpactRatio: 0.65,
        equalOpportunityDifference: 0.28,
      ),
      explanation: const ReportExplanation(
        headline: 'Significant payment bias detected against your business.',
        paragraphs: [
          'Your payment terms of 75 days are substantially longer than the industry average of 48.5 days.',
          'Under the MSMED Act 2006, buyers are required to make payment within 45 days of acceptance.',
        ],
        keyFindings: [
          KeyFinding(
            icon: '⚠️',
            title: 'Extended Credit Period',
            description:
                'Payment terms exceed the MSME statutory limit by 30 days.',
          ),
          KeyFinding(
            icon: '📉',
            title: 'Working Capital Impact',
            description:
                'The extended terms cost approximately ₹1.8L in annual interest.',
          ),
        ],
        actionItems: [
          'Renegotiate the payment cycle to 45 days to align with MSME guidelines.',
          'Include a clear late payment interest clause as per MSMED Act, 2006.',
        ],
      ),
    );
  }

  HeatmapData offlineHeatmap(String industry) {
    const samples = <Map<String, dynamic>>[
      {
        'state': 'Bihar',
        'state_code': 'BR',
        'avg_payment_terms_days': 103.2,
        'avg_fairness_score': 18.0,
        'total_analyses': 62,
        'bias_level': 'severe'
      },
      {
        'state': 'Jharkhand',
        'state_code': 'JH',
        'avg_payment_terms_days': 100.1,
        'avg_fairness_score': 22.0,
        'total_analyses': 48,
        'bias_level': 'severe'
      },
      {
        'state': 'Uttar Pradesh',
        'state_code': 'UP',
        'avg_payment_terms_days': 95.3,
        'avg_fairness_score': 28.0,
        'total_analyses': 74,
        'bias_level': 'severe'
      },
      {
        'state': 'Odisha',
        'state_code': 'OR',
        'avg_payment_terms_days': 89.7,
        'avg_fairness_score': 32.0,
        'total_analyses': 41,
        'bias_level': 'severe'
      },
      {
        'state': 'West Bengal',
        'state_code': 'WB',
        'avg_payment_terms_days': 83.7,
        'avg_fairness_score': 36.0,
        'total_analyses': 55,
        'bias_level': 'severe'
      },
      {
        'state': 'Rajasthan',
        'state_code': 'RJ',
        'avg_payment_terms_days': 72.4,
        'avg_fairness_score': 44.0,
        'total_analyses': 38,
        'bias_level': 'moderate'
      },
      {
        'state': 'Gujarat',
        'state_code': 'GJ',
        'avg_payment_terms_days': 64.1,
        'avg_fairness_score': 52.0,
        'total_analyses': 66,
        'bias_level': 'moderate'
      },
      {
        'state': 'Tamil Nadu',
        'state_code': 'TN',
        'avg_payment_terms_days': 58.0,
        'avg_fairness_score': 58.0,
        'total_analyses': 72,
        'bias_level': 'moderate'
      },
      {
        'state': 'Kerala',
        'state_code': 'KL',
        'avg_payment_terms_days': 60.5,
        'avg_fairness_score': 59.0,
        'total_analyses': 34,
        'bias_level': 'moderate'
      },
      {
        'state': 'Karnataka',
        'state_code': 'KA',
        'avg_payment_terms_days': 56.3,
        'avg_fairness_score': 64.0,
        'total_analyses': 91,
        'bias_level': 'moderate'
      },
      {
        'state': 'Haryana',
        'state_code': 'HR',
        'avg_payment_terms_days': 55.9,
        'avg_fairness_score': 66.0,
        'total_analyses': 29,
        'bias_level': 'moderate'
      },
      {
        'state': 'Maharashtra',
        'state_code': 'MH',
        'avg_payment_terms_days': 52.8,
        'avg_fairness_score': 70.0,
        'total_analyses': 112,
        'bias_level': 'fair'
      },
      {
        'state': 'Telangana',
        'state_code': 'TG',
        'avg_payment_terms_days': 52.3,
        'avg_fairness_score': 71.0,
        'total_analyses': 47,
        'bias_level': 'fair'
      },
      {
        'state': 'Delhi',
        'state_code': 'DL',
        'avg_payment_terms_days': 47.7,
        'avg_fairness_score': 76.0,
        'total_analyses': 88,
        'bias_level': 'fair'
      },
    ];
    return HeatmapData(
      states: samples.map(HeatmapState.fromJson).toList(),
      industryFilter: industry,
      lastUpdated: DateTime.now().toUtc().toIso8601String(),
    );
  }

  LeaderboardData offlineLeaderboard(int limit) {
    const entries = <Map<String, dynamic>>[
      {
        'buyer_name': 'Infosys',
        'fairness_score': 82,
        'avg_payment_terms_days': 55.3,
        'total_smes_served': 84,
        'rank': 1,
        'badge': 'gold'
      },
      {
        'buyer_name': 'Bharti Airtel',
        'fairness_score': 74,
        'avg_payment_terms_days': 59.8,
        'total_smes_served': 71,
        'rank': 2,
        'badge': 'silver'
      },
      {
        'buyer_name': 'Asian Paints',
        'fairness_score': 69,
        'avg_payment_terms_days': 60.5,
        'total_smes_served': 63,
        'rank': 3,
        'badge': 'silver'
      },
      {
        'buyer_name': 'Wipro',
        'fairness_score': 67,
        'avg_payment_terms_days': 60.5,
        'total_smes_served': 58,
        'rank': 4,
        'badge': 'silver'
      },
      {
        'buyer_name': 'Hindustan Unilever',
        'fairness_score': 63,
        'avg_payment_terms_days': 61.6,
        'total_smes_served': 92,
        'rank': 5,
        'badge': 'silver'
      },
      {
        'buyer_name': 'Tata Motors',
        'fairness_score': 58,
        'avg_payment_terms_days': 63.1,
        'total_smes_served': 79,
        'rank': 6,
        'badge': 'bronze'
      },
      {
        'buyer_name': 'ITC Ltd',
        'fairness_score': 54,
        'avg_payment_terms_days': 65.4,
        'total_smes_served': 66,
        'rank': 7,
        'badge': 'bronze'
      },
      {
        'buyer_name': 'Bajaj Auto',
        'fairness_score': 50,
        'avg_payment_terms_days': 67.2,
        'total_smes_served': 45,
        'rank': 8,
        'badge': 'bronze'
      },
      {
        'buyer_name': 'Godrej Consumer',
        'fairness_score': 46,
        'avg_payment_terms_days': 68.9,
        'total_smes_served': 52,
        'rank': 9,
        'badge': 'bronze'
      },
      {
        'buyer_name': 'Mahindra & Mahindra',
        'fairness_score': 42,
        'avg_payment_terms_days': 69.8,
        'total_smes_served': 61,
        'rank': 10,
        'badge': 'bronze'
      },
      {
        'buyer_name': 'Maruti Suzuki',
        'fairness_score': 35,
        'avg_payment_terms_days': 70.3,
        'total_smes_served': 88,
        'rank': 11,
        'badge': 'red_flag'
      },
      {
        'buyer_name': 'Larsen & Toubro',
        'fairness_score': 32,
        'avg_payment_terms_days': 71.8,
        'total_smes_served': 73,
        'rank': 12,
        'badge': 'red_flag'
      },
      {
        'buyer_name': 'Adani Enterprises',
        'fairness_score': 28,
        'avg_payment_terms_days': 72.1,
        'total_smes_served': 67,
        'rank': 13,
        'badge': 'red_flag'
      },
      {
        'buyer_name': 'Flipkart',
        'fairness_score': 24,
        'avg_payment_terms_days': 73.3,
        'total_smes_served': 94,
        'rank': 14,
        'badge': 'red_flag'
      },
      {
        'buyer_name': 'Reliance Retail',
        'fairness_score': 18,
        'avg_payment_terms_days': 87.1,
        'total_smes_served': 118,
        'rank': 15,
        'badge': 'red_flag'
      },
    ];
    final limited = entries.take(limit).map(LeaderboardEntry.fromJson).toList();
    return LeaderboardData(
      buyers: limited,
      totalBuyers: entries.length,
      lastUpdated: DateTime.now().toUtc().toIso8601String(),
    );
  }

  GrievanceData offlineGrievanceData() {
    return const GrievanceData(
      grievanceLetter: GrievanceLetter(
        subject: 'Formal Grievance: Violation of MSMED Act, 2006',
        body: 'Dear Procurement Team,\n\nWe are writing to formally flag that the '
            'payment terms of 75 days in the recent contract for India '
            'Operations exceed the statutory limit of 45 days mandated by '
            'the MSMED Act, 2006. We request an immediate revision to align '
            'with the law.',
      ),
      rtiTemplate: RtiTemplate(
        subject: 'RTI Application: MSME Payment Compliance',
        body: 'Under the Right to Information Act, we request disclosure of '
            'all pending payments to MSME vendors that have exceeded 45 days '
            'as of the last financial quarter.',
        applicable: true,
      ),
      legalReferences: [
        'Section 15, MSMED Act 2006',
        'Section 16, MSMED Act 2006 (Interest on delayed payments)',
      ],
    );
  }
}
