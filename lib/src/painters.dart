import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Renders a multi-layered physical 3D glass meniscus lens around the perimeter
/// of the widget, simulating Fresnel surface reflection, edge refraction,
/// chromatic fringe, and directional specular glare for analytical/Web mode.
class MeniscusRimPainter extends CustomPainter {
  final BorderRadius borderRadius;
  final double rimThickness;
  final double meniscusThickness;
  final double lightAngle;
  final double specularIntensity;
  final Color tintColor;

  MeniscusRimPainter({
    required this.borderRadius,
    required this.rimThickness,
    required this.meniscusThickness,
    required this.lightAngle,
    required this.specularIntensity,
    required this.tintColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final rect = Offset.zero & size;
    final outerRRect = borderRadius.toRRect(rect);
    final rimWidth = rimThickness.clamp(12.0, 32.0);

    // -------------------------------------------------------------------------
    // 1. Meniscus Lens Refraction Band (Thick curved glass perimeter)
    // -------------------------------------------------------------------------
    final bandRRect = outerRRect.deflate(rimWidth * 0.45);
    final bandPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = rimWidth * 0.9;

    // Directional light vector (default ~top-left to bottom-right)
    final cosA = math.cos(lightAngle);
    final sinA = math.sin(lightAngle);
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final lightStart = center + Offset(-cosA * size.width * 0.55, -sinA * size.height * 0.55);
    final lightEnd = center + Offset(cosA * size.width * 0.55, sinA * size.height * 0.55);

    bandPaint.shader = ui.Gradient.linear(
      lightStart,
      lightEnd,
      [
        // Facing light: luminous meniscus refraction
        Colors.white.withValues(alpha: (0.28 * specularIntensity).clamp(0.0, 0.6)),
        // Top-left transition with subtle tint
        tintColor.withValues(alpha: 0.15),
        // Sides: chromatic prismatic dispersion
        const Color(0xFF00E5FF).withValues(alpha: 0.12 * specularIntensity),
        const Color(0xFFFF2A85).withValues(alpha: 0.09 * specularIntensity),
        // Away from light: internal total reflection shadow
        Colors.black.withValues(alpha: 0.32),
      ],
      const [0.0, 0.25, 0.55, 0.78, 1.0],
    );
    canvas.drawRRect(bandRRect, bandPaint);

    // -------------------------------------------------------------------------
    // 2. Inner Lens Transition Ridge (Boundary where curved rim meets flat center)
    // -------------------------------------------------------------------------
    final innerRidgeRRect = outerRRect.deflate(rimWidth);
    final innerRidgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    innerRidgePaint.shader = ui.Gradient.linear(
      Offset(size.width * 0.5, 0),
      Offset(size.width * 0.5, size.height),
      [
        // Top ridge: catches light leaving the meniscus
        Colors.white.withValues(alpha: (0.22 * specularIntensity).clamp(0.0, 0.5)),
        Colors.white.withValues(alpha: 0.04),
        // Bottom ridge: shadow from the lower meniscus slope
        Colors.black.withValues(alpha: 0.25),
      ],
      const [0.0, 0.4, 1.0],
    );
    canvas.drawRRect(innerRidgeRRect, innerRidgePaint);

    // -------------------------------------------------------------------------
    // 3. Razor-Sharp Outer Perimeter Specular Hairline
    // -------------------------------------------------------------------------
    final outerHairlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    outerHairlinePaint.shader = ui.Gradient.linear(
      Offset(0, 0),
      Offset(0, size.height),
      [
        // Crisp specular highlight along the upper rim
        Colors.white.withValues(alpha: (0.92 * specularIntensity).clamp(0.0, 1.0)),
        Colors.white.withValues(alpha: 0.40 * specularIntensity),
        Colors.white.withValues(alpha: 0.10),
        // Ground shadow along the very bottom rim
        Colors.black.withValues(alpha: 0.40),
      ],
      const [0.0, 0.20, 0.60, 1.0],
    );
    canvas.drawRRect(outerRRect.deflate(0.6), outerHairlinePaint);

    // -------------------------------------------------------------------------
    // 4. Anisotropic Glint on Top-Left Meniscus Corner
    // -------------------------------------------------------------------------
    final glintRadius = math.min(size.height * 0.45, 60.0);
    final glintPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = ui.Gradient.radial(
        Offset(size.height * 0.4, size.height * 0.28),
        glintRadius,
        [
          Colors.white.withValues(alpha: (0.45 * specularIntensity).clamp(0.0, 0.8)),
          Colors.white.withValues(alpha: 0.12 * specularIntensity),
          Colors.white.withValues(alpha: 0.0),
        ],
        const [0.0, 0.45, 1.0],
      );

    canvas.save();
    canvas.clipRRect(outerRRect);
    canvas.drawCircle(
      Offset(size.height * 0.4, size.height * 0.28),
      glintRadius,
      glintPaint,
    );
    canvas.restore();

    // -------------------------------------------------------------------------
    // 5. Internal Bottom Caustic Refraction Ridge (Internal Light Focusing)
    // -------------------------------------------------------------------------
    final causticPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    causticPaint.shader = ui.Gradient.linear(
      Offset(size.width * 0.5, size.height - rimWidth * 1.1),
      Offset(size.width * 0.5, size.height),
      [
        Colors.transparent,
        tintColor.withValues(alpha: (0.28 * specularIntensity).clamp(0.0, 0.6)),
        Colors.white.withValues(alpha: (0.42 * specularIntensity).clamp(0.0, 0.7)),
      ],
      const [0.0, 0.60, 1.0],
    );
    canvas.drawRRect(outerRRect.deflate(rimWidth * 0.35), causticPaint);
  }

  @override
  bool shouldRepaint(covariant MeniscusRimPainter oldDelegate) =>
      oldDelegate.rimThickness != rimThickness ||
      oldDelegate.meniscusThickness != meniscusThickness ||
      oldDelegate.specularIntensity != specularIntensity ||
      oldDelegate.lightAngle != lightAngle ||
      oldDelegate.tintColor != tintColor ||
      oldDelegate.borderRadius != borderRadius;
}
