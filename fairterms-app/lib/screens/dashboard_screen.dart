// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
/// Dashboard — Fixmyitch minimal.
library;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/bias_report.dart';
import '../providers/analysis_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../widgets/user_avatar.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Refresh history and profile on every dashboard mount.
      ref.invalidate(analysisHistoryProvider);
      ref.invalidate(myProfileProvider);
    });
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good morning';
    if (hour >= 12 && hour < 17) return 'Good afternoon';
    if (hour >= 17 && hour < 21) return 'Good evening';
    return 'Good night';
  }

  @override
  Widget build(BuildContext context) {
    final userName = AuthService.instance.currentUserDisplayName;
    final firstName = userName.split(' ').first;
    
    final profileAsync = ref.watch(myProfileProvider);
    final historyAsync = ref.watch(analysisHistoryProvider);
    
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width <= 900;
    final isGuest = ref.watch(guestModeProvider);
    
    final profile = profileAsync.valueOrNull;
    final isNewUser = !isGuest && !profileAsync.isLoading && profile == null;
    
    // Greeting name: Use business name if available, else first name
    final greetingName = profile?.businessName ?? firstName;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Sticky top bar
          SliverAppBar(
            pinned: true,
            floating: false,
            elevation: 0,
            toolbarHeight: 76,
            backgroundColor: AppColors.background.withValues(alpha: 0.92),
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.none,
              background: Container(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.outline, width: 1)),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Brand
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'FairTerms',
                            style: GoogleFonts.fraunces(
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                              color: AppColors.ink,
                              letterSpacing: -0.02,
                            ),
                          ),
                        ],
                      ),
                      // Tabs
                      if (!isMobile)
                        Row(
                          children: [
                            _PillTab('Dashboard', isActive: true),
                            SizedBox(width: 4),
                            _PillTab('Analyses', onTap: () => context.push(AppConstants.routeHistory)),
                            SizedBox(width: 4),
                            _PillTab('Benchmarks', onTap: () => context.push(AppConstants.routeLeaderboard)),
                            SizedBox(width: 4),
                            _PillTab('Grievances', onTap: () => context.push(AppConstants.routeHeatmap)),
                          ],
                        ),
                      // User chip / guest back button
                      isGuest
                          ? GestureDetector(
                              onTap: () {
                                ref.read(guestModeProvider.notifier).state = false;
                                context.go(AppConstants.routeLogin);
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.outline, width: 1),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.arrow_back, size: 14, color: AppColors.inkMuted),
                                    SizedBox(width: 8),
                                    Text(
                                      'Back to login',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.inkMuted,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : GestureDetector(
                              onTap: () => context.push(AppConstants.routeSettings),
                              child: Row(
                                children: [
                                  UserAvatar(size: 32, fontSize: 13),
                                  SizedBox(width: 14),
                                  Text(
                                    firstName,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.inkMuted,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Main content
          SliverToBoxAdapter(
            child: Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: 1200),
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 56),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero headline with staggered animation
                    _FadeSlideIn(
                      delay: Duration.zero,
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.fraunces(
                            fontSize: 52,
                            fontWeight: FontWeight.w300,
                            color: AppColors.ink,
                            letterSpacing: -0.03,
                            height: 1.05,
                          ),
                          children: [
                            TextSpan(text: '${_greeting()}, '),
                            TextSpan(
                              text: greetingName,
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: AppColors.primary,
                              ),
                            ),
                            TextSpan(text: '.'),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    _FadeSlideIn(
                      delay: Duration(milliseconds: 80),
                      child: Text(
                        profile != null
                            ? 'Displaying fairness metrics for ${profile.businessName} in the ${profile.industry} sector.'
                            : 'You have 3 analyses this month. One buyer is currently flagged for late payment.',
                        style: TextStyle(
                          color: AppColors.inkFaint,
                          fontSize: 15,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                    SizedBox(height: 24),

                    // New-user profile prompt (signed-in only, no profile yet)
                    if (isNewUser)
                      _FadeSlideIn(
                        delay: Duration(milliseconds: 120),
                        child: Container(
                          margin: EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: AppColors.primary.withValues(alpha: 0.04),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Complete your business profile',
                                      style: GoogleFonts.fraunces(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.ink,
                                        letterSpacing: -0.01,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Tell us about your business so we can analyse payment terms accurately for your sector and region.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.inkFaint,
                                        fontFamily: 'Inter',
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 16),
                              GestureDetector(
                                onTap: () => context.push(AppConstants.routeProfile),
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'Fill in details →',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.background,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // CTA panel
                    _FadeSlideIn(
                      delay: Duration(milliseconds: 160),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.outline, width: 1),
                          borderRadius: BorderRadius.circular(14),
                          color: AppColors.surface,
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 28),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Analyse a new contract',
                                    style: GoogleFonts.fraunces(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.ink,
                                      letterSpacing: -0.01,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    isGuest
                                        ? 'Sign up to analyse payment terms and get a full fairness report with actionable insights.'
                                        : 'Enter payment terms from your buyer\'s contract. We\'ll score fairness, benchmark against peers, and flag compliance risk in under 30 seconds.',
                                    style: TextStyle(
                                      color: AppColors.inkFaint,
                                      fontSize: 13,
                                      fontFamily: 'Inter',
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 24),
                            isGuest
                                ? _InkButton(
                                    'Sign up / Login →',
                                    onTap: () async {
                                      await ref.read(signInProvider.notifier).signInWithGoogle();
                                      if (ref.read(authStateProvider).value != null) {
                                        ref.read(guestModeProvider.notifier).state = false;
                                      }
                                    },
                                  )
                                : _InkButton(
                                    'Start your analysis →',
                                    onTap: () => context.push(
                                      AppConstants.routePaymentTerms,
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 48),

                    // Metrics grid
                    historyAsync.when(
                      data: (realAnalyses) {
                        final completed = realAnalyses.where((a) => a.isCompleted).toList();
                        final avgScore = completed.isEmpty
                            ? 0
                            : (completed.fold<int>(0, (sum, a) => sum + (a.fairnessScore ?? 0)) / completed.length).round();
                        
                        // Fake deltas for now if no history, else 0
                        final scoreVal = isGuest ? '68' : avgScore.toString();
                        final countVal = isGuest ? '12' : realAnalyses.length.toString();

                        return _FadeSlideIn(
                          delay: Duration(milliseconds: 240),
                          child: GridView.count(
                            crossAxisCount: isMobile ? 2 : 4,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            childAspectRatio: isMobile ? 1.6 : 1.8,
                            children: [
                              _MetricCard(
                                label: 'YOUR FAIRNESS SCORE',
                                value: scoreVal,
                                delta: isGuest ? '↑ 4 vs last month' : 'Sector average: 62',
                                isDelta: isGuest || avgScore > 62,
                              ),
                              _MetricCard(
                                label: 'CONTRACTS ANALYSED',
                                value: countVal,
                                delta: isGuest ? '↑ 3 this week' : 'Total scanned',
                                isDelta: true,
                              ),
                              _MetricCard(
                                label: 'INTEREST OWED (MSMED)',
                                value: isGuest ? '₹48k' : '₹0',
                                delta: isGuest ? 'Due in 14 days' : 'No overdue flagged',
                                isDelta: false,
                              ),
                              _MetricCard(
                                label: 'FLAGGED BUYERS',
                                value: isGuest ? '2' : completed.where((a) => (a.fairnessScore ?? 100) < 41).length.toString(),
                                delta: isGuest ? 'Review recommended' : 'Severe bias detected',
                                isDelta: false,
                              ),
                            ],
                          ),
                        );
                      },
                      loading: () => const SizedBox(height: 140),
                      error: (_, __) => const SizedBox(height: 140),
                    ),
                    SizedBox(height: 56),

                    // Section header
                    _FadeSlideIn(
                      delay: Duration(milliseconds: 320),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent analyses',
                            style: GoogleFonts.fraunces(
                              fontSize: 26,
                              fontWeight: FontWeight.w400,
                              color: AppColors.ink,
                              letterSpacing: -0.02,
                            ),
                          ),
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () => context.push(AppConstants.routeHistory),
                              child: Text(
                                'View all →',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.inkFaint,
                                  fontFamily: 'Inter',
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),

                    // Analyses list
                    historyAsync.when(
                      data: (realAnalyses) {
                        // Guests see sample data; signed-in users see their real data.
                        final analyses = (realAnalyses.isEmpty && isGuest)
                          ? [
                              AnalysisSummary(
                                analysisId: 'mock_1',
                                buyerName: 'Reliance Industries',
                                createdAt: DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
                                fairnessScore: 82,
                                status: 'completed',
                              ),
                              AnalysisSummary(
                                analysisId: 'mock_2',
                                buyerName: 'Adani Enterprises',
                                createdAt: DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
                                fairnessScore: 45,
                                status: 'completed',
                              ),
                              AnalysisSummary(
                                analysisId: 'mock_3',
                                buyerName: 'Tata Steel',
                                createdAt: DateTime.now().subtract(const Duration(days: 8)).toIso8601String(),
                                fairnessScore: null,
                                status: 'processing',
                              ),
                            ]
                          : realAnalyses;
                        if (analyses.isEmpty) {
                          return _FadeSlideIn(
                            delay: Duration(milliseconds: 400),
                            child: Center(
                              child: Padding(
                                padding: EdgeInsets.all(40),
                                child: Text(
                                  'No analyses yet',
                                  style: TextStyle(
                                    color: AppColors.inkFaint,
                                    fontSize: 14,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                        return _FadeSlideIn(
                          delay: Duration(milliseconds: 400),
                          child: Column(
                            children: List.generate(analyses.length, (index) {
                              return _AnalysisRow(
                                summary: analyses[index],
                                onTap: () => _openAnalysis(context, analyses[index]),
                              );
                            }),
                          ),
                        );
                      },
                      loading: () => _FadeSlideIn(
                        delay: Duration(milliseconds: 400),
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(AppColors.primary),
                            ),
                          ),
                        ),
                      ),
                      error: (e, _) => _FadeSlideIn(
                        delay: Duration(milliseconds: 400),
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: Text(
                              'Failed to load analyses',
                              style: TextStyle(
                                color: AppColors.error,
                                fontSize: 14,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 56),

                    // Two-column panels
                    _FadeSlideIn(
                      delay: Duration(milliseconds: 480),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Peer benchmark
                          Expanded(
                            flex: 7,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.outline, width: 1),
                                borderRadius: BorderRadius.circular(12),
                                color: AppColors.background,
                              ),
                              padding: EdgeInsets.all(28),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Peer benchmark — Textiles, Maharashtra',
                                    style: GoogleFonts.fraunces(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.ink,
                                      letterSpacing: -0.01,
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  _BenchmarkRow('Top quartile', 82),
                                  _BenchmarkRow('Median', 61),
                                  _BenchmarkRow('You', 68, isYou: true),
                                  _BenchmarkRow('Bottom quartile', 38),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 24),
                          // Recent activity
                          Expanded(
                            flex: 4,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.outline, width: 1),
                                borderRadius: BorderRadius.circular(12),
                                color: AppColors.background,
                              ),
                              padding: EdgeInsets.all(28),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Recent activity',
                                    style: GoogleFonts.fraunces(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.ink,
                                      letterSpacing: -0.01,
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  _ActivityItem(
                                    text: 'Hindustan Retail flagged for severe bias',
                                    time: '2 days ago',
                                    dotColor: AppColors.error,
                                  ),
                                  _ActivityItem(
                                    text: 'Grievance acknowledged by Patel Wholesale',
                                    time: '4 days ago',
                                    dotColor: AppColors.primary,
                                  ),
                                  _ActivityItem(
                                    text: 'Interest accrual reminder — ₹12,400',
                                    time: '1 week ago',
                                    dotColor: AppColors.warning,
                                  ),
                                  _ActivityItem(
                                    text: 'New peer benchmark available for your state',
                                    time: '2 weeks ago',
                                    dotColor: AppColors.primary,
                                    isLast: true,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openAnalysis(BuildContext context, AnalysisSummary summary) {
    if (summary.isCompleted) {
      context.push('/analysis/${summary.analysisId}/report');
    } else if (summary.isProcessing) {
      context.push('/analysis/${summary.analysisId}/loading');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Analysis for ${summary.buyerName} failed. Please try again.')),
      );
    }
  }
}

// Staggered fade + slide animation
class _FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _FadeSlideIn({required this.child, required this.delay});

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnim = Tween<Offset>(begin: Offset(0, 0.1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOut),
        );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: widget.child,
      ),
    );
  }
}

// Pill tab
class _PillTab extends StatefulWidget {
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const _PillTab(this.label, {this.isActive = false, this.onTap});

  @override
  State<_PillTab> createState() => _PillTabState();
}

class _PillTabState extends State<_PillTab> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (mounted) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (mounted) setState(() => _isHovered = false);
      },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isActive ? AppColors.ink : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: widget.isActive
                  ? AppColors.ink
                  : (_isHovered ? AppColors.inkMuted : Colors.transparent),
              width: 1,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 13,
              color: widget.isActive ? AppColors.background : AppColors.inkMuted,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ),
    );
  }
}

// Ink button
class _InkButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _InkButton(this.label, {required this.onTap});

  @override
  State<_InkButton> createState() => _InkButtonState();
}

class _InkButtonState extends State<_InkButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (mounted) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (mounted) setState(() => _isHovered = false);
      },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: _isHovered ? Color(0xFF222222) : AppColors.ink,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.background,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ),
    );
  }
}

// Metric card
class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String delta;
  final bool isDelta;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.delta,
    required this.isDelta,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(22),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.outline, width: 1),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.background,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.1,
              color: AppColors.inkFaint,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.fraunces(
              fontSize: 36,
              fontWeight: FontWeight.w400,
              color: AppColors.ink,
              letterSpacing: -0.02,
              height: 1,
            ),
          ),
          SizedBox(height: 10),
          Text(
            delta,
            style: TextStyle(
              fontSize: 12,
              color: isDelta ? AppColors.primary : AppColors.error,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}

// Analyses row with animation
class _AnalysisRow extends StatefulWidget {
  final AnalysisSummary summary;
  final VoidCallback onTap;

  const _AnalysisRow({required this.summary, required this.onTap});

  @override
  State<_AnalysisRow> createState() => _AnalysisRowState();
}

class _AnalysisRowState extends State<_AnalysisRow> {
  bool _isHovered = false;

  Color _getVerdictColor() {
    final score = widget.summary.fairnessScore ?? 0;
    if (score < 41) return AppColors.error;
    if (score < 71) return AppColors.warning;
    return AppColors.primary;
  }

  String _getVerdictLabel() {
    final score = widget.summary.fairnessScore ?? 0;
    if (score < 41) return 'Severe bias';
    if (score < 71) return 'Moderate';
    return 'Fair';
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = widget.summary.createdAt != null
        ? DateFormat('MMM dd, yyyy').format(DateTime.parse(widget.summary.createdAt!))
        : 'Unknown';

    return MouseRegion(
      onEnter: (_) {
        if (mounted) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (mounted) setState(() => _isHovered = false);
      },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          margin: EdgeInsets.only(bottom: 1),
          decoration: BoxDecoration(
            border: Border.all(
              color: _isHovered ? AppColors.inkFaint : AppColors.outline,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
            color: AppColors.background,
          ),
          child: Row(
            children: [
              // Buyer + meta
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.summary.buyerName,
                      style: GoogleFonts.fraunces(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: AppColors.ink,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Textiles · Maharashtra · 90-day terms',
                      style: TextStyle(
                        color: AppColors.inkFaint,
                        fontSize: 12,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              // Verdict pill
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getVerdictColor().withValues(alpha: 0.05),
                  border: Border.all(
                    color: _getVerdictColor().withValues(alpha: 0.3),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _getVerdictLabel(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _getVerdictColor(),
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              SizedBox(width: 16),
              // Score
              SizedBox(
                width: 60,
                child: Text(
                  '${widget.summary.fairnessScore ?? '--'}',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.fraunces(
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                    color: AppColors.ink,
                    letterSpacing: -0.02,
                  ),
                ),
              ),
              Text(
                '/100',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.inkFaint,
                  fontFamily: 'Inter',
                ),
              ),
              SizedBox(width: 20),
              // Date
              SizedBox(
                width: 100,
                child: Text(
                  dateStr,
                  style: TextStyle(
                    color: AppColors.inkFaint,
                    fontSize: 12,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              // Arrow
              SizedBox(
                width: 40,
                child: Text(
                  _isHovered ? '→' : '',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: AppColors.inkFaint,
                    fontSize: 16,
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

// Benchmark bar row with animated width
class _BenchmarkRow extends StatefulWidget {
  final String label;
  final int value;
  final bool isYou;

  const _BenchmarkRow(this.label, this.value, {this.isYou = false});

  @override
  State<_BenchmarkRow> createState() => _BenchmarkRowState();
}

class _BenchmarkRowState extends State<_BenchmarkRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _widthAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _widthAnim = Tween<double>(begin: 0, end: widget.value / 100).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.inkMuted,
                fontFamily: 'Inter',
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(4),
              ),
              child: AnimatedBuilder(
                animation: _widthAnim,
                builder: (context, child) {
                  return FractionallySizedBox(
                    widthFactor: _widthAnim.value,
                    child: Container(
                      decoration: BoxDecoration(
                        color: widget.isYou ? AppColors.ink : AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          SizedBox(width: 16),
          SizedBox(
            width: 52,
            child: Text(
              '${widget.value}',
              textAlign: TextAlign.right,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                color: AppColors.inkMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Activity item
class _ActivityItem extends StatelessWidget {
  final String text;
  final String time;
  final Color dotColor;
  final bool isLast;

  const _ActivityItem({
    required this.text,
    required this.time,
    required this.dotColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                margin: EdgeInsets.only(top: 6, right: 12),
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.ink,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Padding(
            padding: EdgeInsets.only(left: 20),
            child: Text(
              time,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.inkFaint,
                fontFamily: 'Inter',
              ),
            ),
          ),
          if (!isLast)
            Padding(
              padding: EdgeInsets.only(top: 14),
              child: Divider(
                color: AppColors.outline,
                height: 1,
                thickness: 1,
              ),
            ),
        ],
      ),
    );
  }
}

