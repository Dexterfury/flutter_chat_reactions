import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'adaptive.dart';
import 'reaction_styles.dart';

/// Theme for every widget in this package, registered as a [ThemeExtension]:
///
/// ```dart
/// ThemeData(extensions: const [
///   ChatReactionsTheme(barStyle: ReactionBarStyle(emojiSize: 32)),
/// ])
/// ```
///
/// Unset fields fall back to adaptive defaults derived from the app's
/// [ColorScheme], [TextTheme] and platform. Read the resolved theme with
/// [ChatReactionsTheme.of].
class ChatReactionsTheme extends ThemeExtension<ChatReactionsTheme> {
  /// Creates a theme. Every field is optional.
  const ChatReactionsTheme({
    this.style,
    this.barStyle = const ReactionBarStyle(),
    this.menuStyle = const ReactionMenuStyle(),
    this.chipStyle = const ReactionChipStyle(),
    this.overlayStyle = const ReactionOverlayStyle(),
    this.animationDuration,
    this.animationCurve,
    this.haptics,
  });

  /// Fully populated defaults for [colorScheme], [textTheme] and [platform].
  factory ChatReactionsTheme.fromColorScheme(
    ColorScheme colorScheme,
    TextTheme textTheme,
    TargetPlatform platform, {
    ReactionsVisualStyle style = ReactionsVisualStyle.adaptive,
  }) => resolveCupertino(style, platform)
      ? _cupertino(colorScheme)
      : _material(colorScheme, textTheme);

  /// Defaults for a light Material [ThemeData].
  factory ChatReactionsTheme.light({
    TargetPlatform? platform,
    ReactionsVisualStyle style = ReactionsVisualStyle.adaptive,
  }) {
    final data = ThemeData(brightness: Brightness.light);
    return ChatReactionsTheme.fromColorScheme(
      data.colorScheme,
      data.textTheme,
      platform ?? defaultTargetPlatform,
      style: style,
    );
  }

  /// Defaults for a dark Material [ThemeData].
  factory ChatReactionsTheme.dark({
    TargetPlatform? platform,
    ReactionsVisualStyle style = ReactionsVisualStyle.adaptive,
  }) {
    final data = ThemeData(brightness: Brightness.dark);
    return ChatReactionsTheme.fromColorScheme(
      data.colorScheme,
      data.textTheme,
      platform ?? defaultTargetPlatform,
      style: style,
    );
  }

  /// Visual language. Resolved themes are always `material` or `cupertino`.
  final ReactionsVisualStyle? style;

  /// Style of `ReactionBar`.
  final ReactionBarStyle barStyle;

  /// Style of `ReactionActionMenu`.
  final ReactionMenuStyle menuStyle;

  /// Style of `ReactionsSummaryView` chips.
  final ReactionChipStyle chipStyle;

  /// Style of the focused overlay.
  final ReactionOverlayStyle overlayStyle;

  /// Duration of open/close and chip animations.
  final Duration? animationDuration;

  /// Curve of open/close and chip animations.
  final Curve? animationCurve;

  /// Haptic feedback mode.
  final ReactionHaptics? haptics;

  /// Whether the resolved style is Cupertino.
  ///
  /// Meaningful on resolved themes (from [ChatReactionsTheme.of] or the
  /// factories); false for an unresolved theme whose [style] is
  /// [ReactionsVisualStyle.adaptive] or null.
  bool get isCupertino => style == ReactionsVisualStyle.cupertino;

  /// The fully resolved theme for [context]: adaptive defaults, overridden by
  /// any [ChatReactionsTheme] in [ThemeData.extensions]. Animation duration is
  /// zero when the platform requests reduced motion.
  static ChatReactionsTheme of(BuildContext context) {
    final theme = Theme.of(context);
    final extension = theme.extension<ChatReactionsTheme>();
    final base = ChatReactionsTheme.fromColorScheme(
      theme.colorScheme,
      theme.textTheme,
      theme.platform,
      style: extension?.style ?? ReactionsVisualStyle.adaptive,
    );
    var resolved = extension == null
        ? base
        : base.merge(extension).copyWith(style: base.style);
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      resolved = resolved.copyWith(animationDuration: Duration.zero);
    }
    return resolved;
  }

  /// Returns this theme with [other]'s non-null fields applied on top.
  ChatReactionsTheme merge(ChatReactionsTheme? other) {
    if (other == null) return this;
    return ChatReactionsTheme(
      style: other.style ?? style,
      barStyle: barStyle.merge(other.barStyle),
      menuStyle: menuStyle.merge(other.menuStyle),
      chipStyle: chipStyle.merge(other.chipStyle),
      overlayStyle: overlayStyle.merge(other.overlayStyle),
      animationDuration: other.animationDuration ?? animationDuration,
      animationCurve: other.animationCurve ?? animationCurve,
      haptics: other.haptics ?? haptics,
    );
  }

  @override
  ChatReactionsTheme copyWith({
    ReactionsVisualStyle? style,
    ReactionBarStyle? barStyle,
    ReactionMenuStyle? menuStyle,
    ReactionChipStyle? chipStyle,
    ReactionOverlayStyle? overlayStyle,
    Duration? animationDuration,
    Curve? animationCurve,
    ReactionHaptics? haptics,
  }) => ChatReactionsTheme(
    style: style ?? this.style,
    barStyle: barStyle ?? this.barStyle,
    menuStyle: menuStyle ?? this.menuStyle,
    chipStyle: chipStyle ?? this.chipStyle,
    overlayStyle: overlayStyle ?? this.overlayStyle,
    animationDuration: animationDuration ?? this.animationDuration,
    animationCurve: animationCurve ?? this.animationCurve,
    haptics: haptics ?? this.haptics,
  );

  @override
  ChatReactionsTheme lerp(
    covariant ThemeExtension<ChatReactionsTheme>? other,
    double t,
  ) {
    if (other is! ChatReactionsTheme) return this;
    return ChatReactionsTheme(
      style: t < 0.5 ? style : other.style,
      barStyle: ReactionBarStyle.lerp(barStyle, other.barStyle, t)!,
      menuStyle: ReactionMenuStyle.lerp(menuStyle, other.menuStyle, t)!,
      chipStyle: ReactionChipStyle.lerp(chipStyle, other.chipStyle, t)!,
      overlayStyle: ReactionOverlayStyle.lerp(
        overlayStyle,
        other.overlayStyle,
        t,
      )!,
      animationDuration: t < 0.5 ? animationDuration : other.animationDuration,
      animationCurve: t < 0.5 ? animationCurve : other.animationCurve,
      haptics: t < 0.5 ? haptics : other.haptics,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatReactionsTheme &&
          other.runtimeType == runtimeType &&
          other.style == style &&
          other.barStyle == barStyle &&
          other.menuStyle == menuStyle &&
          other.chipStyle == chipStyle &&
          other.overlayStyle == overlayStyle &&
          other.animationDuration == animationDuration &&
          other.animationCurve == animationCurve &&
          other.haptics == haptics;

  @override
  int get hashCode => Object.hash(
    style,
    barStyle,
    menuStyle,
    chipStyle,
    overlayStyle,
    animationDuration,
    animationCurve,
    haptics,
  );

  static const Duration _duration = Duration(milliseconds: 220);

  static ChatReactionsTheme _material(ColorScheme cs, TextTheme tt) {
    return ChatReactionsTheme(
      style: ReactionsVisualStyle.material,
      barStyle: ReactionBarStyle(
        backgroundColor: cs.surfaceContainerHigh,
        highlightColor: cs.primaryContainer,
        shape: const StadiumBorder(),
        shadows: kElevationToShadow[3]!,
        padding: const EdgeInsets.all(6),
        emojiSize: 28,
        itemSpacing: 4,
      ),
      menuStyle: ReactionMenuStyle(
        backgroundColor: cs.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        shadows: kElevationToShadow[3]!,
        textStyle: (tt.bodyLarge ?? const TextStyle(fontSize: 16)).copyWith(
          color: cs.onSurface,
        ),
        iconColor: cs.onSurfaceVariant,
        destructiveColor: cs.error,
        dividerColor: Colors.transparent,
        minWidth: 200,
        maxWidth: 280,
        itemPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      chipStyle: ReactionChipStyle(
        backgroundColor: cs.surfaceContainerHighest,
        selectedBackgroundColor: cs.primaryContainer,
        border: BorderSide(color: cs.outlineVariant),
        selectedBorder: BorderSide(color: cs.primary),
        textStyle: (tt.labelMedium ?? const TextStyle(fontSize: 12)).copyWith(
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
        selectedTextStyle: (tt.labelMedium ?? const TextStyle(fontSize: 12))
            .copyWith(
              color: cs.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        borderRadius: BorderRadius.circular(999),
        emojiSize: 16,
      ),
      overlayStyle: ReactionOverlayStyle(
        barrierColor: cs.scrim.withValues(alpha: 0.32),
        blurSigma: 8,
        messageShadows: const [],
        lift: 1.03,
      ),
      animationDuration: _duration,
      animationCurve: Curves.easeOutCubic,
      haptics: ReactionHaptics.adaptive,
    );
  }

  static ChatReactionsTheme _cupertino(ColorScheme cs) {
    final dark = cs.brightness == Brightness.dark;
    final label = dark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    const shadow = [
      BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 4)),
    ];
    return ChatReactionsTheme(
      style: ReactionsVisualStyle.cupertino,
      barStyle: ReactionBarStyle(
        backgroundColor: dark
            ? const Color(0xFF2C2C2E)
            : const Color(0xFFFFFFFF),
        highlightColor: cs.primary.withValues(alpha: 0.18),
        shape: const StadiumBorder(),
        shadows: shadow,
        padding: const EdgeInsets.all(6),
        emojiSize: 30,
        itemSpacing: 2,
      ),
      menuStyle: ReactionMenuStyle(
        backgroundColor: dark
            ? const Color(0xFF2C2C2E)
            : const Color(0xFFF9F9F9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        shadows: shadow,
        textStyle: TextStyle(fontSize: 17, letterSpacing: -0.4, color: label),
        iconColor: label,
        destructiveColor: dark
            ? const Color(0xFFFF453A)
            : const Color(0xFFFF3B30),
        dividerColor: dark ? const Color(0x33FFFFFF) : const Color(0x1F000000),
        minWidth: 220,
        maxWidth: 280,
        itemPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      ),
      chipStyle: ReactionChipStyle(
        backgroundColor: dark
            ? const Color(0xFF3A3A3C)
            : const Color(0xFFE9E9EB),
        selectedBackgroundColor: cs.primary.withValues(alpha: 0.2),
        border: BorderSide.none,
        selectedBorder: BorderSide(color: cs.primary),
        textStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: dark ? const Color(0xFFEBEBF5) : const Color(0xFF3C3C43),
        ),
        selectedTextStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: cs.primary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        borderRadius: BorderRadius.circular(999),
        emojiSize: 16,
      ),
      overlayStyle: ReactionOverlayStyle(
        barrierColor: dark ? const Color(0x66000000) : const Color(0x33000000),
        blurSigma: 12,
        messageShadows: const [],
        lift: 1.04,
      ),
      animationDuration: _duration,
      animationCurve: Curves.easeOutCubic,
      haptics: ReactionHaptics.adaptive,
    );
  }
}
