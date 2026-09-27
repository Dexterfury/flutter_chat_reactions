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

  testWidgets('scrollable: false renders rows in a plain Column', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        const ReactionDetailsList(
          reactions: [
            ReactionSummary(
              emoji: '👍',
              count: 1,
              users: [ReactionUser(id: 'u1', name: 'Ada')],
            ),
          ],
          scrollable: false,
        ),
      ),
    );
    expect(find.byType(ListView), findsNothing);
    expect(find.text('Ada'), findsOneWidget);
  });

  testWidgets('a user with an avatarUrl shows the avatar image', (
    tester,
  ) async {
    // NetworkImage has no real network in widget tests; suppress the
    // resulting load-failure error so it doesn't fail the test.
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {};
    addTearDown(() => FlutterError.onError = originalOnError);

    await tester.pumpWidget(
      harness(
        const ReactionDetailsList(
          reactions: [
            ReactionSummary(
              emoji: '🔥',
              count: 1,
              users: [
                ReactionUser(
                  id: 'u1',
                  name: 'Ada',
                  avatarUrl: 'https://example.com/a.png',
                ),
              ],
            ),
          ],
        ),
      ),
    );
    await tester.pump();
    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
    expect(avatar.backgroundImage, isA<NetworkImage>());
    expect(avatar.child, isNull);
  });

  group('emojiBuilder', () {
    Widget party(BuildContext context, String emoji, double size) =>
        emoji == ':party:'
        ? SizedBox(key: const Key('party-image'), width: size, height: size)
        : Text(emoji);

    const custom = [
      ReactionSummary(
        emoji: ':party:',
        count: 1,
        users: [ReactionUser(id: 'u1', name: 'Ada')],
      ),
      ReactionSummary(emoji: ':party:', count: 2),
    ];

    testWidgets('ReactionDetailsList renders custom emoji', (tester) async {
      await tester.pumpWidget(
        harness(ReactionDetailsList(reactions: custom, emojiBuilder: party)),
      );
      expect(find.text(':party:'), findsNothing);
      expect(find.byKey(const Key('party-image')), findsNWidgets(2));
    });

    testWidgets('showReactionDetails renders custom emoji in tabs and rows', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showReactionDetails(
                context,
                custom.take(1).toList(),
                emojiBuilder: party,
              ),
              child: const Text('details'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('details'));
      await tester.pumpAndSettle();
      expect(find.textContaining(':party:'), findsNothing);
      // One in the emoji tab, one in the user row of the "All" tab.
      expect(find.byKey(const Key('party-image')), findsNWidgets(2));
    });

    testWidgets('BottomSheetPresenter passes the menu emojiBuilder', (
      tester,
    ) async {
      final menu = ReactionsMenuContext(
        anchorRect: const Rect.fromLTWH(0, 0, 10, 10),
        messageBuilder: (_) => const SizedBox(),
        quickReactions: const ['👍'],
        reactions: custom.take(1).toList(),
        emojiBuilder: party,
      );
      await tester.pumpWidget(
        harness(
          PresenterLauncher(
            presenter: const BottomSheetPresenter(showReactionDetails: true),
            menu: menu,
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Ada'), findsOneWidget);
      expect(find.text(':party:'), findsNothing);
      expect(find.byKey(const Key('party-image')), findsOneWidget);
    });
  });
}
