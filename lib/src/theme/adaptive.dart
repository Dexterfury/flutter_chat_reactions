import 'package:flutter/services.dart';

/// Which visual language the package uses.
enum ReactionsVisualStyle {
  /// Cupertino on iOS and macOS, Material 3 elsewhere.
  adaptive,

  /// Material 3 everywhere.
  material,

  /// Cupertino everywhere.
  cupertino,
}

/// Haptic feedback on open and select.
enum ReactionHaptics {
  /// Selection click on iOS/macOS, light impact elsewhere.
  adaptive,

  /// No haptics.
  none,
}

/// Whether [platform] uses Apple conventions.
bool isCupertinoPlatform(TargetPlatform platform) =>
    platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;

/// Whether the Cupertino look applies for [style] on [platform].
bool resolveCupertino(ReactionsVisualStyle style, TargetPlatform platform) =>
    switch (style) {
      ReactionsVisualStyle.cupertino => true,
      ReactionsVisualStyle.material => false,
      ReactionsVisualStyle.adaptive => isCupertinoPlatform(platform),
    };

/// Whether [platform] is primarily touch-driven.
bool isTouchPlatform(TargetPlatform platform) =>
    platform == TargetPlatform.iOS ||
    platform == TargetPlatform.android ||
    platform == TargetPlatform.fuchsia;

/// Plays the haptic configured by [haptics] for [platform].
void performReactionHaptic(ReactionHaptics haptics, TargetPlatform platform) {
  if (haptics == ReactionHaptics.none) return;
  if (isCupertinoPlatform(platform)) {
    HapticFeedback.selectionClick();
  } else {
    HapticFeedback.lightImpact();
  }
}
