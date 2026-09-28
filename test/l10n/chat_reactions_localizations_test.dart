import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

class _German extends DefaultChatReactionsLocalizations {
  const _German();
  @override
  String get moreReactions => 'Weitere Reaktionen';
}

class _GermanDelegate
    extends LocalizationsDelegate<ChatReactionsLocalizations> {
  const _GermanDelegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<ChatReactionsLocalizations> load(Locale locale) async =>
      const _German();
  @override
  bool shouldReload(_GermanDelegate old) => false;
}

void main() {
  const l10n = DefaultChatReactionsLocalizations();

  test('English defaults', () {
    expect(l10n.openReactionsMenu, 'Open reactions menu');
    expect(l10n.reactionCount(1), '1 reaction');
    expect(l10n.reactionCount(3), '3 reactions');
    expect(l10n.emojiLabel('👍'), 'thumbs up');
    expect(l10n.emojiLabel(':party:'), ':party:');
    expect(l10n.reactionsTitle, 'Reactions');
    expect(l10n.allReactions, 'All');
  });

  test('the package delegate supports every locale and never reloads', () {
    expect(
      ChatReactionsLocalizations.delegate.isSupported(const Locale('en')),
      isTrue,
    );
    expect(
      ChatReactionsLocalizations.delegate.isSupported(const Locale('fr')),
      isTrue,
    );
    expect(
      ChatReactionsLocalizations.delegate.shouldReload(
        ChatReactionsLocalizations.delegate,
      ),
      isFalse,
    );
  });

  testWidgets('falls back to English without a delegate', (tester) async {
    late ChatReactionsLocalizations resolved;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            resolved = ChatReactionsLocalizations.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(resolved, isA<DefaultChatReactionsLocalizations>());
  });

  testWidgets('uses a registered delegate', (tester) async {
    late ChatReactionsLocalizations resolved;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          _GermanDelegate(),
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) {
            resolved = ChatReactionsLocalizations.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pump();
    expect(resolved.moreReactions, 'Weitere Reaktionen');
  });

  test('the package delegate loads English', () async {
    final loaded = await ChatReactionsLocalizations.delegate.load(
      const Locale('en'),
    );
    expect(loaded.cancel, 'Cancel');
  });
}
