import 'package:flutter/material.dart';

void main() => runApp(const ExampleApp());

/// Temporary placeholder; replaced by the demo in Plan 2 Task 16.
class ExampleApp extends StatelessWidget {
  /// Creates the example app.
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(body: Center(child: Text('flutter_chat_reactions'))),
    );
  }
}
