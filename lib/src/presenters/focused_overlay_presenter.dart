import 'package:flutter/material.dart';

import '../l10n/chat_reactions_localizations.dart';
import '../layout/anchored_layout.dart';
import '../layout/reaction_alignment.dart';
import '../theme/chat_reactions_theme.dart';
import '../widgets/reaction_action_menu.dart';
import '../widgets/reaction_bar.dart';
import 'bottom_sheet_presenter.dart';
import 'menu_route.dart';
import 'reactions_menu_context.dart';
import 'reactions_presenter.dart';

/// The default presenter (iMessage/WhatsApp style): the page blurs and dims,
/// the message lifts in place, the reaction bar appears above it and the
/// action menu below, all kept inside the safe area.
///
/// Falls back to [fallback] when the text scale is at least
/// [fallbackTextScale] or the screen is shorter than [fallbackMinHeight].
class FocusedOverlayPresenter extends ReactionsPresenter {
  /// Creates a focused-overlay presenter.
  const FocusedOverlayPresenter({
    this.blurSigma,
    this.barrierColor,
    this.showMessage = true,
    this.showActions = true,
    this.lift,
    this.fallbackTextScale = 2.0,
    this.fallbackMinHeight = 400,
    this.fallback = const BottomSheetPresenter(),
  });

  /// Backdrop blur; defaults to the theme's overlay blur.
  final double? blurSigma;

  /// Backdrop tint; defaults to the theme's overlay barrier color.
  final Color? barrierColor;

  /// Whether to draw the lifted message copy.
  final bool showMessage;

  /// Whether to show the action menu.
  final bool showActions;

  /// Scale of the lifted message; defaults to the theme's overlay lift.
  final double? lift;

  /// Text scale at or above which [fallback] is used.
  final double fallbackTextScale;

  /// Screen height below which [fallback] is used.
  final double fallbackMinHeight;

  /// Presenter used when the overlay would not fit.
  final ReactionsPresenter fallback;

  @override
  Future<void> show(BuildContext context, ReactionsMenuContext menu) {
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    if (textScale >= fallbackTextScale ||
        MediaQuery.sizeOf(context).height < fallbackMinHeight) {
      return fallback.show(context, menu);
    }
    final theme = ChatReactionsTheme.of(context);
    final overlay = theme.overlayStyle;
    final route = ReactionsMenuRoute(
      menu: menu,
      duration: theme.animationDuration!,
      curve: theme.animationCurve!,
      barrierTint: barrierColor ?? overlay.barrierColor,
      blurSigma: blurSigma ?? overlay.blurSigma!,
      barrierLabel: ChatReactionsLocalizations.of(context).dismissMenu,
      builder: (context, animation) => _FocusedMenu(
        menu: menu,
        animation: animation,
        showMessage: showMessage,
        showActions: showActions,
        lift: lift ?? overlay.lift!,
        shadows: overlay.messageShadows!,
      ),
    );
    return showReactionsMenuRoute(context, menu, route);
  }
}

class _FocusedMenu extends StatelessWidget {
  const _FocusedMenu({
    required this.menu,
    required this.animation,
    required this.showMessage,
    required this.showActions,
    required this.lift,
    required this.shadows,
  });

  final ReactionsMenuContext menu;
  final Animation<double> animation;
  final bool showMessage;
  final bool showActions;
  final double lift;
  final List<BoxShadow> shadows;

  @override
  Widget build(BuildContext context) {
    final alignRight =
        (menu.alignment == ReactionAlignment.end) ==
        (menu.textDirection == TextDirection.ltr);
    final origin = alignRight ? Alignment.bottomRight : Alignment.bottomLeft;

    final bar = FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        alignment: origin,
        scale: Tween<double>(begin: 0.8, end: 1).animate(animation),
        child: ReactionBar(
          reactions: menu.quickReactions,
          selected: menu.selectedReactions,
          onSelected: menu.selectReaction,
          onMore: menu.hasMore ? menu.openMore : null,
          emojiBuilder: menu.emojiBuilder,
        ),
      ),
    );

    final message = showMessage
        ? GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: menu.dismiss,
            child: IgnorePointer(
              child: ScaleTransition(
                scale: Tween<double>(begin: 1, end: lift).animate(animation),
                child: DecoratedBox(
                  decoration: BoxDecoration(boxShadow: shadows),
                  child: menu.messageBuilder(context),
                ),
              ),
            ),
          )
        : null;

    final actions = showActions && menu.actions.isNotEmpty
        ? FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              alignment: alignRight ? Alignment.topRight : Alignment.topLeft,
              scale: Tween<double>(begin: 0.9, end: 1).animate(animation),
              child: ReactionActionMenu(
                actions: menu.actions,
                onSelected: menu.selectAction,
              ),
            ),
          )
        : null;

    return Directionality(
      textDirection: menu.textDirection,
      child: AnchoredLayout(
        anchorRect: menu.anchorRect,
        alignment: menu.alignment,
        header: bar,
        anchor: message,
        footer: actions,
      ),
    );
  }
}
