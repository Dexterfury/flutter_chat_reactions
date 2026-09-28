// Importing the barrel is the point of this test: it pulls every exported
// library into coverage.
// ignore: unused_import
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('barrel library loads', () {
    expect(true, isTrue);
  });
}
