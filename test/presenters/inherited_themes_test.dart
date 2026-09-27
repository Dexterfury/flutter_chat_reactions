import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart' show PresenterLauncher;

const Color _red = Color(0xFFFF0000);

class _GermanStrings extends DefaultChatReactionsLocalizations {
  const _GermanStrings();

  @override
  String get moreReactions => 'Mehr Reaktionen';

  @override
  String get cancel => 'Abbrechen';
}

/// A launcher placed below MaterialApp inside a *local* Theme (bar colour
/// red) and a ChatReactionsScope with custom strings.
Widget _localHarness(
  ReactionsPresenter presenter,
  ReactionsMenuContext menu, {
  bool cupertino = false,
}) => MaterialApp(
  home: Scaffold(
    body: Builder(
      builder: (context) => Theme(
        data: Theme.of(context).copyWith(
          platform: cupertino ? TargetPlatform.iOS : TargetPlatform.android,
          extensions: [
            ChatReactionsTheme(
              style: cupertino
                  ? ReactionsVisualStyle.cupertino
                  : ReactionsVisualStyle.material,
              barStyle: const ReactionBarStyle(backgroundColor: _red),
            ),
          ],
        ),
        child: ChatReactionsScope(
          localizations: const _GermanStrings(),
          child: DefaultTextStyle.merge(
            style: const TextStyle(fontSize: 31),
            child: PresenterLauncher(presenter: presenter, menu: menu),
          ),
        ),
      ),
    ),
  ),
);

ReactionsMenuContext _menu() => ReactionsMenuContext(
  anchorRect: const Rect.fromLTWH(300, 250, 200, 60),
  messageBuilder: (_) => const Text('message-copy'),
  quickReactions: const ['👍', '❤️'],
  actions: const [ReactionAction<void>(id: 'reply', label: 'Reply')],
  onMoreTap: () async {},
);

Color? _barColor(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(
    find
        .descendant(
          of: find.byType(ReactionBar),
          matching: find.byType(DecoratedBox),
        )
        .first,
  );
  return (box.decoration as ShapeDecoration).color;
}

Future<void> _open(
  WidgetTester tester,
  ReactionsPresenter presenter, {
  bool cupertino = false,
}) async {
  await tester.pumpWidget(
    _localHarness(presenter, _menu(), cupertino: cupertino),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Focused: menu uses the local theme, scope strings and the '
      "message's DefaultTextStyle", (tester) async {
    await _open(tester, const FocusedOverlayPresenter());
    expect(_barColor(tester), _red);
    expect(find.bySemanticsLabel('Mehr Reaktionen'), findsOneWidget);
    final copy = tester.element(find.text('message-copy'));
    expect(DefaultTextStyle.of(copy).style.fontSize, 31);
  });

  testWidgets('Compact: menu uses the local theme and scope strings', (
    tester,
  ) async {
    await _open(tester, const CompactBarPresenter());
    expect(_barColor(tester), _red);
    expect(find.bySemanticsLabel('Mehr Reaktionen'), findsOneWidget);
  });

  testWidgets('BottomSheet (Material): uses the local theme and scope '
      'strings', (tester) async {
    await _open(tester, const BottomSheetPresenter());
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(_barColor(tester), _red);
    expect(find.bySemanticsLabel('Mehr Reaktionen'), findsOneWidget);
  });

  testWidgets('BottomSheet (Cupertino): uses the local theme and scope '
      'strings', (tester) async {
    await _open(tester, const BottomSheetPresenter(), cupertino: true);
    expect(find.byType(CupertinoActionSheet), findsOneWidget);
    expect(_barColor(tester), _red);
    expect(find.bySemanticsLabel('Mehr Reaktionen'), findsOneWidget);
    expect(find.text('Abbrechen'), findsOneWidget);
  });
}
