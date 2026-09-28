import 'package:example/data/sample_chat.dart';
import 'package:example/widgets/demo_chat_model.dart';
import 'package:example/widgets/message_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sample data never uses default quick-reaction emojis in text', () {
    for (final message in sampleConversation()) {
      for (final emoji in kDefaultQuickReactions) {
        expect(message.text.contains(emoji), isFalse, reason: message.id);
      }
      final rtlText = kRtlSampleTexts[message.id];
      expect(rtlText, isNotNull, reason: '${message.id} has no RTL text');
      for (final emoji in kDefaultQuickReactions) {
        expect(rtlText!.contains(emoji), isFalse, reason: message.id);
      }
    }
  });

  test('seeds reactions and exposes summaries', () {
    final chat = DemoChatModel();
    addTearDown(chat.dispose);
    final m2 = chat.reactionsFor('m2');
    expect(m2.first.emoji, '👍');
    expect(m2.first.count, 2);
    expect(chat.reactionsFor('m3').single.reactedByMe, isTrue);
  });

  test(
    'onReactionSelected toggles through the controller and notifies',
    () async {
      final chat = DemoChatModel();
      addTearDown(chat.dispose);
      var notified = 0;
      chat.addListener(() => notified++);
      chat.onReactionSelected('m1')('🙏');
      await Future<void>.delayed(Duration.zero);
      expect(chat.reactionsFor('m1').single.emoji, '🙏');
      expect(notified, greaterThan(0));
    },
  );

  test(
    'multiple policy keeps several reactions from the current user',
    () async {
      final chat = DemoChatModel(policy: const ReactionPolicy.multiple());
      addTearDown(chat.dispose);
      chat.onReactionSelected('m1')('👍');
      chat.onReactionSelected('m1')('🎉');
      await Future<void>.delayed(Duration.zero);
      expect(chat.reactionsFor('m1'), hasLength(2));
    },
  );

  test('actionsFor offers delete only on own messages and pin on request', () {
    final mine = sampleConversation().firstWhere((m) => m.isMine);
    final theirs = sampleConversation().firstWhere((m) => !m.isMine);
    expect(actionsFor(mine), contains(kDeleteAction));
    expect(actionsFor(theirs), isNot(contains(kDeleteAction)));
    expect(actionsFor(theirs, pin: true), contains(kPinAction));
  });

  testWidgets('delete and pin actions update the model', (tester) async {
    final chat = DemoChatModel();
    addTearDown(chat.dispose);
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (c) {
              context = c;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    final m5 = chat.messages.firstWhere((m) => m.id == 'm5');
    final m1 = chat.messages.firstWhere((m) => m.id == 'm1');

    chat.handleAction(context, m1, kPinAction);
    expect(chat.pinned?.id, 'm1');

    chat.handleAction(context, m5, kDeleteAction);
    await tester.pump();
    expect(chat.messages.any((m) => m.id == 'm5'), isFalse);
    expect(find.text('Message deleted'), findsOneWidget);

    chat.handleAction(context, m1, kDeleteAction);
    expect(
      chat.pinned,
      isNull,
      reason: 'deleting the pinned message unpins it',
    );
  });
}
