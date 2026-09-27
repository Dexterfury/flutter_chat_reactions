import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  testWidgets('RTL: end alignment anchors the bar to the message left edge', (
    tester,
  ) async {
    final menu = testMenu(
      anchorRect: const Rect.fromLTWH(40, 250, 200, 60),
      textDirection: TextDirection.rtl,
    );
    await tester.pumpWidget(
      harness(
        PresenterLauncher(
          presenter: const FocusedOverlayPresenter(),
          menu: menu,
        ),
        textDirection: TextDirection.rtl,
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byType(ReactionBar)).left, 40);
  });

  testWidgets('keyboard: Tab reaches the first emoji, Enter selects it', (
    tester,
  ) async {
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
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(emoji, '👍');
  });

  testWidgets('reduced motion: menu is fully visible after one frame', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        PresenterLauncher(
          presenter: const FocusedOverlayPresenter(),
          menu: testMenu(),
        ),
        disableAnimations: true,
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump();
    final fades = tester.widgetList<FadeTransition>(
      find.ancestor(of: find.text('😂'), matching: find.byType(FadeTransition)),
    );
    expect(fades, isNotEmpty);
    expect(fades.every((f) => f.opacity.value == 1), isTrue);
  });

  testWidgets('bar buttons expose names and selection', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      harness(
        PresenterLauncher(
          presenter: const FocusedOverlayPresenter(),
          menu: testMenu(
            reactions: const [
              ReactionSummary(emoji: '❤️', count: 2, reactedByMe: true),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.bySemanticsLabel('red heart')),
      // ignore: deprecated_member_use
      containsSemantics(isButton: true, isSelected: true),
    );
    handle.dispose();
  });

  testWidgets(
    'focus returns to the message after keyboard-opened menu closes',
    (tester) async {
      await tester.pumpWidget(
        harness(
          Center(
            child: ReactableMessage(
              onReactionSelected: (_) {},
              child: const SizedBox(width: 100, height: 40),
            ),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final messageFocus = FocusManager.instance.primaryFocus;
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus, messageFocus);
    },
  );

  testWidgets(
    'macOS: dismissing a hover-opened bar with Escape does not reopen it '
    'while the pointer stays over the message',
    (tester) async {
      const presenter = CompactBarPresenter();
      await tester.pumpWidget(
        harness(
          ChatReactionsScope(
            presenter: presenter,
            child: Center(
              child: ReactableMessage(
                onReactionSelected: (_) {},
                child: const SizedBox(width: 100, height: 40),
              ),
            ),
          ),
          platform: TargetPlatform.macOS,
        ),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: Offset.zero);
      await tester.pump();

      final center = tester.getCenter(find.byType(SizedBox).first);
      await gesture.moveTo(center);
      await tester.pump(
        presenter.hoverDelay + const Duration(milliseconds: 50),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ReactionBar), findsOneWidget);

      // Pointer stays put; only the menu is dismissed via keyboard.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(ReactionBar), findsNothing);

      // Wait well past hoverDelay again: the bar must not reopen on its own.
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.byType(ReactionBar), findsNothing);
    },
  );

  testWidgets(
    'macOS: a genuine re-hover after the bar auto-closes (pointer leaves) '
    'reopens it',
    (tester) async {
      const presenter = CompactBarPresenter();
      const bubbleKey = ValueKey('bubble-scenario-a');
      await tester.pumpWidget(
        harness(
          ChatReactionsScope(
            presenter: presenter,
            child: Center(
              child: ReactableMessage(
                onReactionSelected: (_) {},
                child: const SizedBox(key: bubbleKey, width: 100, height: 40),
              ),
            ),
          ),
          platform: TargetPlatform.macOS,
        ),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: Offset.zero);
      await tester.pump();

      final center = tester.getCenter(find.byKey(bubbleKey));
      await gesture.moveTo(center);
      await tester.pump(
        presenter.hoverDelay + const Duration(milliseconds: 50),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ReactionBar), findsOneWidget);

      // Pointer leaves both the message and the bar; the bar auto-closes
      // after hoverExitDelay.
      await gesture.moveTo(const Offset(5, 5));
      await tester.pump(
        presenter.hoverExitDelay + const Duration(milliseconds: 50),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ReactionBar), findsNothing);

      // A genuine re-hover of the message must reopen the bar.
      await gesture.moveTo(center);
      await tester.pump(
        presenter.hoverDelay + const Duration(milliseconds: 50),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ReactionBar), findsOneWidget);
    },
  );

  testWidgets('macOS: a genuine re-hover after Escape (pointer was on the bar) '
      'reopens it', (tester) async {
    const presenter = CompactBarPresenter();
    const bubbleKey = ValueKey('bubble-scenario-b');
    await tester.pumpWidget(
      harness(
        ChatReactionsScope(
          presenter: presenter,
          child: Center(
            child: ReactableMessage(
              onReactionSelected: (_) {},
              child: const SizedBox(key: bubbleKey, width: 100, height: 40),
            ),
          ),
        ),
        platform: TargetPlatform.macOS,
      ),
    );

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.addPointer(location: Offset.zero);
    await tester.pump();

    final center = tester.getCenter(find.byKey(bubbleKey));
    await gesture.moveTo(center);
    await tester.pump(presenter.hoverDelay + const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
    expect(find.byType(ReactionBar), findsOneWidget);

    // Move the pointer onto the bar itself.
    final barCenter = tester.getCenter(find.byType(ReactionBar));
    await gesture.moveTo(barCenter);
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(ReactionBar), findsNothing);

    // Pointer leaves the (now closed) area entirely.
    await gesture.moveTo(const Offset(5, 5));
    await tester.pump();

    // A genuine re-hover of the message must reopen the bar.
    await gesture.moveTo(center);
    await tester.pump(presenter.hoverDelay + const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
    expect(find.byType(ReactionBar), findsOneWidget);
  });
}
