import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

const three = [
  ReactionSummary(emoji: '👍', count: 3, reactedByMe: true),
  ReactionSummary(emoji: '❤️', count: 1),
  ReactionSummary(emoji: '😂', count: 2),
];

void main() {
  testWidgets('empty reactions render nothing', (tester) async {
    await tester.pumpWidget(harness(const ReactionsSummaryView(reactions: [])));
    expect(tester.getSize(find.byType(ReactionsSummaryView)), Size.zero);
  });

  testWidgets('chips show emoji and count, tap reports emoji', (tester) async {
    String? tapped;
    await tester.pumpWidget(
      harness(
        ReactionsSummaryView(
          reactions: three,
          onReactionTap: (e) => tapped = e,
        ),
      ),
    );
    expect(find.text('👍'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    await tester.tap(find.text('😂'));
    expect(tapped, '😂');
  });

  testWidgets('selected chip uses selected style', (tester) async {
    await tester.pumpWidget(
      harness(const ReactionsSummaryView(reactions: three)),
    );
    final context = tester.element(find.text('3'));
    final chip = ChatReactionsTheme.of(context).chipStyle;
    expect(
      tester.widget<Text>(find.text('3')).style?.color,
      chip.selectedTextStyle!.color,
    );
    expect(
      tester.widget<Text>(find.text('1')).style?.color,
      chip.textStyle!.color,
    );
  });

  testWidgets('maxVisible adds a +N chip', (tester) async {
    await tester.pumpWidget(
      harness(const ReactionsSummaryView(reactions: three, maxVisible: 2)),
    );
    expect(find.text('+1'), findsOneWidget);
    expect(find.text('😂'), findsNothing);
  });

  testWidgets('maxVisible of 0 shows only the +N chip', (tester) async {
    await tester.pumpWidget(
      harness(const ReactionsSummaryView(reactions: three, maxVisible: 0)),
    );
    expect(find.text('+3'), findsOneWidget);
    expect(find.text('👍'), findsNothing);
    expect(find.text('❤️'), findsNothing);
    expect(find.text('😂'), findsNothing);
  });

  testWidgets('negative maxVisible asserts', (tester) async {
    expect(
      () => ReactionsSummaryView(reactions: three, maxVisible: -1),
      throwsAssertionError,
    );
  });

  testWidgets('stacked layout shows total count', (tester) async {
    await tester.pumpWidget(
      harness(
        const ReactionsSummaryView(
          reactions: three,
          layout: ReactionSummaryLayout.stacked,
        ),
      ),
    );
    expect(find.text('6'), findsOneWidget);
    expect(find.text('👍'), findsOneWidget);
  });

  testWidgets('compact layout shows up to three emojis and total', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        const ReactionsSummaryView(
          reactions: [
            ...three,
            ReactionSummary(emoji: '🔥', count: 1),
          ],
          layout: ReactionSummaryLayout.compact,
        ),
      ),
    );
    expect(find.text('🔥'), findsNothing);
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('onTap covers the whole view', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      harness(
        ReactionsSummaryView(
          reactions: three,
          layout: ReactionSummaryLayout.compact,
          onTap: () => taps++,
        ),
      ),
    );
    await tester.tap(find.byType(ReactionsSummaryView));
    expect(taps, 1);
  });

  testWidgets('chipBuilder overrides chips', (tester) async {
    await tester.pumpWidget(
      harness(
        ReactionsSummaryView(
          reactions: three,
          chipBuilder: (context, s) => Text('chip ${s.emoji}'),
        ),
      ),
    );
    expect(find.text('chip 👍'), findsOneWidget);
  });

  testWidgets('count changes animate', (tester) async {
    await tester.pumpWidget(
      harness(
        const ReactionsSummaryView(
          reactions: [ReactionSummary(emoji: '👍', count: 1)],
        ),
      ),
    );
    await tester.pumpWidget(
      harness(
        const ReactionsSummaryView(
          reactions: [ReactionSummary(emoji: '👍', count: 2)],
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    expect(
      find.text('1'),
      findsOneWidget,
      reason: 'old count still fading out',
    );
    await tester.pumpAndSettle();
    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('overlay places the summary over the bubble bottom edge', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        const Align(
          alignment: Alignment.topLeft,
          child: ReactionsSummaryView.overlay(
            reactions: three,
            child: SizedBox(key: Key('bubble'), width: 200, height: 80),
          ),
        ),
      ),
    );
    final bubble = tester.getRect(find.byKey(const Key('bubble')));
    final summary = tester.getRect(find.text('👍'));
    expect(summary.top, lessThan(bubble.bottom));
    expect(summary.bottom, greaterThan(bubble.bottom));
  });

  testWidgets('onLongPress reports the long-pressed chip emoji', (
    tester,
  ) async {
    String? longPressed;
    await tester.pumpWidget(
      harness(
        ReactionsSummaryView(
          reactions: three,
          onLongPress: (e) => longPressed = e,
        ),
      ),
    );
    await tester.longPress(find.text('😂'));
    expect(longPressed, '😂');
  });

  testWidgets('overlay constructor runs at runtime (non-const invocation)', (
    tester,
  ) async {
    // Deliberately not `const` so the constructor's initializer list runs
    // at runtime instead of being folded away by the compiler.
    // ignore: prefer_const_constructors
    final view = ReactionsSummaryView.overlay(
      reactions: three,
      child: const SizedBox(key: Key('bubble2'), width: 100, height: 40),
    );
    await tester.pumpWidget(harness(view));
    expect(find.byKey(const Key('bubble2')), findsOneWidget);
    expect(view.overlayChild, isNotNull);
  });

  testWidgets('chip semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      harness(ReactionsSummaryView(reactions: three, onReactionTap: (_) {})),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('thumbs up, 3 reactions')),
      isSemantics(isButton: true, isSelected: true, hasTapAction: true),
    );
    handle.dispose();
  });
}
