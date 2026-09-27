# Migrating from 0.2.x to 1.0

1.0 is a redesign. The ideas are the same — wrap a message, show its reactions — but the data now
belongs to your app, presentation is pluggable, and styling moved to a `ThemeExtension`.

**Requirements:** Flutter 3.32+ / Dart 3.8+. The package no longer depends on `animate_do` or
`emoji_picker_flutter`.

## At a glance

| 0.2.x | 1.0 |
| --- | --- |
| `ChatMessageWrapper` | `ReactableMessage` |
| `StackedReactions` | `ReactionsSummaryView(layout: ReactionSummaryLayout.stacked)` |
| `ChatReactionsConfig` | `ChatReactionsTheme` (look), `ChatReactionsScope` (defaults), presenter options (behaviour) |
| `MenuItem` | `ReactionAction` (matched by `id`, not label) |
| `'➕'` in `availableReactions` + `emojiPickerBuilder` | `onMoreTap` — open any picker, return the emoji |
| `ReactionsDialogWidget`, `ContextMenuWidget`, `HeroDialogRoute` | presenters (`FocusedOverlayPresenter` …) and building blocks (`ReactionBar`, `ReactionActionMenu`, `AnchoredLayout`) |

## Before / after

```dart
// 0.2.x
ChatMessageWrapper(
  messageId: message.id,
  controller: controller,
  config: const ChatReactionsConfig(enableDoubleTap: true, maxReactionsToShow: 3),
  onReactionAdded: (emoji) => api.add(message.id, emoji),
  onReactionRemoved: (emoji) => api.remove(message.id, emoji),
  onMenuItemTapped: (item) => handle(item.label),
  child: MessageBubble(message),
)
```

```dart
// 1.0
ReactableMessage(
  reactions: controller.summariesFor(message.id),
  onReactionSelected: controller.bind(message.id).onReactionSelected,
  triggers: const {ReactionTrigger.longPress, ReactionTrigger.doubleTap},
  actionsBuilder: (context) => const [
    ReactionAction<void>(id: 'reply', label: 'Reply', icon: Icons.reply),
  ],
  onActionSelected: (action) => handle(action.id),
  child: MessageBubble(message),
)
```

Backend sync moves from per-widget callbacks to the controller:
`ReactionsController(currentUserId: …, onChange: (change) async { … })`, where `change` is a
`ReactionAdded`, `ReactionRemoved` or `ReactionReplaced`. If you already keep reactions in your own
state, skip the controller and pass `List<ReactionSummary>` directly.

## `ChatReactionsConfig` options

| 0.2.x option | 1.0 |
| --- | --- |
| `availableReactions` | `quickReactions` on `ReactableMessage` or `ChatReactionsScope` |
| `showAddReactionButton` / `emojiPickerBuilder` | `onMoreTap` (the "+" button shows only when it is set) |
| `menuItems` | `actionsBuilder` (per message — e.g. Delete only on your own messages) |
| `customMenuItemBuilder` | `ChatReactionsTheme.menuStyle`, or a `CustomPresenter` |
| `enableLongPress` / `enableDoubleTap` | `triggers: {ReactionTrigger.longPress, ReactionTrigger.doubleTap, …}` |
| `enableHapticFeedback` | `ChatReactionsTheme(haptics: ReactionHaptics.adaptive / .none)` |
| `animationDuration` / `dialogTransitionDuration` | `ChatReactionsTheme(animationDuration: …)` |
| `dialogBlurSigma` | `ReactionOverlayStyle(blurSigma: …)` or `FocusedOverlayPresenter(blurSigma: …)` |
| `dialogBackgroundColor` / `dialogBorderRadius` | `ReactionMenuStyle(backgroundColor: …, shape: …)` |
| `dialogPadding` | removed — menus are positioned within the safe area automatically |
| `dismissOnTapOutside` | always on for built-in presenters; `CustomPresenter(dismissible: false)` to disable |
| `showContextMenu: false` | `FocusedOverlayPresenter(showActions: false)` or no `actionsBuilder` |
| `maxReactionsToShow` | `ReactionsSummaryView(maxVisible: …)` |
| `reactionSize` | `ReactionChipStyle(emojiSize: …)` / `ReactionBarStyle(emojiSize: …)` |
| `stackedValue` | removed — the stacked layout computes its overlap |
| `customReactionBuilder` | `ReactionsSummaryView(chipBuilder: …)` or `emojiBuilder` |

## `StackedReactions`

| 0.2.x | 1.0 `ReactionsSummaryView` |
| --- | --- |
| `messageId` + `controller` | `reactions: controller.summariesFor(messageId)` |
| `size` | `style: ReactionChipStyle(emojiSize: …)` |
| `maxReactionsToShow` | `maxVisible` |
| `onTap` | `onTap` (whole view) or `onReactionTap` (per chip) |
| `customReactionBuilder` | `chipBuilder` |
| `reactionBackgroundColor` | `style: ReactionChipStyle(backgroundColor: …)` |
| `direction` | follows the ambient `Directionality` |

## `ReactionsController`

| 0.2.x | 1.0 |
| --- | --- |
| `getReactions(id)` | `reactionsFor(id)` (unmodifiable) |
| `getReactionCounts(id)` | `summariesFor(id)` → `List<ReactionSummary>` |
| `hasUserReacted(id, emoji)` | `hasReacted(id, emoji)` |
| `addReaction` / `removeReaction` / `toggleReaction` | `add` / `remove` / `toggle` (return `Future`s) |
| one reaction per user (hard-coded) | `policy: ReactionPolicy.single()` (default) or `.multiple(max: …)` |
| `loadReactions(id, list)` | `setReactions(id, list)` |
| `clearReactions(id)` / `clearAllReactions()` | `clear(id)` / `clear()` |
| `getAllReactions()` | removed — keep your source of truth in your app |

## `Reaction`

`timestamp` is now the optional `createdAt`, and `Reaction.fromJson` still reads the old
`timestamp` key. Reactions gained an `extra` map for app data, and equality now compares all fields.

## Menu items

`MenuItem(label:, icon:, isDestructive:)` → `ReactionAction(id:, label:, icon:, isDestructive:, value:)`.
Match actions by `id` so translated labels don't break your handlers.
