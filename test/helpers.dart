import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';

/// Wraps [child] in a MaterialApp with the given platform, brightness,
/// direction and accessibility settings.
Widget harness(
  Widget child, {
  TargetPlatform platform = TargetPlatform.android,
  Brightness brightness = Brightness.light,
  TextDirection textDirection = TextDirection.ltr,
  ChatReactionsTheme? reactionsTheme,
  double textScale = 1,
  bool disableAnimations = false,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: brightness,
      platform: platform,
      extensions: [?reactionsTheme],
    ),
    builder: (context, app) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
        disableAnimations: disableAnimations,
      ),
      child: Directionality(textDirection: textDirection, child: app!),
    ),
    home: Scaffold(body: child),
  );
}
