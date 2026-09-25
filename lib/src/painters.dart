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

/// Paints a realistic glossy curved specular highlight on the upper face
/// of the liquid glass for analytical fallback mode.
class SpecularGlarePainter extends CustomPainter {
  final BorderRadius borderRadius;
  final double intensity;
  final double lightAngle;

  SpecularGlarePainter({
    required this.borderRadius,
    required this.intensity,
    required this.lightAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity <= 0.05) return;

    final paint = Paint()..style = PaintingStyle.fill;
    final path = Path();
    final topGlareHeight = size.height * 0.42;

    path.moveTo(0, borderRadius.topLeft.y);
    path.arcToPoint(
      Offset(borderRadius.topLeft.x, 0),
      radius: borderRadius.topLeft,
    );
    path.lineTo(size.width - borderRadius.topRight.x, 0);
    path.arcToPoint(
      Offset(size.width, borderRadius.topRight.y),
      radius: borderRadius.topRight,
    );
    path.lineTo(size.width, topGlareHeight * 0.4);
    path.quadraticBezierTo(
      size.width * 0.45,
      topGlareHeight,
      0,
      topGlareHeight * 0.8,
    );
    path.close();

    paint.shader = ui.Gradient.linear(
      Offset(size.width * 0.2, 0),
      Offset(size.width * 0.5, topGlareHeight),
      [
        Colors.white.withValues(alpha: (0.35 * intensity).clamp(0.0, 0.8)),
        Colors.white.withValues(alpha: (0.10 * intensity).clamp(0.0, 0.4)),
        Colors.white.withValues(alpha: 0.0),
      ],
      const [0.0, 0.5, 1.0],
    );

    canvas.drawPath(path, paint);

    final bottomPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = ui.Gradient.radial(
        Offset(size.width * 0.85, size.height * 0.85),
        size.width * 0.35,
        [
          Colors.white.withValues(alpha: (0.18 * intensity).clamp(0.0, 0.5)),
          Colors.white.withValues(alpha: 0.0),
        ],
      );

    final bottomPath = Path();
    bottomPath.moveTo(size.width * 0.6, size.height);
    bottomPath.lineTo(size.width - borderRadius.bottomRight.x, size.height);
    bottomPath.arcToPoint(
      Offset(size.width, size.height - borderRadius.bottomRight.y),
      radius: borderRadius.bottomRight,
    );
    bottomPath.lineTo(size.width, size.height * 0.7);
    bottomPath.quadraticBezierTo(
      size.width * 0.8,
      size.height * 0.78,
      size.width * 0.6,
      size.height,
    );
    bottomPath.close();

    canvas.drawPath(bottomPath, bottomPaint);
  }

  @override
  bool shouldRepaint(covariant SpecularGlarePainter oldDelegate) =>
      oldDelegate.intensity != intensity || oldDelegate.lightAngle != lightAngle;
}
