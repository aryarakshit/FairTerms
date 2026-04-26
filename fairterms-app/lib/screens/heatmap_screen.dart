/// National bias heatmap — ranked state view with industry filter.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/bias_report.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';
import '../widgets/user_avatar.dart';

/// Industries shown as filter chips (superset of profile industries).
const _industryOptions = <String>[
  'all',
  'Textiles',
  'IT Services',
  'Auto Components',
  'Pharma',
  'Food Processing',
  'Chemicals',
  'Electronics',
  'Handicrafts',
  'Leather',
  'Metal Fabrication',
];

class HeatmapScreen extends ConsumerStatefulWidget {
  const HeatmapScreen({super.key});

  @override
  ConsumerState<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends ConsumerState<HeatmapScreen> {
  String _industry = 'all';
  Future<HeatmapData>? _future;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() => _isOffline = false);
    _future = ApiService.instance.getHeatmap(industry: _industry).catchError(
      (Object e) {
        if (mounted) setState(() => _isOffline = true);
        return ApiService.instance.offlineHeatmap(_industry);
      },
    );
  }

  void _onIndustryChanged(String industry) {
    setState(() {
      _industry = industry;
      _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 720;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(onBack: () => Navigator.of(context).maybePop()),
            if (_isOffline)
              Container(
                width: double.infinity,
                color: AppColors.warning.withValues(alpha: 0.12),
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
                child: Text(
                  'Offline — showing sample data',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.warning,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
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
                        _FilterBar(
                          selected: _industry,
                          onChanged: _onIndustryChanged,
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: FutureBuilder<HeatmapData>(
                            future: _future,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primary,
                                    strokeWidth: 2,
                                  ),
                                );
                              }
                              if (snapshot.hasError) {
                                return _ErrorView(
                                  message: snapshot.error.toString(),
                                  onRetry: () => setState(_load),
                                );
                              }
                              final data = snapshot.data!;
                              if (data.states.isEmpty) {
                                return _EmptyState();
                              }
                              final sorted = [...data.states]..sort(
                                  (a, b) => a.avgFairnessScore
                                      .compareTo(b.avgFairnessScore),
                                );
                              return ListView.separated(
                                itemCount: sorted.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, i) => _StateTile(
                                  rank: i + 1,
                                  state: sorted[i],
                                ),
                              );
                            },
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
          'Grievances',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.inkFaint,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'National bias heatmap.',
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
          'State-wise fairness rankings by industry and payment practices.',
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

class _FilterBar extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _FilterBar({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _industryOptions.map((opt) {
            final isSelected = opt == selected;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _IndustryChip(
                label: opt == 'all' ? 'All' : opt,
                selected: isSelected,
                onTap: () => onChanged(opt),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _IndustryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _IndustryChip({
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

class _StateTile extends StatefulWidget {
  final int rank;
  final HeatmapState state;

  const _StateTile({required this.rank, required this.state});

  @override
  State<_StateTile> createState() => _StateTileState();
}

class _StateTileState extends State<_StateTile> {
  bool _hovered = false;

  Color get _color {
    if (widget.state.isFair) return AppColors.primary;
    if (widget.state.isModerate) return AppColors.warning;
    return AppColors.error;
  }

  String get _biasLabel {
    if (widget.state.isFair) return 'Fair';
    if (widget.state.isModerate) return 'Moderate';
    return 'Severe';
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      isScrollControlled: true,
      builder: (_) => _StateDetailSheet(state: widget.state),
    );
  }

  @override
  Widget build(BuildContext context) {
    final barFraction = (widget.state.avgFairnessScore.clamp(0, 100)) / 100.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: _hovered ? AppColors.surfaceVariant : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _showDetails(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(
                color: _hovered ? AppColors.inkFaint : AppColors.outline,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 32,
                      child: Text(
                        '#${widget.rank}',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.inkFaint,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.state.state,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppColors.ink,
                              letterSpacing: -0.1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.state.totalAnalyses} analyses · Avg ${widget.state.avgPaymentTermsDays.round()}d',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.inkFaint,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        _biasLabel,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _color,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: AppColors.inkFaint,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    height: 6,
                    color: AppColors.surface,
                    child: FractionallySizedBox(
                      widthFactor: barFraction.clamp(0, 1),
                      alignment: Alignment.centerLeft,
                      child: Container(color: _color),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Fairness ${widget.state.avgFairnessScore.toStringAsFixed(1)}/100',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.inkFaint,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StateDetailSheet extends StatelessWidget {
  final HeatmapState state;

  const _StateDetailSheet({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: AppColors.outline,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          Text(
            'State profile',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.inkFaint,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.state,
            style: GoogleFonts.fraunces(
              fontSize: 28,
              fontWeight: FontWeight.w300,
              color: AppColors.ink,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${state.totalAnalyses} analyses · ${state.stateCode}',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: 24),
          _DetailRow(
            label: 'Avg payment terms',
            value: '${state.avgPaymentTermsDays.round()} days',
          ),
          _DetailRow(
            label: 'Avg fairness score',
            value: '${state.avgFairnessScore.toStringAsFixed(1)}/100',
          ),
          _DetailRow(
            label: 'Bias level',
            value: state.biasLevel,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.inkMuted,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.map_outlined, size: 40, color: AppColors.inkFaint),
          const SizedBox(height: 16),
          Text(
            'No data available',
            style: GoogleFonts.fraunces(
              fontSize: 20,
              fontWeight: FontWeight.w400,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Heatmap data will appear here.',
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
                'Could not load heatmap',
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
