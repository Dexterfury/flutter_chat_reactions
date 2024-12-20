import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/widgets/reactions_bubble.dart';

/// A widget that arranges reaction bubbles in a stacked formation.
///
/// This widget is responsible for laying out individual reaction bubbles
/// with proper overlap and direction.
class ReactionStack extends StatelessWidget {
  /// Creates a reaction stack widget.
  ///
  /// All parameters must not be null.
  const ReactionStack({
    super.key,
    required this.reactions,
    required this.size,
    required this.stackedValue,
    required this.direction,
  });

  /// The list of reactions to display in the stack.
  final List<String> reactions;

  /// The font size for each reaction.
  final double size;

  /// The horizontal offset between stacked reactions.
  final double stackedValue;

  /// The direction in which reactions should be stacked.
  final TextDirection direction;

  @override
  Widget build(BuildContext context) {
    // Create a list of reaction bubbles with proper indexing
    final reactionWidgets = reactions.asMap().entries.map((entry) {
      return ReactionBubble(
        reaction: entry.value,
        index: entry.key,
        size: size,
        stackedValue: stackedValue,
      );
    }).toList();

    // Reverse the list for LTR layout to ensure proper stacking order
    return Stack(
      children: direction == TextDirection.ltr
          ? reactionWidgets.reversed.toList()
          : reactionWidgets,
    );
  }
}
