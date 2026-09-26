import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('factories produce the concrete policies', () {
    expect(const ReactionPolicy.single(), isA<SingleReactionPolicy>());
    const multiple = ReactionPolicy.multiple(max: 3);
    expect(multiple, isA<MultipleReactionPolicy>());
    expect((multiple as MultipleReactionPolicy).max, 3);
  });

  test('multiple policies compare by max', () {
    expect(
      const MultipleReactionPolicy(max: 2),
      const MultipleReactionPolicy(max: 2),
    );
    expect(
      const MultipleReactionPolicy() == const MultipleReactionPolicy(max: 2),
      isFalse,
    );
  });

  test('max must be positive', () {
    expect(() => MultipleReactionPolicy(max: 0), throwsAssertionError);
  });
}
