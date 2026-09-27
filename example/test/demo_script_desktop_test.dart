import 'package:example/app/demo_id.dart';
import 'package:example/app/gallery_app.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/demo_script.dart';

/// Runs a couple of demo scripts in fake time under a desktop platform, to
/// prove [openMenu] opens the reactions menu on desktop (right-click), where
/// long press is not a default trigger. See
/// lib/src/trigger/reaction_trigger.dart's `defaultReactionTriggers`.
void main() {
  for (final id in [DemoId.quickStart, DemoId.messenger]) {
    testWidgets('demo script: ${id.slug} opens menus on desktop (windows)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        await tester.pumpWidget(
          GalleryApp(initialDemo: id, themeMode: ThemeMode.light),
        );
        await tester.pumpAndSettle();
        await runDemoScript(
          tester,
          id,
          pace: (duration) async {
            await tester.pump(duration);
            await tester.pumpAndSettle();
          },
        );
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }
}
