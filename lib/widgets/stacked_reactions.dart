import 'package:flutter/material.dart';

class StackedReactions extends StatelessWidget {
  const StackedReactions({
    super.key,
    required this.reactions,
    this.size = 20.0,
    this.stackedValue = 4.0,
    this.direction = TextDirection.ltr,
  });

  // List of reactions
  final List<String> reactions;

  // Size of the reaction icon/text
  final double size;

  // Value used to calculate the horizontal offset of each reaction
  final double stackedValue;

  // Text direction (LTR or RTL)
  final TextDirection direction;

  @override
  Widget build(BuildContext context) {
    // Limit the number of displayed reactions to 5 for performance
    final reactionsToShow =
        reactions.length > 5 ? reactions.sublist(0, 5) : reactions;

    // Calculate the remaining number of reactions (if any)
    final remaining = reactions.length - reactionsToShow.length;

    // Helper function to create a reaction widget with proper styling
    Widget createReactionWidget(String reaction, int index) {
      final leftOffset = size - stackedValue;

      return Container(
        margin: EdgeInsets.only(left: leftOffset * index),
        padding: const EdgeInsets.fromLTRB(5.0, 2.0, 5.0, 2.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.background,
          borderRadius: const BorderRadius.all(Radius.circular(25)),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.onBackground,
              offset: const Offset(0.0, 1.0),
              blurRadius: 6.0,
            ),
          ],
        ),
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Text(
              reaction,
              style: TextStyle(fontSize: size),
            ),
          ),
        ),
      );
    }

    // Build the list of reaction widgets using the helper function
    final reactionWidgets = reactionsToShow.asMap().entries.map((entry) {
      final index = entry.key;
      final reaction = entry.value;
      return createReactionWidget(reaction, index);
    }).toList();

    return reactions.isEmpty
        ? const SizedBox.shrink()
        : Row(
            children: [
              Stack(
                // Efficiently display reactions based on direction
                children: direction == TextDirection.ltr
                    ? reactionWidgets.reversed.toList()
                    : reactionWidgets,
              ),
              // Show remaining count only if there are more than 5 reactions
              if (remaining > 0)
                Container(
                  padding: const EdgeInsets.all(2.0),
                  margin: const EdgeInsets.all(2.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.background,
                    borderRadius: const BorderRadius.all(Radius.circular(25)),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.onBackground,
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
                          '+$remaining',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
  }
}
