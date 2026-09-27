import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  testWidgets('renders reactions and reports taps', (tester) async {
    String? tapped;
    await tester.pumpWidget(
      harness(
        Center(
          child: ReactionBar(
            reactions: const ['👍', '❤️'],
            onSelected: (e) => tapped = e,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('👍'), findsOneWidget);
    await tester.tap(find.text('❤️'));
    expect(tapped, '❤️');
  });

  testWidgets('more and more-actions buttons appear only with callbacks', (
    tester,
  ) async {
    var more = 0;
    var actions = 0;
    await tester.pumpWidget(
      harness(
        Center(
          child: ReactionBar(
            reactions: const ['👍'],
            onSelected: (_) {},
            onMore: () => more++,
            onMoreActions: () => actions++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('More reactions'));
    await tester.tap(find.bySemanticsLabel('More actions'));
    expect((more, actions), (1, 1));

    await tester.pumpWidget(
      harness(
        Center(
          child: ReactionBar(reactions: const ['👍'], onSelected: (_) {}),
        ),
      ),
    );
    expect(find.bySemanticsLabel('More reactions'), findsNothing);
  });

  testWidgets('selected emojis are marked selected in semantics', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      harness(
        Center(
          child: ReactionBar(
            reactions: const ['👍', '❤️'],
            selected: const {'👍'},
            onSelected: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.bySemanticsLabel('thumbs up')),
      // ignore: deprecated_member_use
      containsSemantics(isButton: true, isSelected: true, hasTapAction: true),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('red heart')),
      // ignore: deprecated_member_use
      containsSemantics(isSelected: false),
    );
    handle.dispose();
  });

  testWidgets('custom emojiBuilder is used', (tester) async {
    await tester.pumpWidget(
      harness(
        Center(
          child: ReactionBar(
            reactions: const [':party:'],
            onSelected: (_) {},
            emojiBuilder: (context, emoji, size) => Text('custom-$emoji'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('custom-:party:'), findsOneWidget);
  });

  testWidgets('staggered entrance completes', (tester) async {
    await tester.pumpWidget(
      harness(
        Center(
          child: ReactionBar(
            reactions: const ['👍', '❤️', '😂'],
            onSelected: (_) {},
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 10));
    final early = tester
        .widget<FadeTransition>(
          find
              .ancestor(
                of: find.text('😂'),
                matching: find.byType(FadeTransition),
              )
              .first,
        )
        .opacity
        .value;
    expect(early, lessThan(1));
    await tester.pumpAndSettle();
    final late = tester
        .widget<FadeTransition>(
          find
              .ancestor(
                of: find.text('😂'),
                matching: find.byType(FadeTransition),
              )
              .first,
        )
        .opacity
        .value;
    expect(late, 1);
  });
}
