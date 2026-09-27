import 'package:example/demos/custom_demo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: CustomDemo()));
    await tester.pumpAndSettle();
  }

  testWidgets('shows a radial ring of reactions around the message', (
    tester,
  ) async {
    await pump(tester);
    final anchor = tester.getRect(find.byKey(const ValueKey('msg-m2')));
    await tester.longPress(find.byKey(const ValueKey('msg-m2')));
    await tester.pumpAndSettle();

    expect(find.byType(ReactionBar), findsNothing, reason: 'fully custom UI');
    final centers = [
      for (final emoji in kDefaultQuickReactions)
        tester.getCenter(find.byKey(ValueKey('radial-$emoji'))),
    ];
    final ringCenter =
        centers.reduce((a, b) => a + b) / centers.length.toDouble();
    for (final c in centers) {
      expect((c - ringCenter).distance, closeTo(100, 1));
    }
    // The ring is centred on the message unless clamped to the screen.
    expect((ringCenter - anchor.center).distance, lessThan(120));
  });

  testWidgets('tapping a radial item reacts and closes the menu', (
    tester,
  ) async {
    await pump(tester);
    await tester.longPress(find.byKey(const ValueKey('msg-m2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('radial-🙏')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('radial-🙏')), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('summary-m2')),
        matching: find.text('🙏'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('tap outside dismisses', (tester) async {
    await pump(tester);
    await tester.longPress(find.byKey(const ValueKey('msg-m2')));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(8, 830));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('radial-👍')), findsNothing);
  });

  testWidgets('radial items are accessible buttons', (tester) async {
    await pump(tester);
    await tester.longPress(find.byKey(const ValueKey('msg-m2')));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('thumbs up'), findsOneWidget);
  });
}
