import 'package:flutter/foundation.dart';

import '../theme/adaptive.dart';

/// Gestures and inputs that open the reactions menu.
enum ReactionTrigger {
  /// Long press (touch).
  longPress,

  /// Double tap.
  doubleTap,

  /// Right-click or two-finger trackpad click.
  secondaryTap,

  /// Mouse hover; only used with `CompactBarPresenter`.
  hover,

  /// Enter, Shift+F10 or the context-menu key while the message has focus.
  keyboard,
}

/// Default triggers for [platform]: long press on touch platforms, right-click
/// and hover on desktop. Keyboard is always enabled.
Set<ReactionTrigger> defaultReactionTriggers(TargetPlatform platform) =>
    isTouchPlatform(platform)
    ? const {ReactionTrigger.longPress, ReactionTrigger.keyboard}
    : const {
        ReactionTrigger.secondaryTap,
        ReactionTrigger.hover,
        ReactionTrigger.keyboard,
      };
