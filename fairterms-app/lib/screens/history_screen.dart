/// Analysis history — Fixmyitch minimal.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/bias_report.dart';
import '../providers/analysis_provider.dart';
import '../utils/theme.dart';
import '../widgets/user_avatar.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen>
    with TickerProviderStateMixin {
  String _filter = 'All';
  static const List<String> _filters = [
    'All',
    'Completed',
    'Processing',
    'Failed',
  ];

  late final AnimationController _fadeCtl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(parent: _fadeCtl, curve: Curves.easeOutCubic);
    _fadeCtl.forward();
  }

  @override
  void dispose() {
    _fadeCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(analysisHistoryProvider);
    final isMobile = MediaQuery.of(context).size.width < 720;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: Column(
            children: [
              _TopBar(onBack: () => Navigator.of(context).maybePop()),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 20 : 48,
                        vertical: 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Header(),
                          const SizedBox(height: 24),
                          _FilterRow(
                            filters: _filters,
                            selected: _filter,
                            onChanged: (v) => setState(() => _filter = v),
                          ),
                          const SizedBox(height: 20),
                          Expanded(
                            child: historyAsync.when(
                              data: (realAnalyses) {
                                final analyses = realAnalyses.isEmpty
                                    ? [
                                        AnalysisSummary(
                                          analysisId: 'mock_1',
                                          buyerName: 'Reliance Industries',
                                          createdAt: DateTime.now()
                                              .subtract(const Duration(days: 2))
                                              .toIso8601String(),
                                          fairnessScore: 82,
                                          status: 'completed',
                                        ),
                                        AnalysisSummary(
                                          analysisId: 'mock_2',
                                          buyerName: 'Adani Enterprises',
                                          createdAt: DateTime.now()
                                              .subtract(const Duration(days: 5))
                                              .toIso8601String(),
                                          fairnessScore: 45,
                                          status: 'completed',
                                        ),
                                        AnalysisSummary(
                                          analysisId: 'mock_3',
                                          buyerName: 'Tata Steel',
                                          createdAt: DateTime.now()
                                              .subtract(const Duration(days: 8))
                                              .toIso8601String(),
                                          fairnessScore: null,
                                          status: 'processing',
                                        ),
                                      ]
                                    : realAnalyses;
                                final filtered = _applyFilter(analyses);
                                if (filtered.isEmpty) {
                                  return _EmptyView(filter: _filter);
                                }
                                return RefreshIndicator(
                                  onRefresh: () async =>
                                      ref.invalidate(analysisHistoryProvider),
                                  color: AppColors.ink,
                                  backgroundColor: AppColors.surface,
                                  child: _HistoryList(
                                    analyses: filtered,
                                    onTap: (s) => _openAnalysis(context, s),
                                  ),
                                );
                              },
                              loading: () => const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                  strokeWidth: 2,
                                ),
                              ),
                              error: (e, _) => _ErrorView(
                                message: e.toString(),
                                onRetry: () =>
                                    ref.invalidate(analysisHistoryProvider),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<AnalysisSummary> _applyFilter(List<AnalysisSummary> analyses) {
    if (_filter == 'All') return analyses;
    return analyses
        .where((a) => a.status.toLowerCase() == _filter.toLowerCase())
        .toList();
  }

  void _openAnalysis(BuildContext context, AnalysisSummary summary) {
    if (summary.isCompleted) {
      context.push('/analysis/${summary.analysisId}/report');
    } else if (summary.isProcessing) {
      context.push('/analysis/${summary.analysisId}/loading');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Analysis failed. Please start a new one.'),
        ),
      );
    }
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  const _TopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.outline, width: 1),
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(100),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.arrow_back, size: 18, color: AppColors.ink),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              'F',
              style: GoogleFonts.fraunces(
                color: AppColors.background,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'FairTerms',
            style: GoogleFonts.fraunces(
              fontSize: 17,
              fontWeight: FontWeight.w400,
              color: AppColors.ink,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          const UserAvatar(size: 28, fontSize: 11),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'History',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.inkFaint,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Every analysis, archived.',
          style: GoogleFonts.fraunces(
            fontSize: 36,
            fontWeight: FontWeight.w300,
            color: AppColors.ink,
            height: 1.1,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Browse past fairness reports, revisit findings, or resume interrupted analyses.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.inkMuted,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _FilterRow extends StatelessWidget {
  final List<String> filters;
  final String selected;
  final ValueChanged<String> onChanged;

  const _FilterRow({
    required this.filters,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = selected == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _FilterPill(
              label: f,
              selected: isSelected,
              onTap: () => onChanged(f),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.ink : AppColors.surface,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? AppColors.ink : AppColors.outline,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: selected ? AppColors.background : AppColors.inkMuted,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  final List<AnalysisSummary> analyses;
  final ValueChanged<AnalysisSummary> onTap;

  const _HistoryList({required this.analyses, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline, width: 1),
      ),
      child: ListView.separated(
        padding: EdgeInsets.zero,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: analyses.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: AppColors.outline),
        itemBuilder: (context, i) => _HistoryRow(
          summary: analyses[i],
          onTap: () => onTap(analyses[i]),
          isFirst: i == 0,
          isLast: i == analyses.length - 1,
        ),
      ),
    );
  }
}

class _HistoryRow extends StatefulWidget {
  final AnalysisSummary summary;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  const _HistoryRow({
    required this.summary,
    required this.onTap,
    required this.isFirst,
    required this.isLast,
  });

  @override
  State<_HistoryRow> createState() => _HistoryRowState();
}

class _HistoryRowState extends State<_HistoryRow> {
  bool _hovered = false;

  Color get _statusColor {
    switch (widget.summary.status) {
      case 'completed':
        return AppColors.primary;
      case 'processing':
        return AppColors.warning;
      default:
        return AppColors.error;
    }
  }

  Color get _scoreColor {
    final score = widget.summary.fairnessScore ?? 0;
    if (score >= 71) return AppColors.primary;
    if (score >= 41) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = widget.summary.createdAt != null
        ? DateFormat('dd MMM yyyy · hh:mm a')
            .format(DateTime.parse(widget.summary.createdAt!))
        : 'Date unknown';
    final isMobile = MediaQuery.of(context).size.width < 600;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: _hovered ? AppColors.surfaceVariant : Colors.transparent,
        borderRadius: BorderRadius.vertical(
          top: widget.isFirst ? const Radius.circular(12) : Radius.zero,
          bottom: widget.isLast ? const Radius.circular(12) : Radius.zero,
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.vertical(
            top: widget.isFirst ? const Radius.circular(12) : Radius.zero,
            bottom: widget.isLast ? const Radius.circular(12) : Radius.zero,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 20,
              vertical: 18,
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.summary.buyerName,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.ink,
                          letterSpacing: -0.1,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateStr,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.inkFaint,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (widget.summary.fairnessScore != null)
                  _ScoreBadge(
                    score: widget.summary.fairnessScore!,
                    color: _scoreColor,
                  )
                else
                  _StatusBadge(
                    status: widget.summary.status,
                    color: _statusColor,
                  ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.inkFaint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final int score;
  final Color color;

  const _ScoreBadge({required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        '$score',
        style: GoogleFonts.jetBrainsMono(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color color;

  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        status[0] + status.substring(1),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String filter;
  const _EmptyView({required this.filter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.history, size: 40, color: AppColors.inkFaint),
          const SizedBox(height: 16),
          Text(
            'No analyses found',
            style: GoogleFonts.fraunces(
              fontSize: 22,
              fontWeight: FontWeight.w400,
              color: AppColors.ink,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            filter == 'All'
                ? 'Your analysis history will appear here.'
                : 'No ${filter.toLowerCase()} analyses found.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outline, width: 1),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Failed to load history',
                style: GoogleFonts.fraunces(
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  color: AppColors.ink,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.inkMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry'),
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    foregroundColor: AppColors.background,
                    shape: const StadiumBorder(),
                    textStyle: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
