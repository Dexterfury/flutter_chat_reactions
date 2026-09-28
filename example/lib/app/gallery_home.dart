import 'package:example/app/demo_id.dart';
import 'package:example/app/demo_registry.dart';
import 'package:flutter/material.dart';

/// Lists every registered demo.
class GalleryHome extends StatelessWidget {
  /// Creates the home list.
  const GalleryHome({super.key});

  @override
  Widget build(BuildContext context) {
    final demos = DemoId.values.where(demoBuilders.containsKey).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('flutter_chat_reactions')),
      body: ListView(
        children: [
          for (final demo in demos)
            ListTile(
              key: ValueKey('demo-${demo.slug}'),
              leading: Icon(demo.icon),
              title: Text(demo.title),
              subtitle: Text(demo.subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute<void>(builder: (_) => buildDemo(demo))),
            ),
        ],
      ),
    );
  }
}
