import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

BorderSide? _lerpSide(BorderSide? a, BorderSide? b, double t) {
  if (a == null || b == null) return t < 0.5 ? a : b;
  return BorderSide.lerp(a, b, t);
}

/// Visual properties of `ReactionBar`.
@immutable
class ReactionBarStyle {
  /// Creates a bar style. Null fields fall back to the theme defaults.
  const ReactionBarStyle({
    this.backgroundColor,
    this.highlightColor,
    this.shape,
    this.shadows,
    this.padding,
    this.emojiSize,
    this.itemSpacing,
  });

  /// Bar fill color.
  final Color? backgroundColor;

  /// Circle behind emojis the current user already chose.
  final Color? highlightColor;

  /// Bar outline.
  final ShapeBorder? shape;

  /// Bar shadow.
  final List<BoxShadow>? shadows;

  /// Space between the bar edge and its items.
  final EdgeInsetsGeometry? padding;

  /// Emoji font size in logical pixels.
  final double? emojiSize;

  /// Horizontal gap between items.
  final double? itemSpacing;

  /// Returns a copy with the given fields replaced.
  ReactionBarStyle copyWith({
    Color? backgroundColor,
    Color? highlightColor,
    ShapeBorder? shape,
    List<BoxShadow>? shadows,
    EdgeInsetsGeometry? padding,
    double? emojiSize,
    double? itemSpacing,
  }) => ReactionBarStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    highlightColor: highlightColor ?? this.highlightColor,
    shape: shape ?? this.shape,
    shadows: shadows ?? this.shadows,
    padding: padding ?? this.padding,
    emojiSize: emojiSize ?? this.emojiSize,
    itemSpacing: itemSpacing ?? this.itemSpacing,
  );

  /// Returns this style with [other]'s non-null fields applied on top.
  ReactionBarStyle merge(ReactionBarStyle? other) {
    if (other == null) return this;
    return copyWith(
      backgroundColor: other.backgroundColor,
      highlightColor: other.highlightColor,
      shape: other.shape,
      shadows: other.shadows,
      padding: other.padding,
      emojiSize: other.emojiSize,
      itemSpacing: other.itemSpacing,
    );
  }

  /// Linearly interpolates between two bar styles.
  static ReactionBarStyle? lerp(
    ReactionBarStyle? a,
    ReactionBarStyle? b,
    double t,
  ) {
    if (identical(a, b)) return a;
    return ReactionBarStyle(
      backgroundColor: Color.lerp(a?.backgroundColor, b?.backgroundColor, t),
      highlightColor: Color.lerp(a?.highlightColor, b?.highlightColor, t),
      shape: ShapeBorder.lerp(a?.shape, b?.shape, t),
      shadows: BoxShadow.lerpList(a?.shadows, b?.shadows, t),
      padding: EdgeInsetsGeometry.lerp(a?.padding, b?.padding, t),
      emojiSize: lerpDouble(a?.emojiSize, b?.emojiSize, t),
      itemSpacing: lerpDouble(a?.itemSpacing, b?.itemSpacing, t),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ReactionBarStyle &&
      other.backgroundColor == backgroundColor &&
      other.highlightColor == highlightColor &&
      other.shape == shape &&
      listEquals(other.shadows, shadows) &&
      other.padding == padding &&
      other.emojiSize == emojiSize &&
      other.itemSpacing == itemSpacing;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    highlightColor,
    shape,
    shadows == null ? null : Object.hashAll(shadows!),
    padding,
    emojiSize,
    itemSpacing,
  );
}

/// Visual properties of `ReactionActionMenu`.
@immutable
class ReactionMenuStyle {
  /// Creates a menu style. Null fields fall back to the theme defaults.
  const ReactionMenuStyle({
    this.backgroundColor,
    this.shape,
    this.shadows,
    this.textStyle,
    this.iconColor,
    this.destructiveColor,
    this.dividerColor,
    this.minWidth,
    this.maxWidth,
    this.itemPadding,
  });

  /// Menu fill color.
  final Color? backgroundColor;

  /// Menu outline.
  final ShapeBorder? shape;

  /// Menu shadow.
  final List<BoxShadow>? shadows;

  /// Label text style.
  final TextStyle? textStyle;

  /// Icon color for non-destructive actions.
  final Color? iconColor;

  /// Label and icon color for destructive actions.
  final Color? destructiveColor;

  /// Divider color between items (transparent hides dividers).
  final Color? dividerColor;

  /// Minimum menu width.
  final double? minWidth;

  /// Maximum menu width.
  final double? maxWidth;

  /// Padding inside each item.
  final EdgeInsetsGeometry? itemPadding;

  /// Returns a copy with the given fields replaced.
  ReactionMenuStyle copyWith({
    Color? backgroundColor,
    ShapeBorder? shape,
    List<BoxShadow>? shadows,
    TextStyle? textStyle,
    Color? iconColor,
    Color? destructiveColor,
    Color? dividerColor,
    double? minWidth,
    double? maxWidth,
    EdgeInsetsGeometry? itemPadding,
  }) => ReactionMenuStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    shape: shape ?? this.shape,
    shadows: shadows ?? this.shadows,
    textStyle: textStyle ?? this.textStyle,
    iconColor: iconColor ?? this.iconColor,
    destructiveColor: destructiveColor ?? this.destructiveColor,
    dividerColor: dividerColor ?? this.dividerColor,
    minWidth: minWidth ?? this.minWidth,
    maxWidth: maxWidth ?? this.maxWidth,
    itemPadding: itemPadding ?? this.itemPadding,
  );

  /// Returns this style with [other]'s non-null fields applied on top.
  ReactionMenuStyle merge(ReactionMenuStyle? other) {
    if (other == null) return this;
    return copyWith(
      backgroundColor: other.backgroundColor,
      shape: other.shape,
      shadows: other.shadows,
      textStyle: textStyle?.merge(other.textStyle) ?? other.textStyle,
      iconColor: other.iconColor,
      destructiveColor: other.destructiveColor,
      dividerColor: other.dividerColor,
      minWidth: other.minWidth,
      maxWidth: other.maxWidth,
      itemPadding: other.itemPadding,
    );
  }

  /// Linearly interpolates between two menu styles.
  static ReactionMenuStyle? lerp(
    ReactionMenuStyle? a,
    ReactionMenuStyle? b,
    double t,
  ) {
    if (identical(a, b)) return a;
    return ReactionMenuStyle(
      backgroundColor: Color.lerp(a?.backgroundColor, b?.backgroundColor, t),
      shape: ShapeBorder.lerp(a?.shape, b?.shape, t),
      shadows: BoxShadow.lerpList(a?.shadows, b?.shadows, t),
      textStyle: TextStyle.lerp(a?.textStyle, b?.textStyle, t),
      iconColor: Color.lerp(a?.iconColor, b?.iconColor, t),
      destructiveColor: Color.lerp(a?.destructiveColor, b?.destructiveColor, t),
      dividerColor: Color.lerp(a?.dividerColor, b?.dividerColor, t),
      minWidth: lerpDouble(a?.minWidth, b?.minWidth, t),
      maxWidth: lerpDouble(a?.maxWidth, b?.maxWidth, t),
      itemPadding: EdgeInsetsGeometry.lerp(a?.itemPadding, b?.itemPadding, t),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ReactionMenuStyle &&
      other.backgroundColor == backgroundColor &&
      other.shape == shape &&
      listEquals(other.shadows, shadows) &&
      other.textStyle == textStyle &&
      other.iconColor == iconColor &&
      other.destructiveColor == destructiveColor &&
      other.dividerColor == dividerColor &&
      other.minWidth == minWidth &&
      other.maxWidth == maxWidth &&
      other.itemPadding == itemPadding;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    shape,
    shadows == null ? null : Object.hashAll(shadows!),
    textStyle,
    iconColor,
    destructiveColor,
    dividerColor,
    minWidth,
    maxWidth,
    itemPadding,
  );
}

/// Visual properties of the chips in `ReactionsSummaryView`.
@immutable
class ReactionChipStyle {
  /// Creates a chip style. Null fields fall back to the theme defaults.
  const ReactionChipStyle({
    this.backgroundColor,
    this.selectedBackgroundColor,
    this.border,
    this.selectedBorder,
    this.textStyle,
    this.selectedTextStyle,
    this.padding,
    this.borderRadius,
    this.emojiSize,
  });

  /// Chip fill color.
  final Color? backgroundColor;

  /// Chip fill color when the current user reacted.
  final Color? selectedBackgroundColor;

  /// Chip border.
  final BorderSide? border;

  /// Chip border when the current user reacted.
  final BorderSide? selectedBorder;

  /// Count text style.
  final TextStyle? textStyle;

  /// Count text style when the current user reacted.
  final TextStyle? selectedTextStyle;

  /// Padding inside a chip.
  final EdgeInsetsGeometry? padding;

  /// Chip corner radius.
  final BorderRadiusGeometry? borderRadius;

  /// Emoji size inside a chip.
  final double? emojiSize;

  /// Returns a copy with the given fields replaced.
  ReactionChipStyle copyWith({
    Color? backgroundColor,
    Color? selectedBackgroundColor,
    BorderSide? border,
    BorderSide? selectedBorder,
    TextStyle? textStyle,
    TextStyle? selectedTextStyle,
    EdgeInsetsGeometry? padding,
    BorderRadiusGeometry? borderRadius,
    double? emojiSize,
  }) => ReactionChipStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    selectedBackgroundColor:
        selectedBackgroundColor ?? this.selectedBackgroundColor,
    border: border ?? this.border,
    selectedBorder: selectedBorder ?? this.selectedBorder,
    textStyle: textStyle ?? this.textStyle,
    selectedTextStyle: selectedTextStyle ?? this.selectedTextStyle,
    padding: padding ?? this.padding,
    borderRadius: borderRadius ?? this.borderRadius,
    emojiSize: emojiSize ?? this.emojiSize,
  );

  /// Returns this style with [other]'s non-null fields applied on top.
  ReactionChipStyle merge(ReactionChipStyle? other) {
    if (other == null) return this;
    return copyWith(
      backgroundColor: other.backgroundColor,
      selectedBackgroundColor: other.selectedBackgroundColor,
      border: other.border,
      selectedBorder: other.selectedBorder,
      textStyle: textStyle?.merge(other.textStyle) ?? other.textStyle,
      selectedTextStyle:
          selectedTextStyle?.merge(other.selectedTextStyle) ??
          other.selectedTextStyle,
      padding: other.padding,
      borderRadius: other.borderRadius,
      emojiSize: other.emojiSize,
    );
  }

  /// Linearly interpolates between two chip styles.
  static ReactionChipStyle? lerp(
    ReactionChipStyle? a,
    ReactionChipStyle? b,
    double t,
  ) {
    if (identical(a, b)) return a;
    return ReactionChipStyle(
      backgroundColor: Color.lerp(a?.backgroundColor, b?.backgroundColor, t),
      selectedBackgroundColor: Color.lerp(
        a?.selectedBackgroundColor,
        b?.selectedBackgroundColor,
        t,
      ),
      border: _lerpSide(a?.border, b?.border, t),
      selectedBorder: _lerpSide(a?.selectedBorder, b?.selectedBorder, t),
      textStyle: TextStyle.lerp(a?.textStyle, b?.textStyle, t),
      selectedTextStyle: TextStyle.lerp(
        a?.selectedTextStyle,
        b?.selectedTextStyle,
        t,
      ),
      padding: EdgeInsetsGeometry.lerp(a?.padding, b?.padding, t),
      borderRadius: BorderRadiusGeometry.lerp(
        a?.borderRadius,
        b?.borderRadius,
        t,
      ),
      emojiSize: lerpDouble(a?.emojiSize, b?.emojiSize, t),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ReactionChipStyle &&
      other.backgroundColor == backgroundColor &&
      other.selectedBackgroundColor == selectedBackgroundColor &&
      other.border == border &&
      other.selectedBorder == selectedBorder &&
      other.textStyle == textStyle &&
      other.selectedTextStyle == selectedTextStyle &&
      other.padding == padding &&
      other.borderRadius == borderRadius &&
      other.emojiSize == emojiSize;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    selectedBackgroundColor,
    border,
    selectedBorder,
    textStyle,
    selectedTextStyle,
    padding,
    borderRadius,
    emojiSize,
  );
}

/// Visual properties of the focused overlay (backdrop and lifted message).
@immutable
class ReactionOverlayStyle {
  /// Creates an overlay style. Null fields fall back to the theme defaults.
  const ReactionOverlayStyle({
    this.barrierColor,
    this.blurSigma,
    this.messageShadows,
    this.lift,
  });

  /// Tint painted over the page behind the menu.
  final Color? barrierColor;

  /// Backdrop blur strength (0 disables blur).
  final double? blurSigma;

  /// Shadow painted around the lifted message copy.
  final List<BoxShadow>? messageShadows;

  /// Scale applied to the lifted message copy.
  final double? lift;

  /// Returns a copy with the given fields replaced.
  ReactionOverlayStyle copyWith({
    Color? barrierColor,
    double? blurSigma,
    List<BoxShadow>? messageShadows,
    double? lift,
  }) => ReactionOverlayStyle(
    barrierColor: barrierColor ?? this.barrierColor,
    blurSigma: blurSigma ?? this.blurSigma,
    messageShadows: messageShadows ?? this.messageShadows,
    lift: lift ?? this.lift,
  );

  /// Returns this style with [other]'s non-null fields applied on top.
  ReactionOverlayStyle merge(ReactionOverlayStyle? other) {
    if (other == null) return this;
    return copyWith(
      barrierColor: other.barrierColor,
      blurSigma: other.blurSigma,
      messageShadows: other.messageShadows,
      lift: other.lift,
    );
  }

  /// Linearly interpolates between two overlay styles.
  static ReactionOverlayStyle? lerp(
    ReactionOverlayStyle? a,
    ReactionOverlayStyle? b,
    double t,
  ) {
    if (identical(a, b)) return a;
    return ReactionOverlayStyle(
      barrierColor: Color.lerp(a?.barrierColor, b?.barrierColor, t),
      blurSigma: lerpDouble(a?.blurSigma, b?.blurSigma, t),
      messageShadows: BoxShadow.lerpList(
        a?.messageShadows,
        b?.messageShadows,
        t,
      ),
      lift: lerpDouble(a?.lift, b?.lift, t),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ReactionOverlayStyle &&
      other.barrierColor == barrierColor &&
      other.blurSigma == blurSigma &&
      listEquals(other.messageShadows, messageShadows) &&
      other.lift == lift;

  @override
  int get hashCode => Object.hash(
    barrierColor,
    blurSigma,
    messageShadows == null ? null : Object.hashAll(messageShadows!),
    lift,
  );
}
