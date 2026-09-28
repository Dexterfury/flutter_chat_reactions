# Plan 3 of 4 — Example Showcase Gallery Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn `example/` into a showcase gallery of six demos: Quick start, Messenger, Team channel, Telegram-like, Custom (headless) and Theming playground. Every demo can be opened directly with `--dart-define`, and every demo has a scripted interaction that runs as a fast widget test in CI and as a real-time integration test, which Plan 4 records as a GIF.

**Architecture:** `example/lib/` is split into:
- `app/`: the gallery shell, demo ids and the builder registry;
- `data/`: sample users, messages and reactions;
- `widgets/`: the shared bubble, bubble row, chat model, message actions and the radial menu;
- `demos/`: one file per demo;
- `adapters/`: the `emoji_picker_flutter` sheet.

Each demo is registered in `demoBuilders`, and its interaction script is registered in `demoScripts` in `example/integration_test/demo_script.dart`. A script receives a `Pace` callback, so the same script runs in fake time (widget test) or real time (integration test).

**Tech Stack:** Flutter ≥ 3.32 / Dart ^3.8, the `flutter_chat_reactions` 1.0 API (path dependency), `emoji_picker_flutter` `>=4.4.0 <4.5.0` (example only), `integration_test` (SDK).

**Spec:** `docs/superpowers/specs/2026-09-26-v1-modernization-design.md` §12 (and §14.4, which consumes the demo scripts in Plan 4).

## Global Constraints

- Only `example/**`, `.github/workflows/ci.yml` and this plan's docs change. The package's `lib/` and `test/` stay unchanged unless a real package bug is found. In that case, fix it in a separate `fix:` commit with a regression test in the package's `test/`.
- The example depends on `emoji_picker_flutter: '>=4.4.0 <4.5.0'`. 4.5.x requires Flutter 3.41, and CI's minimum leg is Flutter 3.32. The package itself never depends on it.
- The demo ids and slugs are exactly `quickstart`, `messenger`, `team`, `telegram`, `custom` and `theming`. `--dart-define=DEMO=<slug>` opens a demo directly. `--dart-define=THEME=<light|dark>` forces the theme; any other value, or none, means system.
- Test keys are part of the contract with the demo scripts:
  - `ValueKey('msg-<id>')` on each message's visible body;
  - `ValueKey('reactable-<id>')` on each `ReactableMessage`;
  - `ValueKey('summary-<id>')` on each `ReactionsSummaryView`;
  - `ValueKey('demo-<slug>')` on each gallery tile;
  - `ValueKey('emoji-<shortcode>')` on each custom emoji widget;
  - `ValueKey('radial-<emoji>')` on each radial menu item;
  - `ValueKey('pinned-banner')`;
  - `ValueKey('control-brightness' | 'control-style' | 'control-text-scale' | 'control-rtl' | 'control-seed-<index>')`.
- Sample message texts must not contain any of the default quick-reaction emojis (`👍 ❤️ 😂 😮 😢 🙏`), so that emoji finders stay unambiguous.
- The example's lints are `flutter_lints` (example/analysis_options.yaml). `cd example && flutter analyze --fatal-infos` must be clean. Write `[?x]` rather than `[if (x != null) x]` (`use_null_aware_elements`).
- Every task runs `dart format .` at the repository root before committing. The repo must stay format-clean.
- Commits use Conventional Commits and end with `Co-Authored-By: <committing model> <noreply@anthropic.com>`. Stage explicit paths only.
- The local SDK is Flutter 3.47.x (upgraded 2026-09-27), and CI tests 3.32.x and stable. Only use APIs that exist on 3.32. If 3.47 deprecates or removes something the package or example already uses, fix it with an approach that works on both versions and record it in the report.
- Tests run with a phone-sized surface: `tester.view.physicalSize = const Size(1170, 2532); tester.view.devicePixelRatio = 3; addTearDown(tester.view.reset);`.

---

## File Map

```
example/lib/main.dart                         entry: GalleryApp(initialDemo: DEMO, themeMode: THEME)
example/lib/app/demo_id.dart                  DemoId enum (slug/title/subtitle/icon), fromSlug, fromEnvironment, themeModeFromEnvironment
example/lib/app/gallery_app.dart              GalleryApp (MaterialApp), buildTheme()
example/lib/app/gallery_home.dart             GalleryHome list of registered demos
example/lib/app/demo_registry.dart            demoBuilders map + buildDemo()
example/lib/data/sample_chat.dart             ChatUser, ChatMessage, kMe/kSam/kAlex/kPriya, sampleConversation(), sampleReactions()
example/lib/widgets/message_actions.dart      kReplyAction/kCopyAction/kPinAction/kDeleteAction, actionsFor()
example/lib/widgets/demo_chat_model.dart      DemoChatModel (messages + ReactionsController + action handling + pin)
example/lib/widgets/chat_bubble.dart          ChatBubble
example/lib/widgets/bubble_row.dart           BubbleRow (ReactableMessage + ChatBubble + summary chips)
example/lib/widgets/radial_reaction_menu.dart RadialReactionMenu (headless presenter UI)
example/lib/adapters/emoji_picker_sheet.dart  showEmojiPickerSheet()
example/lib/demos/quick_start_demo.dart       QuickStartDemo
example/lib/demos/messenger_demo.dart         MessengerDemo
example/lib/demos/team_demo.dart              TeamDemo, kTeamReactions, teamEmojiBuilder, teamReactions()
example/lib/demos/telegram_demo.dart          TelegramDemo
example/lib/demos/custom_demo.dart            CustomDemo
example/lib/demos/theming_demo.dart           ThemingDemo
example/integration_test/demo_script.dart     Pace, DemoScript, demoScripts, runDemoScript, finder helpers
example/integration_test/demo_script_test.dart  real-time runner (IntegrationTestWidgetsFlutterBinding)
example/test/*.dart                           widget tests
example/README.md                             how to run the gallery / scripts
.github/workflows/ci.yml                      + example-tests job
```

---

### Task 1: Shared chat fixtures (data, actions, model, bubble, row)

**Files:**
- Create: `example/lib/data/sample_chat.dart`, `example/lib/widgets/message_actions.dart`, `example/lib/widgets/demo_chat_model.dart`, `example/lib/widgets/chat_bubble.dart`, `example/lib/widgets/bubble_row.dart`
- Test: `example/test/demo_chat_model_test.dart`, `example/test/bubble_row_test.dart`

**Interfaces:**
- Consumes: `ReactionsController`, `ReactionPolicy`, `Reaction`, `ReactionSummary`, `ReactionAction`, `ReactableMessage`, `ReactionsSummaryView`, `ReactionSummaryLayout`, `ReactionAlignment` from `package:flutter_chat_reactions/flutter_chat_reactions.dart`.
- Produces:
  - `ChatUser{id, name, color}` and the constants `kMe`, `kSam`, `kAlex`, `kPriya`, `kUsers`.
  - `ChatMessage{id, authorId, text; author; isMine}`.
  - `List<ChatMessage> sampleConversation()` (ids `m1`–`m5`) and `Map<String, List<Reaction>> sampleReactions()`.
  - The constants `kReplyAction`, `kCopyAction`, `kPinAction`, `kDeleteAction`, and `List<ReactionAction<dynamic>> actionsFor(ChatMessage, {bool pin = false})`.
  - `DemoChatModel({ReactionPolicy policy = const ReactionPolicy.single(), Map<String, List<Reaction>>? reactions})`, a `ChangeNotifier` with:
    - fields: `controller`, `messages`;
    - getter: `pinned`;
    - methods: `reactionsFor(id)`, `onReactionSelected(id)`, `handleAction(BuildContext, ChatMessage, ReactionAction<dynamic>)`.
  - `ChatBubble({key, required message, showAuthor = false})`, whose visible container carries `ValueKey('msg-<id>')`.
  - `BubbleRow({key, required message, required chat, actionsFor, summaryLayout = ReactionSummaryLayout.chips, showAuthor = true})`.

- [ ] **Step 1: Write the failing tests**

`example/test/demo_chat_model_test.dart`:

```dart
import 'package:example/data/sample_chat.dart';
import 'package:example/widgets/demo_chat_model.dart';
import 'package:example/widgets/message_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sample data never uses default quick-reaction emojis in text', () {
    for (final message in sampleConversation()) {
      for (final emoji in kDefaultQuickReactions) {
        expect(message.text.contains(emoji), isFalse, reason: message.id);
      }
    }
  });

  test('seeds reactions and exposes summaries', () {
    final chat = DemoChatModel();
    addTearDown(chat.dispose);
    final m2 = chat.reactionsFor('m2');
    expect(m2.first.emoji, '👍');
    expect(m2.first.count, 2);
    expect(chat.reactionsFor('m3').single.reactedByMe, isTrue);
  });

  test('onReactionSelected toggles through the controller and notifies', () async {
    final chat = DemoChatModel();
    addTearDown(chat.dispose);
    var notified = 0;
    chat.addListener(() => notified++);
    chat.onReactionSelected('m1')('🙏');
    await Future<void>.delayed(Duration.zero);
    expect(chat.reactionsFor('m1').single.emoji, '🙏');
    expect(notified, greaterThan(0));
  });

  test('multiple policy keeps several reactions from the current user', () async {
    final chat = DemoChatModel(policy: const ReactionPolicy.multiple());
    addTearDown(chat.dispose);
    chat.onReactionSelected('m1')('👍');
    chat.onReactionSelected('m1')('🎉');
    await Future<void>.delayed(Duration.zero);
    expect(chat.reactionsFor('m1'), hasLength(2));
  });

  test('actionsFor offers delete only on own messages and pin on request', () {
    final mine = sampleConversation().firstWhere((m) => m.isMine);
    final theirs = sampleConversation().firstWhere((m) => !m.isMine);
    expect(actionsFor(mine), contains(kDeleteAction));
    expect(actionsFor(theirs), isNot(contains(kDeleteAction)));
    expect(actionsFor(theirs, pin: true), contains(kPinAction));
  });

  testWidgets('delete and pin actions update the model', (tester) async {
    final chat = DemoChatModel();
    addTearDown(chat.dispose);
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Builder(builder: (c) {
        context = c;
        return const SizedBox();
      })),
    ));
    final m5 = chat.messages.firstWhere((m) => m.id == 'm5');
    final m1 = chat.messages.firstWhere((m) => m.id == 'm1');

    chat.handleAction(context, m1, kPinAction);
    expect(chat.pinned?.id, 'm1');

    chat.handleAction(context, m5, kDeleteAction);
    await tester.pump();
    expect(chat.messages.any((m) => m.id == 'm5'), isFalse);
    expect(find.text('Message deleted'), findsOneWidget);

    chat.handleAction(context, m1, kDeleteAction);
    expect(chat.pinned, isNull, reason: 'deleting the pinned message unpins it');
  });
}
```

`example/test/bubble_row_test.dart`:

```dart
import 'package:example/data/sample_chat.dart';
import 'package:example/widgets/bubble_row.dart';
import 'package:example/widgets/demo_chat_model.dart';
import 'package:example/widgets/message_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DemoChatModel chat;

  setUp(() => chat = DemoChatModel());
  tearDown(() => chat.dispose());

  Future<void> pumpRows(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ListenableBuilder(
          listenable: chat,
          builder: (context, _) => ListView(children: [
            for (final m in chat.messages)
              BubbleRow(message: m, chat: chat, actionsFor: actionsFor),
          ]),
        ),
      ),
    ));
  }

  testWidgets('renders keyed bubbles and summaries', (tester) async {
    await pumpRows(tester);
    expect(find.byKey(const ValueKey('msg-m1')), findsOneWidget);
    expect(find.byKey(const ValueKey('reactable-m2')), findsOneWidget);
    expect(find.byKey(const ValueKey('summary-m2')), findsOneWidget);
    expect(find.byKey(const ValueKey('summary-m1')), findsNothing,
        reason: 'no summary without reactions');
  });

  testWidgets('long-press, react, and the chip appears', (tester) async {
    await pumpRows(tester);
    await tester.longPress(find.byKey(const ValueKey('msg-m1')));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
      of: find.byType(ReactionBar),
      matching: find.text('😮'),
    ));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('summary-m1')),
        matching: find.text('😮'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('tapping a chip toggles it', (tester) async {
    await pumpRows(tester);
    await tester.tap(find.descendant(
      of: find.byKey(const ValueKey('summary-m2')),
      matching: find.text('👍'),
    ));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('summary-m2')),
        matching: find.text('3'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('own messages align to the end', (tester) async {
    await pumpRows(tester);
    final mine = tester.getRect(find.byKey(const ValueKey('msg-m2')));
    final theirs = tester.getRect(find.byKey(const ValueKey('msg-m1')));
    expect(mine.right, greaterThan(theirs.right));
  });
}
```

- [ ] **Step 2: Run the tests to confirm they fail**

Run: `cd example && flutter test test/demo_chat_model_test.dart test/bubble_row_test.dart`
Expected: compilation errors, e.g. `Target of URI doesn't exist: 'package:example/data/sample_chat.dart'`.

- [ ] **Step 3: Implement `example/lib/data/sample_chat.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';

/// A chat participant in the demos.
@immutable
class ChatUser {
  /// Creates a user.
  const ChatUser({required this.id, required this.name, required this.color});

  /// Stable id, used as the reaction user id.
  final String id;

  /// Display name.
  final String name;

  /// Avatar / name colour.
  final Color color;
}

/// The current user.
const ChatUser kMe = ChatUser(id: 'me', name: 'You', color: Colors.indigo);

/// Other participants.
const ChatUser kSam = ChatUser(id: 'sam', name: 'Sam', color: Colors.teal);
const ChatUser kAlex =
    ChatUser(id: 'alex', name: 'Alex', color: Colors.deepOrange);
const ChatUser kPriya = ChatUser(id: 'priya', name: 'Priya', color: Colors.purple);

/// All users by id.
const Map<String, ChatUser> kUsers = {
  'me': kMe,
  'sam': kSam,
  'alex': kAlex,
  'priya': kPriya,
};

/// A chat message in the demos.
@immutable
class ChatMessage {
  /// Creates a message.
  const ChatMessage({
    required this.id,
    required this.authorId,
    required this.text,
  });

  /// Stable id; also the reactions key.
  final String id;

  /// Author's user id.
  final String authorId;

  /// Message text. Must not contain default quick-reaction emojis.
  final String text;

  /// The author.
  ChatUser get author => kUsers[authorId]!;

  /// Whether the current user wrote this message.
  bool get isMine => authorId == kMe.id;
}

/// The conversation every demo starts from (ids m1–m5).
List<ChatMessage> sampleConversation() => const [
  ChatMessage(
    id: 'm1',
    authorId: 'sam',
    text: 'Morning! Did the new build land?',
  ),
  ChatMessage(
    id: 'm2',
    authorId: 'me',
    text: 'Yes, reactions work everywhere now.',
  ),
  ChatMessage(
    id: 'm3',
    authorId: 'priya',
    text: 'Long-press any message to react.',
  ),
  ChatMessage(
    id: 'm4',
    authorId: 'alex',
    text: 'On desktop you can right-click or hover instead.',
  ),
  ChatMessage(id: 'm5', authorId: 'me', text: 'Shipping it after lunch.'),
];

/// Reactions every demo starts from, keyed by message id.
Map<String, List<Reaction>> sampleReactions() => const {
  'm2': [
    Reaction(emoji: '👍', userId: 'sam', userName: 'Sam'),
    Reaction(emoji: '👍', userId: 'alex', userName: 'Alex'),
    Reaction(emoji: '❤️', userId: 'priya', userName: 'Priya'),
  ],
  'm3': [Reaction(emoji: '❤️', userId: 'me', userName: 'You')],
  'm4': [Reaction(emoji: '😂', userId: 'sam', userName: 'Sam')],
};
```

- [ ] **Step 4: Implement `example/lib/widgets/message_actions.dart`**

```dart
import 'package:example/data/sample_chat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';

/// Reply to a message.
const ReactionAction<void> kReplyAction =
    ReactionAction<void>(id: 'reply', label: 'Reply', icon: Icons.reply);

/// Copy a message's text.
const ReactionAction<void> kCopyAction =
    ReactionAction<void>(id: 'copy', label: 'Copy', icon: Icons.copy_outlined);

/// Pin a message to the top of the chat.
const ReactionAction<void> kPinAction = ReactionAction<void>(
  id: 'pin',
  label: 'Pin',
  icon: Icons.push_pin_outlined,
);

/// Delete one of your own messages.
const ReactionAction<void> kDeleteAction = ReactionAction<void>(
  id: 'delete',
  label: 'Delete',
  icon: Icons.delete_outline,
  isDestructive: true,
);

/// Actions offered for [message]: delete only on your own messages.
List<ReactionAction<dynamic>> actionsFor(
  ChatMessage message, {
  bool pin = false,
}) => [
  kReplyAction,
  kCopyAction,
  if (pin) kPinAction,
  if (message.isMine) kDeleteAction,
];
```

- [ ] **Step 5: Implement `example/lib/widgets/demo_chat_model.dart`**

```dart
import 'dart:async';

import 'package:example/data/sample_chat.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';

/// Messages + reactions + action handling shared by the demos.
class DemoChatModel extends ChangeNotifier {
  /// Creates a model seeded with [sampleConversation] and [reactions]
  /// (defaults to [sampleReactions]).
  DemoChatModel({
    ReactionPolicy policy = const ReactionPolicy.single(),
    Map<String, List<Reaction>>? reactions,
  }) : controller = ReactionsController(
         currentUserId: kMe.id,
         currentUserName: kMe.name,
         policy: policy,
       ) {
    for (final entry in (reactions ?? sampleReactions()).entries) {
      controller.setReactions(entry.key, entry.value);
    }
    controller.addListener(notifyListeners);
  }

  /// The reactions store.
  final ReactionsController controller;

  /// Current messages (deletable).
  final List<ChatMessage> messages = List.of(sampleConversation());

  String? _pinnedId;

  /// The pinned message, if any.
  ChatMessage? get pinned {
    for (final m in messages) {
      if (m.id == _pinnedId) return m;
    }
    return null;
  }

  /// Summaries for message [id].
  List<ReactionSummary> reactionsFor(String id) => controller.summariesFor(id);

  /// Toggle callback for message [id].
  ValueChanged<String> onReactionSelected(String id) =>
      controller.bind(id).onReactionSelected;

  /// Runs [action] on [message]; feedback is shown via [context]'s
  /// ScaffoldMessenger.
  void handleAction(
    BuildContext context,
    ChatMessage message,
    ReactionAction<dynamic> action,
  ) {
    final messenger = ScaffoldMessenger.of(context);
    switch (action.id) {
      case 'delete':
        messages.removeWhere((m) => m.id == message.id);
        if (_pinnedId == message.id) _pinnedId = null;
        controller.clear(message.id);
        notifyListeners();
        messenger.showSnackBar(
          const SnackBar(content: Text('Message deleted')),
        );
      case 'pin':
        _pinnedId = message.id;
        notifyListeners();
      case 'copy':
        unawaited(
          Clipboard.setData(ClipboardData(text: message.text))
              .catchError((Object _) {}),
        );
        messenger.showSnackBar(
          const SnackBar(content: Text('Copied to clipboard')),
        );
      case 'reply':
        messenger.showSnackBar(
          SnackBar(content: Text('Replying to ${message.author.name}')),
        );
    }
  }

  @override
  void dispose() {
    controller.removeListener(notifyListeners);
    controller.dispose();
    super.dispose();
  }
}
```

- [ ] **Step 6: Implement `example/lib/widgets/chat_bubble.dart`**

```dart
import 'package:example/data/sample_chat.dart';
import 'package:flutter/material.dart';

/// A chat bubble. Its visible container carries `ValueKey('msg-<id>')`.
class ChatBubble extends StatelessWidget {
  /// Creates a bubble for [message].
  const ChatBubble({super.key, required this.message, this.showAuthor = false});

  /// The message to show.
  final ChatMessage message;

  /// Whether to show the author's name above other people's messages.
  final bool showAuthor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final mine = message.isMine;
    const big = Radius.circular(18);
    const small = Radius.circular(4);
    return Container(
      key: ValueKey('msg-${message.id}'),
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: mine ? scheme.primary : scheme.surfaceContainerHighest,
        borderRadius: BorderRadiusDirectional.only(
          topStart: big,
          topEnd: big,
          bottomStart: mine ? big : small,
          bottomEnd: mine ? small : big,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showAuthor && !mine)
            Text(
              message.author.name,
              style: text.labelMedium?.copyWith(
                color: message.author.color,
                fontWeight: FontWeight.w700,
              ),
            ),
          Text(
            message.text,
            style: text.bodyLarge?.copyWith(
              color: mine ? scheme.onPrimary : scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 7: Implement `example/lib/widgets/bubble_row.dart`**

```dart
import 'package:example/data/sample_chat.dart';
import 'package:example/widgets/chat_bubble.dart';
import 'package:example/widgets/demo_chat_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';

/// One message row: a [ReactableMessage] around a [ChatBubble], with a
/// [ReactionsSummaryView] below it when the message has reactions.
class BubbleRow extends StatelessWidget {
  /// Creates a row for [message] backed by [chat].
  const BubbleRow({
    super.key,
    required this.message,
    required this.chat,
    this.actionsFor,
    this.summaryLayout = ReactionSummaryLayout.chips,
    this.showAuthor = true,
  });

  /// The message.
  final ChatMessage message;

  /// The demo's chat model.
  final DemoChatModel chat;

  /// Context-menu actions for a message; null for none.
  final List<ReactionAction<dynamic>> Function(ChatMessage message)? actionsFor;

  /// How the summary under the bubble is laid out.
  final ReactionSummaryLayout summaryLayout;

  /// Whether other people's names appear in their bubbles.
  final bool showAuthor;

  @override
  Widget build(BuildContext context) {
    final id = message.id;
    final reactions = chat.reactionsFor(id);
    final select = chat.onReactionSelected(id);
    final mine = message.isMine;
    final actions = actionsFor;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Align(
        alignment: mine
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: mine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            ReactableMessage(
              key: ValueKey('reactable-$id'),
              alignment: mine ? ReactionAlignment.end : ReactionAlignment.start,
              reactions: reactions,
              onReactionSelected: select,
              actionsBuilder: actions == null ? null : (_) => actions(message),
              onActionSelected: (action) =>
                  chat.handleAction(context, message, action),
              child: ChatBubble(message: message, showAuthor: showAuthor),
            ),
            if (reactions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: ReactionsSummaryView(
                  key: ValueKey('summary-$id'),
                  reactions: reactions,
                  layout: summaryLayout,
                  onReactionTap: select,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 8: Run the tests**

Run: `cd example && flutter test test/demo_chat_model_test.dart test/bubble_row_test.dart && flutter analyze --fatal-infos`
Expected: all tests pass and `No issues found!`. The existing `example/test/example_test.dart` still passes; Task 2 replaces it.

- [ ] **Step 9: Commit**

```bash
dart format .
git add example/lib/data example/lib/widgets example/test/demo_chat_model_test.dart example/test/bubble_row_test.dart
git commit -m "feat(example): Add shared chat fixtures for the gallery demos

Co-Authored-By: <committing model> <noreply@anthropic.com>"
```

---

### Task 2: Gallery shell, Quick start demo, and the demo-script harness

**Files:**
- Create: `example/lib/app/demo_id.dart`, `example/lib/app/gallery_app.dart`, `example/lib/app/gallery_home.dart`, `example/lib/app/demo_registry.dart`, `example/lib/demos/quick_start_demo.dart`, `example/integration_test/demo_script.dart`, `example/test/gallery_test.dart`, `example/test/demo_script_test.dart`
- Modify: `example/lib/main.dart` (replace), `example/pubspec.yaml` (add `integration_test` dev dependency)
- Delete: `example/test/example_test.dart`

**Interfaces:**
- Consumes: Task 1 (`sampleConversation`, `sampleReactions`, `kMe`, `ChatBubble`).
- Produces:
  - `enum DemoId { quickStart, messenger, team, telegram, custom, theming }`, each with `slug`, `title`, `subtitle` and `icon`.
  - `DemoId.fromSlug(String?)` and `DemoId.fromEnvironment()`, both returning `DemoId?`.
  - `ThemeMode themeModeFromEnvironment()`.
  - `GalleryApp({key, DemoId? initialDemo, ThemeMode themeMode = ThemeMode.system})` and `ThemeData buildTheme(Brightness, {Color seed = Colors.indigo})`.
  - `GalleryHome`.
  - `final Map<DemoId, Widget Function()> demoBuilders` and `Widget buildDemo(DemoId)`. Later tasks add one entry each.
  - In `integration_test/demo_script.dart`:
    - `typedef Pace = Future<void> Function(Duration)` and `typedef DemoScript = Future<void> Function(WidgetTester, Pace)`;
    - `final Map<DemoId, DemoScript> demoScripts`, to which later tasks add one entry each;
    - `runDemoScript(tester, id, {required pace})`;
    - the helpers `beat`, `linger`, `messageFinder(id)`, `summaryFinder(id)`, `reactionInBar(emoji)`, `openMenu(tester, id, pace)`, `tapAndPace(tester, finder, pace)` and `expectInSummary(id, finder)`.
  - Every demo's `AppBar` title is exactly `DemoId.<x>.title`.

- [ ] **Step 1: Add the `integration_test` dev dependency**

In `example/pubspec.yaml`, under `dev_dependencies:`, add:

```yaml
  integration_test:
    sdk: flutter
```

Run: `cd example && flutter pub get`
Expected: `Got dependencies!`.

- [ ] **Step 2: Write the failing tests**

`example/test/gallery_test.dart`:

```dart
import 'package:example/app/demo_id.dart';
import 'package:example/app/demo_registry.dart';
import 'package:example/app/gallery_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  test('fromSlug round-trips and rejects unknown slugs', () {
    for (final id in DemoId.values) {
      expect(DemoId.fromSlug(id.slug), id);
    }
    expect(DemoId.fromSlug(''), isNull);
    expect(DemoId.fromSlug(null), isNull);
    expect(DemoId.fromSlug('nope'), isNull);
  });

  test('slugs are the spec values', () {
    expect(DemoId.values.map((d) => d.slug), [
      'quickstart',
      'messenger',
      'team',
      'telegram',
      'custom',
      'theming',
    ]);
  });

  test('without --dart-define, theme mode is system and no demo is forced', () {
    expect(themeModeFromEnvironment(), ThemeMode.system);
    expect(DemoId.fromEnvironment(), isNull);
  });

  testWidgets('home lists every registered demo and opens each one', (tester) async {
    phone(tester);
    await tester.pumpWidget(const GalleryApp());
    for (final id in DemoId.values.where(demoBuilders.containsKey)) {
      await tester.tap(find.byKey(ValueKey('demo-${id.slug}')));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, id.title), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('initialDemo opens that demo directly', (tester) async {
    phone(tester);
    await tester.pumpWidget(const GalleryApp(initialDemo: DemoId.quickStart));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, DemoId.quickStart.title), findsOneWidget);
  });

  testWidgets('themeMode dark is applied', (tester) async {
    phone(tester);
    await tester.pumpWidget(
      const GalleryApp(initialDemo: DemoId.quickStart, themeMode: ThemeMode.dark),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(Scaffold));
    expect(Theme.of(context).brightness, Brightness.dark);
  });
}
```

`example/test/demo_script_test.dart`:

```dart
import 'package:example/app/gallery_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/demo_script.dart';

/// Runs every registered demo script in fake time (fast) on flutter-tester.
void main() {
  for (final entry in demoScripts.entries) {
    testWidgets('demo script: ${entry.key.slug}', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        GalleryApp(initialDemo: entry.key, themeMode: ThemeMode.light),
      );
      await tester.pumpAndSettle();
      await runDemoScript(
        tester,
        entry.key,
        pace: (duration) async {
          await tester.pump(duration);
          await tester.pumpAndSettle();
        },
      );
    });
  }
}
```

- [ ] **Step 3: Run the tests to confirm they fail**

Run: `cd example && flutter test test/gallery_test.dart test/demo_script_test.dart`
Expected: compilation errors (missing `package:example/app/...` and `../integration_test/demo_script.dart`).

- [ ] **Step 4: Implement `example/lib/app/demo_id.dart`**

```dart
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
```

- [ ] **Step 5: Implement `example/lib/app/gallery_app.dart`, `gallery_home.dart` and `demo_registry.dart`**

`example/lib/app/gallery_app.dart`:

```dart
import 'package:example/app/demo_id.dart';
import 'package:example/app/demo_registry.dart';
import 'package:example/app/gallery_home.dart';
import 'package:flutter/material.dart';

/// The app theme used across the gallery.
ThemeData buildTheme(Brightness brightness, {Color seed = Colors.indigo}) =>
    ThemeData(colorSchemeSeed: seed, brightness: brightness);

/// The showcase gallery. Opens [initialDemo] directly when given.
class GalleryApp extends StatelessWidget {
  /// Creates the gallery.
  const GalleryApp({
    super.key,
    this.initialDemo,
    this.themeMode = ThemeMode.system,
  });

  /// Demo to open instead of the home list.
  final DemoId? initialDemo;

  /// Light / dark / system.
  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    final demo = initialDemo;
    return MaterialApp(
      title: 'flutter_chat_reactions',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      home: demo != null && demoBuilders.containsKey(demo)
          ? buildDemo(demo)
          : const GalleryHome(),
    );
  }
}
```

`example/lib/app/gallery_home.dart`:

```dart
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
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => buildDemo(demo)),
              ),
            ),
        ],
      ),
    );
  }
}
```

`example/lib/app/demo_registry.dart`:

```dart
import 'package:example/app/demo_id.dart';
import 'package:example/demos/quick_start_demo.dart';
import 'package:flutter/widgets.dart';

/// Builders for every implemented demo.
final Map<DemoId, Widget Function()> demoBuilders = {
  DemoId.quickStart: () => const QuickStartDemo(),
};

/// Builds [id]'s screen. [id] must be in [demoBuilders].
Widget buildDemo(DemoId id) => demoBuilders[id]!();
```

- [ ] **Step 6: Implement `example/lib/demos/quick_start_demo.dart`**

This demo is the minimal integration, shown on pub.dev as the example, so it deliberately uses `ReactionsController` directly rather than `DemoChatModel`.

```dart
import 'package:example/app/demo_id.dart';
import 'package:example/data/sample_chat.dart';
import 'package:example/widgets/chat_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';

/// The smallest useful integration: a controller, ReactableMessage around
/// each bubble, and a ReactionsSummaryView below it.
class QuickStartDemo extends StatefulWidget {
  /// Creates the demo.
  const QuickStartDemo({super.key});

  @override
  State<QuickStartDemo> createState() => _QuickStartDemoState();
}

class _QuickStartDemoState extends State<QuickStartDemo> {
  final _controller = ReactionsController(
    currentUserId: kMe.id,
    currentUserName: kMe.name,
  );
  final _messages = sampleConversation();

  @override
  void initState() {
    super.initState();
    for (final entry in sampleReactions().entries) {
      _controller.setReactions(entry.key, entry.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(DemoId.quickStart.title)),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final message in _messages)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Align(
                  alignment: message.isMine
                      ? AlignmentDirectional.centerEnd
                      : AlignmentDirectional.centerStart,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: message.isMine
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      ReactableMessage(
                        key: ValueKey('reactable-${message.id}'),
                        alignment: message.isMine
                            ? ReactionAlignment.end
                            : ReactionAlignment.start,
                        reactions: _controller.summariesFor(message.id),
                        onReactionSelected:
                            _controller.bind(message.id).onReactionSelected,
                        child: ChatBubble(message: message),
                      ),
                      const SizedBox(height: 4),
                      ReactionsSummaryView(
                        key: ValueKey('summary-${message.id}'),
                        reactions: _controller.summariesFor(message.id),
                        onReactionTap:
                            _controller.bind(message.id).onReactionSelected,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 7: Replace `example/lib/main.dart`**

```dart
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
```

- [ ] **Step 8: Implement `example/integration_test/demo_script.dart`**

```dart
import 'package:example/app/demo_id.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

/// Waits [duration]: fake time in widget tests, real time when recording.
typedef Pace = Future<void> Function(Duration duration);

/// A scripted interaction for one demo.
typedef DemoScript = Future<void> Function(WidgetTester tester, Pace pace);

/// Pause between steps.
const Duration beat = Duration(milliseconds: 700);

/// Pause at the end so the final state is visible in recordings.
const Duration linger = Duration(milliseconds: 1500);

/// Scripts for every demo that has one.
final Map<DemoId, DemoScript> demoScripts = {
  DemoId.quickStart: _quickStart,
};

/// Runs [id]'s script.
Future<void> runDemoScript(
  WidgetTester tester,
  DemoId id, {
  required Pace pace,
}) => demoScripts[id]!(tester, pace);

/// The visible body of message [id].
Finder messageFinder(String id) => find.byKey(ValueKey('msg-$id'));

/// The reactions summary of message [id].
Finder summaryFinder(String id) => find.byKey(ValueKey('summary-$id'));

/// [emoji] inside the open reaction bar. Shortcodes (`:x:`) are found by
/// their `emoji-<shortcode>` key, unicode emoji by text.
Finder reactionInBar(String emoji) => find.descendant(
  of: find.byType(ReactionBar),
  matching: emoji.startsWith(':')
      ? find.byKey(ValueKey('emoji-$emoji'))
      : find.text(emoji),
);

/// Long-presses message [id] to open its reactions menu.
Future<void> openMenu(WidgetTester tester, String id, Pace pace) async {
  await tester.longPress(messageFinder(id));
  await pace(beat);
}

/// Taps [finder] and waits a beat.
Future<void> tapAndPace(WidgetTester tester, Finder finder, Pace pace) async {
  await tester.tap(finder);
  await pace(beat);
}

/// Asserts that [matching] is shown in message [id]'s summary.
void expectInSummary(String id, Finder matching) => expect(
  find.descendant(of: summaryFinder(id), matching: matching),
  findsOneWidget,
);

Future<void> _quickStart(WidgetTester tester, Pace pace) async {
  await pace(beat);
  await openMenu(tester, 'm1', pace);
  await tapAndPace(tester, reactionInBar('😂'), pace);
  expectInSummary('m1', find.text('😂'));
  await openMenu(tester, 'm1', pace);
  await tapAndPace(tester, reactionInBar('😮'), pace);
  expectInSummary('m1', find.text('😮'));
  await pace(linger);
}
```

- [ ] **Step 9: Delete the old example test and run everything**

Run: `git rm -q example/test/example_test.dart && cd example && flutter test && flutter analyze --fatal-infos`
Expected: all tests pass (including `demo script: quickstart`) and `No issues found!`.

- [ ] **Step 10: Commit**

```bash
dart format .
git add example/pubspec.yaml example/pubspec.lock example/lib example/integration_test example/test
git commit -m "feat(example): Add gallery shell, quick start demo, and demo-script harness

Co-Authored-By: <committing model> <noreply@anthropic.com>"
```

---

### Task 3: Messenger demo (focused overlay, stacked summary, emoji picker)

**Files:**
- Create: `example/lib/adapters/emoji_picker_sheet.dart`, `example/lib/demos/messenger_demo.dart`, `example/test/messenger_demo_test.dart`
- Modify: `example/pubspec.yaml` (add `emoji_picker_flutter: '>=4.4.0 <4.5.0'`), `example/lib/app/demo_registry.dart`, `example/integration_test/demo_script.dart`

**Interfaces:**
- Consumes: Task 1 (`DemoChatModel`, `ChatBubble`, `actionsFor`) and Task 2 (`DemoId`, the registries and script helpers).
- Produces:
  - `typedef EmojiPickerLauncher = Future<String?> Function(BuildContext context)` and `Future<String?> showEmojiPickerSheet(BuildContext)`.
  - `MessengerDemo({key, EmojiPickerLauncher pickEmoji = showEmojiPickerSheet})`.
  - The registry entries `DemoId.messenger` in `demoBuilders` and in `demoScripts`.

- [ ] **Step 1: Add the dependency**

In `example/pubspec.yaml` under `dependencies:` add `emoji_picker_flutter: '>=4.4.0 <4.5.0'`, then run `cd example && flutter pub get`.
Expected: `emoji_picker_flutter 4.4.0` appears in `example/pubspec.lock`.

- [ ] **Step 2: Write the failing test**

`example/test/messenger_demo_test.dart`:

```dart
import 'package:example/demos/messenger_demo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, {EmojiPickerLauncher? pick}) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: MessengerDemo(pickEmoji: pick ?? (_) async => '🔥'),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('uses the focused overlay (blur) with actions', (tester) async {
    await pump(tester);
    await tester.longPress(find.byKey(const ValueKey('msg-m1')));
    await tester.pumpAndSettle();
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.text('Reply'), findsOneWidget);
    expect(find.text('Delete'), findsNothing, reason: "not the user's message");
  });

  testWidgets('"+" opens the picker and applies its emoji', (tester) async {
    await pump(tester);
    await tester.longPress(find.byKey(const ValueKey('msg-m1')));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('More reactions'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('summary-m1')),
        matching: find.text('🔥'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a cancelled picker changes nothing', (tester) async {
    await pump(tester, pick: (_) async => null);
    await tester.longPress(find.byKey(const ValueKey('msg-m1')));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('More reactions'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('summary-m1')), findsOneWidget,
        reason: 'overlay summary wraps the bubble even when empty');
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('summary-m1')),
        matching: find.byType(Text),
      ),
      findsOneWidget,
      reason: 'only the bubble text, no reaction',
    );
  });

  testWidgets('tapping the stacked summary shows who reacted', (tester) async {
    await pump(tester);
    final summary = find.byKey(const ValueKey('summary-m2'));
    await tester.tap(find.descendant(of: summary, matching: find.text('3')));
    await tester.pumpAndSettle();
    expect(find.text('Sam'), findsOneWidget);
    expect(find.text('Priya'), findsOneWidget);
  });

  testWidgets('summary is the stacked layout overlaid on the bubble', (tester) async {
    await pump(tester);
    final view = tester.widget<ReactionsSummaryView>(
      find.byKey(const ValueKey('summary-m2')),
    );
    expect(view.layout, ReactionSummaryLayout.stacked);
    expect(view.overlayChild, isNotNull);
  });
}
```

- [ ] **Step 3: Run the test to confirm it fails**

Run: `cd example && flutter test test/messenger_demo_test.dart`
Expected: a compilation error (`package:example/demos/messenger_demo.dart` doesn't exist).

- [ ] **Step 4: Implement `example/lib/adapters/emoji_picker_sheet.dart`**

```dart
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as picker;
import 'package:flutter/material.dart';

/// Opens a full emoji picker and returns a user-picked emoji, or null.
typedef EmojiPickerLauncher = Future<String?> Function(BuildContext context);

/// [EmojiPickerLauncher] backed by `emoji_picker_flutter` in a bottom sheet.
///
/// This is the adapter the README documents: the package ships no picker of
/// its own; wire any picker into `ReactableMessage.onMoreTap` like this.
Future<String?> showEmojiPickerSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (sheetContext) => SizedBox(
      height: 340,
      child: picker.EmojiPicker(
        onEmojiSelected: (_, emoji) =>
            Navigator.of(sheetContext).pop(emoji.emoji),
        config: picker.Config(
          height: 320,
          checkPlatformCompatibility: true,
          emojiViewConfig: picker.EmojiViewConfig(
            backgroundColor: Theme.of(sheetContext).colorScheme.surface,
          ),
        ),
      ),
    ),
  );
}
```

(If a `Config`/`EmojiViewConfig` parameter name differs in 4.4.0, check the package's `Config` class in the pub cache and use the matching name; keep the behaviour of popping `emoji.emoji`.)

- [ ] **Step 5: Implement `example/lib/demos/messenger_demo.dart`**

```dart
import 'package:example/adapters/emoji_picker_sheet.dart';
import 'package:example/app/demo_id.dart';
import 'package:example/data/sample_chat.dart';
import 'package:example/widgets/chat_bubble.dart';
import 'package:example/widgets/demo_chat_model.dart';
import 'package:example/widgets/message_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';

export 'package:example/adapters/emoji_picker_sheet.dart'
    show EmojiPickerLauncher;

/// iMessage / WhatsApp style: focused overlay, stacked summary overlaid on
/// the bubble, one reaction per user, and a full emoji picker behind "+".
class MessengerDemo extends StatefulWidget {
  /// Creates the demo. [pickEmoji] is injectable for tests.
  const MessengerDemo({super.key, this.pickEmoji = showEmojiPickerSheet});

  /// Opens the full emoji picker.
  final EmojiPickerLauncher pickEmoji;

  @override
  State<MessengerDemo> createState() => _MessengerDemoState();
}

class _MessengerDemoState extends State<MessengerDemo> {
  final _chat = DemoChatModel();

  @override
  void dispose() {
    _chat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(DemoId.messenger.title)),
      body: ChatReactionsScope(
        presenter: const FocusedOverlayPresenter(),
        child: ListenableBuilder(
          listenable: _chat,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
            children: [
              for (final message in _chat.messages)
                _MessengerRow(
                  key: ValueKey('row-${message.id}'),
                  message: message,
                  chat: _chat,
                  pickEmoji: widget.pickEmoji,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessengerRow extends StatelessWidget {
  const _MessengerRow({
    super.key,
    required this.message,
    required this.chat,
    required this.pickEmoji,
  });

  final ChatMessage message;
  final DemoChatModel chat;
  final EmojiPickerLauncher pickEmoji;

  @override
  Widget build(BuildContext context) {
    final reactions = chat.reactionsFor(message.id);
    final select = chat.onReactionSelected(message.id);
    final alignment = message.isMine
        ? ReactionAlignment.end
        : ReactionAlignment.start;
    return Padding(
      padding: EdgeInsets.only(bottom: reactions.isEmpty ? 8 : 20),
      child: Align(
        alignment: message.isMine
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: ReactableMessage(
          key: ValueKey('reactable-${message.id}'),
          alignment: alignment,
          reactions: reactions,
          onReactionSelected: select,
          actionsBuilder: (_) => actionsFor(message),
          onActionSelected: (action) =>
              chat.handleAction(context, message, action),
          onMoreTap: (menuContext) async {
            final emoji = await pickEmoji(menuContext);
            if (emoji != null) select(emoji);
          },
          child: ReactionsSummaryView.overlay(
            key: ValueKey('summary-${message.id}'),
            reactions: reactions,
            alignment: alignment,
            onTap: () => showReactionDetails(context, reactions),
            child: ChatBubble(message: message),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Register the demo and its script**

In `example/lib/app/demo_registry.dart`, add the import `package:example/demos/messenger_demo.dart` and the entry `DemoId.messenger: () => const MessengerDemo(),`.

In `example/integration_test/demo_script.dart`, add the entry `DemoId.messenger: _messenger,` and this function:

```dart
Future<void> _messenger(WidgetTester tester, Pace pace) async {
  await pace(beat);
  // Priya's message already has your ❤️: pick 😂 to replace it.
  await openMenu(tester, 'm3', pace);
  await tapAndPace(tester, reactionInBar('😂'), pace);
  expectInSummary('m3', find.text('😂'));
  // Change your mind.
  await openMenu(tester, 'm3', pace);
  await tapAndPace(tester, reactionInBar('😮'), pace);
  expectInSummary('m3', find.text('😮'));
  // Run an action: delete your own message.
  await openMenu(tester, 'm5', pace);
  await tapAndPace(tester, find.text('Delete'), pace);
  expect(messageFinder('m5'), findsNothing);
  await pace(linger);
}
```

- [ ] **Step 7: Run and commit**

Run: `cd example && flutter test && flutter analyze --fatal-infos`
Expected: all tests pass (including `demo script: messenger`) and `No issues found!`.

```bash
dart format .
git add example/pubspec.yaml example/pubspec.lock example/lib example/integration_test example/test/messenger_demo_test.dart
git commit -m "feat(example): Add Messenger demo with focused overlay and emoji picker

Co-Authored-By: <committing model> <noreply@anthropic.com>"
```

---

### Task 4: Team channel demo (compact bar, chips, multiple reactions, custom emoji)

**Files:**
- Create: `example/lib/demos/team_demo.dart`, `example/test/team_demo_test.dart`
- Modify: `example/lib/app/demo_registry.dart`, `example/integration_test/demo_script.dart`

**Interfaces:**
- Consumes: Tasks 1 and 2.
- Produces:
  - `const List<String> kTeamReactions = ['👍', '🎉', '👀', ':party:', ':ship_it:', ':lgtm:']`;
  - `Widget teamEmojiBuilder(BuildContext, String, double)`, whose shortcode widgets are keyed `ValueKey('emoji-<shortcode>')`;
  - `Map<String, List<Reaction>> teamReactions()`;
  - `TeamDemo({key})`;
  - the registry entries for `DemoId.team`.

- [ ] **Step 1: Write the failing test**

`example/test/team_demo_test.dart`:

```dart
import 'package:example/demos/team_demo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: TeamDemo()));
    await tester.pumpAndSettle();
  }

  testWidgets('long-press opens the compact bar (no blur) with team emoji', (tester) async {
    await pump(tester);
    await tester.longPress(find.byKey(const ValueKey('msg-m1')));
    await tester.pumpAndSettle();
    expect(find.byType(ReactionBar), findsOneWidget);
    expect(find.byType(BackdropFilter), findsNothing);
    expect(
      find.descendant(
        of: find.byType(ReactionBar),
        matching: find.byKey(const ValueKey('emoji-:ship_it:')),
      ),
      findsOneWidget,
    );
  });

  testWidgets('several reactions from the same user are kept', (tester) async {
    await pump(tester);
    for (final emoji in ['🎉', '👀']) {
      await tester.longPress(find.byKey(const ValueKey('msg-m1')));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(
        of: find.byType(ReactionBar),
        matching: find.text(emoji),
      ));
      await tester.pumpAndSettle();
    }
    final summary = find.byKey(const ValueKey('summary-m1'));
    expect(find.descendant(of: summary, matching: find.text('🎉')), findsOneWidget);
    expect(find.descendant(of: summary, matching: find.text('👀')), findsOneWidget);
  });

  testWidgets('custom emoji render in chips via emojiBuilder', (tester) async {
    await pump(tester);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('summary-m4')),
        matching: find.byKey(const ValueKey('emoji-:ship_it:')),
      ),
      findsOneWidget,
    );
  });

  testWidgets('"⋯" reveals message actions', (tester) async {
    await pump(tester);
    await tester.longPress(find.byKey(const ValueKey('msg-m1')));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('More actions'));
    await tester.pumpAndSettle();
    expect(find.text('Reply'), findsOneWidget);
  });

  test('team data includes shortcode reactions', () {
    expect(kTeamReactions, contains(':party:'));
    expect(teamReactions()['m4']!.where((r) => r.emoji == ':ship_it:'), hasLength(2));
  });
}
```

- [ ] **Step 2: Run the test to confirm it fails**

Run: `cd example && flutter test test/team_demo_test.dart`
Expected: a compilation error.

- [ ] **Step 3: Implement `example/lib/demos/team_demo.dart`**

```dart
import 'package:example/app/demo_id.dart';
import 'package:example/data/sample_chat.dart';
import 'package:example/widgets/demo_chat_model.dart';
import 'package:example/widgets/message_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';

/// Quick reactions for the team channel, including custom shortcodes.
const List<String> kTeamReactions = [
  '👍',
  '🎉',
  '👀',
  ':party:',
  ':ship_it:',
  ':lgtm:',
];

@immutable
class _Shortcode {
  const _Shortcode(this.icon, this.colors);
  final IconData icon;
  final List<Color> colors;
}

const Map<String, _Shortcode> _shortcodes = {
  ':party:': _Shortcode(Icons.celebration, [
    Color(0xFFFF6B6B),
    Color(0xFFFFB347),
  ]),
  ':ship_it:': _Shortcode(Icons.rocket_launch, [
    Color(0xFF4D96FF),
    Color(0xFF6BCB77),
  ]),
  ':lgtm:': _Shortcode(Icons.check_circle, [
    Color(0xFF2E7D32),
    Color(0xFF1DE9B6),
  ]),
};

/// Draws `:shortcode:` emoji as gradient badges; unicode emoji as text.
Widget teamEmojiBuilder(BuildContext context, String emoji, double size) {
  final spec = _shortcodes[emoji];
  if (spec == null) return defaultEmojiBuilder(context, emoji, size);
  return Container(
    key: ValueKey('emoji-$emoji'),
    width: size * 1.15,
    height: size * 1.15,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(size * 0.3),
      gradient: LinearGradient(colors: spec.colors),
    ),
    child: Icon(spec.icon, size: size * 0.75, color: Colors.white),
  );
}

/// Sample reactions plus some shortcode reactions.
Map<String, List<Reaction>> teamReactions() => {
  ...sampleReactions(),
  'm4': const [
    Reaction(emoji: ':ship_it:', userId: 'sam', userName: 'Sam'),
    Reaction(emoji: ':ship_it:', userId: 'priya', userName: 'Priya'),
    Reaction(emoji: '👀', userId: 'me', userName: 'You'),
  ],
};

/// Slack / Discord style: compact bar, chips, many reactions per user.
class TeamDemo extends StatefulWidget {
  /// Creates the demo.
  const TeamDemo({super.key});

  @override
  State<TeamDemo> createState() => _TeamDemoState();
}

class _TeamDemoState extends State<TeamDemo> {
  final _chat = DemoChatModel(
    policy: const ReactionPolicy.multiple(),
    reactions: teamReactions(),
  );

  @override
  void dispose() {
    _chat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(DemoId.team.title)),
      body: ChatReactionsScope(
        presenter: const CompactBarPresenter(),
        quickReactions: kTeamReactions,
        emojiBuilder: teamEmojiBuilder,
        child: ListenableBuilder(
          listenable: _chat,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              for (final message in _chat.messages)
                _TeamRow(message: message, chat: _chat),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamRow extends StatelessWidget {
  const _TeamRow({required this.message, required this.chat});

  final ChatMessage message;
  final DemoChatModel chat;

  @override
  Widget build(BuildContext context) {
    final id = message.id;
    final reactions = chat.reactionsFor(id);
    final select = chat.onReactionSelected(id);
    final author = message.author;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: author.color,
            child: Text(
              author.name.characters.first,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReactableMessage(
                  key: ValueKey('reactable-$id'),
                  alignment: ReactionAlignment.start,
                  reactions: reactions,
                  onReactionSelected: select,
                  actionsBuilder: (_) => actionsFor(message),
                  onActionSelected: (action) =>
                      chat.handleAction(context, message, action),
                  child: Container(
                    key: ValueKey('msg-$id'),
                    width: double.infinity,
                    color: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          author.name,
                          style: text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(message.text, style: text.bodyLarge),
                      ],
                    ),
                  ),
                ),
                if (reactions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: ReactionsSummaryView(
                      key: ValueKey('summary-$id'),
                      reactions: reactions,
                      emojiBuilder: teamEmojiBuilder,
                      onReactionTap: select,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Register the demo and its script**

In `demo_registry.dart`, add the import `package:example/demos/team_demo.dart` and the entry `DemoId.team: () => const TeamDemo(),`.

In `demo_script.dart`, add the entry `DemoId.team: _team,` and:

```dart
Future<void> _team(WidgetTester tester, Pace pace) async {
  await pace(beat);
  await openMenu(tester, 'm1', pace);
  await tapAndPace(tester, reactionInBar('🎉'), pace);
  await openMenu(tester, 'm1', pace);
  await tapAndPace(tester, reactionInBar(':party:'), pace);
  // Multiple reactions per user: both stay.
  expectInSummary('m1', find.text('🎉'));
  expectInSummary('m1', find.byKey(const ValueKey('emoji-:party:')));
  // Tap an existing chip to +1 it.
  await tapAndPace(
    tester,
    find.descendant(of: summaryFinder('m2'), matching: find.text('👍')),
    pace,
  );
  expectInSummary('m2', find.text('3'));
  await pace(linger);
}
```

- [ ] **Step 5: Run and commit**

Run: `cd example && flutter test && flutter analyze --fatal-infos`
Expected: all tests pass and `No issues found!`.

```bash
dart format .
git add example/lib example/integration_test example/test/team_demo_test.dart
git commit -m "feat(example): Add Team channel demo with compact bar and custom emoji

Co-Authored-By: <committing model> <noreply@anthropic.com>"
```

---

### Task 5: Telegram-like demo (bottom sheet with reaction details, pinning)

**Files:**
- Create: `example/lib/demos/telegram_demo.dart`, `example/test/telegram_demo_test.dart`
- Modify: `example/lib/app/demo_registry.dart`, `example/integration_test/demo_script.dart`

**Interfaces:**
- Consumes: Task 1 (`BubbleRow`, `DemoChatModel.pinned`, `actionsFor(pin: true)`) and Task 2.
- Produces: `TelegramDemo({key})` and the registry entries for `DemoId.telegram`. The pinned banner is keyed `ValueKey('pinned-banner')`.

- [ ] **Step 1: Write the failing test**

`example/test/telegram_demo_test.dart`:

```dart
import 'package:example/demos/telegram_demo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: TelegramDemo()));
    await tester.pumpAndSettle();
  }

  testWidgets('long-press opens a bottom sheet with reaction details', (tester) async {
    await pump(tester);
    await tester.longPress(find.byKey(const ValueKey('msg-m2')));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    final sheet = find.byType(BottomSheet);
    expect(find.descendant(of: sheet, matching: find.byType(ReactionBar)), findsOneWidget);
    expect(
      find.descendant(of: sheet, matching: find.text('Sam')),
      findsOneWidget,
      reason: 'reaction details list (Sam also appears as a bubble author)',
    );
    expect(find.descendant(of: sheet, matching: find.text('Pin')), findsOneWidget);
  });

  testWidgets('Pin shows the pinned banner', (tester) async {
    await pump(tester);
    expect(find.byKey(const ValueKey('pinned-banner')), findsNothing);
    await tester.longPress(find.byKey(const ValueKey('msg-m1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pin'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('pinned-banner')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('pinned-banner')),
        matching: find.textContaining('Morning'),
      ),
      findsOneWidget,
    );
  });
}
```

- [ ] **Step 2: Run the test to confirm it fails**

Run: `cd example && flutter test test/telegram_demo_test.dart`
Expected: a compilation error.

- [ ] **Step 3: Implement `example/lib/demos/telegram_demo.dart`**

```dart
import 'package:example/app/demo_id.dart';
import 'package:example/data/sample_chat.dart';
import 'package:example/widgets/bubble_row.dart';
import 'package:example/widgets/demo_chat_model.dart';
import 'package:example/widgets/message_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';

/// Telegram style: a bottom sheet with the reaction row, who reacted, and
/// full-width actions (including Pin).
class TelegramDemo extends StatefulWidget {
  /// Creates the demo.
  const TelegramDemo({super.key});

  @override
  State<TelegramDemo> createState() => _TelegramDemoState();
}

class _TelegramDemoState extends State<TelegramDemo> {
  final _chat = DemoChatModel();

  @override
  void dispose() {
    _chat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(DemoId.telegram.title)),
      body: ChatReactionsScope(
        presenter: const BottomSheetPresenter(showReactionDetails: true),
        child: ListenableBuilder(
          listenable: _chat,
          builder: (context, _) {
            final pinned = _chat.pinned;
            return Column(
              children: [
                if (pinned != null) _PinnedBanner(message: pinned),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      for (final message in _chat.messages)
                        BubbleRow(
                          message: message,
                          chat: _chat,
                          actionsFor: (m) => actionsFor(m, pin: true),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PinnedBanner extends StatelessWidget {
  const _PinnedBanner({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      key: const ValueKey('pinned-banner'),
      color: scheme.secondaryContainer,
      child: ListTile(
        dense: true,
        leading: Icon(Icons.push_pin, color: scheme.onSecondaryContainer),
        title: const Text('Pinned message'),
        subtitle: Text(
          message.text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Register the demo and its script**

In `demo_registry.dart`, add the import `package:example/demos/telegram_demo.dart` and the entry `DemoId.telegram: () => const TelegramDemo(),`.

In `demo_script.dart`, add the entry `DemoId.telegram: _telegram,` and:

```dart
Future<void> _telegram(WidgetTester tester, Pace pace) async {
  await pace(beat);
  // The sheet shows who reacted before you pick.
  await openMenu(tester, 'm2', pace);
  await pace(beat);
  await tapAndPace(tester, reactionInBar('🙏'), pace);
  expectInSummary('m2', find.text('🙏'));
  // Run an action: pin a message.
  await openMenu(tester, 'm1', pace);
  await tapAndPace(tester, find.text('Pin'), pace);
  expect(find.byKey(const ValueKey('pinned-banner')), findsOneWidget);
  await pace(linger);
}
```

- [ ] **Step 5: Run and commit**

Run: `cd example && flutter test && flutter analyze --fatal-infos`
Expected: all tests pass and `No issues found!`.

```bash
dart format .
git add example/lib example/integration_test example/test/telegram_demo_test.dart
git commit -m "feat(example): Add Telegram-like demo with bottom sheet and pinning

Co-Authored-By: <committing model> <noreply@anthropic.com>"
```

---

### Task 6: Custom (headless) demo with a radial picker

**Files:**
- Create: `example/lib/widgets/radial_reaction_menu.dart`, `example/lib/demos/custom_demo.dart`, `example/test/custom_demo_test.dart`
- Modify: `example/lib/app/demo_registry.dart`, `example/integration_test/demo_script.dart`

**Interfaces:**
- Consumes: `CustomPresenter(builder: (BuildContext, ReactionsMenuContext, Animation<double>) => Widget, barrierColor, blurSigma)`, and from `ReactionsMenuContext`: `anchorRect`, `messageBuilder`, `quickReactions`, `selectedReactions`, `selectReaction` and `emojiBuilder`. Also `defaultEmojiBuilder`, `ChatReactionsLocalizations.of(context).emojiLabel`, and `BubbleRow` from Task 1.
- Produces:
  - `RadialReactionMenu({key, required ReactionsMenuContext menu, required Animation<double> animation, double radius = 100})`, whose items are keyed `ValueKey('radial-<emoji>')`;
  - `CustomDemo({key})`;
  - the registry entries for `DemoId.custom`.

- [ ] **Step 1: Write the failing test**

`example/test/custom_demo_test.dart`:

```dart
import 'package:example/demos/custom_demo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: CustomDemo()));
    await tester.pumpAndSettle();
  }

  testWidgets('shows a radial ring of reactions around the message', (tester) async {
    await pump(tester);
    final anchor = tester.getRect(find.byKey(const ValueKey('msg-m2')));
    await tester.longPress(find.byKey(const ValueKey('msg-m2')));
    await tester.pumpAndSettle();

    expect(find.byType(ReactionBar), findsNothing, reason: 'fully custom UI');
    final centers = [
      for (final emoji in kDefaultQuickReactions)
        tester.getCenter(find.byKey(ValueKey('radial-$emoji'))),
    ];
    final ringCenter = centers.reduce((a, b) => a + b) / centers.length.toDouble();
    for (final c in centers) {
      expect((c - ringCenter).distance, closeTo(100, 1));
    }
    // The ring is centred on the message unless clamped to the screen.
    expect((ringCenter - anchor.center).distance, lessThan(120));
  });

  testWidgets('tapping a radial item reacts and closes the menu', (tester) async {
    await pump(tester);
    await tester.longPress(find.byKey(const ValueKey('msg-m2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('radial-🙏')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('radial-🙏')), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('summary-m2')),
        matching: find.text('🙏'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('tap outside dismisses', (tester) async {
    await pump(tester);
    await tester.longPress(find.byKey(const ValueKey('msg-m2')));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(8, 830));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('radial-👍')), findsNothing);
  });

  testWidgets('radial items are accessible buttons', (tester) async {
    await pump(tester);
    await tester.longPress(find.byKey(const ValueKey('msg-m2')));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('thumbs up'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the test to confirm it fails**

Run: `cd example && flutter test test/custom_demo_test.dart`
Expected: a compilation error.

- [ ] **Step 3: Implement `example/lib/widgets/radial_reaction_menu.dart`**

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';

/// A headless-presenter UI: the message copy stays in place and the quick
/// reactions fan out on a ring around it.
class RadialReactionMenu extends StatelessWidget {
  /// Creates the radial menu for [menu], driven by [animation].
  const RadialReactionMenu({
    super.key,
    required this.menu,
    required this.animation,
    this.radius = 100,
  });

  /// The menu to present.
  final ReactionsMenuContext menu;

  /// 0→1 on open, 1→0 on close.
  final Animation<double> animation;

  /// Ring radius in logical pixels.
  final double radius;

  static const double _itemSize = 52;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final margin = radius + _itemSize / 2 + 8;
    final anchorCenter = menu.anchorRect.center;
    final center = Offset(
      anchorCenter.dx.clamp(margin, math.max(margin, size.width - margin)),
      anchorCenter.dy.clamp(
        padding.top + margin,
        math.max(padding.top + margin, size.height - padding.bottom - margin),
      ),
    );
    final emojis = menu.quickReactions;
    final selected = menu.selectedReactions;
    final emojiBuilder = menu.emojiBuilder ?? defaultEmojiBuilder;

    return Stack(
      children: [
        Positioned.fromRect(
          rect: menu.anchorRect,
          child: IgnorePointer(child: menu.messageBuilder(context)),
        ),
        for (var i = 0; i < emojis.length; i++)
          _RadialItem(
            key: ValueKey('radial-${emojis[i]}'),
            animation: animation,
            center: center,
            angle: -math.pi / 2 + 2 * math.pi * i / emojis.length,
            radius: radius,
            size: _itemSize,
            child: _RadialButton(
              emoji: emojis[i],
              selected: selected.contains(emojis[i]),
              emojiBuilder: emojiBuilder,
              onTap: () => menu.selectReaction(emojis[i]),
            ),
          ),
      ],
    );
  }
}

class _RadialItem extends AnimatedWidget {
  const _RadialItem({
    super.key,
    required Animation<double> animation,
    required this.center,
    required this.angle,
    required this.radius,
    required this.size,
    required this.child,
  }) : super(listenable: animation);

  final Offset center;
  final double angle;
  final double radius;
  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = (listenable as Animation<double>).value;
    final position =
        center + Offset(math.cos(angle), math.sin(angle)) * radius * t;
    return Positioned(
      left: position.dx - size / 2,
      top: position.dy - size / 2,
      width: size,
      height: size,
      child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
    );
  }
}

class _RadialButton extends StatelessWidget {
  const _RadialButton({
    required this.emoji,
    required this.selected,
    required this.emojiBuilder,
    required this.onTap,
  });

  final String emoji;
  final bool selected;
  final EmojiBuilder emojiBuilder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: ChatReactionsLocalizations.of(context).emojiLabel(emoji),
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        shape: const CircleBorder(),
        elevation: 4,
        color: selected ? scheme.primaryContainer : scheme.surface,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Center(child: emojiBuilder(context, emoji, 26)),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Implement `example/lib/demos/custom_demo.dart`**

```dart
import 'package:example/app/demo_id.dart';
import 'package:example/widgets/bubble_row.dart';
import 'package:example/widgets/demo_chat_model.dart';
import 'package:example/widgets/radial_reaction_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';

Widget _buildRadial(
  BuildContext context,
  ReactionsMenuContext menu,
  Animation<double> animation,
) => RadialReactionMenu(menu: menu, animation: animation);

/// Headless mode: CustomPresenter handles the route, barrier and dismissal;
/// the UI is a radial ring drawn by this app.
class CustomDemo extends StatefulWidget {
  /// Creates the demo.
  const CustomDemo({super.key});

  @override
  State<CustomDemo> createState() => _CustomDemoState();
}

class _CustomDemoState extends State<CustomDemo> {
  final _chat = DemoChatModel();

  @override
  void dispose() {
    _chat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(DemoId.custom.title)),
      body: ChatReactionsScope(
        presenter: const CustomPresenter(
          builder: _buildRadial,
          barrierColor: Color(0x99000000),
          blurSigma: 6,
        ),
        child: ListenableBuilder(
          listenable: _chat,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.all(12),
            children: [
              for (final message in _chat.messages)
                BubbleRow(
                  message: message,
                  chat: _chat,
                  summaryLayout: ReactionSummaryLayout.compact,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Register the demo and its script**

In `demo_registry.dart`, add the import `package:example/demos/custom_demo.dart` and the entry `DemoId.custom: () => const CustomDemo(),`.

In `demo_script.dart`, add the entry `DemoId.custom: _custom,` and:

```dart
Future<void> _custom(WidgetTester tester, Pace pace) async {
  await pace(beat);
  await openMenu(tester, 'm2', pace);
  await pace(beat);
  await tapAndPace(tester, find.byKey(const ValueKey('radial-🙏')), pace);
  expectInSummary('m2', find.text('🙏'));
  await openMenu(tester, 'm3', pace);
  await tapAndPace(tester, find.byKey(const ValueKey('radial-😂')), pace);
  expectInSummary('m3', find.text('😂'));
  await pace(linger);
}
```

- [ ] **Step 6: Run and commit**

Run: `cd example && flutter test && flutter analyze --fatal-infos`
Expected: all tests pass and `No issues found!`.

```bash
dart format .
git add example/lib example/integration_test example/test/custom_demo_test.dart
git commit -m "feat(example): Add headless demo with a radial reaction picker

Co-Authored-By: <committing model> <noreply@anthropic.com>"
```

---

### Task 7: Theming playground

**Files:**
- Create: `example/lib/demos/theming_demo.dart`, `example/test/theming_demo_test.dart`
- Modify: `example/lib/app/demo_registry.dart`, `example/integration_test/demo_script.dart`

**Interfaces:**
- Consumes: `buildTheme` (Task 2), `BubbleRow` and `DemoChatModel` (Task 1), `ChatReactionsTheme(style:)`, `ChatReactionsTheme.of(context).isCupertino`, and `ReactionsVisualStyle`.
- Produces:
  - `ThemingDemo({key})`;
  - the control keys `control-brightness`, `control-style`, `control-seed-<0..3>`, `control-text-scale` and `control-rtl`;
  - the registry entries for `DemoId.theming`.

- [ ] **Step 1: Write the failing test**

`example/test/theming_demo_test.dart`:

```dart
import 'package:example/demos/theming_demo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: ThemingDemo()));
    await tester.pumpAndSettle();
  }

  BuildContext previewContext(WidgetTester tester) =>
      tester.element(find.byKey(const ValueKey('msg-m1')));

  testWidgets('brightness toggle darkens only the preview', (tester) async {
    await pump(tester);
    expect(Theme.of(previewContext(tester)).brightness, Brightness.light);
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(Theme.of(previewContext(tester)).brightness, Brightness.dark);
  });

  testWidgets('style toggle forces Cupertino and the menu follows', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Cupertino'));
    await tester.pumpAndSettle();
    expect(ChatReactionsTheme.of(previewContext(tester)).isCupertino, isTrue);

    await tester.longPress(find.byKey(const ValueKey('msg-m1')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(ReactionActionMenu),
        matching: find.byType(Divider),
      ),
      findsWidgets,
      reason: 'Cupertino action menu draws dividers (the page has its own Divider too)',
    );
  });

  testWidgets('RTL flips message alignment', (tester) async {
    await pump(tester);
    final before = tester.getRect(find.byKey(const ValueKey('msg-m1')));
    await tester.tap(find.byKey(const ValueKey('control-rtl')));
    await tester.pumpAndSettle();
    final after = tester.getRect(find.byKey(const ValueKey('msg-m1')));
    expect(after.center.dx, greaterThan(before.center.dx));
  });

  testWidgets('text scale 2× makes the focused overlay fall back to a sheet', (tester) async {
    await pump(tester);
    final slider = find.byKey(const ValueKey('control-text-scale'));
    await tester.drag(slider, const Offset(400, 0));
    await tester.pumpAndSettle();
    await tester.longPress(find.byKey(const ValueKey('msg-m1')));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
  });

  testWidgets('seed colour changes the preview colour scheme', (tester) async {
    await pump(tester);
    final before = Theme.of(previewContext(tester)).colorScheme.primary;
    await tester.tap(find.byKey(const ValueKey('control-seed-2')));
    await tester.pumpAndSettle();
    expect(Theme.of(previewContext(tester)).colorScheme.primary, isNot(before));
  });
}
```

- [ ] **Step 2: Run the test to confirm it fails**

Run: `cd example && flutter test test/theming_demo_test.dart`
Expected: a compilation error.

- [ ] **Step 3: Implement `example/lib/demos/theming_demo.dart`**

```dart
import 'package:example/app/demo_id.dart';
import 'package:example/app/gallery_app.dart';
import 'package:example/widgets/bubble_row.dart';
import 'package:example/widgets/demo_chat_model.dart';
import 'package:example/widgets/message_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';

/// Live controls for brightness, visual style, seed colour, text scale and
/// text direction, applied to a preview chat (the menus follow the preview's
/// Theme because presenters capture the message's inherited themes).
class ThemingDemo extends StatefulWidget {
  /// Creates the demo.
  const ThemingDemo({super.key});

  @override
  State<ThemingDemo> createState() => _ThemingDemoState();
}

class _ThemingDemoState extends State<ThemingDemo> {
  static const List<Color> _seeds = [
    Colors.indigo,
    Colors.teal,
    Colors.pink,
    Colors.orange,
  ];

  final _chat = DemoChatModel();
  Brightness _brightness = Brightness.light;
  ReactionsVisualStyle _style = ReactionsVisualStyle.adaptive;
  Color _seed = Colors.indigo;
  double _textScale = 1;
  bool _rtl = false;

  @override
  void dispose() {
    _chat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final previewTheme = buildTheme(_brightness, seed: _seed).copyWith(
      extensions: [ChatReactionsTheme(style: _style)],
    );
    return Scaffold(
      appBar: AppBar(title: Text(DemoId.theming.title)),
      body: Column(
        children: [
          _controls(context),
          const Divider(height: 1),
          Expanded(
            child: Theme(
              data: previewTheme,
              child: Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(_textScale),
                  ),
                  child: Directionality(
                    textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
                    child: ColoredBox(
                      color: Theme.of(context).colorScheme.surface,
                      child: ListenableBuilder(
                        listenable: _chat,
                        builder: (context, _) => ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            for (final message in _chat.messages)
                              BubbleRow(
                                message: message,
                                chat: _chat,
                                actionsFor: actionsFor,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _controls(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SegmentedButton<Brightness>(
            key: const ValueKey('control-brightness'),
            segments: const [
              ButtonSegment(
                value: Brightness.light,
                icon: Icon(Icons.light_mode_outlined),
                label: Text('Light'),
              ),
              ButtonSegment(
                value: Brightness.dark,
                icon: Icon(Icons.dark_mode_outlined),
                label: Text('Dark'),
              ),
            ],
            selected: {_brightness},
            onSelectionChanged: (s) => setState(() => _brightness = s.first),
          ),
          SegmentedButton<ReactionsVisualStyle>(
            key: const ValueKey('control-style'),
            segments: const [
              ButtonSegment(
                value: ReactionsVisualStyle.adaptive,
                label: Text('Adaptive'),
              ),
              ButtonSegment(
                value: ReactionsVisualStyle.material,
                label: Text('Material'),
              ),
              ButtonSegment(
                value: ReactionsVisualStyle.cupertino,
                label: Text('Cupertino'),
              ),
            ],
            selected: {_style},
            onSelectionChanged: (s) => setState(() => _style = s.first),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < _seeds.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: InkResponse(
                    key: ValueKey('control-seed-$i'),
                    onTap: () => setState(() => _seed = _seeds[i]),
                    child: CircleAvatar(
                      radius: 13,
                      backgroundColor: _seeds[i],
                      child: _seeds[i] == _seed
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : null,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(
            width: 240,
            child: Row(
              children: [
                Text('Text ${_textScale.toStringAsFixed(2)}×'),
                Expanded(
                  child: Slider(
                    key: const ValueKey('control-text-scale'),
                    min: 1,
                    max: 2,
                    divisions: 4,
                    value: _textScale,
                    onChanged: (v) => setState(() => _textScale = v),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('RTL'),
              Switch(
                key: const ValueKey('control-rtl'),
                value: _rtl,
                onChanged: (v) => setState(() => _rtl = v),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Register the demo and its script**

In `demo_registry.dart`, add the import `package:example/demos/theming_demo.dart` and the entry `DemoId.theming: () => const ThemingDemo(),`.

In `demo_script.dart`, add the entry `DemoId.theming: _theming,` and:

```dart
Future<void> _theming(WidgetTester tester, Pace pace) async {
  await pace(beat);
  await openMenu(tester, 'm1', pace);
  await tapAndPace(tester, reactionInBar('❤️'), pace);
  await tapAndPace(tester, find.text('Dark'), pace);
  await tapAndPace(tester, find.text('Cupertino'), pace);
  await openMenu(tester, 'm1', pace);
  await pace(beat);
  await tapAndPace(tester, reactionInBar('😮'), pace);
  expectInSummary('m1', find.text('😮'));
  await tapAndPace(tester, find.byKey(const ValueKey('control-rtl')), pace);
  await openMenu(tester, 'm2', pace);
  await pace(linger);
  await tester.tapAt(const Offset(8, 830));
  await pace(beat);
}
```

- [ ] **Step 5: Run and commit**

Run: `cd example && flutter test && flutter analyze --fatal-infos`
Expected: all tests pass and `No issues found!`. If the text-scale drag in the test doesn't reach 2.0 on the surface, drag by the slider's full width (`tester.getSize(slider).width`) instead of 400.

```bash
dart format .
git add example/lib example/integration_test example/test/theming_demo_test.dart
git commit -m "feat(example): Add theming playground demo

Co-Authored-By: <committing model> <noreply@anthropic.com>"
```

---

### Task 8: Real-time integration runner, completeness check, CI job, example README

**Files:**
- Create: `example/integration_test/demo_script_test.dart`
- Modify: `example/test/gallery_test.dart` (completeness test), `.github/workflows/ci.yml` (new `example-tests` job), `example/README.md` (replace)

**Interfaces:**
- Consumes: `demoScripts`, `runDemoScript`, `DemoId.fromEnvironment`, `themeModeFromEnvironment` and `GalleryApp`.
- Produces: `flutter test integration_test/demo_script_test.dart -d <device> --dart-define=DEMO=<slug> --dart-define=THEME=<light|dark>`, which runs one demo script in real time. Plan 4's GIF workflow runs exactly this command.

- [ ] **Step 1: Add the completeness test (it fails if a demo lacks a builder or script)**

Append to `example/test/gallery_test.dart`, adding the import `import '../integration_test/demo_script.dart';`:

```dart
  test('every demo has a screen and a script', () {
    for (final id in DemoId.values) {
      expect(demoBuilders.containsKey(id), isTrue, reason: '${id.slug} builder');
      expect(demoScripts.containsKey(id), isTrue, reason: '${id.slug} script');
    }
  });
```

Run: `cd example && flutter test test/gallery_test.dart`
Expected: pass. Tasks 2–7 registered all six demos. If it fails, a task missed a registration, so add it.

- [ ] **Step 2: Create `example/integration_test/demo_script_test.dart`**

```dart
import 'package:example/app/demo_id.dart';
import 'package:example/app/gallery_app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'demo_script.dart';

/// Runs one demo's script in real time on a device or simulator.
///
///   flutter test integration_test/demo_script_test.dart -d <device> \
///     --dart-define=DEMO=messenger --dart-define=THEME=dark
///
/// Plan 4's GIF workflow records the simulator while this runs.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final demo = DemoId.fromEnvironment() ?? DemoId.messenger;

  testWidgets('demo script: ${demo.slug}', (tester) async {
    await tester.pumpWidget(
      GalleryApp(initialDemo: demo, themeMode: themeModeFromEnvironment()),
    );
    await tester.pumpAndSettle();
    await runDemoScript(
      tester,
      demo,
      pace: (duration) async {
        await Future<void>.delayed(duration);
        await tester.pumpAndSettle();
      },
    );
  });
}
```

Run: `cd example && flutter analyze --fatal-infos`
Expected: `No issues found!`.

If a Windows desktop toolchain is available (`flutter devices` lists `windows`), also run `cd example && flutter test integration_test/demo_script_test.dart -d windows --dart-define=DEMO=team`. Expected: `All tests passed!`. If no desktop device is available, record that in the report; the fake-time run of the same scripts in `test/demo_script_test.dart` is the CI check.

- [ ] **Step 3: Add the `example-tests` CI job**

In `.github/workflows/ci.yml`, add this job after the `example` job:

```yaml
  example-tests:
    name: Example tests
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: example
    steps:
      - uses: actions/checkout@v5
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true
      - run: flutter pub get
      - name: Analyze example
        run: flutter analyze --fatal-infos
      - name: Test example (gallery + demo scripts in fake time)
        run: flutter test
```

Run: `python -c "import yaml;yaml.safe_load(open('.github/workflows/ci.yml'));print('ok')"`
Expected: `ok`.

- [ ] **Step 4: Replace `example/README.md`**

````markdown
# flutter_chat_reactions — showcase gallery

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
````

- [ ] **Step 5: Full verification**

Run:
```bash
dart format --output=none --set-exit-if-changed . && flutter analyze --fatal-infos && flutter test && (cd example && flutter analyze --fatal-infos && flutter test && flutter build web)
```
Expected: every command exits 0. The package's own tests are untouched and still pass. The example suite includes six `demo script: <slug>` tests.

- [ ] **Step 6: Commit**

```bash
dart format .
git add example/integration_test/demo_script_test.dart example/test/gallery_test.dart example/README.md .github/workflows/ci.yml
git commit -m "feat(example): Add real-time demo runner, example CI job, and gallery README

Co-Authored-By: <committing model> <noreply@anthropic.com>"
```
