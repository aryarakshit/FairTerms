// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
/// Admin — Fixmyitch minimal.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/admin_service.dart';
import '../utils/theme.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  int _activeNav = 0;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width <= 768;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: isMobile
          ? Column(
              children: [
                _TopBar(title: 'Overview', controller: _pulseController),
                Expanded(child: _OverviewContent(controller: _pulseController)),
              ],
            )
          : Row(
              children: [
                _Sidebar(
                  activeIndex: _activeNav,
                  onTap: (i) => setState(() => _activeNav = i),
                ),
                Expanded(
                  child: Column(
                    children: [
                      _TopBar(title: 'Overview', controller: _pulseController),
                      Expanded(
                        child: _OverviewContent(controller: _pulseController),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sidebar
// ---------------------------------------------------------------------------

class _Sidebar extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onTap;
  const _Sidebar({required this.activeIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(color: AppColors.outline, width: 1),
        ),
      ),
      child: ListView(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        fontSize: 19,
                        fontWeight: FontWeight.w400,
                        color: AppColors.ink,
                        letterSpacing: -0.02 * 19,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                Divider(
                  color: AppColors.outline,
                  height: 1,
                  thickness: 1,
                ),
              ],
            ),
          ),
          _NavGroup(
            header: 'Overview',
            items: [
              _NavGroupItem('Dashboard', 0, activeIndex, onTap, bullet: true),
              _NavGroupItem('Analytics', 1, activeIndex, onTap, count: '12k'),
            ],
          ),
          _NavGroup(
            header: 'Management',
            items: [
              _NavGroupItem('Users', 2, activeIndex, onTap, count: '342'),
              _NavGroupItem('Analyses', 3, activeIndex, onTap, count: '12.4k'),
              _NavGroupItem('Grievances', 4, activeIndex, onTap, count: '28'),
            ],
          ),
          _NavGroup(
            header: 'System',
            items: [
              _NavGroupItem('Services', 5, activeIndex, onTap),
              _NavGroupItem('Seed data', 6, activeIndex, onTap),
              _NavGroupItem('Audit log', 7, activeIndex, onTap),
            ],
          ),
          _NavGroup(
            header: 'Settings',
            items: [
              _NavGroupItem('Configuration', 8, activeIndex, onTap),
              _NavGroupItem('API keys', 9, activeIndex, onTap),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavGroup extends StatelessWidget {
  final String header;
  final List<Widget> items;
  const _NavGroup({required this.header, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(18, 0, 18, 8),
          child: Text(
            header,
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 0.15 * 10,
              color: AppColors.inkFaint,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ...items,
        SizedBox(height: 22),
      ],
    );
  }
}

class _NavGroupItem extends StatelessWidget {
  final String label;
  final int index;
  final int activeIndex;
  final ValueChanged<int> onTap;
  final bool bullet;
  final String? count;

  const _NavGroupItem(
    this.label,
    this.index,
    this.activeIndex,
    this.onTap, {
    this.bullet = false,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == activeIndex;
    return InkWell(
      onTap: () => onTap(index),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 9, horizontal: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        margin: EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isActive ? AppColors.background : AppColors.inkMuted,
              ),
            ),
            if (bullet) ...[
              SizedBox(width: 4),
              Text(
                '•',
                style: TextStyle(
                  color: isActive ? AppColors.background : AppColors.inkMuted,
                ),
              ),
            ],
            Spacer(),
            if (count != null)
              Text(
                count!,
                style: TextStyle(
                  fontSize: 11,
                  color: isActive
                      ? AppColors.background.withValues(alpha: 0.6)
                      : AppColors.inkFaint,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top bar
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  final String title;
  final AnimationController controller;
  const _TopBar({required this.title, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 36),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.outline, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.fraunces(
              fontSize: 32,
              fontWeight: FontWeight.w400,
              color: AppColors.ink,
              letterSpacing: -0.02 * 32,
            ),
          ),
          _StatusChip(controller: controller),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final AnimationController controller;
  const _StatusChip({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.outline, width: 1),
        borderRadius: BorderRadius.circular(999),
        color: AppColors.background,
      ),
      child: Row(
        children: [
          ScaleTransition(
            scale: Tween(begin: 0.4, end: 1.0).animate(
              CurvedAnimation(parent: controller, curve: Curves.easeInOut),
            ),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          SizedBox(width: 8),
          Text(
            'All systems operational',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.inkFaint,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Overview content
// ---------------------------------------------------------------------------

class _OverviewContent extends StatefulWidget {
  final AnimationController controller;
  const _OverviewContent({required this.controller});

  @override
  State<_OverviewContent> createState() => _OverviewContentState();
}

class _OverviewContentState extends State<_OverviewContent> {
  Future<AdminStats>? _statsFuture;

  final _mockStats = AdminStats(
    totalAnalyses: 47,
    completedAnalyses: 42,
    processingAnalyses: 3,
    failedAnalyses: 2,
    totalProfiles: 89,
    uniqueUsers: 342,
    avgFairnessScore: 67,
    generatedAt: 'offline',
  );

  @override
  void initState() {
    super.initState();
    _statsFuture =
        AdminService.instance.getStats().catchError((Object _) => _mockStats);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AdminStats>(
      future: _statsFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        final stats = snap.data ?? _mockStats;
        return SingleChildScrollView(
          padding: EdgeInsets.all(40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MetricsGrid(stats: stats),
              SizedBox(height: 40),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 1000) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 14,
                          child: _RecentUsersPanel(),
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          flex: 10,
                          child: _ActivityPanel(controller: widget.controller),
                        ),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      _RecentUsersPanel(),
                      SizedBox(height: 20),
                      _ActivityPanel(controller: widget.controller),
                    ],
                  );
                },
              ),
              SizedBox(height: 40),
              _HealthGrid(controller: widget.controller),
              SizedBox(height: 40),
              _SeedDataSection(),
              SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Metrics grid
// ---------------------------------------------------------------------------

class _MetricsGrid extends StatelessWidget {
  final AdminStats stats;
  const _MetricsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth < 700 ? 2 : 4;
        return GridView.count(
          crossAxisCount: cols,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          childAspectRatio: 2.4,
          children: [
            _MetricCard(
              label: 'Total users',
              value: '${stats.uniqueUsers}',
              delta: '▲ 18 this week',
            ),
            _MetricCard(
              label: 'Analyses today',
              value: '${stats.totalAnalyses}',
              delta: '▲ 12% vs yesterday',
            ),
            _MetricCard(
              label: 'Gemini API calls',
              value: '1.2k',
              delta: '▲ within quota',
            ),
            _MetricCard(
              label: 'Grievances filed',
              value: '${stats.failedAnalyses * 14}',
              delta: '3 awaiting review',
              negative: true,
            ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String delta;
  final bool negative;
  const _MetricCard({
    required this.label,
    required this.value,
    required this.delta,
    this.negative = false,
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
              letterSpacing: 0.1 * 11,
              color: AppColors.inkFaint,
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
              letterSpacing: -0.02 * 36,
            ),
          ),
          SizedBox(height: 10),
          Text(
            delta,
            style: TextStyle(
              fontSize: 12,
              color: negative ? AppColors.error : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recent users panel
// ---------------------------------------------------------------------------

class _RecentUsersPanel extends StatelessWidget {
  const _RecentUsersPanel();

  @override
  Widget build(BuildContext context) {
    final rows = [
      _UserRowData('Rajesh Sharma', 'rajesh@sharmatex.com', 12, 34,
          AppColors.error, true),
      _UserRowData(
          'Priya Patel', 'priya@patelfoods.in', 8, 51, AppColors.warning, true),
      _UserRowData('Amit Das', 'amit@daselectronics.com', 3, 72,
          AppColors.primary, false),
      _UserRowData('Sunita Devi', 'sunita@devihandlooms.in', 15, 28,
          AppColors.error, true),
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.outline, width: 1),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.background,
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.outline, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent users',
                  style: GoogleFonts.fraunces(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: AppColors.ink,
                    letterSpacing: -0.01 * 18,
                  ),
                ),
                Text(
                  '342 total',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.inkFaint,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                bottom: BorderSide(color: AppColors.outline, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'USER',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 0.14 * 10,
                      color: AppColors.inkFaint,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'ANALYSES',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 0.14 * 10,
                      color: AppColors.inkFaint,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'AVG SCORE',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 0.14 * 10,
                      color: AppColors.inkFaint,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    'ACTIVE',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 0.14 * 10,
                      color: AppColors.inkFaint,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...rows.asMap().entries.map((e) {
            final isLast = e.key == rows.length - 1;
            return _UserRow(row: e.value, isLast: isLast);
          }),
        ],
      ),
    );
  }
}

class _UserRowData {
  final String name;
  final String email;
  final int analyses;
  final int score;
  final Color scoreColor;
  final bool active;
  _UserRowData(this.name, this.email, this.analyses, this.score,
      this.scoreColor, this.active);
}

class _UserRow extends StatelessWidget {
  final _UserRowData row;
  final bool isLast;
  const _UserRow({required this.row, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: AppColors.outline, width: 1),
              ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.name,
                  style: GoogleFonts.fraunces(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: AppColors.ink,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  row.email,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.inkFaint,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              '${row.analyses}',
              style: TextStyle(fontSize: 13, color: AppColors.inkMuted),
            ),
          ),
          Expanded(
            child: Text(
              '${row.score}',
              style: TextStyle(
                fontSize: 13,
                color: row.scoreColor,
                fontFamily: 'JetBrains Mono',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.outline, width: 1),
                  color: row.active
                      ? AppColors.primary.withValues(alpha: 0.05)
                      : Colors.transparent,
                ),
                child: Text(
                  row.active ? 'on' : '—',
                  style: TextStyle(
                    fontSize: 11,
                    color: row.active ? AppColors.primary : AppColors.inkMuted,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Activity panel
// ---------------------------------------------------------------------------

class _ActivityPanel extends StatelessWidget {
  final AnimationController controller;
  const _ActivityPanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    final items = [
      _ActivityItemData(AppColors.error,
          'Severe bias flagged — Hindustan Retail', '2 min ago'),
      _ActivityItemData(AppColors.primary,
          'Grievance acknowledged by Patel Wholesale', '14 min ago'),
      _ActivityItemData(AppColors.warning,
          'Gemini API rate-limit approaching 80%', '1 hr ago'),
      _ActivityItemData(
          AppColors.primary, 'New user onboarded — Khanna Exports', '2 hr ago'),
      _ActivityItemData(
          AppColors.primary, 'Seed data refresh completed', 'yesterday'),
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.outline, width: 1),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.background,
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.outline, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Activity',
                  style: GoogleFonts.fraunces(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: AppColors.ink,
                    letterSpacing: -0.01 * 18,
                  ),
                ),
                Text(
                  'live',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.inkFaint,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
              ],
            ),
          ),
          ...items.asMap().entries.map((e) {
            final isLast = e.key == items.length - 1;
            return _ActivityItem(
              data: e.value,
              isLast: isLast,
            );
          }),
        ],
      ),
    );
  }
}

class _ActivityItemData {
  final Color dot;
  final String text;
  final String time;
  _ActivityItemData(this.dot, this.text, this.time);
}

class _ActivityItem extends StatelessWidget {
  final _ActivityItemData data;
  final bool isLast;
  const _ActivityItem({required this.data, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: AppColors.outline, width: 1),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: data.dot,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.text,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.inkMuted,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  data.time,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.inkFaint,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Health grid
// ---------------------------------------------------------------------------

class _HealthGrid extends StatelessWidget {
  final AnimationController controller;
  const _HealthGrid({required this.controller});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth < 700 ? 1 : 3;
        return GridView.count(
          crossAxisCount: cols,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          childAspectRatio: cols == 1 ? 4 : 2.2,
          children: [
            _HealthCard(
              title: 'Backend API',
              controller: controller,
              stats: [
                ('p95 latency', '142ms'),
                ('Uptime 30d', '99.98%'),
                ('Error rate', '0.02%'),
              ],
            ),
            _HealthCard(
              title: 'Fairness Engine',
              controller: controller,
              stats: [
                ('Avg scoring', '2.1s'),
                ('Queue depth', '3'),
                ('Model version', 'v2.4'),
              ],
            ),
            _HealthCard(
              title: 'Gemini API',
              controller: controller,
              stats: [
                ('Quota used', '78%'),
                ('Avg latency', '860ms'),
                ('Fails today', '0'),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _HealthCard extends StatelessWidget {
  final String title;
  final AnimationController controller;
  final List<(String, String)> stats;
  const _HealthCard({
    required this.title,
    required this.controller,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.outline, width: 1),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.background,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.fraunces(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: AppColors.ink,
                  letterSpacing: -0.01 * 16,
                ),
              ),
              ScaleTransition(
                scale: Tween(begin: 0.4, end: 1.0).animate(
                  CurvedAnimation(parent: controller, curve: Curves.easeInOut),
                ),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          ...stats.map((stat) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    stat.$1,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.inkFaint,
                    ),
                  ),
                  Text(
                    stat.$2,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.inkMuted,
                      fontFamily: 'JetBrains Mono',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Seed data section
// ---------------------------------------------------------------------------

class _SeedDataSection extends StatelessWidget {
  const _SeedDataSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(28),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.outline, width: 1),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.background,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seed data management',
            style: GoogleFonts.fraunces(
              fontSize: 20,
              fontWeight: FontWeight.w400,
              color: AppColors.ink,
              letterSpacing: -0.01 * 20,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Benchmark data is sourced from BigQuery MSME payment records. Refresh weekly or after a significant regulatory update.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.inkFaint,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth < 600 ? 2 : 4;
              return GridView.count(
                crossAxisCount: cols,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                childAspectRatio: 1.8,
                children: [
                  _SeedGridItem('BigQuery records', '24,108'),
                  _SeedGridItem('Buyers indexed', '1,842'),
                  _SeedGridItem('States covered', '28'),
                  _SeedGridItem('Last refresh', '14 Apr'),
                ],
              );
            },
          ),
          SizedBox(height: 20),
          Divider(color: AppColors.outline, height: 1, thickness: 1),
          SizedBox(height: 20),
          Row(
            children: [
              _ActionButton(label: 'Regenerate now', primary: true),
              SizedBox(width: 10),
              _ActionButton(label: 'Export CSV', ghost: true),
              SizedBox(width: 10),
              _ActionButton(label: 'Reset all seed data', danger: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _SeedGridItem extends StatelessWidget {
  final String label;
  final String value;
  const _SeedGridItem(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.outline, width: 1),
        borderRadius: BorderRadius.circular(10),
        color: AppColors.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 0.1 * 11,
              color: AppColors.inkFaint,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.fraunces(
              fontSize: 22,
              fontWeight: FontWeight.w400,
              color: AppColors.ink,
              letterSpacing: -0.02 * 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final bool primary;
  final bool ghost;
  final bool danger;
  const _ActionButton({
    required this.label,
    this.primary = false,
    this.ghost = false,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = primary
        ? AppColors.ink
        : (danger ? Colors.transparent : Colors.transparent);
    final fg = primary
        ? AppColors.background
        : (danger ? AppColors.error : AppColors.ink);
    final border = danger
        ? AppColors.error.withValues(alpha: 0.3)
        : (primary ? null : AppColors.outline);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        border: border != null ? Border.all(color: border, width: 1) : null,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: fg,
          fontWeight: primary ? FontWeight.w500 : FontWeight.w400,
        ),
      ),
    );
  }
}
