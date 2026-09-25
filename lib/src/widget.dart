import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'config.dart';
import 'enums.dart';
import 'painters.dart';

/// A pure Flutter-engine powered Liquid Glass widget that delivers optical
/// refraction, chromatic dispersion, lens distortion, specular highlights,
/// and frosted diffusion without any third-party packages.
///
/// Any property not explicitly provided to this widget will automatically
/// inherit from the ambient [LiquidGlassTheme], or fallback to
/// [LiquidGlassConfig.defaultConfig].
class LiquidGlass extends StatefulWidget {
  final Widget? child;
  final double width;
  final double height;
  final double cornerRadius;
  final LiquidGlassShape shape;
  final LiquidGlassEngineMode? engineMode;

  /// Refraction index / lens curvature strength (0.0 to 1.0).
  final double? refraction;

  /// Chromatic dispersion / aberration intensity (0.0 to 1.0).
  final double? chromaticAberration;

  /// Surface frostiness blur sigma (0.0 to 50.0).
  final double? blur;

  /// Specular glare brightness (0.0 to 1.0).
  final double? specularIntensity;

  /// Meniscus rim / 3D beveled edge thickness for analytical mode (0.5 to 4.0).
  final double? meniscusThickness;

  /// Width of the curved edge lens region in logical pixels (e.g. 24.0 to 32.0).
  final double? rimThickness;

  /// Global screen position of this glass widget in logical pixels.
  final Offset screenPosition;

  /// Dynamic wobble / ripple modulation factor (0.0 to 1.0).
  final double? wobble;

  /// Glass tint color.
  final Color? tintColor;

  /// Glass tint opacity (0.0 to 0.5).
  final double? tintOpacity;

  /// Physical drag velocity vector in logical pixels (drives fluid squish).
  final Offset velocity;

  /// Fluid surface tension oscillation amplitude (-1.0 to 1.0).
  final double fluidWobble;

  /// Dynamic light source angle in radians.
  final double? lightAngle;

  const LiquidGlass({
    super.key,
    this.child,
    this.width = 340,
    this.height = 200,
    this.cornerRadius = 32,
    this.shape = LiquidGlassShape.roundedRect,
    this.engineMode,
    this.refraction,
    this.chromaticAberration,
    this.blur,
    this.specularIntensity,
    this.meniscusThickness,
    this.rimThickness,
    this.screenPosition = Offset.zero,
    this.velocity = Offset.zero,
    this.fluidWobble = 0.0,
    this.wobble,
    this.tintColor,
    this.tintOpacity,
    this.lightAngle,
  });

  @override
  State<LiquidGlass> createState() => _LiquidGlassState();
}

class _LiquidGlassState extends State<LiquidGlass>
    with SingleTickerProviderStateMixin {
  static ui.FragmentProgram? _program;
  static bool _loadingProgram = false;

  AnimationController? _tickerController;
  ui.FragmentShader? _shader;
  bool _shaderAvailable = false;

  @override
  void initState() {
    super.initState();
    _tickerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _loadShaderIfSupported();
  }

  void _loadShaderIfSupported() {
    if (_program != null) {
      setState(() {
        _shaderAvailable = true;
      });
      return;
    }

    if (_loadingProgram) return;
    _loadingProgram = true;

    bool isShaderSupported = false;
    try {
      isShaderSupported = ui.ImageFilter.isShaderFilterSupported;
    } catch (_) {
      isShaderSupported = false;
    }

    if (isShaderSupported) {
      // First try loading with package asset prefix, fallback to direct path
      ui.FragmentProgram.fromAsset('packages/liquid_glass/shaders/liquid_glass.frag')
          .then((program) {
        if (mounted) {
          setState(() {
            _program = program;
            _shaderAvailable = true;
          });
        }
      }).catchError((error) {
        // Fallback for when root project declares shader directly
        ui.FragmentProgram.fromAsset('shaders/liquid_glass.frag').then((program) {
          if (mounted) {
            setState(() {
              _program = program;
              _shaderAvailable = true;
            });
          }
        }).catchError((fallbackError) {
          if (kDebugMode) {
            print('LiquidGlass: FragmentProgram load error: $fallbackError');
          }
        });
      });
    } else {
      if (kDebugMode) {
        print('LiquidGlass: ImageFilter.isShaderFilterSupported is false. Using Analytical Optics mode.');
      }
    }
  }

  @override
  void dispose() {
    _tickerController?.dispose();
    _shader?.dispose();
    super.dispose();
  }

  ShapeBorder _getShapeBorder() {
    switch (widget.shape) {
      case LiquidGlassShape.circle:
        return const CircleBorder();
      case LiquidGlassShape.pill:
        return const StadiumBorder();
      case LiquidGlassShape.roundedRect:
        return RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(widget.cornerRadius),
        );
    }
  }

  BorderRadius _getBorderRadius() {
    switch (widget.shape) {
      case LiquidGlassShape.circle:
        return BorderRadius.circular(widget.width / 2);
      case LiquidGlassShape.pill:
        return BorderRadius.circular(widget.height / 2);
      case LiquidGlassShape.roundedRect:
        return BorderRadius.circular(widget.cornerRadius);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Resolve ambient or global configuration
    final config = LiquidGlassTheme.of(context);

    final effectiveEngineMode = widget.engineMode ?? config.engineMode;
    final effectiveRefraction = widget.refraction ?? config.refraction;
    final effectiveChromaticAberration =
        widget.chromaticAberration ?? config.chromaticAberration;
    final effectiveBlur = widget.blur ?? config.blur;
    final effectiveSpecularIntensity =
        widget.specularIntensity ?? config.specularIntensity;
    final effectiveRimThickness = widget.rimThickness ?? config.rimThickness;
    final effectiveMeniscusThickness =
        widget.meniscusThickness ?? config.meniscusThickness;
    final effectiveTintColor = widget.tintColor ?? config.tintColor;
    final effectiveTintOpacity = widget.tintOpacity ?? config.tintOpacity;
    final effectiveLightAngle = widget.lightAngle ?? config.lightAngle;

    final borderRadius = _getBorderRadius();

    return AnimatedBuilder(
      animation: _tickerController!,
      builder: (context, _) {
        final useShader = effectiveEngineMode == LiquidGlassEngineMode.glslShader &&
            _shaderAvailable &&
            _program != null;

        final mediaQuery = MediaQuery.maybeOf(context);
        final pixelRatio = mediaQuery?.devicePixelRatio ?? 1.0;
        final screenSize = mediaQuery?.size ?? Size(widget.width, widget.height);

        ui.ImageFilter imageFilter;

        if (useShader) {
          try {
            _shader?.dispose();
            _shader = _program!.fragmentShader();

            double radius;
            switch (widget.shape) {
              case LiquidGlassShape.circle:
                radius = widget.width / 2;
                break;
              case LiquidGlassShape.pill:
                radius = widget.height / 2;
                break;
              case LiquidGlassShape.roundedRect:
                radius = widget.cornerRadius;
                break;
            }

            // Uniform 0, 1: u_size in physical pixels
            _shader!.setFloat(0, screenSize.width * pixelRatio);
            _shader!.setFloat(1, screenSize.height * pixelRatio);

            // Uniform 2, 3, 4, 5: u_rect in physical pixels
            _shader!.setFloat(2, widget.screenPosition.dx * pixelRatio);
            _shader!.setFloat(3, widget.screenPosition.dy * pixelRatio);
            _shader!.setFloat(4, widget.width * pixelRatio);
            _shader!.setFloat(5, widget.height * pixelRatio);

            // Uniform 6: u_corner_radius
            _shader!.setFloat(6, radius * pixelRatio);

            // Uniform 7: u_rim_thickness
            _shader!.setFloat(7, effectiveRimThickness * pixelRatio);

            // Uniform 8: u_refraction
            _shader!.setFloat(8, effectiveRefraction * 42.0 * pixelRatio);

            // Uniform 9: u_dispersion
            _shader!.setFloat(9, effectiveChromaticAberration * 0.15);

            // Uniform 10: u_frost
            _shader!.setFloat(10, (effectiveBlur / 40.0).clamp(0.0, 1.0));

            // Uniform 11: u_specular
            _shader!.setFloat(11, effectiveSpecularIntensity);

            // Uniform 12: u_tint
            _shader!.setFloat(12, effectiveTintOpacity * 2.0);

            // Uniform 13, 14: u_velocity
            _shader!.setFloat(13, widget.velocity.dx * pixelRatio);
            _shader!.setFloat(14, widget.velocity.dy * pixelRatio);

            // Uniform 15: u_fluid_wobble
            _shader!.setFloat(15, widget.fluidWobble);

            imageFilter = ui.ImageFilter.shader(_shader!);
          } catch (e) {
            imageFilter = _buildAnalyticalFilter(effectiveBlur, effectiveRefraction);
          }
        } else {
          imageFilter = _buildAnalyticalFilter(effectiveBlur, effectiveRefraction);
        }

        const fluidMargin = 48.0;
        final totalWidth = widget.width + fluidMargin * 2;
        final totalHeight = widget.height + fluidMargin * 2;

        if (useShader) {
          return SizedBox(
            width: totalWidth,
            height: totalHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                BackdropFilter(
                  filter: imageFilter,
                  blendMode: BlendMode.srcOver,
                  child: const SizedBox.expand(),
                ),
                if (widget.child != null)
                  Center(
                    child: SizedBox(
                      width: widget.width,
                      height: widget.height,
                      child: widget.child!,
                    ),
                  ),
              ],
            ),
          );
        }

        // Compute fluid squish and volume-preserving elasticity
        final speedX = widget.velocity.dx.abs();
        final speedY = widget.velocity.dy.abs();
        final ex = (speedX * 0.00003).clamp(0.0, 0.05);
        final ey = (speedY * 0.00003).clamp(0.0, 0.05);
        final wobble = (widget.fluidWobble * 0.035).clamp(-0.035, 0.035);
        final scaleX = (1.0 + (ex - ey * 0.5) + wobble).clamp(0.94, 1.06);
        final scaleY = (1.0 + (ey - ex * 0.5) - wobble).clamp(0.94, 1.06);

        // Fallback for Web and platforms where runtime GLSL shaders are unsupported
        return SizedBox(
          width: totalWidth,
          height: totalHeight,
          child: Center(
            child: Transform.scale(
              scaleX: scaleX,
              scaleY: scaleY,
              child: Container(
                width: widget.width,
                height: widget.height,
                decoration: ShapeDecoration(
                  shape: _getShapeBorder(),
                  shadows: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 30,
                      spreadRadius: -4,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: borderRadius,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      BackdropFilter(
                        filter: imageFilter,
                        blendMode: BlendMode.srcOver,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: borderRadius,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(
                                  alpha: (0.20 * effectiveSpecularIntensity)
                                      .clamp(0.08, 0.40),
                                ),
                                Colors.white.withValues(alpha: 0.05),
                                Colors.white.withValues(alpha: 0.02),
                              ],
                              stops: const [0.0, 0.50, 1.0],
                            ),
                          ),
                        ),
                      ),
                      CustomPaint(
                        painter: MeniscusRimPainter(
                          borderRadius: borderRadius,
                          rimThickness: effectiveRimThickness,
                          meniscusThickness: effectiveMeniscusThickness,
                          lightAngle: effectiveLightAngle,
                          specularIntensity: effectiveSpecularIntensity,
                          tintColor: effectiveTintColor,
                        ),
                      ),
                      if (widget.child != null)
                        Center(
                          child: SizedBox(
                            width: widget.width,
                            height: widget.height,
                            child: widget.child!,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  ui.ImageFilter _buildAnalyticalFilter(double blur, double refraction) {
    // Classic glassmorphic backdrop blur
    final blurSigma = blur > 0 ? blur : 20.0;
    return ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma);
  }
}
