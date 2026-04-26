/// Buyer Fairness Leaderboard — Fixmyitch minimal.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/bias_report.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';

/// Public ranking of large buyers by fairness toward SME suppliers.
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with TickerProviderStateMixin {
  Future<LeaderboardData>? _future;
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  String _query = '';
  bool _isOffline = false;

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
    _loadLeaderboard();
  }

  void _loadLeaderboard() {
    setState(() => _isOffline = false);
    _future = ApiService.instance.getLeaderboard().catchError(
      (Object e) {
        if (mounted) setState(() => _isOffline = true);
        return ApiService.instance.offlineLeaderboard(50);
      },
    );
  }

  @override
  void dispose() {
    _fadeCtl.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<LeaderboardEntry> _filter(List<LeaderboardEntry> all) {
    if (_query.isEmpty) return all;
    final q = _query.toLowerCase();
    return all.where((e) => e.buyerName.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 720;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: Column(
            children: [
              _TopBar(onBack: () => Navigator.of(context).maybePop()),
              if (_isOffline) const _OfflineBanner(),
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
                          _SearchField(
                            controller: _searchController,
                            focusNode: _searchFocus,
                            query: _query,
                            onChanged: (v) => setState(() => _query = v),
                            onClear: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          ),
                          const SizedBox(height: 20),
                          Expanded(
                            child: FutureBuilder<LeaderboardData>(
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
                                    onRetry: _loadLeaderboard,
                                  );
                                }
                                final buyers = _filter(snapshot.data!.buyers);
                                if (buyers.isEmpty) {
                                  return _EmptyState(query: _query);
                                }
                                return _LeaderboardList(
                                  buyers: buyers,
                                  onTap: (e) => _showBreakdown(context, e),
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
      ),
    );
  }

  void _showBreakdown(BuildContext context, LeaderboardEntry entry) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      isScrollControlled: true,
      builder: (_) => _BuyerDetailSheet(entry: entry),
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
          'Leaderboard',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.inkFaint,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Buyers ranked by fairness.',
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
          'Public ranking based on average payment terms and on-time performance.',
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

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.warning.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      child: Text(
        'Offline — showing sample data',
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.warning,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _SearchField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    setState(() => _focused = widget.focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _focused ? AppColors.ink : AppColors.outline,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(
            Icons.search,
            size: 16,
            color: _focused ? AppColors.ink : AppColors.inkFaint,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              onChanged: widget.onChanged,
              cursorColor: AppColors.ink,
              style: GoogleFonts.inter(
                color: AppColors.ink,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                hintText: 'Search buyers',
                hintStyle: GoogleFonts.inter(
                  color: AppColors.inkFaint,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          if (widget.query.isNotEmpty)
            GestureDetector(
              onTap: widget.onClear,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: AppColors.inkMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LeaderboardList extends StatelessWidget {
  final List<LeaderboardEntry> buyers;
  final ValueChanged<LeaderboardEntry> onTap;

  const _LeaderboardList({required this.buyers, required this.onTap});

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
        itemCount: buyers.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: AppColors.outline),
        itemBuilder: (context, i) => _BuyerRow(
          entry: buyers[i],
          onTap: () => onTap(buyers[i]),
          isFirst: i == 0,
          isLast: i == buyers.length - 1,
        ),
      ),
    );
  }
}

class _BuyerRow extends StatefulWidget {
  final LeaderboardEntry entry;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  const _BuyerRow({
    required this.entry,
    required this.onTap,
    required this.isFirst,
    required this.isLast,
  });

  @override
  State<_BuyerRow> createState() => _BuyerRowState();
}

class _BuyerRowState extends State<_BuyerRow> {
  bool _hovered = false;

  Color get _scoreColor {
    final score = widget.entry.fairnessScore;
    if (score >= 71) return AppColors.primary;
    if (score >= 41) return AppColors.warning;
    return AppColors.error;
  }

  bool get _isPodium =>
      widget.entry.isGold || widget.entry.isSilver || widget.entry.isBronze;

  String get _rankLabel => '${widget.entry.rank}';

  @override
  Widget build(BuildContext context) {
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
                SizedBox(
                  width: 32,
                  child: Text(
                    _rankLabel,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _isPodium ? AppColors.ink : AppColors.inkFaint,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.entry.buyerName,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: AppColors.ink,
                                letterSpacing: -0.1,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_isPodium) ...[
                            const SizedBox(width: 8),
                            _PodiumChip(entry: widget.entry),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Avg ${widget.entry.avgPaymentTermsDays.round()}d · ${widget.entry.totalSmesServed} SMEs',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.inkFaint,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _ScorePill(
                  score: widget.entry.fairnessScore,
                  color: _scoreColor,
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

class _PodiumChip extends StatelessWidget {
  final LeaderboardEntry entry;
  const _PodiumChip({required this.entry});

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;
    if (entry.isGold) {
      label = 'Gold';
      color = AppColors.primary;
    } else if (entry.isSilver) {
      label = 'Silver';
      color = AppColors.inkMuted;
    } else {
      label = 'Bronze';
      color = const Color(0xFFB07A3A);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  final int score;
  final Color color;
  const _ScorePill({required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        '$score',
        style: GoogleFonts.jetBrainsMono(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: color,
          height: 1.0,
        ),
      ),
    );
  }
}

class _BuyerDetailSheet extends StatelessWidget {
  final LeaderboardEntry entry;

  const _BuyerDetailSheet({required this.entry});

  Color get _scoreColor {
    if (entry.fairnessScore >= 71) return AppColors.primary;
    if (entry.fairnessScore >= 41) return AppColors.warning;
    return AppColors.error;
  }

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
            'Buyer profile',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.inkFaint,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            entry.buyerName,
            style: GoogleFonts.fraunces(
              fontSize: 28,
              fontWeight: FontWeight.w300,
              color: AppColors.ink,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Rank #${entry.rank} · ${entry.badge.replaceAll('_', ' ')}',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: 24),
          _DetailRow(
            label: 'Fairness score',
            value: '${entry.fairnessScore} / 100',
            valueColor: _scoreColor,
          ),
          _DetailRow(
            label: 'Avg payment terms',
            value: '${entry.avgPaymentTermsDays.round()} days',
          ),
          _DetailRow(
            label: 'SMEs served',
            value: '${entry.totalSmesServed}',
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outline, width: 1),
            ),
            child: Text(
              'Industry and regional breakdowns appear once more analyses are aggregated for this buyer.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.inkMuted,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

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
              color: valueColor ?? AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String query;
  const _EmptyState({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, size: 40, color: AppColors.inkFaint),
          const SizedBox(height: 16),
          Text(
            query.isEmpty ? 'No buyers ranked yet' : 'No matches for "$query"',
            style: GoogleFonts.fraunces(
              fontSize: 20,
              fontWeight: FontWeight.w400,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try a different search term.',
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
                'Could not load leaderboard',
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
