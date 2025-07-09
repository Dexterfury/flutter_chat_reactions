import 'package:example/models/message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';

class MessageWidget extends StatelessWidget {
  const MessageWidget({
    super.key,
    required this.message,
    required this.controller,
  });

  final Message message;
  final ReactionsController controller;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
          minWidth: MediaQuery.of(context).size.width * 0.3,
        ),
        child: Stack(
          children: [
            // message
            buildMessage(
              context,
            ),

            //reactions
            buildReactions(
              context,
              message.isMe,
            ),
          ],
        ),
      ),
    );
  }

  // reactions widget
  Widget buildReactions(BuildContext context, bool isMe) {
    return isMe
        ? Positioned(
            bottom: 4,
            right: 20,
            child: StackedReactions(
              messageId: message.id,
              controller: controller,
              maxReactionsToShow: 3,
            ),
          )
        : Positioned(
            bottom: 4,
            left: 8,
            child: StackedReactions(
              messageId: message.id,
              controller: controller,
              maxReactionsToShow: 3,
            ),
          );
  }

  // message widget
  Widget buildMessage(
    BuildContext context,
  ) {
    final hasReactions = controller.getReactionCounts(message.id).isNotEmpty;
    // padding for the message card
    final padding = hasReactions
        ? message.isMe
            ? const EdgeInsets.only(left: 30.0, bottom: 25.0)
            : const EdgeInsets.only(right: 30.0, bottom: 25.0)
        : const EdgeInsets.only(bottom: 0.0);
    // border radius for the message card
    final borderRadius = message.isMe
        ? const BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
            bottomLeft: Radius.circular(15),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
            bottomRight: Radius.circular(15),
          );
    // car color
    final cardColor = message.isMe
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.secondary;

    // text color
    final textColor = message.isMe
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.onSecondary;
    return Padding(
      padding: padding,
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
        ),
        color: cardColor,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: message.isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  message.message,
                  style: TextStyle(
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.timeSent,
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(width: 5),
                    message.isMe
                        ? const Icon(
                            Icons.done_all,
                            color: Colors.blue,
                            size: 20,
                          )
                        : const SizedBox.shrink(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
