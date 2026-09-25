import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass/liquid_glass.dart';

void main() {
  group('LiquidGlassConfig & Theme', () {
    test('default configuration has expected Apple liquid glass values', () {
      const config = LiquidGlassConfig();
      expect(config.refraction, 0.65);
      expect(config.chromaticAberration, 0.5);
      expect(config.blur, 0.0);
      expect(config.specularIntensity, 0.9);
      expect(config.rimThickness, 26.0);
      expect(config.enableFluidPhysics, true);
    });

    test('copyWith updates specified properties while preserving others', () {
      const config = LiquidGlassConfig();
      final updated = config.copyWith(
        refraction: 0.85,
        rimThickness: 32.0,
      );

      expect(updated.refraction, 0.85);
      expect(updated.rimThickness, 32.0);
      expect(updated.specularIntensity, 0.9); // preserved
      expect(updated.chromaticAberration, 0.5); // preserved
    });

    testWidgets('LiquidGlassTheme provides ambient config to descendants',
        (tester) async {
      const customConfig = LiquidGlassConfig(
        refraction: 0.92,
        specularIntensity: 0.77,
      );

      late LiquidGlassConfig resolvedConfig;

      await tester.pumpWidget(
        LiquidGlassTheme(
          config: customConfig,
          child: Builder(
            builder: (context) {
              resolvedConfig = LiquidGlassTheme.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(resolvedConfig.refraction, 0.92);
      expect(resolvedConfig.specularIntensity, 0.77);
    });

    testWidgets('LiquidGlass widget renders cleanly with analytical fallback in tests',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: LiquidGlass(
                width: 200,
                height: 80,
                shape: LiquidGlassShape.pill,
                child: Text('Test Glass'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Test Glass'), findsOneWidget);
    });

    testWidgets('DraggableLiquidGlass renders cleanly with child',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                DraggableLiquidGlass(
                  width: 200,
                  height: 80,
                  shape: LiquidGlassShape.pill,
                  child: Text('Draggable Test'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Draggable Test'), findsOneWidget);
    });
  });
}
