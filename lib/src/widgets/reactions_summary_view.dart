import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/chat_reactions_localizations.dart';
import '../layout/reaction_alignment.dart';
import '../models/reaction_summary.dart';
import '../theme/chat_reactions_theme.dart';
import '../theme/reaction_styles.dart';
import 'emoji.dart';

/// How [ReactionsSummaryView] arranges reactions.
enum ReactionSummaryLayout {
  /// One pill per emoji with its count, wrapping (Slack, Discord).
  chips,

  /// Overlapping emoji circles plus the total count (WhatsApp).
  stacked,

  /// A single pill with up to three emojis and the total count.
  compact,
}

/// Displays a message's reactions.
class ReactionsSummaryView extends StatelessWidget {
  /// Creates a summary view.
  const ReactionsSummaryView({
    super.key,
    required this.reactions,
    this.layout = ReactionSummaryLayout.chips,
    this.maxVisible = 5,
    this.onReactionTap,
    this.onTap,
    this.onLongPress,
    this.chipBuilder,
    this.emojiBuilder,
    this.style,
  }) : assert(maxVisible >= 0, 'maxVisible must not be negative'),
       overlayChild = null,
       alignment = ReactionAlignment.end,
       overlap = 0;

  /// Places the summary over the bottom edge of [child] (e.g. a bubble),
  /// aligned to [alignment] and overlapping by [overlap] pixels.
  const ReactionsSummaryView.overlay({
    super.key,
    required Widget child,
    required this.reactions,
    this.layout = ReactionSummaryLayout.stacked,
    this.alignment = ReactionAlignment.end,
    this.overlap = 12,
    this.maxVisible = 5,
    this.onReactionTap,
    this.onTap,
    this.onLongPress,
    this.chipBuilder,
    this.emojiBuilder,
    this.style,
  }) : assert(maxVisible >= 0, 'maxVisible must not be negative'),
       overlayChild = child;

  /// Reactions to display.
  final List<ReactionSummary> reactions;

  /// Arrangement.
  final ReactionSummaryLayout layout;

  /// Maximum emojis shown before a "+N" indicator. Must not be negative;
  /// negative values are clamped to 0 at runtime outside of debug asserts.
  final int maxVisible;

  /// Called with the tapped chip's emoji (chips layout).
  final ValueChanged<String>? onReactionTap;

  /// Called when the whole view is tapped.
  final VoidCallback? onTap;

  /// Called with the long-pressed chip's emoji (chips layout).
  final ValueChanged<String>? onLongPress;

  /// Replaces the default chip (chips layout).
  final Widget Function(BuildContext context, ReactionSummary summary)?
  chipBuilder;

  /// Custom emoji rendering.
  final EmojiBuilder? emojiBuilder;

  /// Overrides for the themed chip style.
  final ReactionChipStyle? style;

  /// The bubble the summary overlaps ([ReactionsSummaryView.overlay] only).
  final Widget? overlayChild;

  /// Side of [overlayChild] the summary aligns to.
  final ReactionAlignment alignment;

  /// How far the summary overlaps [overlayChild]'s bottom edge.
  final double overlap;

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return overlayChild ?? const SizedBox.shrink();

    final theme = ChatReactionsTheme.of(context);
    final chip = theme.chipStyle.merge(style);
    final l10n = ChatReactionsLocalizations.of(context);
    final emoji = emojiBuilder ?? defaultEmojiBuilder;

    Widget content = switch (layout) {
      ReactionSummaryLayout.chips => _chips(context, chip, l10n, emoji, theme),
      ReactionSummaryLayout.stacked => _stacked(context, chip, l10n, emoji),
      ReactionSummaryLayout.compact => _compact(context, chip, l10n, emoji),
    };
    content = AnimatedSize(
      duration: theme.animationDuration!,
      curve: theme.animationCurve!,
      alignment: AlignmentDirectional.centerStart,
      child: content,
    );
    if (onTap != null) {
      content = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: content,
      );
    }

    final child = overlayChild;
    if (child == null) return content;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignment == ReactionAlignment.end
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        child,
        Transform.translate(
          offset: Offset(0, -overlap),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
            child: content,
          ),
        ),
      ],
    );
  }

  int get _total => reactions.fold(0, (sum, r) => sum + r.count);

  String _label(ChatReactionsLocalizations l10n) => reactions
      .map((r) => '${l10n.emojiLabel(r.emoji)}, ${l10n.reactionCount(r.count)}')
      .join('; ');

  Widget _chips(
    BuildContext context,
    ReactionChipStyle chip,
    ChatReactionsLocalizations l10n,
    EmojiBuilder emoji,
    ChatReactionsTheme theme,
  ) {
    final limit = math.max(0, maxVisible);
    final visible = reactions.take(limit).toList();
    final remaining = reactions.length - visible.length;
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final summary in visible)
          chipBuilder?.call(context, summary) ??
              _ReactionChip(
                summary: summary,
                style: chip,
                emojiBuilder: emoji,
                duration: theme.animationDuration!,
                label:
                    '${l10n.emojiLabel(summary.emoji)}, ${l10n.reactionCount(summary.count)}',
                onTap: onReactionTap == null
                    ? null
                    : () => onReactionTap!(summary.emoji),
                onLongPress: onLongPress == null
                    ? null
                    : () => onLongPress!(summary.emoji),
              ),
        if (remaining > 0)
          _Pill(
            style: chip,
            child: Text('+$remaining', style: chip.textStyle),
          ),
      ],
    );
  }

  Widget _stacked(
    BuildContext context,
    ReactionChipStyle chip,
    ChatReactionsLocalizations l10n,
    EmojiBuilder emoji,
  ) {
    final limit = math.max(0, maxVisible);
    final visible = reactions.take(limit).toList();
    final size = chip.emojiSize!;
    final circle = size + 6;
    final step = circle * 0.6;
    final mine = reactions.any((r) => r.reactedByMe);
    return Semantics(
      label: _label(l10n),
      selected: mine,
      excludeSemantics: true,
      child: _Pill(
        style: chip,
        selected: mine,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: circle + step * (visible.length - 1),
              height: circle,
              child: Stack(
                children: [
                  for (var i = 0; i < visible.length; i++)
                    PositionedDirectional(
                      start: step * i,
                      child: Container(
                        width: circle,
                        height: circle,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: chip.backgroundColor,
                          shape: BoxShape.circle,
                        ),
                        child: emoji(context, visible[i].emoji, size * 0.8),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '$_total',
              style: mine ? chip.selectedTextStyle : chip.textStyle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _compact(
    BuildContext context,
    ReactionChipStyle chip,
    ChatReactionsLocalizations l10n,
    EmojiBuilder emoji,
  ) {
    final mine = reactions.any((r) => r.reactedByMe);
    return Semantics(
      label: _label(l10n),
      selected: mine,
      excludeSemantics: true,
      child: _Pill(
        style: chip,
        selected: mine,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final r in reactions.take(3))
              emoji(context, r.emoji, chip.emojiSize!),
            const SizedBox(width: 4),
            Text(
              '$_total',
              style: mine ? chip.selectedTextStyle : chip.textStyle,
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.style,
    required this.child,
    this.selected = false,
  });

  final ReactionChipStyle style;
  final Widget child;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final side =
        (selected ? style.selectedBorder : style.border) ?? BorderSide.none;
    return Container(
      padding: style.padding,
      decoration: BoxDecoration(
        color: selected ? style.selectedBackgroundColor : style.backgroundColor,
        border: Border.fromBorderSide(side),
        borderRadius: style.borderRadius,
      ),
      child: child,
    );
  }
}

class _ReactionChip extends StatelessWidget {
  const _ReactionChip({
    required this.summary,
    required this.style,
    required this.emojiBuilder,
    required this.duration,
    required this.label,
    this.onTap,
    this.onLongPress,
  });

  final ReactionSummary summary;
  final ReactionChipStyle style;
  final EmojiBuilder emojiBuilder;
  final Duration duration;
  final String label;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final selected = summary.reactedByMe;
    final side =
        (selected ? style.selectedBorder : style.border) ?? BorderSide.none;
    final radius = style.borderRadius!.resolve(Directionality.of(context));
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: radius,
          excludeFromSemantics: true,
          child: AnimatedContainer(
            duration: duration,
            padding: style.padding,
            decoration: BoxDecoration(
              color: selected
                  ? style.selectedBackgroundColor
                  : style.backgroundColor,
              border: Border.fromBorderSide(side),
              borderRadius: radius,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                emojiBuilder(context, summary.emoji, style.emojiSize!),
                const SizedBox(width: 4),
                AnimatedSwitcher(
                  duration: duration,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  ),
                  child: Text(
                    '${summary.count}',
                    key: ValueKey(summary.count),
                    style: selected ? style.selectedTextStyle : style.textStyle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
