import 'package:flutter/material.dart';

/// The gallery's demos. [slug] is the `--dart-define=DEMO=` value.
enum DemoId {
  quickStart(
    'quickstart',
    'Quick start',
    'The smallest integration: default overlay + controller',
    Icons.bolt_outlined,
  ),
  messenger(
    'messenger',
    'Messenger',
    'iMessage / WhatsApp style focused overlay',
    Icons.chat_bubble_outline,
  ),
  team(
    'team',
    'Team channel',
    'Slack / Discord style compact bar, multiple reactions',
    Icons.forum_outlined,
  ),
  telegram(
    'telegram',
    'Telegram-like',
    'Bottom sheet with reaction details',
    Icons.send_outlined,
  ),
  custom(
    'custom',
    'Custom (headless)',
    'Radial picker built with CustomPresenter',
    Icons.blur_circular,
  ),
  theming(
    'theming',
    'Theming playground',
    'Light/dark, Material/Cupertino, colour, text scale, RTL',
    Icons.palette_outlined,
  );

  const DemoId(this.slug, this.title, this.subtitle, this.icon);

  /// Stable id for `--dart-define=DEMO=<slug>`.
  final String slug;

  /// Screen title (also the AppBar title of the demo).
  final String title;

  /// One-line description for the gallery list.
  final String subtitle;

  /// Gallery list icon.
  final IconData icon;

  /// The demo with [slug], or null.
  static DemoId? fromSlug(String? slug) {
    for (final id in values) {
      if (id.slug == slug) return id;
    }
    return null;
  }

  /// The demo named by `--dart-define=DEMO=...`, or null.
  static DemoId? fromEnvironment() =>
      fromSlug(const String.fromEnvironment('DEMO'));
}

/// Theme mode from `--dart-define=THEME=light|dark` (system otherwise).
ThemeMode themeModeFromEnvironment() =>
    switch (const String.fromEnvironment('THEME')) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
