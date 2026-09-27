import 'package:example/data/sample_chat.dart';
import 'package:flutter/material.dart';

/// A chat bubble. Its visible container carries `ValueKey('msg-<id>')`.
class ChatBubble extends StatelessWidget {
  /// Creates a bubble for [message].
  const ChatBubble({super.key, required this.message, this.showAuthor = false});

  /// The message to show.
  final ChatMessage message;

  /// Whether to show the author's name above other people's messages.
  final bool showAuthor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final mine = message.isMine;
    const big = Radius.circular(18);
    const small = Radius.circular(4);
    return Container(
      key: ValueKey('msg-${message.id}'),
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: mine ? scheme.primary : scheme.surfaceContainerHighest,
        borderRadius: BorderRadiusDirectional.only(
          topStart: big,
          topEnd: big,
          bottomStart: mine ? big : small,
          bottomEnd: mine ? small : big,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showAuthor && !mine)
            Text(
              message.author.name,
              style: text.labelMedium?.copyWith(
                color: message.author.color,
                fontWeight: FontWeight.w700,
              ),
            ),
          Text(
            message.text,
            style: text.bodyLarge?.copyWith(
              color: mine ? scheme.onPrimary : scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
