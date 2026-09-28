import 'package:example/app/demo_id.dart';
import 'package:example/app/gallery_app.dart';
import 'package:flutter/material.dart';

/// Runs the showcase gallery. Open a demo directly with
/// `--dart-define=DEMO=<quickstart|messenger|team|telegram|custom|theming>`
/// and force a theme with `--dart-define=THEME=<light|dark>`.
void main() => runApp(
  GalleryApp(
    initialDemo: DemoId.fromEnvironment(),
    themeMode: themeModeFromEnvironment(),
  ),
);
