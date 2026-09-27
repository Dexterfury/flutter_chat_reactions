import 'package:example/app/gallery_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/demo_script.dart';

/// Runs every registered demo script in fake time (fast) on flutter-tester.
void main() {
  for (final entry in demoScripts.entries) {
    testWidgets('demo script: ${entry.key.slug}', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        GalleryApp(initialDemo: entry.key, themeMode: ThemeMode.light),
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
    });
  }
}
