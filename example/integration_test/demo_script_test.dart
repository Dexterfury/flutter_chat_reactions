import 'package:example/app/demo_id.dart';
import 'package:example/app/gallery_app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'demo_script.dart';

/// Runs one demo's script in real time on a device or simulator.
///
///   flutter test integration_test/demo_script_test.dart -d &lt;device&gt; \
///     --dart-define=DEMO=messenger --dart-define=THEME=dark
///
/// Plan 4's GIF workflow records the simulator while this runs.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final demo = DemoId.fromEnvironment() ?? DemoId.messenger;

  testWidgets('demo script: ${demo.slug}', (tester) async {
    await tester.pumpWidget(
      GalleryApp(initialDemo: demo, themeMode: themeModeFromEnvironment()),
    );
    await tester.pumpAndSettle();
    await runDemoScript(
      tester,
      demo,
      pace: (duration) async {
        await Future<void>.delayed(duration);
        await tester.pumpAndSettle();
      },
    );
  });
}
