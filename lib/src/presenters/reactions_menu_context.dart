import 'package:flutter/widgets.dart';

import '../layout/reaction_alignment.dart';
import '../models/reaction_action.dart';
import '../models/reaction_summary.dart';
import '../trigger/reaction_trigger.dart';
import '../widgets/emoji.dart';

/// Everything a [ReactionsPresenter] needs to show a menu for one message.
///
/// `ReactableMessage` creates it; presenters read the data, call
/// [selectReaction], [selectAction], [openMore] or [dismiss], and register how
/// to close themselves with [setDismissHandler].
class ReactionsMenuContext {
  /// Creates a menu context. Presenters normally receive one; construct it
  /// directly only for tests or when calling a presenter yourself.
  ReactionsMenuContext({
    required this.anchorRect,
    required this.messageBuilder,
    required this.quickReactions,
    this.reactions = const [],
    this.actions = const [],
    this.alignment = ReactionAlignment.end,
    this.textDirection = TextDirection.ltr,
    this.trigger = ReactionTrigger.longPress,
    this.emojiBuilder,
    ValueChanged<String>? onReactionSelected,
    ValueChanged<ReactionAction<dynamic>>? onActionSelected,
    Future<void> Function()? onMoreTap,
  }) : _onReactionSelected = onReactionSelected,
       _onActionSelected = onActionSelected,
       _onMoreTap = onMoreTap;

  /// The message's bounds in the root overlay's coordinate space.
  final Rect anchorRect;

  /// Rebuilds the message for display inside the menu.
  final WidgetBuilder messageBuilder;

  /// Emojis offered in the reaction bar.
  final List<String> quickReactions;

  /// The message's current reactions.
  final List<ReactionSummary> reactions;

  /// Context-menu actions for this message.
  final List<ReactionAction<dynamic>> actions;

  /// Side the menu aligns to.
  final ReactionAlignment alignment;

  /// Text direction at the message.
  final TextDirection textDirection;

  /// What opened the menu.
  final ReactionTrigger trigger;

  /// Custom emoji rendering, if any.
  final EmojiBuilder? emojiBuilder;

  final ValueChanged<String>? _onReactionSelected;
  final ValueChanged<ReactionAction<dynamic>>? _onActionSelected;
  final Future<void> Function()? _onMoreTap;
  VoidCallback? _dismissHandler;
  bool _dismissed = false;

  /// Whether a "more reactions" callback exists (show a "+" button).
  bool get hasMore => _onMoreTap != null;

  /// Emojis the current user already reacted with.
  Set<String> get selectedReactions => {
    for (final r in reactions)
      if (r.reactedByMe) r.emoji,
  };

  /// Whether [dismiss] has been called.
  bool get isDismissed => _dismissed;

  /// Registers how the presenter closes itself. Presenters call this before
  /// showing.
  void setDismissHandler(VoidCallback handler) => _dismissHandler = handler;

  /// Closes the menu. Safe to call more than once.
  void dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    _dismissHandler?.call();
  }

  /// Closes the menu, then reports [emoji] as selected.
  void selectReaction(String emoji) {
    dismiss();
    _onReactionSelected?.call(emoji);
  }

  /// Closes the menu, then reports [action] as selected.
  void selectAction(ReactionAction<dynamic> action) {
    dismiss();
    _onActionSelected?.call(action);
  }

  /// Closes the menu, then runs the "more reactions" callback.
  Future<void> openMore() async {
    final callback = _onMoreTap;
    dismiss();
    if (callback != null) await callback();
  }
}
