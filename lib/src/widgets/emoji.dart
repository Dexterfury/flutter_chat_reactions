import 'package:flutter/widgets.dart';

/// Builds the visual for an emoji string at [size] logical pixels. Use it to
/// render custom emoji such as `:party:` as images.
typedef EmojiBuilder =
    Widget Function(BuildContext context, String emoji, double size);

/// Renders [emoji] as text at [size], ignoring the system text scale (the
/// containers scale instead).
Widget defaultEmojiBuilder(BuildContext context, String emoji, double size) =>
    Text(
      emoji,
      textScaler: TextScaler.noScaling,
      style: TextStyle(fontSize: size, height: 1.15),
    );
