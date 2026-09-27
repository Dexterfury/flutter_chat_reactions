import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

const reactions = [
  ReactionSummary(
    emoji: '👍',
    count: 2,
    users: [
      ReactionUser(id: 'u1', name: 'Ada'),
      ReactionUser(id: 'u2', name: 'Bo'),
    ],
  ),
  ReactionSummary(
    emoji: '❤️',
    count: 1,
    users: [ReactionUser(id: 'u3')],
  ),
];

void main() {
  testWidgets('showReactionDetails lists users per tab', (tester) async {
    await tester.pumpWidget(
      harness(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showReactionDetails(context, reactions),
            child: const Text('details'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('details'));
    await tester.pumpAndSettle();

    expect(find.text('All 3'), findsOneWidget);
    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('u3'), findsOneWidget, reason: 'falls back to id');

    await tester.tap(find.text('❤️ 1'));
    await tester.pumpAndSettle();
    expect(find.text('Ada'), findsNothing);
    expect(find.text('u3'), findsOneWidget);
  });

  testWidgets('ReactionDetailsList shows a count when users are unknown', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        const ReactionDetailsList(
          reactions: [ReactionSummary(emoji: '🔥', count: 4)],
        ),
      ),
    );
    expect(find.text('4 reactions'), findsOneWidget);
  });
}
