import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_reactions/src/controllers/reactions_controller.dart';
import 'package:flutter_chat_reactions/src/models/chat_reactions_config.dart';
import 'package:flutter_chat_reactions/src/models/menu_item.dart';
import 'package:flutter_chat_reactions/src/utilities/hero_dialog_route.dart';
import 'package:flutter_chat_reactions/src/widgets/context_menu_widget.dart';

class ChatMessageWrapper extends StatelessWidget {
  final String messageId;
  final Widget child;
  final ReactionsController controller;
  final ChatReactionsConfig config;
  final Function(String)? onReactionAdded;
  final Function(String)? onReactionRemoved;
  final Function(MenuItem)? onMenuItemTapped;
  final Alignment alignment;

  const ChatMessageWrapper({
    super.key,
    required this.messageId,
    required this.child,
    required this.controller,
    this.config = const ChatReactionsConfig(),
    this.onReactionAdded,
    this.onReactionRemoved,
    this.onMenuItemTapped,
    this.alignment = Alignment.centerRight,
  });

  void _handleReactionTap(BuildContext context, String reaction) {
    if (config.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }

    if (reaction == '➕') {
      showModalBottomSheet(
        context: context,
        builder: (context) => config.emojiPickerBuilder!(
          context,
          (emoji) {
            Navigator.pop(context);
            _addReaction(emoji);
          },
        ),
      );
    } else {
      _toggleReaction(reaction);
    }
  }

  void _addReaction(String reaction) {
    controller.addReaction(messageId, reaction);
    onReactionAdded?.call(reaction);
  }

  void _toggleReaction(String reaction) {
    final wasReacted = controller.hasUserReacted(messageId, reaction);
    controller.toggleReaction(messageId, reaction);

    if (wasReacted) {
      onReactionRemoved?.call(reaction);
    } else {
      onReactionAdded?.call(reaction);
    }
  }

  void _handleMenuItemTap(MenuItem item) {
    if (config.enableHapticFeedback) {
      HapticFeedback.selectionClick();
    }
    onMenuItemTapped?.call(item);
  }

  void _showReactionsDialog(BuildContext context) {
    Navigator.of(context).push(
      HeroDialogRoute(
        builder: (context) => ReactionsDialogWidget(
          messageId: messageId,
          messageWidget: child,
          controller: controller,
          config: config,
          onReactionTap: (reaction) => _handleReactionTap(context, reaction),
          onMenuItemTap: _handleMenuItemTap,
          alignment: alignment,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress:
          config.enableLongPress ? () => _showReactionsDialog(context) : null,
      onDoubleTap:
          config.enableDoubleTap ? () => _showReactionsDialog(context) : null,
      child: Hero(
        tag: messageId,
        child: child,
      ),
    );
  }
}
