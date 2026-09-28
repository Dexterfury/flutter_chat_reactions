import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

class _Recording extends ReactionsPresenter {
  ReactionsMenuContext? last;
  @override
  Future<void> show(BuildContext context, ReactionsMenuContext menu) async =>
      last = menu;
}

void main() {
  testWidgets('scope supplies defaults; widget arguments win', (tester) async {
    final scoped = _Recording();
    await tester.pumpWidget(
      harness(
        ChatReactionsScope(
          presenter: scoped,
          quickReactions: const ['🔥'],
          actionsBuilder: (_) => const [
            ReactionAction<void>(id: 'pin', label: 'Pin'),
          ],
          child: const Column(
            children: [
              ReactableMessage(
                child: SizedBox(
                  key: Key('a'),
                  width: 50,
                  height: 50,
                  child: ColoredBox(color: Colors.green),
                ),
              ),
              ReactableMessage(
                quickReactions: ['✅'],
                child: SizedBox(
                  key: Key('b'),
                  width: 50,
                  height: 50,
                  child: ColoredBox(color: Colors.green),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.longPress(find.byKey(const Key('a')));
    expect(scoped.last!.quickReactions, ['🔥']);
    expect(scoped.last!.actions.single.id, 'pin');

    await tester.longPress(find.byKey(const Key('b')));
    expect(scoped.last!.quickReactions, ['✅']);
  });

  testWidgets('scope localizations override the delegate', (tester) async {
    late ChatReactionsLocalizations l10n;
    await tester.pumpWidget(
      harness(
        ChatReactionsScope(
          localizations: const _Custom(),
          child: Builder(
            builder: (context) {
              l10n = ChatReactionsLocalizations.of(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    expect(l10n.cancel, 'Abbrechen');
  });

  testWidgets('updateShouldNotify compares every field', (tester) async {
    const child = SizedBox();
    final quickReactions = ['🔥'];
    final a = ChatReactionsScope(quickReactions: quickReactions, child: child);
    // Reuses every field by reference, so no clause short-circuits true and
    // updateShouldNotify evaluates all the way through to the last field.
    final same = ChatReactionsScope(
      presenter: a.presenter,
      quickReactions: a.quickReactions,
      triggers: a.triggers,
      actionsBuilder: a.actionsBuilder,
      onMoreTap: a.onMoreTap,
      emojiBuilder: a.emojiBuilder,
      localizations: a.localizations,
      child: child,
    );
    const different = ChatReactionsScope(quickReactions: ['✅'], child: child);
    expect(a.updateShouldNotify(same), isFalse);
    expect(a.updateShouldNotify(different), isTrue);
  });
}

class _Custom extends DefaultChatReactionsLocalizations {
  const _Custom();
  @override
  String get cancel => 'Abbrechen';
}
