import 'package:example/app/demo_id.dart';
import 'package:example/app/gallery_app.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'demo_script.dart';

/// Runs one demo's script in real time on a device or simulator.
///
/// ```bash
/// flutter test integration_test/demo_script_test.dart -d <device> \
///   --dart-define=DEMO=messenger --dart-define=THEME=dark
/// ```
///
/// `--dart-define=PLATFORM=ios` (or `android`) makes the app behave as that
/// platform, so the long-press path can be run in real time on desktop.
///
/// Plan 4's GIF workflow records the simulator while this runs.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // Draw every frame (not only on explicit pumps) so recordings are smooth.
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  final demo = DemoId.fromEnvironment() ?? DemoId.messenger;
  final platform = _platformFromEnvironment();

  testWidgets('demo script: ${demo.slug}', (tester) async {
    // When a long press opens the menu, the Navigator cancels the pointers
    // that are still down (NavigatorState._cancelActivePointers). The live
    // binding treats that synthesized PointerCancelEvent as a *device* event
    // and drops it, so the message's LongPressGestureRecognizer never sees
    // the cancel (nor the later up, whose hit-test entry the cancel removed)
    // and stays stuck in the "possible" state: every later long press on the
    // same message is ignored. Letting device events through delivers the
    // cancel, as on a real device.
    binding.shouldPropagateDevicePointerEvents = true;
    // The binding paints a crosshair marker for every simulated (test-source)
    // pointer, which would show up in the GIFs. Dispatch the scripts' taps as
    // device events instead: not painted, and delivered to the app because
    // of the line above.
    hideTouchIndicators = true;
    debugDefaultTargetPlatformOverride = platform;
    // Explain gesture problems in the log (CI failures must explain
    // themselves). flutter_test requires these to be reset before the test
    // ends, hence the finally below.
    debugPrintGestureArenaDiagnostics = true;
    debugPrintRecognizerCallbacksTrace = true;
    try {
      await tester.pumpWidget(
        GalleryApp(initialDemo: demo, themeMode: themeModeFromEnvironment()),
      );
      await tester.pumpAndSettle();
      // tool/record_gifs.sh starts the simulator recording when it sees
      // DEMO_SCRIPT_START and stops it at DEMO_SCRIPT_END.
      debugPrint('DEMO_SCRIPT_START');
      await Future<void>.delayed(const Duration(seconds: 2));
      try {
        await runDemoScript(
          tester,
          demo,
          pace: (duration) async {
            await Future<void>.delayed(duration);
            await tester.pumpAndSettle();
          },
        );
      } catch (_) {
        _dumpState(tester);
        rethrow;
      }
      debugPrint('DEMO_SCRIPT_END');
    } finally {
      debugPrintGestureArenaDiagnostics = false;
      debugPrintRecognizerCallbacksTrace = false;
      debugDefaultTargetPlatformOverride = null;
      binding.shouldPropagateDevicePointerEvents = false;
      hideTouchIndicators = false;
    }
  });
}

/// The platform from `--dart-define=PLATFORM=...`, or null (the real one).
TargetPlatform? _platformFromEnvironment() {
  const name = String.fromEnvironment('PLATFORM');
  for (final platform in TargetPlatform.values) {
    if (platform.name.toLowerCase() == name.toLowerCase()) return platform;
  }
  return null;
}

/// Prints what is on screen, so a failed CI run explains itself.
void _dumpState(WidgetTester tester) {
  int count(Finder finder) => finder.evaluate().length;
  final lines = <String>[
    'DEMO_STATE platform=$defaultTargetPlatform',
    'DEMO_STATE ReactionBar=${count(find.byType(ReactionBar))} '
        'ModalBarrier=${count(find.byType(ModalBarrier))} '
        'BottomSheet=${count(find.byType(BottomSheet))}',
  ];
  final views = find.byType(MediaQuery);
  if (views.evaluate().isNotEmpty) {
    final size = MediaQuery.sizeOf(views.evaluate().first);
    lines.add('DEMO_STATE MediaQuery.size=$size');
  }
  for (var i = 1; i <= 5; i++) {
    final finder = find.byKey(ValueKey('msg-m$i'), skipOffstage: false);
    final n = count(finder);
    if (n == 0) continue;
    final rects = [
      for (final element in finder.evaluate())
        if (element.renderObject case final RenderBox box when box.attached)
          box.localToGlobal(Offset.zero) & box.size,
    ];
    lines.add('DEMO_STATE msg-m$i count=$n rects=$rects');
  }
  lines.forEach(debugPrint);
}
