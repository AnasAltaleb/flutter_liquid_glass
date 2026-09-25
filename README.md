# liquid_glass

Authentic Apple VisionOS & iOS style Liquid Glass effect in pure Flutter with GLSL runtime refraction shaders, chromatic dispersion, edge meniscus lens, specular highlights, and squishy volume-preserving fluid physics.

Zero third-party packages required — runs purely on the Flutter engine (`dart:ui`, `BackdropFilter`, runtime shader with Impeller/Skia).

---

## Features

- **Physically Grounded Optics:** Real Snell's law refraction ray deflection along curved 3D meniscus lens perimeter.
- **Prismatic Chromatic Dispersion:** Wavelength-dependent light splitting along the boundary.
- **3D Specular Highlight & Caustics:** Realistic glossy overhead glare and internal caustic base ring.
- **Squishy Fluid Droplet Physics:** Volume-preserving elongation along drag velocity and compression in perpendicular axis, with damped surface-tension wobble.
- **Single Global/App-Level Configuration:** Configure once in `main()` with `LiquidGlassConfig.defaultConfig` or wrap with `LiquidGlassTheme`.
- **Zero Third-Party Dependencies:** 100% pure Flutter engine runtime shader.

---

## Getting Started

Add the package dependency to your `pubspec.yaml`:

```yaml
dependencies:
  liquid_glass:
    path: packages/liquid_glass
```

---

## Usage

### 1. Configure Once Per App (Global Setup)

In your `main.dart`, you can customize the liquid glass defaults once for your whole app:

```dart
import 'package:flutter/material.dart';
import 'package:liquid_glass/liquid_glass.dart';

void main() {
  // Set default config once for the whole app
  LiquidGlassConfig.defaultConfig = const LiquidGlassConfig(
    refraction: 0.70,
    chromaticAberration: 0.50,
    specularIntensity: 0.90,
    rimThickness: 28.0,
    tintColor: Color(0xFFE0F2FE),
    tintOpacity: 0.06,
  );

  runApp(const MyApp());
}
```

Or wrap your app (or any sub-tree) in a `LiquidGlassTheme`:

```dart
LiquidGlassTheme(
  config: const LiquidGlassConfig(
    refraction: 0.8,
    blur: 0.0,
  ),
  child: const HomeScreen(),
)
```

---

### 2. Use `LiquidGlass` Anywhere

All widgets automatically pick up your app's configuration:

```dart
LiquidGlass(
  width: 320,
  height: 64,
  shape: LiquidGlassShape.pill,
  child: const Center(
    child: Text('Apple Liquid Glass'),
  ),
)
```

If you wish to override a setting for a specific widget, simply pass it:

```dart
LiquidGlass(
  width: 120,
  height: 120,
  shape: LiquidGlassShape.circle,
  refraction: 0.95, // Per-widget override
  child: const Icon(Icons.star, color: Colors.white),
)
```

---

### 3. Interactive Draggable Liquid Glass

Add an interactive draggable liquid glass capsule with fluid squish & inertia:

```dart
Stack(
  children: [
    const BackgroundWidget(),
    DraggableLiquidGlass(
      width: 420,
      height: 70,
      shape: LiquidGlassShape.pill,
      child: const MySearchBar(),
    ),
  ],
)
```

---

## Configuration Options

| Option | Type | Default | Description |
|---|---|---|---|
| `engineMode` | `LiquidGlassEngineMode` | `glslShader` | `glslShader` (hardware GLSL) or `analyticalOptics` fallback. |
| `refraction` | `double` (0.0 to 1.0) | `0.65` | Refraction index / lens curvature strength. |
| `chromaticAberration` | `double` (0.0 to 1.0) | `0.50` | Color splitting intensity on the lens rim. |
| `blur` | `double` (0.0 to 50.0) | `0.0` | Center frostiness blur sigma (0 = crystal clear). |
| `specularIntensity` | `double` (0.0 to 1.0) | `0.90` | Specular glare and rim highlight brightness. |
| `rimThickness` | `double` | `26.0` | Width of the curved edge lens in logical pixels. |
| `tintColor` | `Color` | `0xFFE0F2FE` | Subtle glass tint tone. |
| `tintOpacity` | `double` (0.0 to 0.5) | `0.06` | Tint opacity. |
| `lightAngle` | `double` | `-0.75` | Primary directional light angle in radians. |
| `enableFluidPhysics` | `bool` | `true` | Volume-preserving squish and stretch when dragged. |
