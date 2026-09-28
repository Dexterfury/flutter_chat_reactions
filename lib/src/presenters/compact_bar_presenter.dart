import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/chat_reactions_localizations.dart';
import '../layout/anchored_layout.dart';
import '../theme/chat_reactions_theme.dart';
import '../trigger/reaction_trigger.dart';
import '../widgets/reaction_action_menu.dart';
import '../widgets/reaction_bar.dart';
import 'menu_route.dart';
import 'reactions_menu_context.dart';
import 'reactions_presenter.dart';

/// A small floating reaction bar attached to the message (Slack/Discord
/// style). No blur. On desktop it can open on hover and stays open while the
/// pointer is over the message or the bar.
class CompactBarPresenter extends ReactionsPresenter {
  /// Creates a compact-bar presenter.
  const CompactBarPresenter({
    this.hoverDelay = const Duration(milliseconds: 300),
    this.hoverExitDelay = const Duration(milliseconds: 200),
    this.actionsOverflow = true,
  });

  /// How long the pointer must rest on a message before the bar opens.
  final Duration hoverDelay;

  /// How long after the pointer leaves the message and bar before closing.
  final Duration hoverExitDelay;

  /// Whether to add a "⋯" button that reveals the message actions.
  final bool actionsOverflow;

  @override
  Future<void> show(BuildContext context, ReactionsMenuContext menu) {
    final theme = ChatReactionsTheme.of(context);
    final route = ReactionsMenuRoute(
      menu: menu,
      duration: theme.animationDuration!,
      curve: theme.animationCurve!,
      barrierLabel: ChatReactionsLocalizations.of(context).dismissMenu,
      builder: (context, animation) =>
          _CompactMenu(menu: menu, animation: animation, presenter: this),
    );
    return showReactionsMenuRoute(context, menu, route);
  }
}

class _CompactMenu extends StatefulWidget {
  const _CompactMenu({
    required this.menu,
    required this.animation,
    required this.presenter,
  });

  final ReactionsMenuContext menu;
  final Animation<double> animation;
  final CompactBarPresenter presenter;

  @override
  State<_CompactMenu> createState() => _CompactMenuState();
}

class _CompactMenuState extends State<_CompactMenu> {
  bool _overAnchor = true;
  bool _overBar = false;
  bool _showActions = false;
  Timer? _exitTimer;

  bool get _hoverMode => widget.menu.trigger == ReactionTrigger.hover;

  void _update() {
    _exitTimer?.cancel();
    if (!_hoverMode || _overAnchor || _overBar) return;
    _exitTimer = Timer(widget.presenter.hoverExitDelay, widget.menu.dismiss);
  }

  @override
  void dispose() {
    _exitTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final menu = widget.menu;
    final animation = widget.animation;
    final canShowActions =
        widget.presenter.actionsOverflow && menu.actions.isNotEmpty;

    final bar = MouseRegion(
      onEnter: (_) {
        _overBar = true;
        _update();
      },
      onExit: (_) {
        _overBar = false;
        _update();
      },
      child: FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1).animate(animation),
          child: ReactionBar(
            reactions: menu.quickReactions,
            selected: menu.selectedReactions,
            onSelected: menu.selectReaction,
            onMore: menu.hasMore ? menu.openMore : null,
            onMoreActions: canShowActions
                ? () => setState(() => _showActions = !_showActions)
                : null,
            emojiBuilder: menu.emojiBuilder,
          ),
        ),
      ),
    );

    return Directionality(
      textDirection: menu.textDirection,
      child: Stack(
        children: [
          Positioned.fromRect(
            rect: menu.anchorRect,
            child: MouseRegion(
              opaque: false,
              onEnter: (_) {
                _overAnchor = true;
                _update();
              },
              onExit: (_) {
                _overAnchor = false;
                _update();
              },
              child: const SizedBox.expand(),
            ),
          ),
          Positioned.fill(
            child: AnchoredLayout(
              anchorRect: menu.anchorRect,
              alignment: menu.alignment,
              header: bar,
              footer: _showActions
                  ? ReactionActionMenu(
                      actions: menu.actions,
                      onSelected: menu.selectAction,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
