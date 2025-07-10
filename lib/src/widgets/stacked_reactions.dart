import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/src/controllers/reactions_controller.dart';

/// A widget that displays a stack of reactions for a message.
///
/// This widget shows a row of reactions with their counts, and a "+N" indicator
/// if there are more reactions than can be shown.
class StackedReactions extends StatelessWidget {
  /// Unique identifier for the message.
  final String messageId;

  /// Controller to manage reaction state.
  final ReactionsController controller;

  /// The size of each reaction widget.
  final double size;

  /// The amount of overlap for stacked reactions.
  final double stackedValue;

  /// The direction of the reaction stack (ltr or rtl).
  final TextDirection direction;

  /// The maximum number of reactions to show before "+N".
  final int maxReactionsToShow;

  /// Callback triggered when the widget is tapped.
  final VoidCallback? onTap;

  /// Optional custom builder for the reaction widget.
  final Widget Function(String, int, bool)? customReactionBuilder;

  /// Reaction background color
  final Color? reactionBackgroundColor;

  /// Creates a stacked reactions widget.
  const StackedReactions({
    super.key,
    required this.messageId,
    required this.controller,
    this.size = 25.0,
    this.stackedValue = 4.0,
    this.direction = TextDirection.ltr,
    this.maxReactionsToShow = 5,
    this.onTap,
    this.customReactionBuilder,
    this.reactionBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = reactionBackgroundColor ?? Theme.of(context).primaryColor;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final reactionCounts = controller.getReactionCounts(messageId);
        if (reactionCounts.isEmpty) return const SizedBox.shrink();

        final sortedReactions = reactionCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        final reactionsToShow =
            sortedReactions.take(maxReactionsToShow).toList();
        final remaining = sortedReactions.length - reactionsToShow.length;

        return GestureDetector(
          onTap: onTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  for (int i = 0; i < reactionsToShow.length; i++)
                    _buildReactionWidget(
                      context,
                      reactionsToShow[i].key,
                      reactionsToShow[i].value,
                      i,
                      color,
                    ),
                ],
              ),
              if (remaining > 0) _buildRemainingWidget(context, remaining),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReactionWidget(
      BuildContext context, String emoji, int count, int index, Color color) {
    final isUserReacted = controller.hasUserReacted(messageId, emoji);
    final leftOffset = size - stackedValue;

    return Container(
      margin: EdgeInsets.only(
        left: direction == TextDirection.ltr ? leftOffset * index : 0,
        right: direction == TextDirection.rtl ? leftOffset * index : 0,
      ),
      child: customReactionBuilder?.call(emoji, count, isUserReacted) ??
          _defaultReactionWidget(context, emoji, count, isUserReacted, color),
    );
  }

  Widget _defaultReactionWidget(BuildContext context, String emoji, int count,
      bool isUserReacted, Color color) {
    // final theme = Theme.of(context);
    // final color = isUserReacted ? theme.primaryColor : theme.disabledColor;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            //color: color,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: TextStyle(fontSize: size * 0.8)),
            if (count > 1) ...[
              const SizedBox(width: 2),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: size * 0.6,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRemainingWidget(BuildContext context, int remaining) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        margin: const EdgeInsets.only(left: 4),
        decoration: BoxDecoration(
          color: theme.disabledColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '+$remaining',
          style: TextStyle(
            fontSize: size * 0.6,
            fontWeight: FontWeight.bold,
            color: theme.disabledColor,
          ),
        ),
      ),
    );
  }
}
