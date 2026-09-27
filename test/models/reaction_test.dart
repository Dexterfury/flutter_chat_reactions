import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

Reaction r(String emoji, String user, {int? minute, String? name}) => Reaction(
  emoji: emoji,
  userId: user,
  userName: name,
  createdAt: minute == null ? null : DateTime.utc(2026, 1, 1, 0, minute),
);

void main() {
  group('Reaction JSON', () {
    test('round trip including extra', () {
      final reaction = Reaction(
        emoji: '👍',
        userId: 'u1',
        userName: 'Ada',
        createdAt: DateTime.utc(2026, 9, 26, 10),
        extra: const {'source': 'ios'},
      );
      expect(Reaction.fromJson(reaction.toJson()), reaction);
    });

    test('accepts the 0.2.x "timestamp" key', () {
      final reaction = Reaction.fromJson({
        'emoji': '👍',
        'userId': 'u1',
        'timestamp': '2026-09-26T10:00:00.000Z',
      });
      expect(reaction.createdAt, DateTime.utc(2026, 9, 26, 10));
    });

    test('equality considers extra', () {
      const a = Reaction(emoji: '👍', userId: 'u1', extra: {'k': 1});
      const b = Reaction(emoji: '👍', userId: 'u1', extra: {'k': 2});
      expect(a == b, isFalse);
      expect(a, const Reaction(emoji: '👍', userId: 'u1', extra: {'k': 1}));
    });

    test('copyWith replaces given fields and keeps the rest', () {
      const original = Reaction(emoji: '👍', userId: 'u1', userName: 'Ada');
      final copy = original.copyWith(
        emoji: '❤️',
        userId: 'u2',
        userName: 'Bo',
        createdAt: DateTime.utc(2026),
        extra: const {'k': 1},
      );
      expect(copy.emoji, '❤️');
      expect(copy.userId, 'u2');
      expect(copy.userName, 'Bo');
      expect(copy.createdAt, DateTime.utc(2026));
      expect(copy.extra, {'k': 1});
      expect(
        original.copyWith().emoji,
        '👍',
        reason: 'no-arg copyWith keeps values',
      );
    });

    test('hashCode is consistent with equality and toString identifies it', () {
      const a = Reaction(emoji: '👍', userId: 'u1', extra: {'k': 1});
      const b = Reaction(emoji: '👍', userId: 'u1', extra: {'k': 1});
      expect(a.hashCode, b.hashCode);
      expect(a.toString(), contains('👍'));
      expect(a.toString(), contains('u1'));
    });
  });

  group('summarize', () {
    test('aggregates counts, users and reactedByMe', () {
      final summaries = [
        r('👍', 'u1', name: 'Ada'),
        r('❤️', 'me'),
        r('👍', 'me'),
      ].summarize(currentUserId: 'me');

      expect(summaries.map((s) => s.emoji), ['👍', '❤️']);
      expect(summaries.first.count, 2);
      expect(summaries.first.reactedByMe, isTrue);
      expect(
        summaries.first.users.first,
        const ReactionUser(id: 'u1', name: 'Ada'),
      );
    });

    test('ignores duplicate reactions from the same user', () {
      final summaries = [
        r('👍', 'u1'),
        r('👍', 'u1'),
      ].summarize(currentUserId: 'me');
      expect(summaries.single.count, 1);
    });

    test('countDesc breaks ties by first appearance', () {
      final summaries = [
        r('😂', 'u1'),
        r('👍', 'u2'),
        r('👍', 'u3'),
        r('❤️', 'u4'),
      ].summarize(currentUserId: 'me');
      expect(summaries.map((s) => s.emoji), ['👍', '😂', '❤️']);
    });

    test('firstReacted orders by earliest createdAt, undated last', () {
      final summaries = [
        r('😂', 'u1'),
        r('👍', 'u2', minute: 5),
        r('❤️', 'u3', minute: 1),
      ].summarize(currentUserId: 'me', sort: ReactionSort.firstReacted);
      expect(summaries.map((s) => s.emoji), ['❤️', '👍', '😂']);
    });

    test('firstReacted: a dated reaction sorts before an undated one, and '
        'two undated reactions keep first-appearance order', () {
      final summaries = [
        r('❤️', 'u1'),
        r('😂', 'u2'),
        r('👍', 'u3', minute: 5),
      ].summarize(currentUserId: 'me', sort: ReactionSort.firstReacted);
      expect(summaries.map((s) => s.emoji), ['👍', '❤️', '😂']);
    });

    test('none keeps first-appearance order', () {
      final summaries = [
        r('😂', 'u1'),
        r('👍', 'u2'),
        r('👍', 'u3'),
      ].summarize(currentUserId: 'me', sort: ReactionSort.none);
      expect(summaries.map((s) => s.emoji), ['😂', '👍']);
    });

    test('result is unmodifiable', () {
      final summaries = [r('👍', 'u1')].summarize(currentUserId: 'me');
      expect(() => summaries.add(summaries.first), throwsUnsupportedError);
    });
  });
}
