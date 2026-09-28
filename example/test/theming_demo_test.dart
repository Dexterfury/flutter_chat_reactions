import 'package:example/app/demo_id.dart';
import 'package:example/app/gallery_app.dart';
import 'package:example/data/sample_chat.dart';
import 'package:example/demos/theming_demo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: ThemingDemo()));
    await tester.pumpAndSettle();
  }

  BuildContext previewContext(WidgetTester tester) =>
      tester.element(find.byKey(const ValueKey('msg-m1')));

  testWidgets('brightness toggle darkens only the preview', (tester) async {
    await pump(tester);
    expect(Theme.of(previewContext(tester)).brightness, Brightness.light);
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(Theme.of(previewContext(tester)).brightness, Brightness.dark);
  });

  testWidgets('style toggle forces Cupertino and the menu follows', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('Cupertino'));
    await tester.pumpAndSettle();
    expect(ChatReactionsTheme.of(previewContext(tester)).isCupertino, isTrue);

    await tester.longPress(find.byKey(const ValueKey('msg-m1')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(ReactionActionMenu),
        matching: find.byType(Divider),
      ),
      findsWidgets,
      reason:
          'Cupertino action menu draws dividers (the page has its own Divider too)',
    );
  });

  testWidgets('RTL flips message alignment', (tester) async {
    await pump(tester);
    final before = tester.getRect(find.byKey(const ValueKey('msg-m1')));
    await tester.tap(find.byKey(const ValueKey('control-rtl')));
    await tester.pumpAndSettle();
    final after = tester.getRect(find.byKey(const ValueKey('msg-m1')));
    expect(after.center.dx, greaterThan(before.center.dx));
  });

  testWidgets('RTL swaps the sample text to Arabic and back', (tester) async {
    await pump(tester);
    expect(find.text('Morning! Did the new build land?'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('control-rtl')));
    await tester.pumpAndSettle();
    expect(find.text(kRtlSampleTexts['m1']!), findsOneWidget);
    expect(find.text('Morning! Did the new build land?'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('control-rtl')));
    await tester.pumpAndSettle();
    expect(find.text('Morning! Did the new build land?'), findsOneWidget);
    expect(find.text(kRtlSampleTexts['m1']!), findsNothing);
  });

  testWidgets('text scale 2× makes the focused overlay fall back to a sheet', (
    tester,
  ) async {
    await pump(tester);
    final slider = find.byKey(const ValueKey('control-text-scale'));
    await tester.drag(slider, const Offset(400, 0));
    await tester.pumpAndSettle();
    await tester.longPress(find.byKey(const ValueKey('msg-m1')));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
  });

  testWidgets('seed colour changes the preview colour scheme', (tester) async {
    await pump(tester);
    final before = Theme.of(previewContext(tester)).colorScheme.primary;
    await tester.tap(find.byKey(const ValueKey('control-seed-2')));
    await tester.pumpAndSettle();
    expect(Theme.of(previewContext(tester)).colorScheme.primary, isNot(before));
  });

  testWidgets('preview starts in the ambient (dark) brightness', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const GalleryApp(initialDemo: DemoId.theming, themeMode: ThemeMode.dark),
    );
    await tester.pumpAndSettle();
    expect(Theme.of(previewContext(tester)).brightness, Brightness.dark);
  });
}
