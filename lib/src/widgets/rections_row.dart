import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/src/widgets/reactions_button.dart';

class ReactionsRow extends StatelessWidget {
  /// Creates a reactions row widget.
  const ReactionsRow({
    super.key,
    required this.reactions,
    required this.alignment,
    required this.onReactionTap,
  });

  final List<String> reactions;
  final Alignment alignment;
  final Function(String, int) onReactionTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade500,
                spreadRadius: 1,
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < reactions.length; i++)
                ReactionButton(
                  reaction: reactions[i],
                  index: i,
                  onTap: onReactionTap,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
