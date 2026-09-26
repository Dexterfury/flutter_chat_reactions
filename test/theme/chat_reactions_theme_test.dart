import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ChatReactionsTheme> resolve(
  WidgetTester tester, {
  TargetPlatform platform = TargetPlatform.android,
  Brightness brightness = Brightness.light,
  ChatReactionsTheme? extension,
  bool disableAnimations = false,
}) async {
  late ChatReactionsTheme resolved;
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Theme(
        data: ThemeData(
          platform: platform,
          brightness: brightness,
          extensions: [?extension],
        ),
        child: Builder(
          builder: (context) {
            resolved = ChatReactionsTheme.of(context);
            return const SizedBox();
          },
        ),
      ),
    ),
  );
  return resolved;
}

void main() {
  testWidgets('adaptive: Cupertino on iOS and macOS, Material elsewhere', (
    tester,
  ) async {
    expect(
      (await resolve(tester, platform: TargetPlatform.iOS)).isCupertino,
      isTrue,
    );
    expect(
      (await resolve(tester, platform: TargetPlatform.macOS)).isCupertino,
      isTrue,
    );
    expect(
      (await resolve(tester, platform: TargetPlatform.android)).isCupertino,
      isFalse,
    );
    expect(
      (await resolve(tester, platform: TargetPlatform.windows)).style,
      ReactionsVisualStyle.material,
    );
  });

  testWidgets('style can be forced through the extension', (tester) async {
    final theme = await resolve(
      tester,
      platform: TargetPlatform.android,
      extension: const ChatReactionsTheme(
        style: ReactionsVisualStyle.cupertino,
      ),
    );
    expect(theme.isCupertino, isTrue);
  });

  testWidgets('Material defaults derive from the ColorScheme', (tester) async {
    final theme = await resolve(tester);
    final scheme = ThemeData().colorScheme;
    expect(theme.menuStyle.destructiveColor, scheme.error);
    expect(theme.chipStyle.selectedBackgroundColor, scheme.primaryContainer);
    expect(theme.animationDuration, const Duration(milliseconds: 220));
    expect(theme.animationCurve, Curves.easeOutCubic);
    expect(theme.haptics, ReactionHaptics.adaptive);
  });

  testWidgets('every style field is resolved (non-null)', (tester) async {
    for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
      for (final brightness in Brightness.values) {
        final t = await resolve(
          tester,
          platform: platform,
          brightness: brightness,
        );
        final bar = t.barStyle;
        final menu = t.menuStyle;
        final chip = t.chipStyle;
        final overlay = t.overlayStyle;
        expect(
          [
            bar.backgroundColor,
            bar.highlightColor,
            bar.shape,
            bar.shadows,
            bar.padding,
            bar.emojiSize,
            bar.itemSpacing,
            menu.backgroundColor,
            menu.shape,
            menu.shadows,
            menu.textStyle,
            menu.iconColor,
            menu.destructiveColor,
            menu.dividerColor,
            menu.minWidth,
            menu.maxWidth,
            menu.itemPadding,
            chip.backgroundColor,
            chip.selectedBackgroundColor,
            chip.border,
            chip.selectedBorder,
            chip.textStyle,
            chip.selectedTextStyle,
            chip.padding,
            chip.borderRadius,
            chip.emojiSize,
            overlay.barrierColor,
            overlay.blurSigma,
            overlay.messageShadows,
            overlay.lift,
          ],
          everyElement(isNotNull),
          reason: '$platform $brightness',
        );
      }
    }
  });

  testWidgets('extension values override defaults field by field', (
    tester,
  ) async {
    final theme = await resolve(
      tester,
      extension: const ChatReactionsTheme(
        barStyle: ReactionBarStyle(emojiSize: 40),
        haptics: ReactionHaptics.none,
      ),
    );
    expect(theme.barStyle.emojiSize, 40);
    expect(theme.barStyle.backgroundColor, isNotNull, reason: 'kept default');
    expect(theme.haptics, ReactionHaptics.none);
  });

  testWidgets('disableAnimations zeroes the duration', (tester) async {
    final theme = await resolve(tester, disableAnimations: true);
    expect(theme.animationDuration, Duration.zero);
  });

  test('lerp interpolates numeric fields', () {
    const a = ChatReactionsTheme(barStyle: ReactionBarStyle(emojiSize: 20));
    const b = ChatReactionsTheme(barStyle: ReactionBarStyle(emojiSize: 40));
    expect(a.lerp(b, 0.5).barStyle.emojiSize, 30);
    expect(a.lerp(null, 0.5), same(a));
  });

  test('light() and dark() factories', () {
    expect(
      ChatReactionsTheme.light(platform: TargetPlatform.android).isCupertino,
      isFalse,
    );
    final dark = ChatReactionsTheme.dark(platform: TargetPlatform.iOS);
    expect(dark.isCupertino, isTrue);
    expect(dark.barStyle.backgroundColor, const Color(0xFF2C2C2E));
  });
}
