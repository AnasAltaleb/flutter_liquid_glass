import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Paints the 3D beveled meniscus rim with directional highlights and
/// chromatic prismatic dispersion colors for analytical fallback mode.
class MeniscusRimPainter extends CustomPainter {
  final BorderRadius borderRadius;
  final double strokeWidth;
  final double lightAngle;
  final double specularIntensity;

  MeniscusRimPainter({
    required this.borderRadius,
    required this.strokeWidth,
    required this.lightAngle,
    required this.specularIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect).deflate(strokeWidth / 2);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final startOffset = Offset(
      size.width / 2 + size.width * 0.5 * -0.7,
      size.height / 2 + size.height * 0.5 * -0.7,
    );
    final endOffset = Offset(
      size.width / 2 + size.width * 0.5 * 0.7,
      size.height / 2 + size.height * 0.5 * 0.7,
    );

    paint.shader = ui.Gradient.linear(
      startOffset,
      endOffset,
      [
        Colors.white.withValues(alpha: (0.95 * specularIntensity).clamp(0.0, 1.0)),
        const Color(0xFFE0F7FF).withValues(alpha: 0.6 * specularIntensity),
        const Color(0xFFFFD6E8).withValues(alpha: 0.3 * specularIntensity),
        Colors.white.withValues(alpha: 0.1),
        Colors.black.withValues(alpha: 0.25),
      ],
      const [0.0, 0.25, 0.5, 0.75, 1.0],
    );

    canvas.drawRRect(rrect, paint);

    // Inner subtle glow hairline for micro-bevel
    final innerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75
      ..color = Colors.white.withValues(alpha: 0.3 * specularIntensity);

    canvas.drawRRect(rrect.deflate(strokeWidth * 0.8), innerPaint);
  }

  @override
  bool shouldRepaint(covariant MeniscusRimPainter oldDelegate) =>
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.specularIntensity != specularIntensity ||
      oldDelegate.lightAngle != lightAngle;
}
