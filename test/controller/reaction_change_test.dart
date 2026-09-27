import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ReactionAdded equality, hashCode and toString', () {
    const a = ReactionAdded(messageId: 'm1', emoji: '👍');
    const b = ReactionAdded(messageId: 'm1', emoji: '👍');
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a.toString(), 'ReactionAdded(m1, 👍)');
    expect(a == const ReactionAdded(messageId: 'm1', emoji: '❤️'), isFalse);
  });

  test('ReactionRemoved equality, hashCode and toString', () {
    const a = ReactionRemoved(messageId: 'm1', emoji: '👍');
    const b = ReactionRemoved(messageId: 'm1', emoji: '👍');
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a.toString(), 'ReactionRemoved(m1, 👍)');
  });

  test('different subtypes with the same fields are not equal', () {
    const added = ReactionAdded(messageId: 'm1', emoji: '👍');
    const removed = ReactionRemoved(messageId: 'm1', emoji: '👍');
    expect(added == removed, isFalse);
  });

  test('ReactionReplaced equality, hashCode and toString', () {
    const a = ReactionReplaced(
      messageId: 'm1',
      emoji: '❤️',
      previousEmoji: '👍',
    );
    const b = ReactionReplaced(
      messageId: 'm1',
      emoji: '❤️',
      previousEmoji: '👍',
    );
    const c = ReactionReplaced(
      messageId: 'm1',
      emoji: '❤️',
      previousEmoji: '😂',
    );
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a == c, isFalse);
    expect(a.toString(), 'ReactionReplaced(m1, 👍 → ❤️)');
  });
}
