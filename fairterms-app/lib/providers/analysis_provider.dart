/// Analysis state providers for FairTerms.
library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/analysis_request.dart';
import '../models/bias_report.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

/// Holds the current analysis state during processing.
class AnalysisState {
  final String? analysisId;
  final String status;
  final int elapsedSeconds;
  final BiasReport? report;
  final String? errorMessage;
  final bool timedOut;

  const AnalysisState({
    this.analysisId,
    this.status = 'idle',
    this.elapsedSeconds = 0,
    this.report,
    this.errorMessage,
    this.timedOut = false,
  });

  /// Creates a copy with updated fields.
  AnalysisState copyWith({
    String? analysisId,
    String? status,
    int? elapsedSeconds,
    BiasReport? report,
    String? errorMessage,
    bool? timedOut,
  }) {
    return AnalysisState(
      analysisId: analysisId ?? this.analysisId,
      status: status ?? this.status,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      report: report ?? this.report,
      errorMessage: errorMessage ?? this.errorMessage,
      timedOut: timedOut ?? this.timedOut,
    );
  }

  /// Whether this analysis is currently running.
  bool get isProcessing => status == 'processing';

  /// Whether this analysis completed successfully.
  bool get isCompleted => status == 'completed';

  /// Whether this analysis failed.
  bool get isFailed => status == 'failed' || errorMessage != null;
}

/// Manages the analysis lifecycle: submission, polling, and report loading.
class AnalysisNotifier extends StateNotifier<AnalysisState> {
  AnalysisNotifier() : super(const AnalysisState());

  Timer? _pollingTimer;
  Timer? _elapsedTimer;
  Timer? _timeoutTimer;
  int _consecutiveFailures = 0;
  static const int _maxConsecutiveFailures = 5;

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }

  void _cancelTimers() {
    _pollingTimer?.cancel();
    _elapsedTimer?.cancel();
    _timeoutTimer?.cancel();
    _pollingTimer = null;
    _elapsedTimer = null;
    _timeoutTimer = null;
    _consecutiveFailures = 0;
  }

  /// Starts a new analysis and begins polling for completion.
  Future<void> startAnalysis(AnalysisRequest request) async {
    _cancelTimers();
    state = const AnalysisState(status: 'submitting');

    try {
      final runResponse = await ApiService.instance.runAnalysis(request);
      state = AnalysisState(
        analysisId: runResponse.analysisId,
        status: 'processing',
        elapsedSeconds: 0,
      );
      _startPolling(runResponse.analysisId);
    } catch (e) {
      state = AnalysisState(
        status: 'failed',
        errorMessage: e.toString(),
      );
    }
  }

  void _startPolling(String analysisId) {
    // Elapsed time counter
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
      }
    });

    // Timeout after configured seconds
    _timeoutTimer = Timer(
      const Duration(seconds: AppConstants.pollingTimeoutSeconds),
      () {
        if (mounted && state.isProcessing) {
          _cancelTimers();
          state = state.copyWith(timedOut: true, status: 'failed');
        }
      },
    );

    // Poll every N seconds
    _pollingTimer = Timer.periodic(
      const Duration(seconds: AppConstants.pollingIntervalSeconds),
      (_) async {
        if (!mounted) return;
        await _checkStatus(analysisId);
      },
    );
  }

  Future<void> _checkStatus(String analysisId) async {
    try {
      final statusResponse =
          await ApiService.instance.getAnalysisStatus(analysisId);

      if (!mounted) return;

      if (statusResponse.isCompleted) {
        _cancelTimers();
        state = state.copyWith(status: 'completed');
        await _fetchReport(analysisId);
      } else if (statusResponse.isFailed) {
        _cancelTimers();
        state = state.copyWith(
          status: 'failed',
          errorMessage: 'Analysis failed on the server.',
        );
      }
    } catch (e) {
      _consecutiveFailures++;
      // ignore: avoid_print
      print(
          '[AnalysisNotifier] Poll error ($_consecutiveFailures/$_maxConsecutiveFailures): $e');
      if (_consecutiveFailures >= _maxConsecutiveFailures) {
        _cancelTimers();
        if (mounted) {
          state = state.copyWith(
            status: 'failed',
            errorMessage:
                'Lost connection to server after $_maxConsecutiveFailures attempts.',
          );
        }
      }
      return;
    }
    _consecutiveFailures = 0;
  }

  Future<void> _fetchReport(String analysisId) async {
    try {
      final report = await ApiService.instance.getAnalysisReport(analysisId);
      if (mounted) {
        state = state.copyWith(report: report);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          status: 'failed',
          errorMessage: 'Failed to load report: ${e.toString()}',
        );
      }
    }
  }

  /// Resumes polling for an analysis that was previously in 'processing' state.
  /// Call this from initState when navigating back to the loading screen.
  void resumePolling(String analysisId) {
    if (_pollingTimer != null) return; // already polling
    state = AnalysisState(
      analysisId: analysisId,
      status: 'processing',
      elapsedSeconds: state.elapsedSeconds,
    );
    _startPolling(analysisId);
  }

  /// Retries the analysis by re-starting polling for the same analysis ID.
  Future<void> retry(AnalysisRequest request) async {
    await startAnalysis(request);
  }

  /// Resets the analysis state to idle.
  void reset() {
    _cancelTimers();
    state = const AnalysisState();
  }
}

/// Provider for [AnalysisNotifier].
final analysisProvider = StateNotifierProvider<AnalysisNotifier, AnalysisState>(
  (_) => AnalysisNotifier(),
);

/// Provider for the analysis history list.
/// Returns empty list on network/auth errors so the screen shows empty state
/// rather than an error — the user can pull-to-refresh when online.
final analysisHistoryProvider =
    FutureProvider<List<AnalysisSummary>>((ref) async {
  ref.watch(authStateProvider); // re-fetch when auth state changes
  try {
    return await ApiService.instance.getAnalysisHistory();
  } on ApiException catch (e) {
    // ignore: avoid_print
    print('[analysisHistoryProvider] ${e.code}: ${e.message}');
    return const [];
  } catch (e) {
    // ignore: avoid_print
    print('[analysisHistoryProvider] error: $e');
    return const [];
  }
});
