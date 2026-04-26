/// Admin API service — only callable by users with admin: true Firebase claim.
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'auth_service.dart';
import 'api_service.dart' show ApiException;

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

class AdminStats {
  final int totalAnalyses;
  final int completedAnalyses;
  final int processingAnalyses;
  final int failedAnalyses;
  final int totalProfiles;
  final int uniqueUsers;
  final int? avgFairnessScore;
  final String generatedAt;

  const AdminStats({
    required this.totalAnalyses,
    required this.completedAnalyses,
    required this.processingAnalyses,
    required this.failedAnalyses,
    required this.totalProfiles,
    required this.uniqueUsers,
    required this.avgFairnessScore,
    required this.generatedAt,
  });

  factory AdminStats.fromJson(Map<String, dynamic> j) => AdminStats(
        totalAnalyses: j['total_analyses'] as int? ?? 0,
        completedAnalyses: j['completed_analyses'] as int? ?? 0,
        processingAnalyses: j['processing_analyses'] as int? ?? 0,
        failedAnalyses: j['failed_analyses'] as int? ?? 0,
        totalProfiles: j['total_profiles'] as int? ?? 0,
        uniqueUsers: j['unique_users'] as int? ?? 0,
        avgFairnessScore: j['avg_fairness_score'] as int?,
        generatedAt: j['generated_at'] as String? ?? '',
      );
}

class AdminAnalysis {
  final String analysisId;
  final String userId;
  final String buyerName;
  final String buyerType;
  final String status;
  final int? fairnessScore;
  final String? verdict;
  final String? createdAt;

  const AdminAnalysis({
    required this.analysisId,
    required this.userId,
    required this.buyerName,
    required this.buyerType,
    required this.status,
    required this.fairnessScore,
    required this.verdict,
    required this.createdAt,
  });

  factory AdminAnalysis.fromJson(Map<String, dynamic> j) => AdminAnalysis(
        analysisId: j['analysis_id'] as String? ?? '',
        userId: j['user_id'] as String? ?? '',
        buyerName: j['buyer_name'] as String? ?? '',
        buyerType: j['buyer_type'] as String? ?? '',
        status: j['status'] as String? ?? '',
        fairnessScore: j['fairness_score'] as int?,
        verdict: j['verdict'] as String?,
        createdAt: j['created_at'] as String?,
      );
}

class AdminAnalysesResponse {
  final List<AdminAnalysis> analyses;
  final int total;

  const AdminAnalysesResponse({required this.analyses, required this.total});
}

class SystemHealth {
  final String api;
  final String fairnessEngine;
  final String gemini;
  final String firestore;
  final String mockAuth;
  final String nodeEnv;
  final int uptimeSeconds;
  final int memoryMb;

  const SystemHealth({
    required this.api,
    required this.fairnessEngine,
    required this.gemini,
    required this.firestore,
    required this.mockAuth,
    required this.nodeEnv,
    required this.uptimeSeconds,
    required this.memoryMb,
  });

  factory SystemHealth.fromJson(Map<String, dynamic> j) => SystemHealth(
        api: j['api'] as String? ?? 'unknown',
        fairnessEngine: j['fairness_engine'] as String? ?? 'unknown',
        gemini: j['gemini'] as String? ?? 'unknown',
        firestore: j['firestore'] as String? ?? 'unknown',
        mockAuth: j['mock_auth'] as String? ?? 'disabled',
        nodeEnv: j['node_env'] as String? ?? 'unknown',
        uptimeSeconds: j['uptime_seconds'] as int? ?? 0,
        memoryMb: j['memory_mb'] as int? ?? 0,
      );
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

class AdminService {
  AdminService._();
  static final AdminService instance = AdminService._();

  final http.Client _client = http.Client();

  Uri _uri(String path) => Uri.parse('${AppConstants.apiBaseUrl}$path');

  Future<Map<String, String>> _headers() async {
    final token = await AuthService.instance.getIdToken();
    if (token == null) {
      throw const ApiException(
        message: 'Sign in required.',
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

  Map<String, dynamic> _parse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body['data'] as Map<String, dynamic>? ?? body;
    }
    throw ApiException(
      message: body['message'] as String? ?? body['error'] as String? ?? 'Admin API error',
      code: body['error'] as String?,
      statusCode: response.statusCode,
    );
  }

  Future<AdminStats> getStats() async {
    final response = await _client
        .get(_uri('/admin/stats'), headers: await _headers())
        .timeout(const Duration(seconds: 10));
    return AdminStats.fromJson(_parse(response));
  }

  Future<AdminAnalysesResponse> getAllAnalyses({
    int limit = 50,
    int offset = 0,
    String status = 'all',
    String q = '',
  }) async {
    final uri = _uri('/admin/analyses').replace(queryParameters: {
      'limit': '$limit',
      'offset': '$offset',
      'status': status,
      if (q.isNotEmpty) 'q': q,
    });
    final response = await _client
        .get(uri, headers: await _headers())
        .timeout(const Duration(seconds: 10));
    final data = _parse(response);
    return AdminAnalysesResponse(
      analyses: (data['analyses'] as List<dynamic>? ?? [])
          .map((e) => AdminAnalysis.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: data['total'] as int? ?? 0,
    );
  }

  Future<void> deleteAnalysis(String id) async {
    final response = await _client
        .delete(_uri('/admin/analyses/$id'), headers: await _headers())
        .timeout(const Duration(seconds: 10));
    _parse(response);
  }

  Future<void> setUserRole(String uid, {required bool isAdmin}) async {
    final response = await _client
        .post(
          _uri('/admin/users/$uid/role'),
          headers: await _headers(),
          body: jsonEncode({'admin': isAdmin}),
        )
        .timeout(const Duration(seconds: 10));
    _parse(response);
  }

  Future<SystemHealth> getHealth() async {
    final response = await _client
        .get(_uri('/admin/health'), headers: await _headers())
        .timeout(const Duration(seconds: 8));
    return SystemHealth.fromJson(_parse(response));
  }
}
