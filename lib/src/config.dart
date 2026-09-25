import 'package:flutter/material.dart';
import 'enums.dart';

/// Global and theme-level configuration for the Liquid Glass engine.
///
/// You can configure these options once per application either by setting
/// [LiquidGlassConfig.defaultConfig] in your `main()` function:
///
/// ```dart
/// void main() {
///   LiquidGlassConfig.defaultConfig = const LiquidGlassConfig(
///     refraction: 0.75,
///     chromaticAberration: 0.5,
///     rimThickness: 28.0,
///     specularIntensity: 0.9,
///   );
///   runApp(const MyApp());
/// }
/// ```
///
/// Or by wrapping your widget tree (or sub-tree) in a [LiquidGlassTheme]:
///
/// ```dart
/// LiquidGlassTheme(
///   config: const LiquidGlassConfig(
///     tintColor: Colors.amber,
///     tintOpacity: 0.08,
///   ),
///   child: const MyScreen(),
/// )
/// ```
@immutable
class LiquidGlassConfig {
  /// Default global configuration instance used across the entire application
  /// whenever a [LiquidGlass] widget does not have explicit property overrides
  /// or an ambient [LiquidGlassTheme].
  static LiquidGlassConfig defaultConfig = const LiquidGlassConfig();

  /// Rendering engine backend (GLSL runtime shader vs analytical optics fallback).
  final LiquidGlassEngineMode engineMode;

  /// Optical refraction strength / lens curvature factor (0.0 to 1.0).
  /// Higher values produce stronger light deflection along the curved meniscus.
  final double refraction;

  /// Prismatic chromatic dispersion / color splitting intensity (0.0 to 1.0).
  final double chromaticAberration;

  /// Gaussian frostiness blur sigma (0.0 to 50.0).
  /// 0.0 gives crystal clear refractive glass (Apple style); higher values frost the center.
  final double blur;

  /// Specular highlight brightness / glossy rim reflection intensity (0.0 to 1.0).
  final double specularIntensity;

  /// Width of the curved edge lens region in logical pixels (typically 20.0 to 36.0).
  final double rimThickness;

  /// 3D beveled edge thickness for analytical fallback mode.
  final double meniscusThickness;

  /// Subtle glass tint color.
  final Color tintColor;

  /// Glass tint opacity (0.0 to 0.5).
  final double tintOpacity;

  /// Primary light source angle in radians (e.g. -0.75 is approx -45 degrees top-left).
  final double lightAngle;

  /// Dynamic wobble / ripple modulation factor (0.0 to 1.0).
  final double wobble;

  /// Whether draggable instances squish and stretch like an authentic fluid droplet.
  final bool enableFluidPhysics;

  /// Elasticity factor governing how much the fluid elongates under drag velocity.
  final double fluidElasticity;

  const LiquidGlassConfig({
    this.engineMode = LiquidGlassEngineMode.glslShader,
    this.refraction = 0.65,
    this.chromaticAberration = 0.5,
    this.blur = 0.0,
    this.specularIntensity = 0.9,
    this.rimThickness = 26.0,
    this.meniscusThickness = 1.5,
    this.tintColor = const Color(0xFFE0F2FE),
    this.tintOpacity = 0.06,
    this.lightAngle = -0.75,
    this.wobble = 0.0,
    this.enableFluidPhysics = true,
    this.fluidElasticity = 0.00003,
  });

  /// Creates a copy of this configuration with the given fields replaced with new values.
  LiquidGlassConfig copyWith({
    LiquidGlassEngineMode? engineMode,
    double? refraction,
    double? chromaticAberration,
    double? blur,
    double? specularIntensity,
    double? rimThickness,
    double? meniscusThickness,
    Color? tintColor,
    double? tintOpacity,
    double? lightAngle,
    double? wobble,
    bool? enableFluidPhysics,
    double? fluidElasticity,
  }) {
    return LiquidGlassConfig(
      engineMode: engineMode ?? this.engineMode,
      refraction: refraction ?? this.refraction,
      chromaticAberration: chromaticAberration ?? this.chromaticAberration,
      blur: blur ?? this.blur,
      specularIntensity: specularIntensity ?? this.specularIntensity,
      rimThickness: rimThickness ?? this.rimThickness,
      meniscusThickness: meniscusThickness ?? this.meniscusThickness,
      tintColor: tintColor ?? this.tintColor,
      tintOpacity: tintOpacity ?? this.tintOpacity,
      lightAngle: lightAngle ?? this.lightAngle,
      wobble: wobble ?? this.wobble,
      enableFluidPhysics: enableFluidPhysics ?? this.enableFluidPhysics,
      fluidElasticity: fluidElasticity ?? this.fluidElasticity,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LiquidGlassConfig &&
        other.engineMode == engineMode &&
        other.refraction == refraction &&
        other.chromaticAberration == chromaticAberration &&
        other.blur == blur &&
        other.specularIntensity == specularIntensity &&
        other.rimThickness == rimThickness &&
        other.meniscusThickness == meniscusThickness &&
        other.tintColor == tintColor &&
        other.tintOpacity == tintOpacity &&
        other.lightAngle == lightAngle &&
        other.wobble == wobble &&
        other.enableFluidPhysics == enableFluidPhysics &&
        other.fluidElasticity == fluidElasticity;
  }

  @override
  int get hashCode => Object.hash(
        engineMode,
        refraction,
        chromaticAberration,
        blur,
        specularIntensity,
        rimThickness,
        meniscusThickness,
        tintColor,
        tintOpacity,
        lightAngle,
        wobble,
        enableFluidPhysics,
        fluidElasticity,
      );
}

/// An [InheritedTheme] that provides [LiquidGlassConfig] to descendants.
class LiquidGlassTheme extends InheritedTheme {
  /// The liquid glass configuration for this sub-tree.
  final LiquidGlassConfig config;

  const LiquidGlassTheme({
    super.key,
    required this.config,
    required super.child,
  });

  /// Retrieves the ambient [LiquidGlassConfig] from the closest [LiquidGlassTheme]
  /// ancestor, or falls back to [LiquidGlassConfig.defaultConfig].
  static LiquidGlassConfig of(BuildContext context) {
    final theme = context.dependOnInheritedWidgetOfExactType<LiquidGlassTheme>();
    return theme?.config ?? LiquidGlassConfig.defaultConfig;
  }

  @override
  bool updateShouldNotify(LiquidGlassTheme oldWidget) => config != oldWidget.config;

  @override
  Widget wrap(BuildContext context, Widget child) {
    return LiquidGlassTheme(config: config, child: child);
  }
}
