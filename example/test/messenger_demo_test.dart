import 'package:example/adapters/emoji_picker_sheet.dart';
import 'package:example/demos/messenger_demo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, {EmojiPickerLauncher? pick}) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(home: MessengerDemo(pickEmoji: pick ?? (_) async => '🔥')),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('uses the focused overlay (blur) with actions', (tester) async {
    await pump(tester);
    await tester.longPress(find.byKey(const ValueKey('msg-m1')));
    await tester.pumpAndSettle();
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.text('Reply'), findsOneWidget);
    expect(find.text('Delete'), findsNothing, reason: "not the user's message");
  });

  testWidgets('"+" opens the picker and applies its emoji', (tester) async {
    await pump(tester);
    await tester.longPress(find.byKey(const ValueKey('msg-m1')));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('More reactions'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('summary-m1')),
        matching: find.text('🔥'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a cancelled picker changes nothing', (tester) async {
    await pump(tester, pick: (_) async => null);
    await tester.longPress(find.byKey(const ValueKey('msg-m1')));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('More reactions'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('summary-m1')),
      findsOneWidget,
      reason: 'overlay summary wraps the bubble even when empty',
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('summary-m1')),
        matching: find.byType(Text),
      ),
      findsOneWidget,
      reason: 'only the bubble text, no reaction',
    );
  });

  testWidgets('tapping the stacked summary shows who reacted', (tester) async {
    await pump(tester);
    final summary = find.byKey(const ValueKey('summary-m2'));
    await tester.tap(find.descendant(of: summary, matching: find.text('3')));
    await tester.pumpAndSettle();
    expect(find.text('Sam'), findsOneWidget);
    expect(find.text('Priya'), findsOneWidget);
  });

  testWidgets('summary is the stacked layout overlaid on the bubble', (
    tester,
  ) async {
    await pump(tester);
    final view = tester.widget<ReactionsSummaryView>(
      find.byKey(const ValueKey('summary-m2')),
    );
    expect(view.layout, ReactionSummaryLayout.stacked);
    expect(view.overlayChild, isNotNull);
  });
}
