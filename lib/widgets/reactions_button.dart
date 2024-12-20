import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';

/// Single reaction button with animation
class ReactionButton extends StatelessWidget {
  /// Creates a reaction button widget.
  const ReactionButton({
    super.key,
    required this.reaction,
    required this.index,
    required this.onTap,
    required this.isClicked,
  });

  final String reaction;
  final int index;
  final Function(String, int) onTap;
  final bool isClicked;

  @override
  Widget build(BuildContext context) {
    return FadeInLeft(
      from: (index * 20).toDouble(),
      duration: const Duration(milliseconds: 500),
      delay: const Duration(milliseconds: 200),
      child: InkWell(
        onTap: () => onTap(reaction, index),
        child: Pulse(
          infinite: false,
          duration: const Duration(milliseconds: 500),
          animate: isClicked,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4.0, 2.0, 4.0, 2.0),
            child: Text(
              reaction,
              style: const TextStyle(fontSize: 22),
            ),
          ),
        ),
      ),
    );
  }
}
