import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../l10n/chat_reactions_localizations.dart';
import '../layout/reaction_alignment.dart';
import '../models/reaction_action.dart';
import '../models/reaction_summary.dart';
import '../presenters/compact_bar_presenter.dart';
import '../presenters/focused_overlay_presenter.dart';
import '../presenters/reactions_menu_context.dart';
import '../presenters/reactions_presenter.dart';
import '../theme/adaptive.dart';
import '../theme/chat_reactions_theme.dart';
import '../widgets/emoji.dart';
import 'chat_reactions_scope.dart';
import 'reaction_trigger.dart';

/// Makes [child] (a chat message) open a reactions menu on long press,
/// right-click, hover, keyboard or an accessibility action.
///
/// Reaction data is owned by your app: pass the message's [reactions] and
/// handle [onReactionSelected]. Unset options fall back to the nearest
/// [ChatReactionsScope], then to built-in defaults.
///
/// The menu rebuilds [child] inside the root overlay, so [child] must not
/// depend on inherited widgets that exist only below the chat screen, and
/// must not contain a `GlobalKey`.
class ReactableMessage extends StatefulWidget {
  /// Creates a reactable message.
  const ReactableMessage({
    super.key,
    required this.child,
    this.reactions = const [],
    this.quickReactions,
    this.actionsBuilder,
    this.onReactionSelected,
    this.onActionSelected,
    this.onMoreTap,
    this.presenter,
    this.triggers,
    this.alignment = ReactionAlignment.end,
    this.enabled = true,
    this.emojiBuilder,
    this.semanticLabel,
  });

  /// The message widget.
  final Widget child;

  /// The message's current reactions (used to highlight the user's choices).
  final List<ReactionSummary> reactions;

  /// Emojis in the reaction bar.
  final List<String>? quickReactions;

  /// Builds this message's context-menu actions.
  final ReactionActionsBuilder? actionsBuilder;

  /// Called with the emoji the user tapped.
  final ValueChanged<String>? onReactionSelected;

  /// Called with the action the user tapped.
  final ValueChanged<ReactionAction<dynamic>>? onActionSelected;

  /// Opens a full emoji picker; the "+" button is hidden when null.
  final MoreReactionsCallback? onMoreTap;

  /// How the menu is shown.
  final ReactionsPresenter? presenter;

  /// Which inputs open the menu.
  final Set<ReactionTrigger>? triggers;

  /// Side of the message the menu aligns to.
  final ReactionAlignment alignment;

  /// Whether the menu can be opened.
  final bool enabled;

  /// Custom emoji rendering.
  final EmojiBuilder? emojiBuilder;

  /// Accessible label for the message.
  final String? semanticLabel;

  @override
  State<ReactableMessage> createState() => _ReactableMessageState();
}

class _ReactableMessageState extends State<ReactableMessage> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'ReactableMessage');
  ReactionsMenuContext? _menu;
  Timer? _hoverTimer;

  // While a hover-opened menu is closing, the overlay that occluded this
  // message is removed and the framework re-hit-tests the pointer, which
  // fires a synthetic [MouseRegion.onEnter] even though the pointer never
  // left. Without this guard that synthetic enter would arm a new hover
  // timer and reopen the menu right after it was dismissed. It is cleared
  // by the very next enter (real or synthetic), so a genuine exit-then-enter
  // still reopens the menu normally.
  bool _suppressNextHoverEnter = false;

  ChatReactionsScope? get _scope => ChatReactionsScope.maybeOf(context);

  ReactionsPresenter get _presenter =>
      widget.presenter ?? _scope?.presenter ?? const FocusedOverlayPresenter();

  Set<ReactionTrigger> get _triggers =>
      widget.triggers ??
      _scope?.triggers ??
      defaultReactionTriggers(Theme.of(context).platform);

  Future<void> _open(ReactionTrigger trigger) async {
    if (_menu != null || !widget.enabled || !mounted) return;
    final scope = _scope;
    final platform = Theme.of(context).platform;
    final theme = ChatReactionsTheme.of(context);
    final box = context.findRenderObject()! as RenderBox;
    final overlayBox =
        Navigator.of(
              context,
              rootNavigator: true,
            ).overlay!.context.findRenderObject()!
            as RenderBox;
    final rect =
        box.localToGlobal(Offset.zero, ancestor: overlayBox) & box.size;
    final actionsBuilder = widget.actionsBuilder ?? scope?.actionsBuilder;
    final onMore = widget.onMoreTap ?? scope?.onMoreTap;

    performReactionHaptic(theme.haptics!, platform);
    final menu = ReactionsMenuContext(
      anchorRect: rect,
      messageBuilder: (_) => widget.child,
      quickReactions:
          widget.quickReactions ??
          scope?.quickReactions ??
          kDefaultQuickReactions,
      reactions: widget.reactions,
      actions: actionsBuilder?.call(context) ?? const [],
      alignment: widget.alignment,
      textDirection: Directionality.of(context),
      trigger: trigger,
      emojiBuilder: widget.emojiBuilder ?? scope?.emojiBuilder,
      onReactionSelected: (emoji) {
        performReactionHaptic(theme.haptics!, platform);
        widget.onReactionSelected?.call(emoji);
      },
      onActionSelected: widget.onActionSelected,
      onMoreTap: onMore == null ? null : () => onMore(context),
    );

    _menu = menu;
    try {
      await _presenter.show(context, menu);
    } finally {
      _menu = null;
      if (mounted) {
        if (trigger == ReactionTrigger.keyboard) {
          _focusNode.requestFocus();
        } else if (trigger == ReactionTrigger.hover) {
          _suppressNextHoverEnter = true;
        }
      }
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final shift = HardwareKeyboard.instance.isShiftPressed;
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.contextMenu ||
        (shift && key == LogicalKeyboardKey.f10)) {
      unawaited(_open(ReactionTrigger.keyboard));
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    _hoverTimer?.cancel();
    _menu?.dismiss();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final triggers = _triggers;
    final enabled = widget.enabled;
    final presenter = _presenter;
    Widget result = widget.child;

    if (enabled) {
      result = GestureDetector(
        onLongPress: triggers.contains(ReactionTrigger.longPress)
            ? () => _open(ReactionTrigger.longPress)
            : null,
        onDoubleTap: triggers.contains(ReactionTrigger.doubleTap)
            ? () => _open(ReactionTrigger.doubleTap)
            : null,
        onSecondaryTap: triggers.contains(ReactionTrigger.secondaryTap)
            ? () => _open(ReactionTrigger.secondaryTap)
            : null,
        child: result,
      );
      if (triggers.contains(ReactionTrigger.hover) &&
          presenter is CompactBarPresenter) {
        result = MouseRegion(
          onEnter: (_) {
            if (_suppressNextHoverEnter) {
              _suppressNextHoverEnter = false;
              return;
            }
            _hoverTimer?.cancel();
            _hoverTimer = Timer(
              presenter.hoverDelay,
              () => _open(ReactionTrigger.hover),
            );
          },
          onExit: (_) => _hoverTimer?.cancel(),
          child: result,
        );
      }
    }

    final keyboard = enabled && triggers.contains(ReactionTrigger.keyboard);
    result = Focus(
      focusNode: _focusNode,
      canRequestFocus: keyboard,
      skipTraversal: !keyboard,
      onKeyEvent: keyboard ? _onKey : null,
      child: result,
    );

    return Semantics(
      container: true,
      label: widget.semanticLabel,
      customSemanticsActions: enabled
          ? {
              CustomSemanticsAction(
                label: ChatReactionsLocalizations.of(context).openReactionsMenu,
              ): () =>
                  _open(ReactionTrigger.keyboard),
            }
          : null,
      child: result,
    );
  }
}
