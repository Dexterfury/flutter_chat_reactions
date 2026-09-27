import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as picker;
import 'package:example/adapters/emoji_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Smoke test for the real emoji picker sheet (no injected fake).
void main() {
  testWidgets('opens themed for dark mode and returns the tapped emoji', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final theme = ThemeData(brightness: Brightness.dark);
    String? picked;
    var closed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  picked = await showEmojiPickerSheet(context);
                  closed = true;
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(picker.EmojiPicker), findsOneWidget);
    final config = tester
        .widget<picker.EmojiPicker>(find.byType(picker.EmojiPicker))
        .config;
    final scheme = theme.colorScheme;
    expect(config.bottomActionBarConfig.enabled, isFalse);
    expect(find.byType(picker.DefaultBottomActionBar), findsNothing);
    expect(config.categoryViewConfig.backgroundColor, scheme.surface);
    expect(config.categoryViewConfig.indicatorColor, scheme.primary);
    expect(config.categoryViewConfig.iconColorSelected, scheme.primary);
    expect(config.searchViewConfig.backgroundColor, scheme.surface);

    // Recents start empty: switch to the smileys tab, then tap an emoji.
    await tester.tap(find.byIcon(const picker.CategoryIcons().smileyIcon));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(picker.EmojiCell).first);
    await tester.pumpAndSettle();

    expect(closed, isTrue);
    expect(picked, isNotNull);
    expect(find.byType(picker.EmojiPicker), findsNothing);
  });
}
