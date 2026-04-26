/// Circular arc fairness gauge — cream brutalist style.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';

class FairnessGauge extends StatefulWidget {
  final int score;
  final double size;

  const FairnessGauge({
    super.key,
    required this.score,
    this.size = 120,
  });

  @override
  State<FairnessGauge> createState() => _FairnessGaugeState();
}

class _FairnessGaugeState extends State<FairnessGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = Tween<double>(begin: 0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(FairnessGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _scoreColor(int score) {
    if (score >= AppConstants.fairScoreThreshold) return AppColors.scoreHigh;
    if (score >= AppConstants.moderateBiasThreshold) return AppColors.scoreMid;
    return AppColors.scoreLow;
  }

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(widget.score);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _GaugePainter(
              score: widget.score,
              animationValue: _animation.value,
              gaugeColor: color,
              backgroundColor: AppColors.ink.withValues(alpha: 0.12),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(widget.score * _animation.value).round()}',
                    style: GoogleFonts.inter(
                      fontSize: widget.size * 0.3,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    '/ 100',
                    style: GoogleFonts.inter(
                      fontSize: widget.size * 0.11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(duration: 600.ms).scaleXY(
            begin: 0.85,
            curve: Curves.easeOutBack,
            duration: 600.ms);
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final int score;
  final double animationValue;
  final Color gaugeColor;
  final Color backgroundColor;

  _GaugePainter({
    required this.score,
    required this.animationValue,
    required this.gaugeColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 8;
    const strokeWidth = 12.0;
    const startAngle = math.pi * 0.75;
    const totalSweep = math.pi * 1.5;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      totalSweep,
      false,
      bgPaint,
    );

    final sweepAngle = totalSweep * (score / 100.0) * animationValue;
    if (sweepAngle > 0) {
      final fgPaint = Paint()
        ..color = gaugeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.animationValue != animationValue ||
      old.score != score ||
      old.gaugeColor != gaugeColor;
}
