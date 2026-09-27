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
