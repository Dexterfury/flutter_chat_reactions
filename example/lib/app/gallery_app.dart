import 'package:example/app/demo_id.dart';
import 'package:example/app/demo_registry.dart';
import 'package:example/app/gallery_home.dart';
import 'package:flutter/material.dart';

/// The app theme used across the gallery.
ThemeData buildTheme(Brightness brightness, {Color seed = Colors.indigo}) =>
    ThemeData(colorSchemeSeed: seed, brightness: brightness);

/// The showcase gallery. Opens [initialDemo] directly when given.
class GalleryApp extends StatelessWidget {
  /// Creates the gallery.
  const GalleryApp({
    super.key,
    this.initialDemo,
    this.themeMode = ThemeMode.system,
  });

  /// Demo to open instead of the home list.
  final DemoId? initialDemo;

  /// Light / dark / system.
  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    final demo = initialDemo;
    return MaterialApp(
      title: 'flutter_chat_reactions',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      home: demo != null && demoBuilders.containsKey(demo)
          ? buildDemo(demo)
          : const GalleryHome(),
    );
  }
}
