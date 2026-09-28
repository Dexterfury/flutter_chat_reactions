import 'package:example/data/sample_chat.dart';
import 'package:example/widgets/chat_bubble.dart';
import 'package:example/widgets/demo_chat_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';

/// One message row: a [ReactableMessage] around a [ChatBubble], with a
/// [ReactionsSummaryView] below it when the message has reactions.
class BubbleRow extends StatelessWidget {
  /// Creates a row for [message] backed by [chat].
  const BubbleRow({
    super.key,
    required this.message,
    required this.chat,
    this.actionsFor,
    this.summaryLayout = ReactionSummaryLayout.chips,
    this.showAuthor = true,
  });

  /// The message.
  final ChatMessage message;

  /// The demo's chat model.
  final DemoChatModel chat;

  /// Context-menu actions for a message; null for none.
  final List<ReactionAction<dynamic>> Function(ChatMessage message)? actionsFor;

  /// How the summary under the bubble is laid out.
  final ReactionSummaryLayout summaryLayout;

  /// Whether other people's names appear in their bubbles.
  final bool showAuthor;

  @override
  Widget build(BuildContext context) {
    final id = message.id;
    final reactions = chat.reactionsFor(id);
    final select = chat.onReactionSelected(id);
    final mine = message.isMine;
    final actions = actionsFor;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Align(
        alignment: mine
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: mine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            ReactableMessage(
              key: ValueKey('reactable-$id'),
              alignment: mine ? ReactionAlignment.end : ReactionAlignment.start,
              reactions: reactions,
              onReactionSelected: select,
              actionsBuilder: actions == null ? null : (_) => actions(message),
              onActionSelected: (action) =>
                  chat.handleAction(context, message, action),
              child: ChatBubble(message: message, showAuthor: showAuthor),
            ),
            if (reactions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: ReactionsSummaryView(
                  key: ValueKey('summary-$id'),
                  reactions: reactions,
                  layout: summaryLayout,
                  onReactionTap: select,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
