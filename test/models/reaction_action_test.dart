import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('actions are equal by id only', () {
    const a = ReactionAction<int>(
      id: 'reply',
      label: 'Reply',
      icon: Icons.reply,
      value: 1,
    );
    const b = ReactionAction<int>(id: 'reply', label: 'Antworten', value: 2);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a == const ReactionAction<int>(id: 'copy', label: 'Reply'), isFalse);
  });

  test('defaults', () {
    const a = ReactionAction<void>(id: 'x', label: 'X');
    expect(a.isDestructive, isFalse);
    expect(a.icon, isNull);
  });

  test('toString identifies the action by id', () {
    const a = ReactionAction<void>(id: 'reply', label: 'Reply');
    expect(a.toString(), 'ReactionAction(reply)');
  });

  test('copyWith replaces given fields and keeps the rest', () {
    const a = ReactionAction<int>(
      id: 'reply',
      label: 'Reply',
      icon: Icons.reply,
      value: 1,
    );
    final b = a.copyWith(label: 'Antworten', isDestructive: true, value: 2);
    expect(b.id, 'reply');
    expect(b.label, 'Antworten');
    expect(b.icon, Icons.reply);
    expect(b.isDestructive, isTrue);
    expect(b.value, 2);
    expect(a.copyWith(id: 'copy').id, 'copy');
    expect(a.copyWith().label, 'Reply');
    expect(a.copyWith(icon: Icons.copy).icon, Icons.copy);
  });
}
