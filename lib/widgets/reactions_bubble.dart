import 'package:flutter/material.dart';

/// A widget that displays a single reaction in a decorated bubble.
///
/// This widget handles the visual presentation of each individual reaction,
/// including background, shadow, and text styling.
class ReactionBubble extends StatelessWidget {
  /// Creates a reaction bubble widget.
  ///
  /// All parameters must not be null.
  const ReactionBubble({
    super.key,
    required this.reaction,
    required this.index,
    required this.size,
    required this.stackedValue,
  });

  /// The reaction string to display (typically an emoji).
  final String reaction;

  /// The position index in the stack (affects horizontal positioning).
  final int index;

  /// The font size for the reaction.
  final double size;

  /// The horizontal offset multiplier for positioning.
  final double stackedValue;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final leftOffset = size - stackedValue;

    return Container(
      margin: EdgeInsets.only(left: leftOffset * index),
      padding: const EdgeInsets.fromLTRB(5.0, 2.0, 5.0, 2.0),
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
}
