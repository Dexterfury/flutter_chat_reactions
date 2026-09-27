import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../l10n/chat_reactions_localizations.dart';
import '../theme/chat_reactions_theme.dart';
import '../theme/reaction_styles.dart';
import '../widgets/reaction_bar.dart';
import '../widgets/reaction_details.dart';
import 'menu_route.dart';
import 'reactions_menu_context.dart';
import 'reactions_presenter.dart';

/// Shows reactions and actions in a modal bottom sheet (Material) or an
/// action sheet (Cupertino). The most robust choice for small screens and
/// large text; `FocusedOverlayPresenter` falls back to it automatically.
class BottomSheetPresenter extends ReactionsPresenter {
  /// Creates a bottom-sheet presenter.
  const BottomSheetPresenter({this.showReactionDetails = false});

  /// Whether to list who reacted with what below the reaction bar.
  final bool showReactionDetails;

  @override
  Future<void> show(BuildContext context, ReactionsMenuContext menu) async {
    final theme = ChatReactionsTheme.of(context);
    final navigator = Navigator.of(context, rootNavigator: true);
    Route<dynamic>? sheetRoute;
    var dismissRequested = false;
    menu.setDismissHandler(() {
      final route = sheetRoute;
      if (route != null) {
        closeRouteSafely(navigator, route);
      } else {
        dismissRequested = true;
      }
    });

    Widget capture(BuildContext sheetContext, Widget child) {
      final route = ModalRoute.of(sheetContext);
      sheetRoute = route;
      if (dismissRequested && route != null) {
        SchedulerBinding.instance.addPostFrameCallback(
          (_) => closeRouteSafely(navigator, route),
        );
      }
      return child;
    }

    if (theme.isCupertino) {
      await showCupertinoModalPopup<void>(
        context: context,
        useRootNavigator: true,
        builder: (sheetContext) =>
            capture(sheetContext, _cupertinoSheet(sheetContext, menu)),
      );
    } else {
      await showModalBottomSheet<void>(
        context: context,
        useRootNavigator: true,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (sheetContext) =>
            capture(sheetContext, _materialSheet(sheetContext, menu)),
      );
    }
  }

  Widget _bar(ReactionsMenuContext menu) => ReactionBar(
    reactions: menu.quickReactions,
    selected: menu.selectedReactions,
    onSelected: menu.selectReaction,
    onMore: menu.hasMore ? menu.openMore : null,
    emojiBuilder: menu.emojiBuilder,
    style: const ReactionBarStyle(shadows: []),
  );

  Widget _materialSheet(BuildContext context, ReactionsMenuContext menu) {
    final style = ChatReactionsTheme.of(context).menuStyle;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: _bar(menu)),
          if (showReactionDetails && menu.reactions.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ReactionDetailsList(reactions: menu.reactions),
            ),
          const SizedBox(height: 8),
          for (final action in menu.actions)
            ListTile(
              leading: action.icon == null ? null : Icon(action.icon),
              title: Text(action.label),
              iconColor: action.isDestructive ? style.destructiveColor : null,
              textColor: action.isDestructive ? style.destructiveColor : null,
              onTap: () => menu.selectAction(action),
            ),
        ],
      ),
    );
  }

  Widget _cupertinoSheet(BuildContext context, ReactionsMenuContext menu) {
    final l10n = ChatReactionsLocalizations.of(context);
    return CupertinoActionSheet(
      title: _bar(menu),
      // A tight SizedBox (not ConstrainedBox) is required here: the action
      // sheet's message slot measures its child's intrinsic height, which a
      // shrink-wrapping ListView cannot provide unless its own constraints
      // are already tight.
      message: showReactionDetails && menu.reactions.isNotEmpty
          ? Material(
              type: MaterialType.transparency,
              child: SizedBox(
                height: 240,
                child: ReactionDetailsList(reactions: menu.reactions),
              ),
            )
          : null,
      actions: [
        for (final action in menu.actions)
          CupertinoActionSheetAction(
            isDestructiveAction: action.isDestructive,
            onPressed: () => menu.selectAction(action),
            child: Text(action.label),
          ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: menu.dismiss,
        child: Text(l10n.cancel),
      ),
    );
  }
}
