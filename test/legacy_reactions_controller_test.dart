import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReactionsController (0.2.x behaviour)', () {
    late ReactionsController controller;
    var notifications = 0;

    setUp(() {
      controller = ReactionsController(currentUserId: 'me');
      notifications = 0;
      controller.addListener(() => notifications++);
    });

    test('toggle adds a reaction for the current user', () {
      controller.toggleReaction('m1', '👍');

      expect(controller.hasUserReacted('m1', '👍'), isTrue);
      expect(controller.getReactionCounts('m1'), {'👍': 1});
      expect(notifications, greaterThan(0));
    });

    test('toggling the same emoji twice removes it', () {
      controller.toggleReaction('m1', '👍');
      controller.toggleReaction('m1', '👍');

      expect(controller.hasUserReacted('m1', '👍'), isFalse);
      expect(controller.getReactions('m1'), isEmpty);
    });

    test('a different emoji replaces the previous one (single policy)', () {
      controller.toggleReaction('m1', '👍');
      controller.toggleReaction('m1', '❤️');

      expect(controller.getReactionCounts('m1'), {'❤️': 1});
    });

    test('clearReactions empties one message only', () {
      controller.toggleReaction('m1', '👍');
      controller.toggleReaction('m2', '😂');
      controller.clearReactions('m1');

      expect(controller.getReactions('m1'), isEmpty);
      expect(controller.getReactionCounts('m2'), {'😂': 1});
    });
  });
}
