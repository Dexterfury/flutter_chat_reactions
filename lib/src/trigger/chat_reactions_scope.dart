import 'package:flutter/widgets.dart';

import '../l10n/chat_reactions_localizations.dart';
import '../models/reaction_action.dart';
import '../presenters/reactions_presenter.dart';
import '../widgets/emoji.dart';
import 'reaction_trigger.dart';

/// Builds the context-menu actions for one message.
typedef ReactionActionsBuilder =
    List<ReactionAction<dynamic>> Function(BuildContext context);

/// Opens a full emoji picker. [context] belongs to the message and is still
/// mounted when this is called.
typedef MoreReactionsCallback = Future<void> Function(BuildContext context);

/// Quick reactions used when neither the message nor a scope sets any.
const List<String> kDefaultQuickReactions = [
  '👍',
  '❤️',
  '😂',
  '😮',
  '😢',
  '🙏',
];

/// Provides defaults for every `ReactableMessage` below it. A message's own
/// arguments take precedence.
class ChatReactionsScope extends InheritedWidget {
  /// Creates a scope.
  const ChatReactionsScope({
    super.key,
    required super.child,
    this.presenter,
    this.quickReactions,
    this.triggers,
    this.actionsBuilder,
    this.onMoreTap,
    this.emojiBuilder,
    this.localizations,
  });

  /// Default presenter.
  final ReactionsPresenter? presenter;

  /// Default quick reactions.
  final List<String>? quickReactions;

  /// Default triggers.
  final Set<ReactionTrigger>? triggers;

  /// Default actions builder.
  final ReactionActionsBuilder? actionsBuilder;

  /// Default "more reactions" callback.
  final MoreReactionsCallback? onMoreTap;

  /// Default emoji rendering.
  final EmojiBuilder? emojiBuilder;

  /// Strings override, taking precedence over localization delegates.
  final ChatReactionsLocalizations? localizations;

  /// The nearest scope, or null.
  static ChatReactionsScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ChatReactionsScope>();

  @override
  bool updateShouldNotify(ChatReactionsScope oldWidget) =>
      presenter != oldWidget.presenter ||
      quickReactions != oldWidget.quickReactions ||
      triggers != oldWidget.triggers ||
      actionsBuilder != oldWidget.actionsBuilder ||
      onMoreTap != oldWidget.onMoreTap ||
      emojiBuilder != oldWidget.emojiBuilder ||
      localizations != oldWidget.localizations;
}
