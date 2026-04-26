/// Bias factor card — cream brutalist with impact chip and expandable counterfactual.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/bias_report.dart';
import '../utils/theme.dart';

class BiasFactorCard extends StatefulWidget {
  final BiasFactor factor;

  const BiasFactorCard({super.key, required this.factor});

  @override
  State<BiasFactorCard> createState() => _BiasFactorCardState();
}

class _BiasFactorCardState extends State<BiasFactorCard> {
  bool _expanded = false;

  Color get _impactColor {
    switch (widget.factor.impact) {
      case 'high':
        return AppColors.error;
      case 'medium':
        return AppColors.warning;
      default:
        return AppColors.scoreHigh;
    }
  }

  Color get _impactFill {
    switch (widget.factor.impact) {
      case 'high':
        return AppColors.secondary;
      case 'medium':
        return AppColors.primary;
      default:
        return AppColors.mint;
    }
  }

  IconData get _impactIcon {
    switch (widget.factor.impact) {
      case 'high':
        return Icons.arrow_upward_rounded;
      case 'medium':
        return Icons.remove_rounded;
      default:
        return Icons.arrow_downward_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.outline, width: 1),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.factor.displayName,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _ImpactChip(
                label: widget.factor.impact,
                color: _impactFill,
                icon: _impactIcon,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    border: Border.all(color: AppColors.outline, width: 2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: widget.factor.impactScore.clamp(0.0, 1.0),
                    child: Container(color: _impactFill),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(widget.factor.impactScore * 100).round()}%',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _impactColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.factor.detail,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.inkMuted,
              height: 1.55,
            ),
          ),
          if (widget.factor.counterfactual != null) ...[
            const SizedBox(height: 14),
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(
                children: [
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 20,
                    color: AppColors.ink,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _expanded ? 'HIDE COUNTERFACTUAL' : 'WHAT IF THIS CHANGED?',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: _CounterfactualBox(
                text: widget.factor.counterfactual!,
              ),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
          ],
        ],
      ),
    );
  }
}

class _ImpactChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _ImpactChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _CounterfactualBox extends StatelessWidget {
  final String text;

  const _CounterfactualBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome_rounded,
              size: 16, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.inkMuted,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
