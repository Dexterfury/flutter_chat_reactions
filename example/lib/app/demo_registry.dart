import 'package:example/app/demo_id.dart';
import 'package:example/demos/custom_demo.dart';
import 'package:example/demos/messenger_demo.dart';
import 'package:example/demos/quick_start_demo.dart';
import 'package:example/demos/team_demo.dart';
import 'package:example/demos/telegram_demo.dart';
import 'package:flutter/widgets.dart';

/// Builders for every implemented demo.
final Map<DemoId, Widget Function()> demoBuilders = {
  DemoId.quickStart: () => const QuickStartDemo(),
  DemoId.messenger: () => const MessengerDemo(),
  DemoId.team: () => const TeamDemo(),
  DemoId.telegram: () => const TelegramDemo(),
  DemoId.custom: () => const CustomDemo(),
};

/// Builds [id]'s screen. [id] must be in [demoBuilders].
Widget buildDemo(DemoId id) => demoBuilders[id]!();
