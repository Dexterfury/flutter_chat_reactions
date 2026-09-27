import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';

/// A headless-presenter UI: the message copy stays in place and the quick
/// reactions fan out on a ring around it.
class RadialReactionMenu extends StatelessWidget {
  /// Creates the radial menu for [menu], driven by [animation].
  const RadialReactionMenu({
    super.key,
    required this.menu,
    required this.animation,
    this.radius = 100,
  });

  /// The menu to present.
  final ReactionsMenuContext menu;

  /// 0→1 on open, 1→0 on close.
  final Animation<double> animation;

  /// Ring radius in logical pixels.
  final double radius;

  static const double _itemSize = 52;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final margin = radius + _itemSize / 2 + 8;
    final anchorCenter = menu.anchorRect.center;
    final center = Offset(
      anchorCenter.dx.clamp(margin, math.max(margin, size.width - margin)),
      anchorCenter.dy.clamp(
        padding.top + margin,
        math.max(padding.top + margin, size.height - padding.bottom - margin),
      ),
    );
    final emojis = menu.quickReactions;
    final selected = menu.selectedReactions;
    final emojiBuilder = menu.emojiBuilder ?? defaultEmojiBuilder;

    return Stack(
      children: [
        Positioned.fromRect(
          rect: menu.anchorRect,
          child: IgnorePointer(child: menu.messageBuilder(context)),
        ),
        for (var i = 0; i < emojis.length; i++)
          _RadialItem(
            key: ValueKey('radial-${emojis[i]}'),
            animation: animation,
            center: center,
            angle: -math.pi / 2 + 2 * math.pi * i / emojis.length,
            radius: radius,
            size: _itemSize,
            child: _RadialButton(
              emoji: emojis[i],
              selected: selected.contains(emojis[i]),
              emojiBuilder: emojiBuilder,
              onTap: () => menu.selectReaction(emojis[i]),
            ),
          ),
      ],
    );
  }
}

class _RadialItem extends AnimatedWidget {
  const _RadialItem({
    super.key,
    required Animation<double> animation,
    required this.center,
    required this.angle,
    required this.radius,
    required this.size,
    required this.child,
  }) : super(listenable: animation);

  final Offset center;
  final double angle;
  final double radius;
  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = (listenable as Animation<double>).value;
    final position =
        center + Offset(math.cos(angle), math.sin(angle)) * radius * t;
    return Positioned(
      left: position.dx - size / 2,
      top: position.dy - size / 2,
      width: size,
      height: size,
      child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
    );
  }
}

class _RadialButton extends StatelessWidget {
  const _RadialButton({
    required this.emoji,
    required this.selected,
    required this.emojiBuilder,
    required this.onTap,
  });

  final String emoji;
  final bool selected;
  final EmojiBuilder emojiBuilder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: ChatReactionsLocalizations.of(context).emojiLabel(emoji),
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        shape: const CircleBorder(),
        elevation: 4,
        color: selected ? scheme.primaryContainer : scheme.surface,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Center(child: emojiBuilder(context, emoji, 26)),
        ),
      ),
    );
  }
}
