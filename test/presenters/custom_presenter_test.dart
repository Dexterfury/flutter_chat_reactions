import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

CustomPresenter presenter() => CustomPresenter(
  barrierColor: Colors.black54,
  builder: (context, menu, animation) => Center(
    child: TextButton(
      onPressed: () => menu.selectReaction('🔥'),
      child: const Text('custom-ui'),
    ),
  ),
);

void main() {
  testWidgets('builds custom UI and reports selection', (tester) async {
    String? selected;
    var closed = false;
    await tester.pumpWidget(
      harness(
        PresenterLauncher(
          presenter: presenter(),
          menu: testMenu(onReactionSelected: (e) => selected = e),
          onClosed: () => closed = true,
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('custom-ui'), findsOneWidget);

    await tester.tap(find.text('custom-ui'));
    await tester.pumpAndSettle();
    expect(selected, '🔥');
    expect(closed, isTrue);
    expect(find.text('custom-ui'), findsNothing);
  });

  testWidgets('tap outside dismisses', (tester) async {
    await tester.pumpWidget(
      harness(PresenterLauncher(presenter: presenter(), menu: testMenu())),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 590));
    await tester.pumpAndSettle();
    expect(find.text('custom-ui'), findsNothing);
  });

  testWidgets('Escape dismisses', (tester) async {
    await tester.pumpWidget(
      harness(PresenterLauncher(presenter: presenter(), menu: testMenu())),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('custom-ui'), findsNothing);
  });

  testWidgets('system back dismisses the menu, not the page', (tester) async {
    await tester.pumpWidget(
      harness(PresenterLauncher(presenter: presenter(), menu: testMenu())),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('custom-ui'), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('screen resize dismisses', (tester) async {
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      harness(PresenterLauncher(presenter: presenter(), menu: testMenu())),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(1000, 1600);
    await tester.pumpAndSettle();
    expect(find.text('custom-ui'), findsNothing);
  });

  testWidgets('menu.dismiss() closes the route', (tester) async {
    final menu = testMenu();
    await tester.pumpWidget(
      harness(PresenterLauncher(presenter: presenter(), menu: menu)),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    menu.dismiss();
    await tester.pumpAndSettle();
    expect(find.text('custom-ui'), findsNothing);
  });
}
