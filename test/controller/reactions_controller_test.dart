import 'dart:async';

import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late int notifications;

  ReactionsController make({
    ReactionPolicy policy = const ReactionPolicy.single(),
    Future<void> Function(ReactionChange)? onChange,
  }) {
    notifications = 0;
    final c = ReactionsController(
      currentUserId: 'me',
      currentUserName: 'Me',
      policy: policy,
      onChange: onChange,
    )..addListener(() => notifications++);
    addTearDown(c.dispose);
    return c;
  }

  group('single policy', () {
    test('add, replace, remove via toggle', () async {
      final changes = <ReactionChange>[];
      final c = make(onChange: (change) async => changes.add(change));

      await c.toggle('m1', '👍');
      await c.toggle('m1', '❤️');
      await c.toggle('m1', '❤️');

      expect(changes, [
        const ReactionAdded(messageId: 'm1', emoji: '👍'),
        const ReactionReplaced(
          messageId: 'm1',
          emoji: '❤️',
          previousEmoji: '👍',
        ),
        const ReactionRemoved(messageId: 'm1', emoji: '❤️'),
      ]);
      expect(c.summariesFor('m1'), isEmpty);
      expect(notifications, 3);
    });

    test('keeps other users reactions', () async {
      final c = make();
      c.setReactions('m1', const [Reaction(emoji: '👍', userId: 'u2')]);
      await c.toggle('m1', '👍');

      final summary = c.summariesFor('m1').single;
      expect(summary.count, 2);
      expect(summary.reactedByMe, isTrue);
      expect(summary.users.map((u) => u.name), contains('Me'));
    });

    test('add is a no-op when already reacted', () async {
      final c = make();
      await c.add('m1', '👍');
      final before = notifications;
      await c.add('m1', '👍');
      expect(notifications, before);
    });
  });

  group('multiple policy', () {
    test('toggles emojis independently', () async {
      final c = make(policy: const ReactionPolicy.multiple());
      await c.toggle('m1', '👍');
      await c.toggle('m1', '❤️');
      expect(c.summariesFor('m1').map((s) => s.emoji), ['👍', '❤️']);
      await c.toggle('m1', '👍');
      expect(c.summariesFor('m1').map((s) => s.emoji), ['❤️']);
    });

    test('respects max silently', () async {
      final changes = <ReactionChange>[];
      final c = make(
        policy: const ReactionPolicy.multiple(max: 1),
        onChange: (change) async => changes.add(change),
      );
      await c.add('m1', '👍');
      await c.add('m1', '❤️');
      expect(c.hasReacted('m1', '❤️'), isFalse);
      expect(changes, hasLength(1));
    });
  });

  group('optimistic updates', () {
    test(
      'applies immediately, then rolls back and rethrows on failure',
      () async {
        final gate = Completer<void>();
        final c = make(onChange: (_) => gate.future);

        final pending = c.toggle('m1', '👍');
        expect(c.hasReacted('m1', '👍'), isTrue, reason: 'optimistic');

        gate.completeError(StateError('offline'));
        await expectLater(pending, throwsStateError);
        expect(c.hasReacted('m1', '👍'), isFalse, reason: 'rolled back');
      },
    );

    test('does not roll back over a newer change', () async {
      final first = Completer<void>();
      var call = 0;
      final c = make(
        onChange: (_) => call++ == 0 ? first.future : Future.value(),
      );

      final pending = c.toggle('m1', '👍');
      await c.toggle('m1', '❤️');
      first.completeError(StateError('late failure'));
      await expectLater(pending, throwsStateError);
      expect(c.hasReacted('m1', '❤️'), isTrue);
    });
  });

  test('never exposes internal lists', () {
    final c = make();
    final source = [const Reaction(emoji: '👍', userId: 'u2')];
    c.setReactions('m1', source);
    source.clear();
    expect(c.reactionsFor('m1'), hasLength(1));
    expect(() => c.reactionsFor('m1').clear(), throwsUnsupportedError);
  });

  test('clear one message or all', () async {
    final c = make();
    await c.add('m1', '👍');
    await c.add('m2', '👍');
    c.clear('m1');
    expect(c.summariesFor('m1'), isEmpty);
    expect(c.summariesFor('m2'), hasLength(1));
    c.clear();
    expect(c.summariesFor('m2'), isEmpty);
  });

  test('bind returns current summaries and a toggling callback', () async {
    final c = make(onChange: (_) async => throw StateError('ignored by bind'));
    final binding = c.bind('m1');
    expect(binding.reactions, isEmpty);

    binding.onReactionSelected('👍');
    await Future<void>.delayed(Duration.zero);
    // onChange failed, so the optimistic add was rolled back; no uncaught error.
    expect(c.hasReacted('m1', '👍'), isFalse);
  });

  test('does not notify after dispose', () async {
    final c = ReactionsController(
      currentUserId: 'me',
      onChange: (_) => Future<void>.error(StateError('x')),
    );
    final pending = c.toggle('m1', '👍');
    c.dispose();
    await expectLater(pending, throwsStateError);
  });
}
