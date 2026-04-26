/// Peer comparison bar chart — cream brutalist with bold ink axes.
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/bias_report.dart';
import '../utils/theme.dart';

class PeerComparisonChart extends StatelessWidget {
  final BenchmarkComparison comparison;

  const PeerComparisonChart({super.key, required this.comparison});

  static const List<String> _buckets = [
    '0-30',
    '31-45',
    '46-60',
    '61-90',
    '90+',
  ];

  String _getBucketForDays(int days) {
    if (days <= 30) return '0-30';
    if (days <= 45) return '31-45';
    if (days <= 60) return '46-60';
    if (days <= 90) return '61-90';
    return '90+';
  }

  @override
  Widget build(BuildContext context) {
    final userBucket = _getBucketForDays(comparison.yourTermsDays);
    final maxCount = _buckets
        .map((b) => comparison.distribution[b] ?? 0)
        .fold<int>(0, (prev, e) => e > prev ? e : prev);

    final bars = _buckets.asMap().entries.map((entry) {
      final bucket = entry.value;
      final count = comparison.distribution[bucket] ?? 0;
      final isUserBucket = bucket == userBucket;

      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: count.toDouble(),
            color: isUserBucket ? AppColors.secondary : AppColors.primary,
            width: 28,
            borderRadius: BorderRadius.zero,
            borderSide: const BorderSide(color: AppColors.outline, width: 2),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxCount.toDouble(),
              color: AppColors.surfaceVariant,
            ),
          ),
        ],
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _LegendDot(color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              'PEERS',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(width: 14),
            _LegendDot(color: AppColors.secondary),
            const SizedBox(width: 6),
            Text(
              'YOUR TERMS (${comparison.yourTermsDays}D)',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: BarChart(
            BarChartData(
              maxY: maxCount > 0 ? maxCount * 1.2 : 10,
              barGroups: bars,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => AppColors.ink,
                  tooltipBorder: const BorderSide(
                      color: AppColors.outline, width: 2),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final bucket = _buckets[group.x];
                    return BarTooltipItem(
                      '$bucket days\n',
                      GoogleFonts.inter(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                      children: [
                        TextSpan(
                          text: '${rod.toY.round()} businesses',
                          style: GoogleFonts.inter(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= _buckets.length) {
                        return const SizedBox.shrink();
                      }
                      final isUser = _buckets[index] == userBucket;
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _buckets[index],
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color:
                                isUser ? AppColors.secondary : AppColors.ink,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) {
                      if (value == 0 || value == meta.max) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        value.toInt().toString(),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.inkMuted,
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: AppColors.ink.withValues(alpha: 0.1),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: const Border(
                  left: BorderSide(color: AppColors.outline, width: 2),
                  bottom: BorderSide(color: AppColors.outline, width: 2),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            'PAYMENT TERM BUCKETS (DAYS)',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.inkMuted,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;

  const _LegendDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: AppColors.outline, width: 2),
      ),
    );
  }
}
