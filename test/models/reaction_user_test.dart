import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('JSON round trip omits null fields', () {
    const user = ReactionUser(id: 'u1', name: 'Ada');
    expect(user.toJson(), {'id': 'u1', 'name': 'Ada'});
    expect(ReactionUser.fromJson(user.toJson()), user);
  });

  test('value equality and copyWith', () {
    const a = ReactionUser(id: 'u1', name: 'Ada');
    expect(a, const ReactionUser(id: 'u1', name: 'Ada'));
    expect(a.hashCode, const ReactionUser(id: 'u1', name: 'Ada').hashCode);
    expect(a.copyWith(avatarUrl: 'x').avatarUrl, 'x');
    expect(a == a.copyWith(name: 'Bob'), isFalse);
  });

  test('toString identifies the user', () {
    const a = ReactionUser(id: 'u1', name: 'Ada');
    expect(a.toString(), contains('u1'));
    expect(a.toString(), contains('Ada'));
  });
}
