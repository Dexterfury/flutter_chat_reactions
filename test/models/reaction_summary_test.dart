import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const summary = ReactionSummary(
    emoji: '👍',
    count: 2,
    reactedByMe: true,
    users: [
      ReactionUser(id: 'me'),
      ReactionUser(id: 'u2', name: 'Bo'),
    ],
  );

  test('JSON round trip', () {
    expect(ReactionSummary.fromJson(summary.toJson()), summary);
  });

  test('fromJson tolerates missing optional fields', () {
    final s = ReactionSummary.fromJson({'emoji': '🔥', 'count': 3});
    expect(s.reactedByMe, isFalse);
    expect(s.users, isEmpty);
  });

  test('equality includes users', () {
    expect(summary == summary.copyWith(users: const []), isFalse);
    expect(summary.copyWith(count: 5).count, 5);
  });

  test('count must be at least 1', () {
    expect(() => ReactionSummary(emoji: 'x', count: 0), throwsAssertionError);
  });

  test('hashCode is consistent with equality and toString identifies it', () {
    const a = ReactionSummary(emoji: '👍', count: 2);
    const b = ReactionSummary(emoji: '👍', count: 2);
    expect(a.hashCode, b.hashCode);
    expect(a.toString(), contains('👍'));
    expect(a.toString(), contains('2'));
  });
}
