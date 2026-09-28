import 'package:example/demos/telegram_demo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: TelegramDemo()));
    await tester.pumpAndSettle();
  }

  testWidgets('long-press opens a bottom sheet with reaction details', (
    tester,
  ) async {
    await pump(tester);
    await tester.longPress(find.byKey(const ValueKey('msg-m2')));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    final sheet = find.byType(BottomSheet);
    expect(
      find.descendant(of: sheet, matching: find.byType(ReactionBar)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Sam')),
      findsOneWidget,
      reason: 'reaction details list (Sam also appears as a bubble author)',
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Pin')),
      findsOneWidget,
    );
  });

  testWidgets('Pin shows the pinned banner', (tester) async {
    await pump(tester);
    expect(find.byKey(const ValueKey('pinned-banner')), findsNothing);
    await tester.longPress(find.byKey(const ValueKey('msg-m1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pin'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('pinned-banner')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('pinned-banner')),
        matching: find.textContaining('Morning'),
      ),
      findsOneWidget,
    );
  });
}
