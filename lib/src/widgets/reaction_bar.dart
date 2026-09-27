import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/chat_reactions_localizations.dart';
import '../theme/chat_reactions_theme.dart';
import '../theme/reaction_styles.dart';
import 'emoji.dart';

/// A row of quick reactions with optional "+" (more reactions) and "⋯"
/// (more actions) buttons. Items enter with a staggered scale-and-fade.
class ReactionBar extends StatefulWidget {
  /// Creates a reaction bar.
  const ReactionBar({
    super.key,
    required this.reactions,
    required this.onSelected,
    this.selected = const {},
    this.onMore,
    this.onMoreActions,
    this.emojiBuilder,
    this.style,
    this.animate = true,
  });

  /// Emojis to show, in order.
  final List<String> reactions;

  /// Called with the tapped emoji.
  final ValueChanged<String> onSelected;

  /// Emojis the current user already chose (highlighted).
  final Set<String> selected;

  /// Shows a "+" button when non-null.
  final VoidCallback? onMore;

  /// Shows a "⋯" button when non-null.
  final VoidCallback? onMoreActions;

  /// Custom emoji rendering.
  final EmojiBuilder? emojiBuilder;

  /// Overrides for the themed bar style.
  final ReactionBarStyle? style;

  /// Whether to play the entrance animation.
  final bool animate;

  @override
  State<ReactionBar> createState() => _ReactionBarState();
}

class _ReactionBarState extends State<ReactionBar>
    with SingleTickerProviderStateMixin {
  static const Duration _stagger = Duration(milliseconds: 30);

  late final AnimationController _controller = AnimationController(vsync: this);
  Duration _itemDuration = Duration.zero;
  bool _initialized = false;

  // Per-item entrance animations, cached so rebuilds don't attach new
  // listeners to [_controller]. Rebuilt when the item count or curve changes.
  List<CurvedAnimation> _itemAnimations = const [];
  Curve? _itemCurve;

  int get _itemCount =>
      widget.reactions.length +
      (widget.onMore == null ? 0 : 1) +
      (widget.onMoreActions == null ? 0 : 1);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _itemDuration = ChatReactionsTheme.of(context).animationDuration!;
    if (!widget.animate || _itemDuration == Duration.zero) {
      _controller.value = 1;
      return;
    }
    _controller.duration = _itemDuration + _stagger * _itemCount;
    _controller.forward();
  }

  @override
  void dispose() {
    _disposeItemAnimations();
    _controller.dispose();
    super.dispose();
  }

  void _disposeItemAnimations() {
    for (final animation in _itemAnimations) {
      animation.dispose();
    }
    _itemAnimations = const [];
  }

  void _ensureItemAnimations(int count, Curve curve) {
    if (_itemAnimations.length == count && _itemCurve == curve) return;
    _disposeItemAnimations();
    _itemCurve = curve;
    final total = _controller.duration;
    if (total == null || total == Duration.zero) return;
    _itemAnimations = [
      for (var index = 0; index < count; index++)
        CurvedAnimation(
          parent: _controller,
          curve: _interval(index, total, curve),
        ),
    ];
  }

  Interval _interval(int index, Duration total, Curve curve) {
    final start = math.min(
      1.0,
      (_stagger * index).inMicroseconds / total.inMicroseconds,
    );
    final end = math.min(
      1.0,
      start + _itemDuration.inMicroseconds / total.inMicroseconds,
    );
    return Interval(start, end, curve: curve);
  }

  Widget _animated(int index, Widget child) {
    if (index >= _itemAnimations.length) return child;
    final animation = _itemAnimations[index];
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.4, end: 1).animate(animation),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ChatReactionsTheme.of(context);
    final style = theme.barStyle.merge(widget.style);
    final l10n = ChatReactionsLocalizations.of(context);
    final emojiBuilder = widget.emojiBuilder ?? defaultEmojiBuilder;
    final size = style.emojiSize!;
    final iconColor = theme.menuStyle.iconColor;

    final items = <Widget>[
      for (final emoji in widget.reactions)
        _BarButton(
          label: l10n.emojiLabel(emoji),
          selected: widget.selected.contains(emoji),
          highlight: style.highlightColor!,
          size: size,
          onTap: () => widget.onSelected(emoji),
          child: emojiBuilder(context, emoji, size),
        ),
      if (widget.onMore != null)
        _BarButton(
          label: l10n.moreReactions,
          selected: false,
          highlight: style.highlightColor!,
          size: size,
          onTap: widget.onMore!,
          child: Icon(
            Icons.add_reaction_outlined,
            size: size * 0.8,
            color: iconColor,
          ),
        ),
      if (widget.onMoreActions != null)
        _BarButton(
          label: l10n.moreActions,
          selected: false,
          highlight: style.highlightColor!,
          size: size,
          onTap: widget.onMoreActions!,
          child: Icon(Icons.more_horiz, size: size * 0.8, color: iconColor),
        ),
    ];

    _ensureItemAnimations(items.length, theme.animationCurve!);

    return FocusTraversalGroup(
      child: Material(
        type: MaterialType.transparency,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: style.backgroundColor,
            shape: style.shape!,
            shadows: style.shadows,
          ),
          child: Padding(
            padding: style.padding!,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) SizedBox(width: style.itemSpacing),
                    _animated(i, items[i]),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.label,
    required this.selected,
    required this.highlight,
    required this.size,
    required this.onTap,
    required this.child,
  });

  final String label;
  final bool selected;
  final Color highlight;
  final double size;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final extent = size * 1.5;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: extent / 2,
        excludeFromSemantics: true,
        child: Container(
          width: extent,
          height: extent,
          alignment: Alignment.center,
          decoration: selected
              ? BoxDecoration(color: highlight, shape: BoxShape.circle)
              : null,
          child: child,
        ),
      ),
    );
  }
}
