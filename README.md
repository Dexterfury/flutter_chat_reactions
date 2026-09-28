# flutter_chat_reactions

[![pub package](https://img.shields.io/pub/v/flutter_chat_reactions.svg)](https://pub.dev/packages/flutter_chat_reactions)
[![CI](https://github.com/Dexterfury/flutter_chat_reactions/actions/workflows/ci.yml/badge.svg)](https://github.com/Dexterfury/flutter_chat_reactions/actions/workflows/ci.yml)
[![License](https://img.shields.io/github/license/Dexterfury/flutter_chat_reactions)](LICENSE)

Reactions and context menus for chat messages — iMessage, WhatsApp, Slack, Telegram
or fully custom — for any chat app and any backend. Zero dependencies.

| Messenger | Team channel | Telegram-like |
| :---: | :---: | :---: |
| ![Messenger](https://raw.githubusercontent.com/Dexterfury/flutter_chat_reactions/main/doc/gifs/messenger_light.gif) | ![Team channel](https://raw.githubusercontent.com/Dexterfury/flutter_chat_reactions/main/doc/gifs/team_light.gif) | ![Telegram-like](https://raw.githubusercontent.com/Dexterfury/flutter_chat_reactions/main/doc/gifs/telegram_light.gif) |
| **Custom (headless)** | **Theming** | **Dark mode** |
| ![Custom](https://raw.githubusercontent.com/Dexterfury/flutter_chat_reactions/main/doc/gifs/custom_light.gif) | ![Theming](https://raw.githubusercontent.com/Dexterfury/flutter_chat_reactions/main/doc/gifs/theming_light.gif) | ![Dark](https://raw.githubusercontent.com/Dexterfury/flutter_chat_reactions/main/doc/gifs/messenger_dark.gif) |

## Features

- **Works with any chat app.** Your app owns the data: pass each message's reactions in, get taps out.
  Firebase, Supabase, Stream, your own server, Riverpod, Bloc or `setState` — all fine.
- **Four presentations, all swappable:** focused overlay (default), compact bar, bottom sheet, or
  your own UI via `CustomPresenter`.
- **Adaptive look:** Cupertino on iOS/macOS, Material 3 elsewhere — or force either. Themed with a
  standard `ThemeExtension`, light and dark.
- **Every input:** long-press, double-tap, right-click, hover, keyboard, and screen-reader actions.
- **Accessible:** semantics labels, keyboard navigation, right-to-left layouts, reduced motion.
- **Optional `ReactionsController`** with one-per-user or many-per-user policies and optimistic
  updates that roll back if your backend call fails.
- **Zero dependencies.** Bring any emoji picker (an `emoji_picker_flutter` adapter is in the example).

## Install

```yaml
dependencies:
  flutter_chat_reactions: ^1.0.0 # x-release-please-version
```

Requires Flutter 3.32 or newer.

## Quick start

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

Long-press a message (right-click on desktop) to react. The runnable version is
[`example/lib/demos/quick_start_demo.dart`](example/lib/demos/quick_start_demo.dart).

## Your data, your backend

The widgets only display what you pass and report what the user tapped:

```dart
ReactableMessage(
  reactions: [
    for (final r in message.reactions) // aggregated by your server
      ReactionSummary(emoji: r.emoji, count: r.count, reactedByMe: r.mine),
  ],
  onReactionSelected: (emoji) => api.toggleReaction(message.id, emoji),
  child: MessageBubble(message),
)
```

Storing individual reactions instead? Aggregate them with
`reactions.summarize(currentUserId: me.id)`.

Want the state handled for you? `ReactionsController` keeps reactions in memory, applies changes
immediately, and rolls back if your `onChange` throws:

```dart
final controller = ReactionsController(
  currentUserId: me.id,
  policy: const ReactionPolicy.multiple(max: 3), // or ReactionPolicy.single()
  onChange: (change) => switch (change) {
    ReactionAdded(:final messageId, :final emoji) => api.add(messageId, emoji),
    ReactionRemoved(:final messageId, :final emoji) => api.remove(messageId, emoji),
    ReactionReplaced(:final messageId, :final emoji, :final previousEmoji) =>
      api.replace(messageId, previousEmoji, emoji),
  },
);

final binding = controller.bind(message.id);
ReactableMessage(
  reactions: binding.reactions,
  onReactionSelected: binding.onReactionSelected,
  child: MessageBubble(message),
);
```

## Presenters

| Presenter | Looks like | Notes |
| --- | --- | --- |
| `FocusedOverlayPresenter` (default) | iMessage / WhatsApp | Blurred backdrop, message lifts, bar above, actions below. Falls back to the bottom sheet at large text sizes. |
| `CompactBarPresenter` | Slack / Discord | Small floating bar; opens on hover on desktop; "⋯" reveals actions. |
| `BottomSheetPresenter` | Telegram / Material | Sheet with the reaction row, optional who-reacted list, full-width actions; Cupertino action sheet on iOS. |
| `CustomPresenter` | Anything | You draw it; the package handles the route, barrier, Escape/back and focus. |

Set one per message (`ReactableMessage.presenter`) or for a whole chat:

```dart
ChatReactionsScope(
  presenter: const CompactBarPresenter(),
  quickReactions: const ['👍', '🎉', '👀', '✅'],
  actionsBuilder: (context) => const [
    ReactionAction<void>(id: 'reply', label: 'Reply', icon: Icons.reply),
    ReactionAction<void>(id: 'delete', label: 'Delete', icon: Icons.delete, isDestructive: true),
  ],
  child: ChatList(),
)
```

Headless example — a bar anchored to the message, built from the public building blocks:

```dart
CustomPresenter(
  barrierColor: Colors.black54,
  builder: (context, menu, animation) => AnchoredLayout(
    anchorRect: menu.anchorRect,
    header: FadeTransition(
      opacity: animation,
      child: ReactionBar(
        reactions: menu.quickReactions,
        selected: menu.selectedReactions,
        onSelected: menu.selectReaction,
      ),
    ),
  ),
)
```

See the radial picker in [`example/lib/widgets/radial_reaction_menu.dart`](example/lib/widgets/radial_reaction_menu.dart)
for a complete custom UI.

## Showing reactions

```dart
ReactionsSummaryView(
  reactions: reactions,
  layout: ReactionSummaryLayout.chips, // .stacked (WhatsApp) or .compact
  maxVisible: 5,
  onReactionTap: (emoji) => toggle(emoji),
  onTap: () => showReactionDetails(context, reactions),
)

// Overlapping the bubble's bottom edge, WhatsApp style:
ReactionsSummaryView.overlay(reactions: reactions, child: MessageBubble(message))
```

## Triggers

| Platform | Default triggers |
| --- | --- |
| iOS, Android | long-press, keyboard |
| macOS, Windows, Linux, web on desktop | right-click, hover (compact bar only), keyboard |

Override per message or scope: `triggers: {ReactionTrigger.doubleTap, ReactionTrigger.longPress}`.
Every message also exposes an "Open reactions menu" accessibility action.

## Theming

```dart
MaterialApp(
  theme: ThemeData(
    colorSchemeSeed: Colors.indigo,
    extensions: const [
      ChatReactionsTheme(
        style: ReactionsVisualStyle.cupertino, // .material, or .adaptive (default)
        barStyle: ReactionBarStyle(emojiSize: 32),
        chipStyle: ReactionChipStyle(borderRadius: BorderRadius.all(Radius.circular(8))),
        haptics: ReactionHaptics.none,
      ),
    ],
  ),
)
```

Unset values come from your `ColorScheme` and `TextTheme`, so light and dark mode work out of the
box. A `Theme` placed around part of your UI also applies to the menus opened from there.

## Custom emoji and emoji pickers

Emoji are plain strings, so server-side emoji like `:party:` work — draw them with `emojiBuilder`
(on `ReactableMessage`, `ChatReactionsScope` and `ReactionsSummaryView`). The package ships no emoji
picker: show any picker from `onMoreTap` and pass the result to your selection handler. The example's
[`emoji_picker_sheet.dart`](example/lib/adapters/emoji_picker_sheet.dart) wires up
[`emoji_picker_flutter`](https://pub.dev/packages/emoji_picker_flutter) in about 20 lines.

## Localization

English strings are built in. Translate by overriding what you need:

```dart
class GermanReactions extends DefaultChatReactionsLocalizations {
  const GermanReactions();
  @override
  String get moreReactions => 'Weitere Reaktionen';
  @override
  String emojiLabel(String emoji) =>
      emoji == ':party:' ? 'Party' : super.emojiLabel(emoji);
}

ChatReactionsScope(localizations: const GermanReactions(), child: ChatList())
```

`emojiLabel` is also how custom `:shortcode:` emoji get readable screen-reader names.

## Example gallery

[`example/`](example) contains six demos — Quick start, Messenger, Team channel, Telegram-like,
Custom and Theming playground:

```bash
cd example
flutter run --dart-define=DEMO=team --dart-define=THEME=dark
```

## Upgrading from 0.2.x

1.0 is a new API. See [MIGRATION.md](MIGRATION.md) for a mapping of every 0.2.x class and option.

## Contributing

Contributions are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for the setup, the checks CI runs
and the pull request process. Every change is reviewed by the maintainer before it is merged.
Please report security issues privately as described in [SECURITY.md](SECURITY.md).

## Support

Liked some of my work? Buy me a coffee. Thanks for your support :heart:

<a href="https://www.buymeacoffee.com/raphaelsqu7" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-blue.png" alt="Buy Me A Coffee" height=64></a>

## License

See [LICENSE](LICENSE).
