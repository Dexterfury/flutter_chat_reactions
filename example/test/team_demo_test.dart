import 'package:example/demos/team_demo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: TeamDemo()));
    await tester.pumpAndSettle();
  }

  testWidgets('long-press opens the compact bar (no blur) with team emoji', (
    tester,
  ) async {
    await pump(tester);
    await tester.longPress(find.byKey(const ValueKey('msg-m1')));
    await tester.pumpAndSettle();
    expect(find.byType(ReactionBar), findsOneWidget);
    expect(find.byType(BackdropFilter), findsNothing);
    expect(
      find.descendant(
        of: find.byType(ReactionBar),
        matching: find.byKey(const ValueKey('emoji-:ship_it:')),
      ),
      findsOneWidget,
    );
  });

  testWidgets('several reactions from the same user are kept', (tester) async {
    await pump(tester);
    for (final emoji in ['🎉', '👀']) {
      await tester.longPress(find.byKey(const ValueKey('msg-m1')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(ReactionBar),
          matching: find.text(emoji),
        ),
      );
      await tester.pumpAndSettle();
    }
    final summary = find.byKey(const ValueKey('summary-m1'));
    expect(
      find.descendant(of: summary, matching: find.text('🎉')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: summary, matching: find.text('👀')),
      findsOneWidget,
    );
  });

  testWidgets('custom emoji render in chips via emojiBuilder', (tester) async {
    await pump(tester);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('summary-m4')),
        matching: find.byKey(const ValueKey('emoji-:ship_it:')),
      ),
      findsOneWidget,
    );
  });

  testWidgets('"⋯" reveals message actions', (tester) async {
    await pump(tester);
    await tester.longPress(find.byKey(const ValueKey('msg-m1')));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('More actions'));
    await tester.pumpAndSettle();
    expect(find.text('Reply'), findsOneWidget);
  });

  test('team data includes shortcode reactions', () {
    expect(kTeamReactions, contains(':party:'));
    expect(
      teamReactions()['m4']!.where((r) => r.emoji == ':ship_it:'),
      hasLength(2),
    );
  });
}
