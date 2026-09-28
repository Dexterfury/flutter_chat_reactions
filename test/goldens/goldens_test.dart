@Tags(['golden'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

final bool _skip = !Platform.isLinux;

const _actions = [
  ReactionAction<void>(id: 'reply', label: 'Reply', icon: Icons.reply),
  ReactionAction<void>(id: 'copy', label: 'Copy', icon: Icons.copy),
  ReactionAction<void>(
    id: 'delete',
    label: 'Delete',
    icon: Icons.delete,
    isDestructive: true,
  ),
];

const _summaries = [
  ReactionSummary(emoji: '👍', count: 3, reactedByMe: true),
  ReactionSummary(emoji: '❤️', count: 1),
];

void main() {
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    for (final brightness in Brightness.values) {
      final variant =
          '${platform == TargetPlatform.iOS ? 'cupertino' : 'material'}_${brightness.name}';

      Widget wrap(Widget child) => harness(
        RepaintBoundary(
          key: const Key('golden'),
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
        platform: platform,
        brightness: brightness,
      );

      testWidgets('bar $variant', (tester) async {
        await tester.pumpWidget(
          wrap(
            ReactionBar(
              reactions: kDefaultQuickReactions,
              selected: const {'❤️'},
              onSelected: (_) {},
              onMore: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byKey(const Key('golden')),
          matchesGoldenFile('bar_$variant.png'),
        );
      }, skip: _skip);

      testWidgets('menu $variant', (tester) async {
        await tester.pumpWidget(
          wrap(ReactionActionMenu(actions: _actions, onSelected: (_) {})),
        );
        await expectLater(
          find.byKey(const Key('golden')),
          matchesGoldenFile('menu_$variant.png'),
        );
      }, skip: _skip);

      testWidgets('chips $variant', (tester) async {
        await tester.pumpWidget(
          wrap(const ReactionsSummaryView(reactions: _summaries)),
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byKey(const Key('golden')),
          matchesGoldenFile('chips_$variant.png'),
        );
      }, skip: _skip);

      testWidgets('focused overlay $variant', (tester) async {
        await tester.pumpWidget(
          harness(
            PresenterLauncher(
              presenter: const FocusedOverlayPresenter(),
              menu: testMenu(),
            ),
            platform: platform,
            brightness: brightness,
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('overlay_$variant.png'),
        );
      }, skip: _skip);
    }
  }
}
