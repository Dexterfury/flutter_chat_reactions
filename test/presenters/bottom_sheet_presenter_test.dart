import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  testWidgets('Material: shows bar and actions; action selection closes', (
    tester,
  ) async {
    ReactionAction<dynamic>? action;
    var closed = false;
    await tester.pumpWidget(
      harness(
        PresenterLauncher(
          presenter: const BottomSheetPresenter(),
          menu: testMenu(onActionSelected: (a) => action = a),
          onClosed: () => closed = true,
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(ReactionBar), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(action?.id, 'delete');
    expect(closed, isTrue);
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('reaction selection closes and reports', (tester) async {
    String? emoji;
    await tester.pumpWidget(
      harness(
        PresenterLauncher(
          presenter: const BottomSheetPresenter(),
          menu: testMenu(onReactionSelected: (e) => emoji = e),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('❤️'));
    await tester.pumpAndSettle();
    expect(emoji, '❤️');
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('Cupertino: action sheet with cancel', (tester) async {
    await tester.pumpWidget(
      harness(
        PresenterLauncher(
          presenter: const BottomSheetPresenter(),
          menu: testMenu(),
        ),
        platform: TargetPlatform.iOS,
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoActionSheet), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoActionSheet), findsNothing);
  });

  testWidgets(
    'Material: dismiss before the sheet finishes building closes it',
    (tester) async {
      var closed = false;
      late ReactionsMenuContext menu;
      menu = testMenu();
      await tester.pumpWidget(
        harness(
          PresenterLauncher(
            presenter: const BottomSheetPresenter(),
            menu: menu,
            onClosed: () => closed = true,
          ),
        ),
      );
      await tester.tap(find.text('open'));
      menu.dismiss();
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      expect(closed, isTrue);
    },
  );

  testWidgets(
    'Cupertino: dismiss before the sheet finishes building closes it',
    (tester) async {
      var closed = false;
      late ReactionsMenuContext menu;
      menu = testMenu();
      await tester.pumpWidget(
        harness(
          PresenterLauncher(
            presenter: const BottomSheetPresenter(),
            menu: menu,
            onClosed: () => closed = true,
          ),
          platform: TargetPlatform.iOS,
        ),
      );
      await tester.tap(find.text('open'));
      menu.dismiss();
      await tester.pumpAndSettle();

      expect(find.byType(CupertinoActionSheet), findsNothing);
      expect(closed, isTrue);
    },
  );

  testWidgets('Cupertino: action tap reports and closes', (tester) async {
    ReactionAction<dynamic>? action;
    await tester.pumpWidget(
      harness(
        PresenterLauncher(
          presenter: const BottomSheetPresenter(),
          menu: testMenu(onActionSelected: (a) => action = a),
        ),
        platform: TargetPlatform.iOS,
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(action?.id, 'delete');
    expect(find.byType(CupertinoActionSheet), findsNothing);
  });

  testWidgets('Cupertino: showReactionDetails lists users', (tester) async {
    await tester.pumpWidget(
      harness(
        PresenterLauncher(
          presenter: const BottomSheetPresenter(showReactionDetails: true),
          menu: testMenu(
            reactions: const [
              ReactionSummary(
                emoji: '👍',
                count: 1,
                users: [ReactionUser(id: 'u1', name: 'Ada')],
              ),
            ],
          ),
        ),
        platform: TargetPlatform.iOS,
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Ada'), findsOneWidget);
  });

  testWidgets('Cupertino: showReactionDetails shrinks to fit a single user', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        PresenterLauncher(
          presenter: const BottomSheetPresenter(showReactionDetails: true),
          menu: testMenu(
            reactions: const [
              ReactionSummary(
                emoji: '👍',
                count: 1,
                users: [ReactionUser(id: 'u1', name: 'Ada')],
              ),
            ],
          ),
        ),
        platform: TargetPlatform.iOS,
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final height = tester
        .getSize(find.byKey(const Key('reaction-details-scroll')))
        .height;
    expect(
      height,
      lessThan(240),
      reason: 'a single row should not stretch to the 240px cap',
    );
  });

  testWidgets(
    'Cupertino: showReactionDetails caps at 240px and scrolls for many users',
    (tester) async {
      final users = [
        for (var i = 0; i < 20; i++) ReactionUser(id: 'u$i', name: 'User $i'),
      ];
      await tester.pumpWidget(
        harness(
          PresenterLauncher(
            presenter: const BottomSheetPresenter(showReactionDetails: true),
            menu: testMenu(
              reactions: [
                ReactionSummary(emoji: '👍', count: 20, users: users),
              ],
            ),
          ),
          platform: TargetPlatform.iOS,
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final scrollFinder = find.byKey(const Key('reaction-details-scroll'));
      final viewport = tester.getRect(scrollFinder);
      expect(viewport.height, 240);
      expect(find.text('User 0'), findsOneWidget);

      // The Column form is non-lazy, so every row exists in the tree even
      // when scrolled out of view; check position, not presence.
      final before = tester.getCenter(find.text('User 19'));
      expect(
        before.dy,
        greaterThan(viewport.bottom),
        reason: 'below the visible 240px viewport before scrolling',
      );

      await tester.drag(scrollFinder, const Offset(0, -2000));
      await tester.pumpAndSettle();

      final after = tester.getCenter(find.text('User 19'));
      expect(
        after.dy,
        inInclusiveRange(viewport.top, viewport.bottom),
        reason: 'scrolled into view within the 240px viewport',
      );
    },
  );

  testWidgets('showReactionDetails lists users', (tester) async {
    await tester.pumpWidget(
      harness(
        PresenterLauncher(
          presenter: const BottomSheetPresenter(showReactionDetails: true),
          menu: testMenu(
            reactions: const [
              ReactionSummary(
                emoji: '👍',
                count: 1,
                users: [ReactionUser(id: 'u1', name: 'Ada')],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Ada'), findsOneWidget);
  });
}
