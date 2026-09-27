import 'package:example/app/demo_id.dart';
import 'package:example/app/demo_registry.dart';
import 'package:example/app/gallery_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  test('fromSlug round-trips and rejects unknown slugs', () {
    for (final id in DemoId.values) {
      expect(DemoId.fromSlug(id.slug), id);
    }
    expect(DemoId.fromSlug(''), isNull);
    expect(DemoId.fromSlug(null), isNull);
    expect(DemoId.fromSlug('nope'), isNull);
  });

  test('slugs are the spec values', () {
    expect(DemoId.values.map((d) => d.slug), [
      'quickstart',
      'messenger',
      'team',
      'telegram',
      'custom',
      'theming',
    ]);
  });

  test('without --dart-define, theme mode is system and no demo is forced', () {
    expect(themeModeFromEnvironment(), ThemeMode.system);
    expect(DemoId.fromEnvironment(), isNull);
  });

  testWidgets('home lists every registered demo and opens each one', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(const GalleryApp());
    for (final id in DemoId.values.where(demoBuilders.containsKey)) {
      await tester.tap(find.byKey(ValueKey('demo-${id.slug}')));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, id.title), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('initialDemo opens that demo directly', (tester) async {
    phone(tester);
    await tester.pumpWidget(const GalleryApp(initialDemo: DemoId.quickStart));
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(AppBar, DemoId.quickStart.title),
      findsOneWidget,
    );
  });

  testWidgets('themeMode dark is applied', (tester) async {
    phone(tester);
    await tester.pumpWidget(
      const GalleryApp(
        initialDemo: DemoId.quickStart,
        themeMode: ThemeMode.dark,
      ),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(Scaffold));
    expect(Theme.of(context).brightness, Brightness.dark);
  });
}
