import 'package:example/widgets/bubble_row.dart';
import 'package:example/widgets/demo_chat_model.dart';
import 'package:example/widgets/message_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DemoChatModel chat;

  setUp(() => chat = DemoChatModel());
  tearDown(() => chat.dispose());

  Future<void> pumpRows(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListenableBuilder(
            listenable: chat,
            builder: (context, _) => ListView(
              children: [
                for (final m in chat.messages)
                  BubbleRow(message: m, chat: chat, actionsFor: actionsFor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders keyed bubbles and summaries', (tester) async {
    await pumpRows(tester);
    expect(find.byKey(const ValueKey('msg-m1')), findsOneWidget);
    expect(find.byKey(const ValueKey('reactable-m2')), findsOneWidget);
    expect(find.byKey(const ValueKey('summary-m2')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('summary-m1')),
      findsNothing,
      reason: 'no summary without reactions',
    );
  });

  testWidgets('long-press, react, and the chip appears', (tester) async {
    await pumpRows(tester);
    await tester.longPress(find.byKey(const ValueKey('msg-m1')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: find.byType(ReactionBar), matching: find.text('😮')),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('summary-m1')),
        matching: find.text('😮'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('tapping a chip toggles it', (tester) async {
    await pumpRows(tester);
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('summary-m2')),
        matching: find.text('👍'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('summary-m2')),
        matching: find.text('3'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('own messages align to the end', (tester) async {
    await pumpRows(tester);
    final mine = tester.getRect(find.byKey(const ValueKey('msg-m2')));
    final theirs = tester.getRect(find.byKey(const ValueKey('msg-m1')));
    expect(mine.right, greaterThan(theirs.right));
  });
}
