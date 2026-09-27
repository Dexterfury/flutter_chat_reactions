import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  test(
    'select dismisses first, then reports; dismiss runs the handler once',
    () {
      final log = <String>[];
      final menu = testMenu(
        onReactionSelected: (e) => log.add('select $e'),
        reactions: const [
          ReactionSummary(emoji: '👍', count: 1, reactedByMe: true),
        ],
      )..setDismissHandler(() => log.add('dismiss'));

      expect(menu.selectedReactions, {'👍'});
      menu.selectReaction('❤️');
      menu.dismiss();
      expect(log, ['dismiss', 'select ❤️']);
      expect(menu.isDismissed, isTrue);
    },
  );

  test('openMore dismisses then awaits the callback', () async {
    final log = <String>[];
    final menu = testMenu(onMoreTap: () async => log.add('more'))
      ..setDismissHandler(() => log.add('dismiss'));
    expect(menu.hasMore, isTrue);
    await menu.openMore();
    expect(log, ['dismiss', 'more']);
    expect(testMenu().hasMore, isFalse);
  });

  test('default triggers by platform', () {
    expect(defaultReactionTriggers(TargetPlatform.iOS), {
      ReactionTrigger.longPress,
      ReactionTrigger.keyboard,
    });
    expect(defaultReactionTriggers(TargetPlatform.macOS), {
      ReactionTrigger.secondaryTap,
      ReactionTrigger.hover,
      ReactionTrigger.keyboard,
    });
  });
}
