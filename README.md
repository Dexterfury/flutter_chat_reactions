# flutter_chat_reactions

A fully customizable Flutter package for adding reactions and a context menu to your chat messages.

Need a simple and powerful way to add customizable message reactions to your Flutter chat app? Look no further than flutter_chat_reactions!

Liked some of my work? Buy me a coffee. Thanks for your support :heart:

<a href="https://www.buymeacoffee.com/raphaelsqu7" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-blue.png" alt="Buy Me A Coffee" height=64></a>

[![Demo 1](demo_light.gif)](demo_light.gif)
[![Demo 2](demo_dark.gif)](demo_dark.gif)

## Features

- **Easy Integration:** Simply wrap your message widget with `ChatMessageWrapper` to enable reactions.
- **Highly Customizable:** Use `ChatReactionsConfig` to customize everything from the available reactions to the appearance of the dialog.
- **Built-in Emoji Picker:** Comes with a default emoji picker that can be easily replaced with your own implementation.
- **State Management:** Includes a `ReactionsController` to manage the state of your reactions.
- **Optional Context Menu:** Show or hide the context menu based on your needs.

## Getting started

Add dependency to `pubspec.yaml`

```yaml
dependencies:
  flutter_chat_reactions: ^0.2.0
```

In your dart file, import the library:

```dart
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
```

## Usage

1.  Create a `ReactionsController` in your screen's state:

```dart
class _ChatScreenState extends State<ChatScreen> {
  final _controller = ReactionsController(currentUserId: '1');

  @override
  void initState() {
    super.initState();
    // Load initial reactions
    for (final message in Message.messages) {
      for (final reaction in message.reactions) {
        _controller.addReaction(message.id, reaction);
      }
    }
  }

  // ...
}
```

2.  Wrap your message widget with `ChatMessageWrapper`:

```dart
ChatMessageWrapper(
  messageId: message.id,
  controller: _controller,
  onReactionAdded: (reaction) {
    // Handle reaction added
  },
  onReactionRemoved: (reaction) {
    // Handle reaction removed
  },
  onMenuItemTapped: (item) {
    // Handle menu item tapped
  },
  child: MessageWidget(
    message: message,
    controller: _controller,
  ),
);
```

3.  (Optional) Customize the appearance and behavior using `ChatReactionsConfig`:

```dart
const config = ChatReactionsConfig(
  enableHapticFeedback: true,
  maxReactionsToShow: 3,
  showContextMenu: false,
  enableDoubleTap: true,
  reactionBackgroundColor: Colors.white,
);

ChatMessageWrapper(
  config: config,
  // ...
);
```

### `ChatMessageWrapper` Parameters:

| Name                  | Description                                               | Required | Default value |
| --------------------- | --------------------------------------------------------- | -------- | ------------- |
| `messageId`           | Unique identifier for the message.                        | Yes      | -             |
| `controller`          | The `ReactionsController` to manage reaction state.       | Yes      | -             |
| `child`               | The message widget to be wrapped.                         | Yes      | -             |
| `config`              | Configuration for the reactions dialog.                   | No       | `ChatReactionsConfig()` |
| `onReactionAdded`     | Callback for when a reaction is added.                    | No       | -             |
| `onReactionRemoved`   | Callback for when a reaction is removed.                  | No       | -             |
| `onMenuItemTapped`    | Callback for when a context menu item is tapped.          | No       | -             |
| `alignment`           | The alignment of the dialog.                              | No       | `Alignment.centerRight` |

### `ChatReactionsConfig` Parameters:

| Name                      | Description                                                              | Default value |
| ------------------------- | ------------------------------------------------------------------------ | ------------- |
| `availableReactions`      | The list of reactions to be displayed.                                   | `['👍', '❤️', '😂', '😮', '😢', '😠', '➕']` |
| `menuItems`               | The list of menu items to be displayed in the context menu.              | `[Reply, Copy, Delete]` |
| `showAddReactionButton`   | Whether to show the add reaction button.                                 | `true` |
| `enableHapticFeedback`    | Whether to enable haptic feedback on tap.                                | `true` |
| `enableLongPress`         | Whether to enable long press to show the dialog.                         | `true` |
| `enableDoubleTap`         | Whether to enable double tap to show the dialog.                         | `false` |
| `maxReactionsToShow`      | The maximum number of reactions to show in the stacked view.             | `5` |
| `reactionSize`            | The size of the reaction emoji in the stacked view.                      | `25.0` |
| `stackedValue`            | The overlap value for the stacked reactions.                             | `4.0` |
| `dialogPadding`           | The padding of the reactions dialog.                                     | `EdgeInsets.all(20.0)` |
| `dialogBorderRadius`      | The border radius of the reactions dialog.                               | `null` |
| `dialogBackgroundColor`   | The background color of the reactions dialog.                            | `null` |
| `reactionBackgroundColor` | The background color of the reaction buttons.                            | `null` |
| `dialogBlurSigma`         | The blur sigma for the background when the dialog is open.               | `5.0` |
| `dismissOnTapOutside`     | Whether to dismiss the dialog when tapping outside.                      | `true` |
| `showContextMenu`         | Whether to show the context menu.                                        | `true` |
| `emojiPickerBuilder`      | A builder for a custom emoji picker.                                     | A default implementation using `emoji_picker_flutter` |
| `customReactionBuilder`   | A builder for a custom reaction widget in the stacked view.              | `null` |
| `customMenuItemBuilder`   | A builder for a custom menu item widget.                                 | `null` |

## Contributions

All contributions are welcome!
