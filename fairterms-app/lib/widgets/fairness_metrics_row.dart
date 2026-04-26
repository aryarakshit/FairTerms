/// Fairness metrics row — cream brutalist metric cards.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/bias_report.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';

class FairnessMetricsRow extends StatelessWidget {
  final FairnessMetrics metrics;

  const FairnessMetricsRow({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final useRow = width > 480;

    final cards = [
      _MetricCard(
        shortName: 'Stat. Parity',
        fullName: 'Statistical Parity Difference',
        value: metrics.statisticalParityDifference,
        isFair: metrics.statisticalParityDifference.abs() <=
            AppConstants.statisticalParityThreshold,
        tooltip:
            'Measures the difference in positive outcome rates between groups.\n'
            'Fair range: ±${AppConstants.statisticalParityThreshold}',
      ),
      _MetricCard(
        shortName: 'Disp. Impact',
        fullName: 'Disparate Impact Ratio',
        value: metrics.disparateImpactRatio,
        isFair: metrics.disparateImpactRatio >=
                AppConstants.disparateImpactLower &&
            metrics.disparateImpactRatio <= AppConstants.disparateImpactUpper,
        tooltip: 'Ratio of favorable outcomes between groups.\n'
            'Fair range: ${AppConstants.disparateImpactLower}–${AppConstants.disparateImpactUpper}',
      ),
      _MetricCard(
        shortName: 'Equal Opp.',
        fullName: 'Equal Opportunity Difference',
        value: metrics.equalOpportunityDifference,
        isFair: metrics.equalOpportunityDifference.abs() <=
            AppConstants.equalOpportunityThreshold,
        tooltip: 'Difference in true positive rates between groups.\n'
            'Fair range: ±${AppConstants.equalOpportunityThreshold}',
      ),
    ];

    if (useRow) {
      return Row(
        children: cards.asMap().entries.map((e) {
          return Expanded(
            child: Padding(
              padding:
                  EdgeInsets.only(right: e.key < cards.length - 1 ? 12 : 0),
              child: e.value,
            ),
          );
        }).toList(),
      );
    }

    return Column(
      children: cards.asMap().entries.map((e) {
        return Padding(
          padding: EdgeInsets.only(bottom: e.key < cards.length - 1 ? 12 : 0),
          child: e.value,
        );
      }).toList(),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String shortName;
  final String fullName;
  final double value;
  final bool isFair;
  final String tooltip;

  const _MetricCard({
    required this.shortName,
    required this.fullName,
    required this.value,
    required this.isFair,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isFair ? AppColors.mint : AppColors.secondary;
    final statusLabel = isFair ? 'FAIR' : 'BIAS';
    final statusIcon =
        isFair ? Icons.check_circle_rounded : Icons.warning_rounded;

    return Tooltip(
      message: tooltip,
      triggerMode: TooltipTriggerMode.tap,
      textStyle: GoogleFonts.inter(
        color: AppColors.primary,
        fontSize: 13,
        height: 1.5,
        fontWeight: FontWeight.w500,
      ),
      decoration: const BoxDecoration(color: AppColors.surfaceVariant),
      padding: const EdgeInsets.all(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.outline, width: 1),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    shortName,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.inkMuted,
                      letterSpacing: 0.8,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: AppColors.inkMuted,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value.toStringAsFixed(2),
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                border: Border.all(
                    color: statusColor.withValues(alpha: 0.4), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 12, color: statusColor),
                  const SizedBox(width: 5),
                  Text(
                    statusLabel,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
