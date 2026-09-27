import 'package:example/adapters/emoji_picker_sheet.dart';
import 'package:example/app/demo_id.dart';
import 'package:example/data/sample_chat.dart';
import 'package:example/widgets/chat_bubble.dart';
import 'package:example/widgets/demo_chat_model.dart';
import 'package:example/widgets/message_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';

/// iMessage / WhatsApp style: focused overlay, stacked summary overlaid on
/// the bubble, one reaction per user, and a full emoji picker behind "+".
class MessengerDemo extends StatefulWidget {
  /// Creates the demo. [pickEmoji] is injectable for tests.
  const MessengerDemo({super.key, this.pickEmoji = showEmojiPickerSheet});

  /// Opens the full emoji picker.
  final EmojiPickerLauncher pickEmoji;

  @override
  State<MessengerDemo> createState() => _MessengerDemoState();
}

class _MessengerDemoState extends State<MessengerDemo> {
  final _chat = DemoChatModel();

  @override
  void dispose() {
    _chat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(DemoId.messenger.title)),
      body: ChatReactionsScope(
        presenter: const FocusedOverlayPresenter(),
        child: ListenableBuilder(
          listenable: _chat,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
            children: [
              for (final message in _chat.messages)
                _MessengerRow(
                  key: ValueKey('row-${message.id}'),
                  message: message,
                  chat: _chat,
                  pickEmoji: widget.pickEmoji,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessengerRow extends StatelessWidget {
  const _MessengerRow({
    super.key,
    required this.message,
    required this.chat,
    required this.pickEmoji,
  });

  final ChatMessage message;
  final DemoChatModel chat;
  final EmojiPickerLauncher pickEmoji;

  @override
  Widget build(BuildContext context) {
    final reactions = chat.reactionsFor(message.id);
    final select = chat.onReactionSelected(message.id);
    final alignment = message.isMine
        ? ReactionAlignment.end
        : ReactionAlignment.start;
    return Padding(
      padding: EdgeInsets.only(bottom: reactions.isEmpty ? 8 : 20),
      child: Align(
        alignment: message.isMine
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: ReactableMessage(
          key: ValueKey('reactable-${message.id}'),
          alignment: alignment,
          reactions: reactions,
          onReactionSelected: select,
          actionsBuilder: (_) => actionsFor(message),
          onActionSelected: (action) =>
              chat.handleAction(context, message, action),
          onMoreTap: (context) async {
            final emoji = await pickEmoji(context);
            if (emoji != null) select(emoji);
          },
          child: ReactionsSummaryView.overlay(
            key: ValueKey('summary-${message.id}'),
            reactions: reactions,
            alignment: alignment,
            onTap: () => showReactionDetails(context, reactions),
            child: ChatBubble(message: message),
          ),
        ),
      ),
    );
  }
}
