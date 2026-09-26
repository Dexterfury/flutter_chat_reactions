import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// User-facing strings used by this package.
///
/// Provide translations by subclassing [DefaultChatReactionsLocalizations] and
/// registering a [LocalizationsDelegate], or pass an instance to
/// `ChatReactionsScope.localizations`.
abstract class ChatReactionsLocalizations {
  /// Const constructor for subclasses.
  const ChatReactionsLocalizations();

  /// Semantics action that opens the reactions menu on a message.
  String get openReactionsMenu;

  /// Label of the "+" button that opens a full emoji picker.
  String get moreReactions;

  /// Label of the "⋯" button that reveals message actions.
  String get moreActions;

  /// Label of the barrier that dismisses the menu.
  String get dismissMenu;

  /// Cancel button in the Cupertino action sheet.
  String get cancel;

  /// Title of the reaction details sheet.
  String get reactionsTitle;

  /// "All" tab of the reaction details sheet.
  String get allReactions;

  /// Accessible description of a reaction count.
  String reactionCount(int count);

  /// Accessible name for [emoji]. Returns [emoji] itself when unknown.
  String emojiLabel(String emoji);

  /// English delegate. Register it in `MaterialApp.localizationsDelegates`
  /// (optional; English is used as a fallback anyway).
  static const LocalizationsDelegate<ChatReactionsLocalizations> delegate =
      _DefaultDelegate();

  /// The localizations for [context], falling back to English.
  static ChatReactionsLocalizations of(BuildContext context) =>
      Localizations.of<ChatReactionsLocalizations>(
        context,
        ChatReactionsLocalizations,
      ) ??
      const DefaultChatReactionsLocalizations();
}

/// English strings. Extend this to translate a subset of strings.
class DefaultChatReactionsLocalizations extends ChatReactionsLocalizations {
  /// Creates the English localizations.
  const DefaultChatReactionsLocalizations();

  static const Map<String, String> _names = {
    '👍': 'thumbs up',
    '👎': 'thumbs down',
    '❤️': 'red heart',
    '😂': 'face with tears of joy',
    '😮': 'face with open mouth',
    '😢': 'crying face',
    '😠': 'angry face',
    '🙏': 'folded hands',
    '🔥': 'fire',
    '🎉': 'party popper',
    '👏': 'clapping hands',
    '😍': 'smiling face with heart-eyes',
  };

  @override
  String get openReactionsMenu => 'Open reactions menu';

  @override
  String get moreReactions => 'More reactions';

  @override
  String get moreActions => 'More actions';

  @override
  String get dismissMenu => 'Dismiss';

  @override
  String get cancel => 'Cancel';

  @override
  String get reactionsTitle => 'Reactions';

  @override
  String get allReactions => 'All';

  @override
  String reactionCount(int count) =>
      count == 1 ? '1 reaction' : '$count reactions';

  @override
  String emojiLabel(String emoji) => _names[emoji] ?? emoji;
}

class _DefaultDelegate
    extends LocalizationsDelegate<ChatReactionsLocalizations> {
  const _DefaultDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<ChatReactionsLocalizations> load(Locale locale) =>
      SynchronousFuture(const DefaultChatReactionsLocalizations());

  @override
  bool shouldReload(_DefaultDelegate old) => false;
}
