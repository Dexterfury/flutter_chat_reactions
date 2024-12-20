import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/widgets/reaction_stack.dart';
import 'package:flutter_chat_reactions/widgets/remaining_count.dart';

/// A widget that displays reactions (emojis or text) in a horizontally stacked format.
///
/// This widget is useful for showing multiple reactions in a space-efficient manner,
/// similar to social media reaction displays. It automatically handles overflow by
/// showing a count of additional reactions beyond the maximum visible limit.
///
/// Example usage:
/// ```dart
/// StackedReactions(
///   reactions: DefaultData.reactions,
///   size: 24.0,
///   stackedValue: 5.0,
/// )
/// ```
///
/// The widget supports both LTR and RTL text directions and can be customized with
/// different sizes and spacing between reactions.
class StackedReactions extends StatelessWidget {
  /// Creates a stacked reactions widget.
  ///
  /// The [reactions] parameter must not be null and contains the list of
  /// reactions to display.
  ///
  /// The [size] parameter determines the font size of each reaction.
  ///
  /// The [stackedValue] determines how much each reaction overlaps with the
  /// previous one. A smaller value creates more overlap.
  ///
  /// The [direction] parameter determines the layout direction of the stack.
  const StackedReactions({
    super.key,
    required this.reactions,
    this.size = 20.0,
    this.stackedValue = 4.0,
    this.direction = TextDirection.ltr,
  });

  /// The list of reaction strings to display.
  ///
  /// Each string in this list represents a single reaction, typically an emoji
  /// or a short text.
  final List<String> reactions;

  /// The font size for each reaction.
  ///
  /// This value also affects the overall size of the reaction bubbles.
  /// Defaults to 20.0.
  final double size;

  /// The horizontal offset between stacked reactions.
  ///
  /// A smaller value creates more overlap between reactions.
  /// Defaults to 4.0.
  final double stackedValue;

  /// The direction in which reactions should be stacked.
  ///
  /// Use [TextDirection.ltr] for left-to-right languages and
  /// [TextDirection.rtl] for right-to-left languages.
  /// Defaults to [TextDirection.ltr].
  final TextDirection direction;

  /// Maximum number of reactions to show before displaying a count.
  static const int _maxVisibleReactions = 5;

  /// Font size for the remaining count indicator.
  static const double remainingTextSize = 12.0;

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) {
      return const SizedBox.shrink();
    }

    // Limit the number of visible reactions and calculate remaining count
    final reactionsToShow = reactions.length > _maxVisibleReactions
        ? reactions.sublist(0, _maxVisibleReactions)
        : reactions;
    final remaining = reactions.length - reactionsToShow.length;

    return Row(
      children: [
        ReactionStack(
          reactions: reactionsToShow,
          size: size,
          stackedValue: stackedValue,
          direction: direction,
        ),
        if (remaining > 0)
          RemainingCount(
            count: remaining,
            colorScheme: Theme.of(context).colorScheme,
          ),
      ],
    );
  }
}
