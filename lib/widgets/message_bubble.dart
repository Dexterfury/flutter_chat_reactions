import 'package:flutter/material.dart';

/// Widget that displays the original message with Hero animation
class MessageBubble extends StatelessWidget {
  /// Creates a message widget.
  const MessageBubble({
    super.key,
    required this.id,
    required this.messageWidget,
    required this.alignment,
  });

  final String id;
  final Widget messageWidget;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Hero(
        tag: id,
        child: messageWidget,
      ),
    );
  }
}
