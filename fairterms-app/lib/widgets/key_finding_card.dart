/// Key finding card — cream brutalist with ink outline and yellow icon tile.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/bias_report.dart';
import '../utils/theme.dart';

class KeyFindingCard extends StatelessWidget {
  final KeyFinding finding;

  const KeyFindingCard({super.key, required this.finding});

  static IconData _resolveIcon(String iconName) {
    const iconMap = <String, IconData>{
      'location_on': Icons.location_on_rounded,
      'location_city': Icons.location_city_rounded,
      'business': Icons.business_rounded,
      'payments': Icons.payments_rounded,
      'account_balance': Icons.account_balance_rounded,
      'trending_down': Icons.trending_down_rounded,
      'trending_up': Icons.trending_up_rounded,
      'group': Icons.group_rounded,
      'compare': Icons.compare_arrows_rounded,
      'warning': Icons.warning_rounded,
      'info': Icons.info_rounded,
      'attach_money': Icons.attach_money_rounded,
      'analytics': Icons.analytics_rounded,
      'gavel': Icons.gavel_rounded,
      'handshake': Icons.handshake_rounded,
      'factory': Icons.factory_rounded,
      'local_shipping': Icons.local_shipping_rounded,
      'schedule': Icons.schedule_rounded,
      'percent': Icons.percent_rounded,
    };
    return iconMap[iconName] ?? Icons.lightbulb_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final icon = _resolveIcon(finding.icon);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.outline, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.35), width: 1),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  finding.title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  finding.description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.inkMuted,
                    height: 1.5,
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
