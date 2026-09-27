import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

const actions = [
  ReactionAction<void>(id: 'reply', label: 'Reply', icon: Icons.reply),
  ReactionAction<void>(
    id: 'delete',
    label: 'Delete',
    icon: Icons.delete,
    isDestructive: true,
  ),
];

void main() {
  testWidgets('shows labels and icons, reports taps', (tester) async {
    ReactionAction<dynamic>? tapped;
    await tester.pumpWidget(
      harness(
        Center(
          child: ReactionActionMenu(
            actions: actions,
            onSelected: (a) => tapped = a,
          ),
        ),
      ),
    );
    expect(find.text('Reply'), findsOneWidget);
    expect(find.byIcon(Icons.delete), findsOneWidget);
    await tester.tap(find.text('Delete'));
    expect(tapped?.id, 'delete');
  });

  testWidgets('destructive actions use the theme destructive color', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        Center(
          child: ReactionActionMenu(actions: actions, onSelected: (_) {}),
        ),
      ),
    );
    final context = tester.element(find.text('Delete'));
    final expected = ChatReactionsTheme.of(context).menuStyle.destructiveColor;
    expect(tester.widget<Text>(find.text('Delete')).style?.color, expected);
    expect(tester.widget<Icon>(find.byIcon(Icons.delete)).color, expected);
  });

  testWidgets('width is clamped between min and max', (tester) async {
    await tester.pumpWidget(
      harness(
        Center(
          child: ReactionActionMenu(
            actions: const [ReactionAction<void>(id: 'a', label: 'A')],
            onSelected: (_) {},
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(ReactionActionMenu)).width, 200);

    await tester.pumpWidget(
      harness(
        Center(
          child: ReactionActionMenu(
            actions: [ReactionAction<void>(id: 'b', label: 'B' * 200)],
            onSelected: (_) {},
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(ReactionActionMenu)).width, 280);
  });

  testWidgets('Cupertino style draws dividers between items', (tester) async {
    await tester.pumpWidget(
      harness(
        Center(
          child: ReactionActionMenu(actions: actions, onSelected: (_) {}),
        ),
        platform: TargetPlatform.iOS,
      ),
    );
    expect(find.byType(Divider), findsOneWidget);
  });
}
