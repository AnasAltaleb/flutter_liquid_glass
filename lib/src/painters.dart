import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Renders a classic, elegant glassmorphism gradient border
/// with a crisp specular light edge at the top-left falling off to
/// subtle translucency at the bottom-right.
class MeniscusRimPainter extends CustomPainter {
  final BorderRadius borderRadius;
  final double rimThickness;
  final double meniscusThickness;
  final double lightAngle;
  final double specularIntensity;
  final Color tintColor;

  const MeniscusRimPainter({
    required this.borderRadius,
    this.rimThickness = 1.5,
    this.meniscusThickness = 1.5,
    this.lightAngle = -0.75,
    this.specularIntensity = 1.0,
    this.tintColor = Colors.white,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect);
    final strokeWidth = meniscusThickness.clamp(1.0, 2.5);

    // Classic glassmorphic border: crisp top-left highlight fading to soft translucency
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    borderPaint.shader = ui.Gradient.linear(
      Offset.zero,
      Offset(size.width, size.height),
      [
        Colors.white.withValues(alpha: (0.55 * specularIntensity).clamp(0.15, 0.90)),
        Colors.white.withValues(alpha: (0.20 * specularIntensity).clamp(0.05, 0.40)),
        Colors.white.withValues(alpha: 0.05),
        Colors.white.withValues(alpha: 0.12),
      ],
      const [0.0, 0.40, 0.75, 1.0],
    );

    canvas.drawRRect(rrect.deflate(strokeWidth * 0.5), borderPaint);
  }

  @override
  bool shouldRepaint(covariant MeniscusRimPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.meniscusThickness != meniscusThickness ||
      oldDelegate.specularIntensity != specularIntensity;
}
