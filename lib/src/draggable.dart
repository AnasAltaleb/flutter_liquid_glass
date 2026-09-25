import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'config.dart';
import 'enums.dart';
import 'widget.dart';

/// An interactive, draggable liquid glass container with fluid squish & stretch
/// inertia and damped surface-tension wobble.
///
/// Can be placed inside a [Stack] anywhere in your application:
///
/// ```dart
/// Stack(
///   children: [
///     const MyBackground(),
///     DraggableLiquidGlass(
///       width: 400,
///       height: 70,
///       shape: LiquidGlassShape.pill,
///       child: const MySearchBar(),
///     ),
///   ],
/// )
/// ```
class DraggableLiquidGlass extends StatefulWidget {
  final Widget? child;
  final double width;
  final double height;
  final double cornerRadius;
  final LiquidGlassShape shape;
  final Offset? initialPosition;
  final LiquidGlassEngineMode? engineMode;

  /// Optional per-widget property overrides (otherwise inherits from [LiquidGlassTheme])
  final double? refraction;
  final double? chromaticAberration;
  final double? blur;
  final double? specularIntensity;
  final double? rimThickness;
  final double? meniscusThickness;
  final Color? tintColor;
  final double? tintOpacity;
  final double? lightAngle;

  const DraggableLiquidGlass({
    super.key,
    this.child,
    this.width = 360,
    this.height = 200,
    this.cornerRadius = 32,
    this.shape = LiquidGlassShape.roundedRect,
    this.initialPosition,
    this.engineMode,
    this.refraction,
    this.chromaticAberration,
    this.blur,
    this.specularIntensity,
    this.rimThickness,
    this.meniscusThickness,
    this.tintColor,
    this.tintOpacity,
    this.lightAngle,
  });

  @override
  State<DraggableLiquidGlass> createState() => _DraggableLiquidGlassState();
}

class _DraggableLiquidGlassState extends State<DraggableLiquidGlass>
    with SingleTickerProviderStateMixin {
  late Offset _position;
  Offset _velocity = Offset.zero;
  Offset _releaseVelocity = Offset.zero;
  double _fluidWobble = 0.0;
  bool _isDragging = false;
  DateTime _lastPanTime = DateTime.now();

  late final AnimationController _physicsController;

  @override
  void initState() {
    super.initState();
    _position = widget.initialPosition ?? const Offset(60, 120);

    _physicsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _physicsController.addListener(() {
      final t = _physicsController.value;
      // Damped harmonic oscillator for liquid surface tension wobble
      final decay = math.exp(-5.0 * t);
      final osc = math.sin(t * math.pi * 4.0) * decay;
      final speedFactor = (_releaseVelocity.distance * 0.0006).clamp(0.0, 1.0);
      setState(() {
        _fluidWobble = osc * speedFactor;
        _velocity = _releaseVelocity * decay;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.initialPosition == null && _position == const Offset(60, 120)) {
      final size = MediaQuery.sizeOf(context);
      _position = Offset(
        (size.width - widget.width) / 2,
        (size.height - widget.height) / 2,
      );
    }
  }

  @override
  void dispose() {
    _physicsController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    _physicsController.stop();
    _lastPanTime = DateTime.now();
    setState(() {
      _isDragging = true;
      _fluidWobble = 0.0;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final now = DateTime.now();
    final elapsedMs = now.difference(_lastPanTime).inMilliseconds;
    _lastPanTime = now;
    final dt = (elapsedMs / 1000.0).clamp(0.008, 0.05);

    final instantV = details.delta / dt;

    final screenSize = MediaQuery.maybeSizeOf(context) ?? const Size(800, 600);
    final effectiveWidth = math.min(widget.width, math.max(120.0, screenSize.width - 32.0));
    const minX = 16.0;
    final maxX = math.max(minX, screenSize.width - effectiveWidth - 16.0);
    const minY = 16.0;
    final maxY = math.max(minY, screenSize.height - widget.height - 40.0);

    setState(() {
      _position = Offset(
        (_position.dx + details.delta.dx).clamp(minX, maxX),
        (_position.dy + details.delta.dy).clamp(minY, maxY),
      );

      // Smooth velocity with viscous exponential moving average
      _velocity = _velocity * 0.80 + instantV * 0.20;
      final speed = _velocity.distance;
      if (speed > 1200.0) {
        _velocity = (_velocity / speed) * 1200.0;
      }
      _fluidWobble = 0.0;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _isDragging = false;
    final flingV = details.velocity.pixelsPerSecond;
    if (flingV.distance > 50.0) {
      _releaseVelocity = _velocity * 0.4 + flingV * 0.6;
    } else {
      _releaseVelocity = _velocity;
    }

    _physicsController.reset();
    _physicsController.forward();
  }

  @override
  Widget build(BuildContext context) {
    const fluidMargin = 48.0;

    return Positioned(
      left: _position.dx - fluidMargin,
      top: _position.dy - fluidMargin,
      width: widget.width + fluidMargin * 2,
      height: widget.height + fluidMargin * 2,
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: MouseRegion(
          cursor: _isDragging ? SystemMouseCursors.grabbing : SystemMouseCursors.grab,
          child: LiquidGlass(
            width: widget.width,
            height: widget.height,
            cornerRadius: widget.cornerRadius,
            shape: widget.shape,
            engineMode: widget.engineMode,
            refraction: widget.refraction,
            chromaticAberration: widget.chromaticAberration,
            blur: widget.blur,
            specularIntensity: widget.specularIntensity,
            meniscusThickness: widget.meniscusThickness,
            rimThickness: widget.rimThickness,
            screenPosition: _position,
            velocity: _velocity,
            fluidWobble: _fluidWobble,
            tintColor: widget.tintColor,
            tintOpacity: widget.tintOpacity,
            lightAngle: widget.lightAngle,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
