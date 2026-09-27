import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  testWidgets('shows bar above, message copy at anchor, menu below', (
    tester,
  ) async {
    final menu = testMenu();
    await tester.pumpWidget(
      harness(
        PresenterLauncher(
          presenter: const FocusedOverlayPresenter(),
          menu: menu,
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final bar = tester.getRect(find.byType(ReactionBar));
    final message = tester.getRect(find.byKey(const Key('message-copy')));
    final actions = tester.getRect(find.byType(ReactionActionMenu));
    expect(bar.bottom, lessThanOrEqualTo(message.top));
    expect(actions.top, greaterThanOrEqualTo(message.bottom));
    expect(message.center.dx, closeTo(menu.anchorRect.center.dx, 4));
    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  testWidgets('selecting an emoji closes and reports', (tester) async {
    String? emoji;
    await tester.pumpWidget(
      harness(
        PresenterLauncher(
          presenter: const FocusedOverlayPresenter(),
          menu: testMenu(onReactionSelected: (e) => emoji = e),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('😂'));
    await tester.pumpAndSettle();
    expect(emoji, '😂');
    expect(find.byType(ReactionBar), findsNothing);
  });

  testWidgets('selecting an action closes and reports', (tester) async {
    ReactionAction<dynamic>? action;
    await tester.pumpWidget(
      harness(
        PresenterLauncher(
          presenter: const FocusedOverlayPresenter(),
          menu: testMenu(onActionSelected: (a) => action = a),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reply'));
    await tester.pumpAndSettle();
    expect(action?.id, 'reply');
  });

  testWidgets('tapping the message copy dismisses', (tester) async {
    await tester.pumpWidget(
      harness(
        PresenterLauncher(
          presenter: const FocusedOverlayPresenter(),
          menu: testMenu(),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('message-copy')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    expect(find.byType(ReactionBar), findsNothing);
  });

  testWidgets('stays inside the safe area near the top edge', (tester) async {
    await tester.pumpWidget(
      harness(
        PresenterLauncher(
          presenter: const FocusedOverlayPresenter(),
          menu: testMenu(anchorRect: const Rect.fromLTWH(300, 0, 200, 60)),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byType(ReactionBar)).top,
      greaterThanOrEqualTo(12),
    );
  });

  testWidgets('showActions: false hides the menu', (tester) async {
    await tester.pumpWidget(
      harness(
        PresenterLauncher(
          presenter: const FocusedOverlayPresenter(showActions: false),
          menu: testMenu(),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(ReactionActionMenu), findsNothing);
  });

  testWidgets('falls back to the bottom sheet at large text scale', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        PresenterLauncher(
          presenter: const FocusedOverlayPresenter(),
          menu: testMenu(),
        ),
        textScale: 2,
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('"+" opens more reactions after dismissing', (tester) async {
    var more = 0;
    await tester.pumpWidget(
      harness(
        PresenterLauncher(
          presenter: const FocusedOverlayPresenter(),
          menu: testMenu(onMoreTap: () async => more++),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('More reactions'));
    await tester.pumpAndSettle();
    expect(more, 1);
    expect(find.byType(ReactionBar), findsNothing);
  });
}
