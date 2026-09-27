import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

const headerKey = Key('header');
const anchorKey = Key('anchor');
const footerKey = Key('footer');

Widget box(Key key, double w, double h) =>
    SizedBox(key: key, width: w, height: h);

Future<void> pumpLayout(
  WidgetTester tester, {
  required Rect anchorRect,
  bool withAnchor = true,
  double anchorHeight = 60,
  ReactionAlignment alignment = ReactionAlignment.end,
  TextDirection direction = TextDirection.ltr,
  Size screenSize = const Size(400, 800),
  Size headerSize = const Size(240, 48),
  Size footerSize = const Size(220, 150),
}) async {
  tester.view.physicalSize = screenSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: screenSize),
      child: Directionality(
        textDirection: direction,
        child: AnchoredLayout(
          anchorRect: anchorRect,
          alignment: alignment,
          header: box(headerKey, headerSize.width, headerSize.height),
          anchor: withAnchor
              ? box(anchorKey, anchorRect.width, anchorHeight)
              : null,
          footer: box(footerKey, footerSize.width, footerSize.height),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('places header above and footer below a mid-screen anchor', (
    tester,
  ) async {
    const anchor = Rect.fromLTWH(150, 300, 200, 60);
    await pumpLayout(tester, anchorRect: anchor);

    final header = tester.getRect(find.byKey(headerKey));
    final message = tester.getRect(find.byKey(anchorKey));
    final footer = tester.getRect(find.byKey(footerKey));

    expect(message.topLeft, anchor.topLeft);
    expect(header.bottom, anchor.top - 8);
    expect(footer.top, anchor.bottom + 8);
    expect(header.right, anchor.right, reason: 'end-aligned in LTR');
    expect(footer.right, anchor.right);
  });

  testWidgets('shifts down when the anchor is near the top', (tester) async {
    await pumpLayout(tester, anchorRect: const Rect.fromLTWH(150, 10, 200, 60));
    expect(tester.getRect(find.byKey(headerKey)).top, 12);
    expect(tester.getRect(find.byKey(anchorKey)).top, 12 + 48 + 8);
  });

  testWidgets('shifts up when the anchor is near the bottom', (tester) async {
    await pumpLayout(
      tester,
      anchorRect: const Rect.fromLTWH(150, 740, 200, 60),
    );
    expect(tester.getRect(find.byKey(footerKey)).bottom, 800 - 12);
  });

  testWidgets('limits and scrolls a very tall anchor', (tester) async {
    await pumpLayout(
      tester,
      anchorRect: const Rect.fromLTWH(150, 0, 200, 2000),
      anchorHeight: 2000,
    );
    final message = tester.getRect(find.byType(SingleChildScrollView));
    expect(message.height, 800 - 24 - 48 - 150 - 16);
  });

  testWidgets('start alignment uses the anchor start edge', (tester) async {
    const anchor = Rect.fromLTWH(20, 300, 200, 60);
    await pumpLayout(
      tester,
      anchorRect: anchor,
      alignment: ReactionAlignment.start,
    );
    expect(tester.getRect(find.byKey(headerKey)).left, 20);
  });

  testWidgets('end alignment mirrors in RTL', (tester) async {
    const anchor = Rect.fromLTWH(20, 300, 200, 60);
    await pumpLayout(tester, anchorRect: anchor, direction: TextDirection.rtl);
    expect(tester.getRect(find.byKey(headerKey)).left, 20);
  });

  testWidgets('clamps horizontally inside the margin', (tester) async {
    await pumpLayout(
      tester,
      anchorRect: const Rect.fromLTWH(0, 300, 100, 60),
      alignment: ReactionAlignment.end,
    );
    expect(tester.getRect(find.byKey(headerKey)).left, 12);
  });

  testWidgets(
    'without anchor: header flips below when there is no room above',
    (tester) async {
      const anchor = Rect.fromLTWH(150, 20, 200, 60);
      await pumpLayout(tester, anchorRect: anchor, withAnchor: false);
      expect(tester.getRect(find.byKey(headerKey)).top, anchor.bottom + 8);
      expect(find.byKey(anchorKey), findsNothing);
    },
  );

  testWidgets('without anchor: header above when there is room', (
    tester,
  ) async {
    const anchor = Rect.fromLTWH(150, 300, 200, 60);
    await pumpLayout(tester, anchorRect: anchor, withAnchor: false);
    expect(tester.getRect(find.byKey(headerKey)).bottom, anchor.top - 8);
  });

  testWidgets(
    'does not crash when the safe area is smaller than the margins (with anchor)',
    (tester) async {
      const anchor = Rect.fromLTWH(0, 300, 10, 60);
      await pumpLayout(
        tester,
        anchorRect: anchor,
        screenSize: const Size(10, 800),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'does not crash when the safe area is smaller than the margins (no anchor)',
    (tester) async {
      const anchor = Rect.fromLTWH(0, 300, 10, 60);
      await pumpLayout(
        tester,
        anchorRect: anchor,
        withAnchor: false,
        screenSize: const Size(10, 800),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'without anchor: header and footer do not collapse onto the same rect '
    'when space is tight',
    (tester) async {
      const anchor = Rect.fromLTWH(150, 40, 200, 10);
      await pumpLayout(
        tester,
        anchorRect: anchor,
        withAnchor: false,
        screenSize: const Size(400, 100),
        headerSize: const Size(200, 60),
        footerSize: const Size(200, 60),
      );
      final header = tester.getRect(find.byKey(headerKey));
      final footer = tester.getRect(find.byKey(footerKey));
      expect(header, isNot(equals(footer)));
    },
  );
}
