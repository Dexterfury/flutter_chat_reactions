import 'package:example/app/demo_id.dart';
import 'package:example/demos/messenger_demo.dart';
import 'package:example/demos/quick_start_demo.dart';
import 'package:flutter/widgets.dart';

/// Builders for every implemented demo.
final Map<DemoId, Widget Function()> demoBuilders = {
  DemoId.quickStart: () => const QuickStartDemo(),
  DemoId.messenger: () => const MessengerDemo(),
};

/// Builds [id]'s screen. [id] must be in [demoBuilders].
Widget buildDemo(DemoId id) => demoBuilders[id]!();
