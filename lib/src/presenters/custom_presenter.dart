import 'package:flutter/widgets.dart';

import '../l10n/chat_reactions_localizations.dart';
import '../theme/chat_reactions_theme.dart';
import 'menu_route.dart';
import 'reactions_menu_context.dart';
import 'reactions_presenter.dart';

/// Headless presenter: the package handles the route, barrier, dismissal
/// (tap outside, Escape, back, resize) and focus trapping; [builder] draws
/// everything else. Position your UI using `menu.anchorRect`, e.g. with
/// `AnchoredLayout`.
class CustomPresenter extends ReactionsPresenter {
  /// Creates a custom presenter.
  const CustomPresenter({
    required this.builder,
    this.barrierColor,
    this.blurSigma = 0,
    this.transitionDuration,
    this.dismissible = true,
  });

  /// Builds the menu. [animation] runs 0→1 on open and 1→0 on close.
  final Widget Function(
    BuildContext context,
    ReactionsMenuContext menu,
    Animation<double> animation,
  )
  builder;

  /// Tint behind the menu; null for none.
  final Color? barrierColor;

  /// Backdrop blur; 0 for none.
  final double blurSigma;

  /// Open/close duration; defaults to the theme's animation duration.
  final Duration? transitionDuration;

  /// Whether tapping outside the menu or pressing Escape closes it (the
  /// default). When false, close the menu yourself with
  /// `ReactionsMenuContext.dismiss` (or a selection). System back and a
  /// screen resize still close it.
  final bool dismissible;

  @override
  Future<void> show(BuildContext context, ReactionsMenuContext menu) {
    final theme = ChatReactionsTheme.of(context);
    final route = ReactionsMenuRoute(
      menu: menu,
      duration: transitionDuration ?? theme.animationDuration!,
      curve: theme.animationCurve!,
      barrierTint: barrierColor,
      blurSigma: blurSigma,
      barrierDismissible: dismissible,
      barrierLabel: ChatReactionsLocalizations.of(context).dismissMenu,
      builder: (context, animation) => builder(context, menu, animation),
    );
    return showReactionsMenuRoute(context, menu, route);
  }
}
