/// Geometrical shape modes supported by [LiquidGlass].
enum LiquidGlassShape {
  /// Rounded rectangle with configurable [cornerRadius].
  roundedRect,

  /// Capsule / Stadium pill where ends are fully semicircular.
  pill,

  /// Symmetrical circle where radius is width / 2.
  circle,
}

/// Rendering engine backend modes supported by [LiquidGlass].
enum LiquidGlassEngineMode {
  /// Hardware-accelerated runtime GLSL fragment shader utilizing Impeller/Skia
  /// for authentic Snell's law refraction, chromatic dispersion, and 3D specular rim.
  glslShader,

  /// Pure Canvas / Matrix optics fallback for platforms or test environments
  /// where runtime GLSL shaders are unavailable.
  analyticalOptics,
}
