import 'package:example/app/gallery_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/demo_script.dart';

/// Phone surfaces every script must pass on (physical size, pixel ratio).
const Map<String, (Size, double)> _surfaces = {
  'phone': (Size(1170, 2532), 3),
  // iPhone SE: 375×667 logical.
  'iPhone SE': (Size(750, 1334), 2),
};

/// Runs every registered demo script in fake time (fast) on flutter-tester,
/// in light and dark mode, on a large and a small phone.
void main() {
  for (final entry in demoScripts.entries) {
    for (final themeMode in [ThemeMode.light, ThemeMode.dark]) {
      for (final surface in _surfaces.entries) {
        testWidgets(
          'demo script: ${entry.key.slug} (${themeMode.name}, ${surface.key})',
          (tester) async {
            final (physicalSize, devicePixelRatio) = surface.value;
            tester.view.physicalSize = physicalSize;
            tester.view.devicePixelRatio = devicePixelRatio;
            addTearDown(tester.view.reset);
            await tester.pumpWidget(
              GalleryApp(initialDemo: entry.key, themeMode: themeMode),
            );
            await tester.pumpAndSettle();
            await runDemoScript(
              tester,
              entry.key,
              pace: (duration) async {
                await tester.pump(duration);
                await tester.pumpAndSettle();
              },
            );
          },
        );
      }
    }
  }
}
