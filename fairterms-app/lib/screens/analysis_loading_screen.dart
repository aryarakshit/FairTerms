/// Analysis loading — Fixmyitch minimal polling UI.
library;

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/analysis_provider.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';

class AnalysisLoadingScreen extends ConsumerStatefulWidget {
  final String analysisId;

  const AnalysisLoadingScreen({super.key, required this.analysisId});

  @override
  ConsumerState<AnalysisLoadingScreen> createState() =>
      _AnalysisLoadingScreenState();
}

class _AnalysisLoadingScreenState extends ConsumerState<AnalysisLoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtl;
  late Animation<double> _pulse;

  final List<String> _steps = const [
    'Received payment terms',
    'Running counterfactual analysis',
    'Comparing with 147+ peer businesses',
    'Computing fairness metrics',
    'Generating report',
  ];

  int _visibleSteps = 1;
  Timer? _stepTimer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    _pulseCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseCtl, curve: Curves.easeInOut),
    );

    _stepTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted && _visibleSteps < _steps.length) {
        setState(() => _visibleSteps++);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = ref.read(analysisProvider.notifier);
      final current = ref.read(analysisProvider);
      if (current.status == 'processing' &&
          current.analysisId == widget.analysisId) {
        notifier.resumePolling(widget.analysisId);
      }
    });
  }

  @override
  void dispose() {
    _pulseCtl.dispose();
    _stepTimer?.cancel();
    super.dispose();
  }

  String _formatElapsed(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  void _navigateToReport(String analysisId) {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    context.pushReplacement('/analysis/$analysisId/report');
  }

  void _showTimeoutDialog() {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Taking longer than expected',
          style: GoogleFonts.fraunces(
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: AppColors.ink,
          ),
        ),
        content: Text(
          'The analysis is taking longer than expected. Please try again or check History later.',
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.inkMuted),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.pop();
            },
            child: const Text('Go back'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _hasNavigated = false;
              ref.read(analysisProvider.notifier).reset();
              context.pop();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final analysisState = ref.watch(analysisProvider);

    ref.listen<AnalysisState>(analysisProvider, (_, next) {
      if (next.report != null && next.isCompleted) {
        _navigateToReport(widget.analysisId);
      } else if (next.timedOut) {
        _showTimeoutDialog();
      } else if (next.isFailed && !next.timedOut) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(next.errorMessage ?? 'Analysis failed. Please try again.'),
          ),
        );
      }
    });

    final elapsedStr = _formatElapsed(analysisState.elapsedSeconds);
    final progress = (analysisState.elapsedSeconds / AppConstants.pollingTimeoutSeconds.toDouble()).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  ScaleTransition(
                    scale: _pulse,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 56,
                            height: 56,
                            child: CircularProgressIndicator(
                              value: progress > 0 ? progress : null,
                              strokeWidth: 2.5,
                              color: AppColors.background,
                              backgroundColor:
                                  AppColors.background.withValues(alpha: 0.2),
                            ),
                          ),
                          const Icon(
                            Icons.analytics_outlined,
                            size: 26,
                            color: AppColors.background,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Analyzing your terms',
                    style: GoogleFonts.fraunces(
                      fontSize: 28,
                      fontWeight: FontWeight.w300,
                      color: AppColors.ink,
                      letterSpacing: -0.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Running counterfactual analysis to detect hidden bias.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.inkMuted,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.outline, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(_steps.length, (index) {
                        final isVisible = index < _visibleSteps;
                        final isLast = index == _visibleSteps - 1;
                        return AnimatedOpacity(
                          opacity: isVisible ? 1.0 : 0.3,
                          duration: const Duration(milliseconds: 400),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: isLast &&
                                          analysisState.isProcessing &&
                                          isVisible
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 1.8,
                                            color: AppColors.ink,
                                          ),
                                        )
                                      : Icon(
                                          isVisible
                                              ? Icons.check_circle
                                              : Icons.circle_outlined,
                                          size: 18,
                                          color: isVisible
                                              ? AppColors.primary
                                              : AppColors.inkFaint,
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _steps[index],
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: isLast
                                          ? FontWeight.w500
                                          : FontWeight.w400,
                                      color: isVisible
                                          ? AppColors.ink
                                          : AppColors.inkFaint,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.timer_outlined,
                          size: 14, color: AppColors.inkFaint),
                      const SizedBox(width: 6),
                      Text(
                        '$elapsedStr elapsed',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          color: AppColors.inkFaint,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
