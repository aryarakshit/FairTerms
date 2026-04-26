/// Dark industrial background layer — near-black canvas with blueprint grid.
/// Uses a GPU-cached static CustomPaint — shouldRepaint always false.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/theme.dart';

/// Wraps [child] with the signature dark page and a subtle blueprint grid.
class AnimatedArtifactBg extends StatelessWidget {
  final Widget child;

  const AnimatedArtifactBg({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: Stack(
        children: [
          // GPU-cached static layer — drawn once, never repaints
          const Positioned.fill(
            child: RepaintBoundary(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _BlueprintGridPainter(),
                  isComplex: true,
                  willChange: false,
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// Draws a sparse dashed grid at ~4% opacity.
/// [shouldRepaint] → always false: drawn ONCE, GPU-raster-cached forever.
class _BlueprintGridPainter extends CustomPainter {
  const _BlueprintGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0x0AFFFFFF) // white @ ~4%
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const spacing = 40.0;
    const dashLen = 3.0;
    const gapLen = 5.0;

    // Vertical dashed lines
    for (double x = 0; x < size.width; x += spacing) {
      double y = 0;
      while (y < size.height) {
        canvas.drawLine(
          Offset(x, y),
          Offset(x, math.min(y + dashLen, size.height)),
          p,
        );
        y += dashLen + gapLen;
      }
    }

    // Horizontal dashed lines
    for (double y = 0; y < size.height; y += spacing) {
      double x = 0;
      while (x < size.width) {
        canvas.drawLine(
          Offset(x, y),
          Offset(math.min(x + dashLen, size.width), y),
          p,
        );
        x += dashLen + gapLen;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
