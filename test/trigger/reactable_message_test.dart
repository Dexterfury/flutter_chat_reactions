import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

const bubbleKey = Key('bubble');

class RecordingPresenter extends ReactionsPresenter {
  RecordingPresenter();
  final List<ReactionsMenuContext> shown = [];

  @override
  Future<void> show(BuildContext context, ReactionsMenuContext menu) async {
    shown.add(menu);
  }
}

/// Records every `show()` call and never completes on its own, so a test can
/// hold the menu "open" indefinitely and control exactly when it closes.
class _PendingPresenter extends ReactionsPresenter {
  final List<Completer<void>> calls = [];

  @override
  Future<void> show(BuildContext context, ReactionsMenuContext menu) {
    final completer = Completer<void>();
    calls.add(completer);
    return completer.future;
  }
}

Widget message({
  ReactionsPresenter? presenter,
  Set<ReactionTrigger>? triggers,
  ValueChanged<String>? onReactionSelected,
  MoreReactionsCallback? onMoreTap,
  ReactionActionsBuilder? actionsBuilder,
  bool enabled = true,
}) => Center(
  child: ReactableMessage(
    presenter: presenter,
    triggers: triggers,
    onReactionSelected: onReactionSelected,
    onMoreTap: onMoreTap,
    actionsBuilder: actionsBuilder,
    enabled: enabled,
    reactions: const [
      ReactionSummary(emoji: '👍', count: 1, reactedByMe: true),
    ],
    child: const SizedBox(
      key: bubbleKey,
      width: 180,
      height: 50,
      child: ColoredBox(color: Colors.green),
    ),
  ),
);

void main() {
  testWidgets('long press opens the default focused overlay', (tester) async {
    String? emoji;
    await tester.pumpWidget(
      harness(message(onReactionSelected: (e) => emoji = e)),
    );
    await tester.longPress(find.byKey(bubbleKey));
    await tester.pumpAndSettle();

    expect(find.byType(ReactionBar), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);
    await tester.tap(find.text('❤️'));
    await tester.pumpAndSettle();
    expect(emoji, '❤️');
  });

  testWidgets('menu context carries the anchor rect and data', (tester) async {
    final presenter = RecordingPresenter();
    await tester.pumpWidget(
      harness(
        message(
          presenter: presenter,
          actionsBuilder: (_) => const [
            ReactionAction<void>(id: 'copy', label: 'Copy'),
          ],
        ),
      ),
    );
    await tester.longPress(find.byKey(bubbleKey));
    final menu = presenter.shown.single;
    expect(menu.anchorRect, tester.getRect(find.byKey(bubbleKey)));
    expect(menu.quickReactions, kDefaultQuickReactions);
    expect(menu.actions.single.id, 'copy');
    expect(menu.selectedReactions, {'👍'});
    expect(menu.hasMore, isFalse);
  });

  testWidgets('desktop defaults: right-click opens, long press does not', (
    tester,
  ) async {
    final presenter = RecordingPresenter();
    await tester.pumpWidget(
      harness(message(presenter: presenter), platform: TargetPlatform.windows),
    );
    await tester.longPress(find.byKey(bubbleKey));
    expect(presenter.shown, isEmpty);
    await tester.tap(find.byKey(bubbleKey), buttons: kSecondaryButton);
    expect(presenter.shown.single.trigger, ReactionTrigger.secondaryTap);
  });

  testWidgets('double tap trigger', (tester) async {
    final presenter = RecordingPresenter();
    await tester.pumpWidget(
      harness(
        message(presenter: presenter, triggers: {ReactionTrigger.doubleTap}),
      ),
    );
    await tester.tap(find.byKey(bubbleKey));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byKey(bubbleKey));
    await tester.pumpAndSettle();
    expect(presenter.shown.single.trigger, ReactionTrigger.doubleTap);
  });

  testWidgets('keyboard: Enter on the focused message opens', (tester) async {
    final presenter = RecordingPresenter();
    await tester.pumpWidget(harness(message(presenter: presenter)));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(presenter.shown.single.trigger, ReactionTrigger.keyboard);
  });

  testWidgets('keyboard: the context-menu key on the focused message opens', (
    tester,
  ) async {
    final presenter = RecordingPresenter();
    await tester.pumpWidget(harness(message(presenter: presenter)));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
    expect(presenter.shown.single.trigger, ReactionTrigger.keyboard);
  });

  testWidgets('keyboard: Shift+F10 on the focused message opens', (
    tester,
  ) async {
    final presenter = RecordingPresenter();
    await tester.pumpWidget(harness(message(presenter: presenter)));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.f10);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    expect(presenter.shown.single.trigger, ReactionTrigger.keyboard);
  });

  testWidgets('hover opens CompactBarPresenter after the delay', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        ChatReactionsScope(
          presenter: const CompactBarPresenter(),
          child: Center(
            child: ReactableMessage(
              onReactionSelected: (_) {},
              child: const SizedBox(key: bubbleKey, width: 180, height: 50),
            ),
          ),
        ),
        platform: TargetPlatform.macOS,
      ),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.byKey(bubbleKey)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(ReactionBar), findsNothing);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();
    expect(find.byType(ReactionBar), findsOneWidget);
  });

  testWidgets('semantics action opens the menu', (tester) async {
    final presenter = RecordingPresenter();
    await tester.pumpWidget(harness(message(presenter: presenter)));
    final semantics = tester.widget<Semantics>(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.customSemanticsActions != null,
      ),
    );
    final actions = semantics.properties.customSemanticsActions!;
    expect(actions.keys.single.label, 'Open reactions menu');
    actions.values.single();
    await tester.pump();
    expect(presenter.shown, hasLength(1));
  });

  testWidgets('disabled messages do not open', (tester) async {
    final presenter = RecordingPresenter();
    await tester.pumpWidget(
      harness(message(presenter: presenter, enabled: false)),
    );
    await tester.longPress(find.byKey(bubbleKey));
    expect(presenter.shown, isEmpty);
  });

  testWidgets('onMoreTap receives the message context', (tester) async {
    BuildContext? moreContext;
    await tester.pumpWidget(
      harness(message(onMoreTap: (context) async => moreContext = context)),
    );
    await tester.longPress(find.byKey(bubbleKey));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('More reactions'));
    await tester.pumpAndSettle();
    expect(moreContext, isNotNull);
    expect(moreContext!.mounted, isTrue);
  });

  testWidgets('removing the message while open closes the menu', (
    tester,
  ) async {
    var show = true;
    late StateSetter setOuter;
    await tester.pumpWidget(
      harness(
        StatefulBuilder(
          builder: (context, setState) {
            setOuter = setState;
            return show ? message() : const SizedBox();
          },
        ),
      ),
    );
    await tester.longPress(find.byKey(bubbleKey));
    await tester.pumpAndSettle();
    expect(find.byType(ReactionBar), findsOneWidget);
    setOuter(() => show = false);
    await tester.pumpAndSettle();
    expect(find.byType(ReactionBar), findsNothing);
  });

  testWidgets(
    'a second long press while open is absorbed by the route barrier, '
    'dismissing the menu',
    (tester) async {
      const menuKey = Key('custom-menu');
      final presenter = CustomPresenter(
        builder: (_, _, _) => const SizedBox(key: menuKey),
      );
      await tester.pumpWidget(harness(message(presenter: presenter)));
      await tester.longPress(find.byKey(bubbleKey));
      await tester.pumpAndSettle();
      expect(find.byKey(menuKey), findsOneWidget);

      // The custom presenter's content is a bare SizedBox that doesn't
      // occupy the anchor's position, so this second long press lands on the
      // route's own dismissible barrier rather than on ReactableMessage's
      // gesture detector, closing the menu. This does not exercise the
      // `_menu != null` re-entry guard directly; see the test below for that.
      await tester.longPress(find.byKey(bubbleKey), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byKey(menuKey), findsNothing);
    },
  );

  testWidgets(
    'the re-entry guard blocks a second trigger while show() is pending',
    (tester) async {
      final presenter = _PendingPresenter();
      await tester.pumpWidget(harness(message(presenter: presenter)));
      final semantics = tester.widget<Semantics>(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.customSemanticsActions != null,
        ),
      );
      final open = semantics.properties.customSemanticsActions!.values.single;

      open();
      await tester.pump();
      expect(presenter.calls, hasLength(1));

      // Triggered again while the first `show()` is still pending: the
      // `_menu != null` guard in `_open` must bail out before calling
      // `show()` a second time.
      open();
      await tester.pump();
      expect(presenter.calls, hasLength(1));

      // Completing the pending call resets `_menu` (in `_open`'s `finally`),
      // so a subsequent trigger opens the menu again.
      presenter.calls.single.complete();
      await tester.pump();
      open();
      await tester.pump();
      expect(presenter.calls, hasLength(2));
    },
  );

  testWidgets('disabling the message while the menu is open closes it', (
    tester,
  ) async {
    var enabled = true;
    late StateSetter setOuter;
    await tester.pumpWidget(
      harness(
        StatefulBuilder(
          builder: (context, setState) {
            setOuter = setState;
            return message(enabled: enabled);
          },
        ),
      ),
    );
    await tester.longPress(find.byKey(bubbleKey));
    await tester.pumpAndSettle();
    expect(find.byType(ReactionBar), findsOneWidget);
    setOuter(() => enabled = false);
    await tester.pumpAndSettle();
    expect(find.byType(ReactionBar), findsNothing);
  });

  group('a pending hover timer does not open the menu', () {
    Future<void> hover(WidgetTester tester) async {
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.byKey(bubbleKey)));
      await tester.pump(const Duration(milliseconds: 100));
    }

    Future<void> expectNoMenu(WidgetTester tester) async {
      // Apply the configuration change first, then let the hover delay pass.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.byType(ReactionBar), findsNothing);
    }

    testWidgets('after the message is disabled', (tester) async {
      var enabled = true;
      late StateSetter setOuter;
      await tester.pumpWidget(
        harness(
          StatefulBuilder(
            builder: (context, setState) {
              setOuter = setState;
              return message(
                presenter: const CompactBarPresenter(),
                triggers: {ReactionTrigger.hover},
                enabled: enabled,
              );
            },
          ),
          platform: TargetPlatform.macOS,
        ),
      );
      await hover(tester);
      setOuter(() => enabled = false);
      await expectNoMenu(tester);
    });

    testWidgets('after hover is removed from the triggers', (tester) async {
      var triggers = {ReactionTrigger.hover, ReactionTrigger.longPress};
      late StateSetter setOuter;
      await tester.pumpWidget(
        harness(
          StatefulBuilder(
            builder: (context, setState) {
              setOuter = setState;
              return message(
                presenter: const CompactBarPresenter(),
                triggers: triggers,
              );
            },
          ),
          platform: TargetPlatform.macOS,
        ),
      );
      await hover(tester);
      setOuter(() => triggers = {ReactionTrigger.longPress});
      await expectNoMenu(tester);
    });

    testWidgets('after the presenter stops being a CompactBarPresenter', (
      tester,
    ) async {
      ReactionsPresenter presenter = const CompactBarPresenter();
      late StateSetter setOuter;
      await tester.pumpWidget(
        harness(
          StatefulBuilder(
            builder: (context, setState) {
              setOuter = setState;
              return message(
                presenter: presenter,
                triggers: {ReactionTrigger.hover},
              );
            },
          ),
          platform: TargetPlatform.macOS,
        ),
      );
      await hover(tester);
      setOuter(() => presenter = const FocusedOverlayPresenter());
      await expectNoMenu(tester);
    });

    testWidgets('after a scope stops enabling hover', (tester) async {
      var triggers = {ReactionTrigger.hover};
      late StateSetter setOuter;
      await tester.pumpWidget(
        harness(
          StatefulBuilder(
            builder: (context, setState) {
              setOuter = setState;
              return ChatReactionsScope(
                triggers: triggers,
                child: message(presenter: const CompactBarPresenter()),
              );
            },
          ),
          platform: TargetPlatform.macOS,
        ),
      );
      await hover(tester);
      setOuter(() => triggers = {ReactionTrigger.longPress});
      await expectNoMenu(tester);
    });
  });
}
