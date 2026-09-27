import 'package:flutter/material.dart';

import '../models/reaction_action.dart';
import '../theme/chat_reactions_theme.dart';
import '../theme/reaction_styles.dart';

/// A vertical list of message actions (Reply, Copy, Delete, ...). Its width is
/// sized to the content, between the style's min and max width.
class ReactionActionMenu extends StatelessWidget {
  /// Creates an action menu.
  const ReactionActionMenu({
    super.key,
    required this.actions,
    required this.onSelected,
    this.style,
  });

  /// Actions to show, in order.
  final List<ReactionAction<dynamic>> actions;

  /// Called with the tapped action.
  final ValueChanged<ReactionAction<dynamic>> onSelected;

  /// Overrides for the themed menu style.
  final ReactionMenuStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ChatReactionsTheme.of(context);
    final style = theme.menuStyle.merge(this.style);
    final shape = style.shape!;

    final children = <Widget>[];
    for (var i = 0; i < actions.length; i++) {
      if (i > 0 && theme.isCupertino) {
        children.add(
          Divider(height: 0.5, thickness: 0.5, color: style.dividerColor),
        );
      }
      children.add(
        _ActionItem(action: actions[i], style: style, onSelected: onSelected),
      );
    }

    return FocusTraversalGroup(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: style.minWidth!,
          maxWidth: style.maxWidth!,
        ),
        child: IntrinsicWidth(
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: style.backgroundColor,
              shape: shape,
              shadows: style.shadows,
            ),
            child: ClipPath(
              clipper: ShapeBorderClipper(
                shape: shape,
                textDirection: Directionality.of(context),
              ),
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({
    required this.action,
    required this.style,
    required this.onSelected,
  });

  final ReactionAction<dynamic> action;
  final ReactionMenuStyle style;
  final ValueChanged<ReactionAction<dynamic>> onSelected;

  @override
  Widget build(BuildContext context) {
    final color = action.isDestructive ? style.destructiveColor : null;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: () => onSelected(action),
        child: Padding(
          padding: style.itemPadding!,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  action.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: style.textStyle!.copyWith(color: color),
                ),
              ),
              if (action.icon != null) ...[
                const SizedBox(width: 16),
                Icon(action.icon, size: 20, color: color ?? style.iconColor),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
