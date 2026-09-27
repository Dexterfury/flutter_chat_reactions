import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  test('default durations are applied at runtime', () {
    // ignore: prefer_const_constructors
    final presenter = CompactBarPresenter();
    expect(presenter.hoverDelay, const Duration(milliseconds: 300));
    expect(presenter.hoverExitDelay, const Duration(milliseconds: 200));
  });

  testWidgets('dismissing while another route covers it removes it directly', (
    tester,
  ) async {
    final menu = testMenu();
    await tester.pumpWidget(
      harness(
        PresenterLauncher(presenter: const CompactBarPresenter(), menu: menu),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(ReactionBar), findsOneWidget);

    final navigator = Navigator.of(
      tester.element(find.text('open')),
      rootNavigator: true,
    );
    unawaited(
      navigator.push(MaterialPageRoute<void>(builder: (_) => const SizedBox())),
    );
    await tester.pumpAndSettle();

    menu.dismiss();
    await tester.pumpAndSettle();

    navigator.pop();
    await tester.pumpAndSettle();
    expect(find.byType(ReactionBar), findsNothing);
  });

  testWidgets('shows only the bar, no blur and no message copy', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        PresenterLauncher(
          presenter: const CompactBarPresenter(),
          menu: testMenu(),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(ReactionBar), findsOneWidget);
    expect(find.byType(BackdropFilter), findsNothing);
    expect(find.byKey(const Key('message-copy')), findsNothing);
    expect(find.byType(ReactionActionMenu), findsNothing);
  });

  testWidgets('"⋯" toggles the action menu', (tester) async {
    ReactionAction<dynamic>? action;
    await tester.pumpWidget(
      harness(
        PresenterLauncher(
          presenter: const CompactBarPresenter(),
          menu: testMenu(onActionSelected: (a) => action = a),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('More actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reply'));
    await tester.pumpAndSettle();
    expect(action?.id, 'reply');
    expect(find.byType(ReactionBar), findsNothing);
  });

  testWidgets('actionsOverflow: false hides "⋯"', (tester) async {
    await tester.pumpWidget(
      harness(
        PresenterLauncher(
          presenter: const CompactBarPresenter(actionsOverflow: false),
          menu: testMenu(),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('More actions'), findsNothing);
  });

  testWidgets('hover-opened bar closes after the pointer leaves both areas', (
    tester,
  ) async {
    final menu = testMenu(trigger: ReactionTrigger.hover);
    await tester.pumpWidget(
      harness(
        PresenterLauncher(presenter: const CompactBarPresenter(), menu: menu),
        platform: TargetPlatform.macOS,
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: menu.anchorRect.center);
    await tester.pump();

    // Move onto the bar: stays open.
    await mouse.moveTo(tester.getCenter(find.byType(ReactionBar)));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(ReactionBar), findsOneWidget);

    // Leave everything: closes after the exit delay.
    await mouse.moveTo(const Offset(5, 590));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();
    expect(find.byType(ReactionBar), findsNothing);
  });

  testWidgets('long-press-opened bar ignores hover exit', (tester) async {
    final menu = testMenu();
    await tester.pumpWidget(
      harness(
        PresenterLauncher(presenter: const CompactBarPresenter(), menu: menu),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: const Offset(5, 590));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(ReactionBar), findsOneWidget);
  });
}
