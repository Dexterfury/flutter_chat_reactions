# flutter_chat_reactions — showcase gallery

## Quick start

The smallest useful integration: a `ReactionsController`, a `ReactableMessage`
around each bubble, and a `ReactionsSummaryView` below it.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';

void main() => runApp(const QuickStartApp());

class QuickStartApp extends StatefulWidget {
  const QuickStartApp({super.key});

  @override
  State<QuickStartApp> createState() => _QuickStartAppState();
}

class _QuickStartAppState extends State<QuickStartApp> {
  final _controller = ReactionsController(
    currentUserId: 'me',
    currentUserName: 'You',
  );
  final _messageIds = ['m1', 'm2'];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Quick start')),
        body: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final id in _messageIds)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ReactableMessage(
                      reactions: _controller.summariesFor(id),
                      onReactionSelected:
                          _controller.bind(id).onReactionSelected,
                      child: Text('Message $id'),
                    ),
                    ReactionsSummaryView(
                      reactions: _controller.summariesFor(id),
                      onReactionTap: _controller.bind(id).onReactionSelected,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
```

The runnable version of this snippet is `lib/demos/quick_start_demo.dart`.

## Gallery

Six demos of the same package, each a different chat style:

| Demo | Slug | Shows |
| --- | --- | --- |
| Quick start | `quickstart` | The smallest integration: `ReactionsController` + `ReactableMessage` + `ReactionsSummaryView` |
| Messenger | `messenger` | iMessage/WhatsApp focused overlay, stacked summary on the bubble, `emoji_picker_flutter` behind "+" |
| Team channel | `team` | Slack/Discord compact bar, chips, several reactions per user, custom `:shortcode:` emoji |
| Telegram-like | `telegram` | Bottom sheet with who-reacted details and a Pin action |
| Custom (headless) | `custom` | `CustomPresenter` drawing a radial picker |
| Theming playground | `theming` | Light/dark, Material/Cupertino, seed colour, text scale, right-to-left |

## Run

```bash
flutter run
```

Open one demo directly, optionally forcing the theme:

```bash
flutter run --dart-define=DEMO=team --dart-define=THEME=dark
```

## Demo scripts

Each demo has a scripted interaction in `integration_test/demo_script.dart`.

- `flutter test` runs every script in fake time (fast; used by CI).
- In real time on a device or simulator (used to record the README GIFs):

```bash
flutter test integration_test/demo_script_test.dart -d <device> --dart-define=DEMO=messenger --dart-define=THEME=light
```

## Emoji picker adapter

The package ships no emoji picker. `lib/adapters/emoji_picker_sheet.dart` shows the ~20-line adapter that plugs `emoji_picker_flutter` into `ReactableMessage.onMoreTap`.
