import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/widgets/stacked_reactions.dart';

/// A widget that displays the count of additional reactions not shown in the stack.
///
/// This widget appears when there are more reactions than can be displayed in
/// the main stack view.
class RemainingCount extends StatelessWidget {
  /// Creates a remaining count widget.
  ///
  /// Both [count] and [colorScheme] must not be null.
  const RemainingCount({
    super.key,
    required this.count,
    required this.colorScheme,
  });

  /// The number of additional reactions not shown in the stack.
  final int count;

  /// The color scheme to use for styling the count indicator.
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2.0),
      margin: const EdgeInsets.all(2.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.all(Radius.circular(25)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.onSurface,
            offset: const Offset(0.0, 1.0),
            blurRadius: 6.0,
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(2.0),
          child: Material(
            color: Colors.transparent,
            child: Text(
              '+$count',
              style:
                  const TextStyle(fontSize: StackedReactions.remainingTextSize),
            ),
          ),
        ),
      ),
    );
  }
}
