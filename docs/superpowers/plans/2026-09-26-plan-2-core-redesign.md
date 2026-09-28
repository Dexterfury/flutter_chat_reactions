# Plan 2 of 4 — Core Redesign (1.0.0 API) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the 0.2.x API with the layered 1.0.0 design:
- app-owned data models;
- an optional controller;
- an adaptive `ThemeExtension`;
- building-block widgets;
- four presenters;
- `ReactableMessage` and `ReactionsSummaryView`.

All of it is test-driven, with ≥ 90% line coverage and no third-party runtime dependencies.

**Architecture:** `ReactableMessage` detects a trigger (long-press, double-tap, right-click, hover, keyboard, or semantics action), measures its child, and hands a `ReactionsMenuContext` to a `ReactionsPresenter`. The built-in presenters push a transparent `PopupRoute` on the root navigator, which gives Android back, Escape, barrier dismissal and focus trapping for free, and compose the public building blocks (`ReactionBar`, `ReactionActionMenu`, `AnchoredLayout`). Styling resolves in this order: widget argument → `ChatReactionsTheme` extension → adaptive defaults derived from `ColorScheme`/`TextTheme` and the platform.

**Tech Stack:** Dart ^3.8 / Flutter ≥ 3.32, `flutter_test`. No runtime packages besides `flutter`.

**Spec:** `docs/superpowers/specs/2026-09-26-v1-modernization-design.md`

**Prerequisite:** Plan 1 is merged into this branch (CI workflows exist, `tool/check_coverage.dart` exists, SDK floor is 3.32).

## Global Constraints

- `pubspec.yaml` runtime `dependencies:` contains only `flutter: sdk: flutter`.
- SDK: `sdk: ^3.8.0`, `flutter: ">=3.32.0"`.
- Every public member has a `///` doc comment (the `public_member_api_docs` lint is enabled in Task 1).
- Padding uses `EdgeInsetsDirectional` wherever left and right differ; alignment uses `ReactionAlignment.start/end`, never left/right.
- Internal-only files (not exported from the barrel): `lib/src/models/equality.dart`, `lib/src/presenters/menu_route.dart`, `lib/src/theme/adaptive.dart` (only its enums are exported).
- The default quick reactions are exactly `['👍', '❤️', '😂', '😮', '😢', '🙏']`.
- Default durations are 220 ms with `Curves.easeOutCubic`, and the bar stagger is 30 ms per item.
- Commit messages use Conventional Commits and end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Breaking-change commits use `feat!:` or `refactor!:`.
- `flutter analyze --fatal-infos` fails on `unused_import` and `unnecessary_import`. The plan's imports were checked against the Flutter 3.44 export lists: `material.dart` does not re-export `listEquals`, `defaultTargetPlatform`, `CustomSemanticsAction`, `SchedulerBinding`, `lerpDouble` or `ImageFilter`. If a different SDK version reports an import problem, fix only the import line.
- Run tests with `flutter test` from the repository root. Every task ends with `flutter analyze --fatal-infos` clean and all tests passing.

### Deviations from the spec, recorded in Task 1

1. **Presenters push a transparent `PopupRoute` on the root navigator** instead of an `OverlayEntry`/`OverlayPortal`. `WidgetsBinding.handlePopRoute` gives the Android back button to observers in registration order, so the app's `Navigator` would pop the page behind an overlay entry. A route gets back, Escape (`DismissIntent`), barrier dismissal and focus scoping from `ModalRoute`. There is still no Hero, so the tag collisions stay fixed. Because the modal barrier absorbs scroll input, "dismiss on scroll" is replaced by "the list cannot scroll while the menu is open" (same as iOS). Dismiss on metrics change is kept.
2. **`CustomPresenter.builder` receives an `Animation<double>`** as a third argument.
3. **`ReactionChipStyle` uses `borderRadius`** (`BorderRadiusGeometry?`) instead of `shape`.
4. **`ReactionOverlayStyle.messageShadows` defaults to `[]`.** A rectangular shadow around a rounded bubble looks wrong; apps can opt in.
5. **Default triggers depend on `TargetPlatform`, not `kIsWeb`,** so mobile web behaves like a touch device.

---

## File Map

```
lib/flutter_chat_reactions.dart                    barrel (exports only)
lib/src/models/equality.dart                        internal list/map equality helpers
lib/src/models/reaction_user.dart                   ReactionUser
lib/src/models/reaction_summary.dart                ReactionSummary
lib/src/models/reaction.dart                        Reaction, ReactionSort, ReactionListX.summarize
lib/src/models/reaction_action.dart                 ReactionAction<T>
lib/src/models/reaction_policy.dart                 ReactionPolicy (sealed), Single/Multiple
lib/src/controller/reaction_change.dart             ReactionChange (sealed) + Added/Removed/Replaced
lib/src/controller/reactions_controller.dart        ReactionsController, ReactionBinding
lib/src/theme/adaptive.dart                         ReactionsVisualStyle, ReactionHaptics, platform helpers, haptic call
lib/src/theme/reaction_styles.dart                  ReactionBarStyle, ReactionMenuStyle, ReactionChipStyle, ReactionOverlayStyle
lib/src/theme/chat_reactions_theme.dart             ChatReactionsTheme (ThemeExtension)
lib/src/l10n/chat_reactions_localizations.dart      ChatReactionsLocalizations + English default + delegate
lib/src/layout/reaction_alignment.dart              ReactionAlignment
lib/src/layout/anchored_layout.dart                 AnchoredLayout
lib/src/widgets/emoji.dart                          EmojiBuilder typedef, defaultEmojiBuilder
lib/src/widgets/reaction_bar.dart                   ReactionBar
lib/src/widgets/reaction_action_menu.dart           ReactionActionMenu
lib/src/widgets/reaction_details.dart               ReactionDetailsList, ReactionDetailsSheet, showReactionDetails
lib/src/widgets/reactions_summary_view.dart         ReactionSummaryLayout, ReactionsSummaryView
lib/src/trigger/reaction_trigger.dart               ReactionTrigger, defaultReactionTriggers
lib/src/trigger/chat_reactions_scope.dart           ChatReactionsScope, kDefaultQuickReactions, typedefs
lib/src/trigger/reactable_message.dart              ReactableMessage
lib/src/presenters/reactions_menu_context.dart      ReactionsMenuContext
lib/src/presenters/reactions_presenter.dart         ReactionsPresenter (abstract)
lib/src/presenters/menu_route.dart                  ReactionsMenuRoute + showReactionsMenuRoute (internal)
lib/src/presenters/custom_presenter.dart            CustomPresenter
lib/src/presenters/bottom_sheet_presenter.dart      BottomSheetPresenter
lib/src/presenters/focused_overlay_presenter.dart   FocusedOverlayPresenter
lib/src/presenters/compact_bar_presenter.dart       CompactBarPresenter
test/helpers.dart                                   harness(), testMenu(), PresenterLauncher
test/models/*_test.dart, test/controller/*, test/theme/*, test/l10n/*, test/layout/*,
test/widgets/*, test/presenters/*, test/trigger/*, test/a11y/*, test/goldens/*
```

---

### Task 1: Clean slate — remove the 0.2.x API and dependencies, strict lints, stub example

**Files:**
- Delete: `lib/src/` (whole directory), `test/legacy_reactions_controller_test.dart`, `example/lib/models/`, `example/lib/widgets/`, `example/test/widget_test.dart`
- Modify: `lib/flutter_chat_reactions.dart`, `pubspec.yaml`, `analysis_options.yaml`, `example/lib/main.dart`, `example/analysis_options.yaml`, the spec
- Create: `test/analysis_options.yaml`, `tool/analysis_options.yaml`, `test/barrel_test.dart`

**Interfaces:**
- Consumes: Plan 1's state.
- Produces: an empty barrel with doc-commented header, strict lints, and a compiling example stub. Later tasks append `export` lines to the barrel in alphabetical order.

- [ ] **Step 1: Delete the old code and dependencies**

```bash
git rm -r -q lib/src test/legacy_reactions_controller_test.dart example/lib/models example/lib/widgets example/test/widget_test.dart
```

In `pubspec.yaml`, delete the `animate_do` and `emoji_picker_flutter` lines under `dependencies:`.

- [ ] **Step 2: Rewrite the barrel `lib/flutter_chat_reactions.dart`**

```dart
/// Reactions and context menus for chat messages.
///
/// Wrap a message in [ReactableMessage] to let users react to it, and show the
/// result with [ReactionsSummaryView]. Reaction data is owned by your app; the
/// optional [ReactionsController] covers apps without their own state layer.
library;
```

(Dartdoc resolves the bracket references once the exports exist. Until Task 12, `flutter analyze` may report `comment_references` infos only if that lint is enabled — it is not.)

- [ ] **Step 3: Strict analysis options**

Replace `analysis_options.yaml`:

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true

linter:
  rules:
    always_declare_return_types: true
    directives_ordering: true
    prefer_const_constructors: true
    prefer_const_declarations: true
    prefer_final_locals: true
    prefer_single_quotes: true
    public_member_api_docs: true
    unawaited_futures: true
    use_super_parameters: true
```

Create `test/analysis_options.yaml` and `tool/analysis_options.yaml` with identical content:

```yaml
include: ../analysis_options.yaml

linter:
  rules:
    public_member_api_docs: false
```

Replace `example/analysis_options.yaml`:

```yaml
include: package:flutter_lints/flutter.yaml
```

- [ ] **Step 4: Stub the example**

Replace `example/lib/main.dart`:

```dart
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
```

- [ ] **Step 5: Barrel smoke test (keeps every library in coverage)**

Create `test/barrel_test.dart`. Importing the barrel loads every exported library, so files without tests still show up in `lcov.info` and cannot inflate the coverage number.

```dart
// Importing the barrel is the point of this test: it pulls every exported
// library into coverage.
// ignore: unused_import
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('barrel library loads', () {
    expect(true, isTrue);
  });
}
```

- [ ] **Step 6: Record the plan deviations in the spec**

Append to the spec a section `## 16. Implementation deviations (Plan 2)` that copies the five numbered items from this plan's "Deviations from the spec" list word for word.

- [ ] **Step 7: Verify**

Run: `flutter pub get && (cd example && flutter pub get) && flutter analyze --fatal-infos && flutter test`
Expected: `No issues found!` and `All tests passed!` (one test). `pubspec.lock` no longer lists `emoji_picker_flutter`, `animate_do` or `shared_preferences`.

- [ ] **Step 8: Commit**

The example's regenerated plugin registrants legitimately change here, because `shared_preferences` is gone, so include them.

```bash
git add -A lib test tool pubspec.yaml analysis_options.yaml example docs/superpowers/specs
git commit -m "refactor!: Remove 0.2.x API and third-party dependencies ahead of 1.0.0

BREAKING CHANGE: ChatMessageWrapper, StackedReactions, ChatReactionsConfig,
MenuItem and the old ReactionsController are removed. See MIGRATION.md (Plan 4).

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Data models

**Files:**
- Create: `lib/src/models/equality.dart`, `lib/src/models/reaction_user.dart`, `lib/src/models/reaction_summary.dart`, `lib/src/models/reaction.dart`, `lib/src/models/reaction_action.dart`, `lib/src/models/reaction_policy.dart`
- Modify: `lib/flutter_chat_reactions.dart` (exports)
- Test: `test/models/reaction_user_test.dart`, `test/models/reaction_summary_test.dart`, `test/models/reaction_test.dart`, `test/models/reaction_action_test.dart`, `test/models/reaction_policy_test.dart`

**Interfaces:**
- Produces:
  - `ReactionUser({required String id, String? name, String? avatarUrl})` with `copyWith`, `toJson`, `fromJson`, `==`.
  - `ReactionSummary({required String emoji, required int count, bool reactedByMe = false, List<ReactionUser> users = const []})` with the same.
  - `Reaction({required String emoji, required String userId, String? userName, DateTime? createdAt, Map<String, Object?> extra = const {}})` with the same. `fromJson` also accepts the 0.2.x `timestamp` key.
  - `enum ReactionSort { countDesc, firstReacted, none }`.
  - `extension ReactionListX on Iterable<Reaction> { List<ReactionSummary> summarize({required String currentUserId, ReactionSort sort = ReactionSort.countDesc}) }`.
  - `ReactionAction<T>({required String id, required String label, IconData? icon, bool isDestructive = false, T? value})`, equal by `id`.
  - `sealed class ReactionPolicy` with `const ReactionPolicy.single()` → `SingleReactionPolicy` and `const ReactionPolicy.multiple({int? max})` → `MultipleReactionPolicy`.

- [ ] **Step 1: Write the failing tests**

`test/models/reaction_user_test.dart`:

```dart
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('JSON round trip omits null fields', () {
    const user = ReactionUser(id: 'u1', name: 'Ada');
    expect(user.toJson(), {'id': 'u1', 'name': 'Ada'});
    expect(ReactionUser.fromJson(user.toJson()), user);
  });

  test('value equality and copyWith', () {
    const a = ReactionUser(id: 'u1', name: 'Ada');
    expect(a, const ReactionUser(id: 'u1', name: 'Ada'));
    expect(a.hashCode, const ReactionUser(id: 'u1', name: 'Ada').hashCode);
    expect(a.copyWith(avatarUrl: 'x').avatarUrl, 'x');
    expect(a == a.copyWith(name: 'Bob'), isFalse);
  });
}
```

`test/models/reaction_summary_test.dart`:

```dart
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const summary = ReactionSummary(
    emoji: '👍',
    count: 2,
    reactedByMe: true,
    users: [ReactionUser(id: 'me'), ReactionUser(id: 'u2', name: 'Bo')],
  );

  test('JSON round trip', () {
    expect(ReactionSummary.fromJson(summary.toJson()), summary);
  });

  test('fromJson tolerates missing optional fields', () {
    final s = ReactionSummary.fromJson({'emoji': '🔥', 'count': 3});
    expect(s.reactedByMe, isFalse);
    expect(s.users, isEmpty);
  });

  test('equality includes users', () {
    expect(summary == summary.copyWith(users: const []), isFalse);
    expect(summary.copyWith(count: 5).count, 5);
  });

  test('count must be at least 1', () {
    expect(() => ReactionSummary(emoji: 'x', count: 0), throwsAssertionError);
  });
}
```

`test/models/reaction_test.dart`:

```dart
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

Reaction r(String emoji, String user, {int? minute, String? name}) => Reaction(
      emoji: emoji,
      userId: user,
      userName: name,
      createdAt: minute == null ? null : DateTime.utc(2026, 1, 1, 0, minute),
    );

void main() {
  group('Reaction JSON', () {
    test('round trip including extra', () {
      final reaction = Reaction(
        emoji: '👍',
        userId: 'u1',
        userName: 'Ada',
        createdAt: DateTime.utc(2026, 9, 26, 10),
        extra: const {'source': 'ios'},
      );
      expect(Reaction.fromJson(reaction.toJson()), reaction);
    });

    test('accepts the 0.2.x "timestamp" key', () {
      final reaction = Reaction.fromJson({
        'emoji': '👍',
        'userId': 'u1',
        'timestamp': '2026-09-26T10:00:00.000Z',
      });
      expect(reaction.createdAt, DateTime.utc(2026, 9, 26, 10));
    });

    test('equality considers extra', () {
      const a = Reaction(emoji: '👍', userId: 'u1', extra: {'k': 1});
      const b = Reaction(emoji: '👍', userId: 'u1', extra: {'k': 2});
      expect(a == b, isFalse);
      expect(a, const Reaction(emoji: '👍', userId: 'u1', extra: {'k': 1}));
    });
  });

  group('summarize', () {
    test('aggregates counts, users and reactedByMe', () {
      final summaries = [
        r('👍', 'u1', name: 'Ada'),
        r('❤️', 'me'),
        r('👍', 'me'),
      ].summarize(currentUserId: 'me');

      expect(summaries.map((s) => s.emoji), ['👍', '❤️']);
      expect(summaries.first.count, 2);
      expect(summaries.first.reactedByMe, isTrue);
      expect(summaries.first.users.first, const ReactionUser(id: 'u1', name: 'Ada'));
    });

    test('ignores duplicate reactions from the same user', () {
      final summaries = [r('👍', 'u1'), r('👍', 'u1')].summarize(currentUserId: 'me');
      expect(summaries.single.count, 1);
    });

    test('countDesc breaks ties by first appearance', () {
      final summaries = [
        r('😂', 'u1'),
        r('👍', 'u2'),
        r('👍', 'u3'),
        r('❤️', 'u4'),
      ].summarize(currentUserId: 'me');
      expect(summaries.map((s) => s.emoji), ['👍', '😂', '❤️']);
    });

    test('firstReacted orders by earliest createdAt, undated last', () {
      final summaries = [
        r('😂', 'u1'),
        r('👍', 'u2', minute: 5),
        r('❤️', 'u3', minute: 1),
      ].summarize(currentUserId: 'me', sort: ReactionSort.firstReacted);
      expect(summaries.map((s) => s.emoji), ['❤️', '👍', '😂']);
    });

    test('none keeps first-appearance order', () {
      final summaries = [r('😂', 'u1'), r('👍', 'u2'), r('👍', 'u3')]
          .summarize(currentUserId: 'me', sort: ReactionSort.none);
      expect(summaries.map((s) => s.emoji), ['😂', '👍']);
    });

    test('result is unmodifiable', () {
      final summaries = [r('👍', 'u1')].summarize(currentUserId: 'me');
      expect(() => summaries.add(summaries.first), throwsUnsupportedError);
    });
  });
}
```

`test/models/reaction_action_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('actions are equal by id only', () {
    const a = ReactionAction<int>(id: 'reply', label: 'Reply', icon: Icons.reply, value: 1);
    const b = ReactionAction<int>(id: 'reply', label: 'Antworten', value: 2);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a == const ReactionAction<int>(id: 'copy', label: 'Reply'), isFalse);
  });

  test('defaults', () {
    const a = ReactionAction<void>(id: 'x', label: 'X');
    expect(a.isDestructive, isFalse);
    expect(a.icon, isNull);
  });
}
```

`test/models/reaction_policy_test.dart`:

```dart
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('factories produce the concrete policies', () {
    expect(const ReactionPolicy.single(), isA<SingleReactionPolicy>());
    const multiple = ReactionPolicy.multiple(max: 3);
    expect(multiple, isA<MultipleReactionPolicy>());
    expect((multiple as MultipleReactionPolicy).max, 3);
  });

  test('multiple policies compare by max', () {
    expect(const MultipleReactionPolicy(max: 2), const MultipleReactionPolicy(max: 2));
    expect(const MultipleReactionPolicy() == const MultipleReactionPolicy(max: 2), isFalse);
  });

  test('max must be positive', () {
    expect(() => MultipleReactionPolicy(max: 0), throwsAssertionError);
  });
}
```

- [ ] **Step 2: Run the tests to confirm they fail**

Run: `flutter test test/models`
Expected: compilation errors such as `Undefined name 'ReactionUser'`.

- [ ] **Step 3: Implement**

`lib/src/models/equality.dart`:

```dart
/// Element-wise list equality. Internal; keeps models free of Flutter imports.
bool equalLists<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Key/value map equality. Internal.
bool equalMaps<K, V>(Map<K, V> a, Map<K, V> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (!b.containsKey(key) || a[key] != b[key]) return false;
  }
  return true;
}

/// Order-independent hash of a map. Internal.
int hashMap<K, V>(Map<K, V> map) => Object.hashAllUnordered(
      map.entries.map((e) => Object.hash(e.key, e.value)),
    );
```

`lib/src/models/reaction_user.dart`:

```dart
/// A user who reacted to a message.
class ReactionUser {
  /// Creates a reaction user.
  const ReactionUser({required this.id, this.name, this.avatarUrl});

  /// Creates a [ReactionUser] from JSON produced by [toJson].
  factory ReactionUser.fromJson(Map<String, Object?> json) => ReactionUser(
        id: json['id']! as String,
        name: json['name'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
      );

  /// Stable user identifier.
  final String id;

  /// Display name, if known.
  final String? name;

  /// Avatar image URL, if known.
  final String? avatarUrl;

  /// Returns a copy with the given fields replaced.
  ReactionUser copyWith({String? id, String? name, String? avatarUrl}) =>
      ReactionUser(
        id: id ?? this.id,
        name: name ?? this.name,
        avatarUrl: avatarUrl ?? this.avatarUrl,
      );

  /// Converts to JSON. Null fields are omitted.
  Map<String, Object?> toJson() => {
        'id': id,
        if (name != null) 'name': name,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      };

  @override
  bool operator ==(Object other) =>
      other is ReactionUser &&
      other.id == id &&
      other.name == name &&
      other.avatarUrl == avatarUrl;

  @override
  int get hashCode => Object.hash(id, name, avatarUrl);

  @override
  String toString() => 'ReactionUser($id, $name)';
}
```

`lib/src/models/reaction_summary.dart`:

```dart
import 'equality.dart';
import 'reaction_user.dart';

/// One aggregated reaction on a message: an emoji, how many users chose it,
/// and whether the current user is one of them.
///
/// This is the primary display input. Servers usually send aggregates, so
/// build these directly, or derive them from raw [Reaction]s with
/// `summarize`.
class ReactionSummary {
  /// Creates a reaction summary. [count] must be at least 1.
  const ReactionSummary({
    required this.emoji,
    required this.count,
    this.reactedByMe = false,
    this.users = const [],
  }) : assert(count >= 1, 'count must be at least 1');

  /// Creates a [ReactionSummary] from JSON produced by [toJson].
  factory ReactionSummary.fromJson(Map<String, Object?> json) =>
      ReactionSummary(
        emoji: json['emoji']! as String,
        count: (json['count']! as num).toInt(),
        reactedByMe: json['reactedByMe'] as bool? ?? false,
        users: [
          for (final user in json['users'] as List<Object?>? ?? const [])
            ReactionUser.fromJson(user! as Map<String, Object?>),
        ],
      );

  /// The emoji. Any string: a unicode emoji or an app-specific id such as
  /// `:party:` rendered through an `EmojiBuilder`.
  final String emoji;

  /// Number of users who reacted with [emoji].
  final int count;

  /// Whether the current user reacted with [emoji].
  final bool reactedByMe;

  /// Users who reacted. May be empty or partial (fewer than [count]).
  final List<ReactionUser> users;

  /// Returns a copy with the given fields replaced.
  ReactionSummary copyWith({
    String? emoji,
    int? count,
    bool? reactedByMe,
    List<ReactionUser>? users,
  }) =>
      ReactionSummary(
        emoji: emoji ?? this.emoji,
        count: count ?? this.count,
        reactedByMe: reactedByMe ?? this.reactedByMe,
        users: users ?? this.users,
      );

  /// Converts to JSON. `users` is omitted when empty.
  Map<String, Object?> toJson() => {
        'emoji': emoji,
        'count': count,
        'reactedByMe': reactedByMe,
        if (users.isNotEmpty) 'users': [for (final u in users) u.toJson()],
      };

  @override
  bool operator ==(Object other) =>
      other is ReactionSummary &&
      other.emoji == emoji &&
      other.count == count &&
      other.reactedByMe == reactedByMe &&
      equalLists(other.users, users);

  @override
  int get hashCode =>
      Object.hash(emoji, count, reactedByMe, Object.hashAll(users));

  @override
  String toString() => 'ReactionSummary($emoji × $count, mine: $reactedByMe)';
}
```

`lib/src/models/reaction.dart`:

```dart
import 'equality.dart';
import 'reaction_summary.dart';
import 'reaction_user.dart';

/// A single user's reaction to a message, for apps that store reactions
/// individually. Convert a list of these to display data with `summarize`.
class Reaction {
  /// Creates a reaction.
  const Reaction({
    required this.emoji,
    required this.userId,
    this.userName,
    this.createdAt,
    this.extra = const {},
  });

  /// Creates a [Reaction] from JSON produced by [toJson].
  ///
  /// Also accepts the 0.2.x `timestamp` key in place of `createdAt`.
  factory Reaction.fromJson(Map<String, Object?> json) {
    final created = json['createdAt'] ?? json['timestamp'];
    return Reaction(
      emoji: json['emoji']! as String,
      userId: json['userId']! as String,
      userName: json['userName'] as String?,
      createdAt: created == null ? null : DateTime.parse(created as String),
      extra: json['extra'] as Map<String, Object?>? ?? const {},
    );
  }

  /// The emoji (see [ReactionSummary.emoji]).
  final String emoji;

  /// Id of the user who reacted.
  final String userId;

  /// Display name of the user who reacted, if known.
  final String? userName;

  /// When the reaction was made, if known.
  final DateTime? createdAt;

  /// App-specific payload carried alongside the reaction.
  final Map<String, Object?> extra;

  /// Returns a copy with the given fields replaced.
  Reaction copyWith({
    String? emoji,
    String? userId,
    String? userName,
    DateTime? createdAt,
    Map<String, Object?>? extra,
  }) =>
      Reaction(
        emoji: emoji ?? this.emoji,
        userId: userId ?? this.userId,
        userName: userName ?? this.userName,
        createdAt: createdAt ?? this.createdAt,
        extra: extra ?? this.extra,
      );

  /// Converts to JSON. Null and empty fields are omitted.
  Map<String, Object?> toJson() => {
        'emoji': emoji,
        'userId': userId,
        if (userName != null) 'userName': userName,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (extra.isNotEmpty) 'extra': extra,
      };

  @override
  bool operator ==(Object other) =>
      other is Reaction &&
      other.emoji == emoji &&
      other.userId == userId &&
      other.userName == userName &&
      other.createdAt == createdAt &&
      equalMaps(other.extra, extra);

  @override
  int get hashCode =>
      Object.hash(emoji, userId, userName, createdAt, hashMap(extra));

  @override
  String toString() => 'Reaction($emoji by $userId)';
}

/// Ordering for [ReactionListX.summarize].
enum ReactionSort {
  /// Most reactions first; ties keep first-appearance order.
  countDesc,

  /// Earliest `createdAt` first; reactions without a date go last.
  firstReacted,

  /// First-appearance order.
  none,
}

/// Aggregation helpers for raw reactions.
extension ReactionListX on Iterable<Reaction> {
  /// Aggregates raw reactions into one [ReactionSummary] per emoji.
  ///
  /// Duplicate reactions (same user, same emoji) count once. The returned
  /// list is unmodifiable.
  List<ReactionSummary> summarize({
    required String currentUserId,
    ReactionSort sort = ReactionSort.countDesc,
  }) {
    final order = <String>[];
    final users = <String, List<ReactionUser>>{};
    final firstAt = <String, DateTime>{};
    final mine = <String>{};

    for (final reaction in this) {
      final list = users.putIfAbsent(reaction.emoji, () {
        order.add(reaction.emoji);
        return <ReactionUser>[];
      });
      if (list.any((u) => u.id == reaction.userId)) continue;
      list.add(ReactionUser(id: reaction.userId, name: reaction.userName));
      if (reaction.userId == currentUserId) mine.add(reaction.emoji);
      final at = reaction.createdAt;
      if (at != null) {
        final previous = firstAt[reaction.emoji];
        if (previous == null || at.isBefore(previous)) {
          firstAt[reaction.emoji] = at;
        }
      }
    }

    final indexed = <(int, ReactionSummary)>[
      for (var i = 0; i < order.length; i++)
        (
          i,
          ReactionSummary(
            emoji: order[i],
            count: users[order[i]]!.length,
            reactedByMe: mine.contains(order[i]),
            users: List.unmodifiable(users[order[i]]!),
          ),
        ),
    ];

    int byIndex((int, ReactionSummary) a, (int, ReactionSummary) b) =>
        a.$1.compareTo(b.$1);

    switch (sort) {
      case ReactionSort.countDesc:
        indexed.sort((a, b) {
          final byCount = b.$2.count.compareTo(a.$2.count);
          return byCount != 0 ? byCount : byIndex(a, b);
        });
      case ReactionSort.firstReacted:
        indexed.sort((a, b) {
          final ta = firstAt[a.$2.emoji];
          final tb = firstAt[b.$2.emoji];
          if (ta != null && tb != null) {
            final byTime = ta.compareTo(tb);
            if (byTime != 0) return byTime;
          } else if (ta != null) {
            return -1;
          } else if (tb != null) {
            return 1;
          }
          return byIndex(a, b);
        });
      case ReactionSort.none:
        break;
    }

    return List.unmodifiable([for (final entry in indexed) entry.$2]);
  }
}
```

`lib/src/models/reaction_action.dart`:

```dart
import 'package:flutter/widgets.dart';

/// An item in a message's context menu (Reply, Copy, Delete, ...).
///
/// Actions are identified by [id]; two actions with the same id are equal
/// regardless of label, so localized labels never break matching.
@immutable
class ReactionAction<T> {
  /// Creates a context-menu action.
  const ReactionAction({
    required this.id,
    required this.label,
    this.icon,
    this.isDestructive = false,
    this.value,
  });

  /// Stable identifier used for matching in `onActionSelected`.
  final String id;

  /// Text shown in the menu.
  final String label;

  /// Optional icon shown next to [label].
  final IconData? icon;

  /// Whether the action is destructive (rendered in the theme's destructive color).
  final bool isDestructive;

  /// Optional app-specific payload.
  final T? value;

  @override
  bool operator ==(Object other) => other is ReactionAction && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ReactionAction($id)';
}
```

`lib/src/models/reaction_policy.dart`:

```dart
/// How many reactions one user may leave on a message. Used by
/// `ReactionsController`; the widgets only report what was tapped.
sealed class ReactionPolicy {
  const ReactionPolicy();

  /// One reaction per user; choosing another emoji replaces the previous one,
  /// choosing the same emoji removes it (WhatsApp, iMessage).
  const factory ReactionPolicy.single() = SingleReactionPolicy;

  /// Any number of distinct reactions per user, optionally capped by [max]
  /// (Slack, Discord).
  const factory ReactionPolicy.multiple({int? max}) = MultipleReactionPolicy;
}

/// See [ReactionPolicy.single].
final class SingleReactionPolicy extends ReactionPolicy {
  /// Creates the single-reaction policy.
  const SingleReactionPolicy();

  @override
  bool operator ==(Object other) => other is SingleReactionPolicy;

  @override
  int get hashCode => (SingleReactionPolicy).hashCode;
}

/// See [ReactionPolicy.multiple].
final class MultipleReactionPolicy extends ReactionPolicy {
  /// Creates the multiple-reaction policy. [max], when given, must be > 0.
  const MultipleReactionPolicy({this.max})
      : assert(max == null || max > 0, 'max must be positive');

  /// Maximum distinct reactions per user, or null for unlimited.
  final int? max;

  @override
  bool operator ==(Object other) =>
      other is MultipleReactionPolicy && other.max == max;

  @override
  int get hashCode => Object.hash(MultipleReactionPolicy, max);
}
```

Append to the barrel `lib/flutter_chat_reactions.dart`:

```dart

export 'src/models/reaction.dart';
export 'src/models/reaction_action.dart';
export 'src/models/reaction_policy.dart';
export 'src/models/reaction_summary.dart';
export 'src/models/reaction_user.dart';
```

- [ ] **Step 4: Run the tests**

Run: `flutter test test/models && flutter analyze --fatal-infos`
Expected: all tests pass and `No issues found!`.

- [ ] **Step 5: Commit**

```bash
git add lib test/models
git commit -m "feat!: Add immutable reaction data models and summarize()

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Optional `ReactionsController` with policies and optimistic rollback

**Files:**
- Create: `lib/src/controller/reaction_change.dart`, `lib/src/controller/reactions_controller.dart`
- Modify: barrel
- Test: `test/controller/reactions_controller_test.dart`

**Interfaces:**
- Consumes: `Reaction`, `ReactionSummary`, `ReactionSort`, `summarize`, `ReactionPolicy`, `SingleReactionPolicy`, `MultipleReactionPolicy` (Task 2).
- Produces:
  - `sealed class ReactionChange { String messageId; String emoji; }` with `ReactionAdded`, `ReactionRemoved`, and `ReactionReplaced` (which adds `previousEmoji`), all constructed with named args.
  - `class ReactionBinding { final List<ReactionSummary> reactions; final ValueChanged<String> onReactionSelected; }`.
  - `ReactionsController({required String currentUserId, String? currentUserName, ReactionPolicy policy = const ReactionPolicy.single(), Future<void> Function(ReactionChange)? onChange, ReactionSort sort = ReactionSort.countDesc})` with:
    - `reactionsFor(String)`
    - `summariesFor(String)`
    - `hasReacted(String, String)`
    - `setReactions(String, Iterable<Reaction>)`
    - `Future<void> toggle/add/remove(String messageId, String emoji)`
    - `clear([String?])`
    - `bind(String)`

- [ ] **Step 1: Write the failing tests**

`test/controller/reactions_controller_test.dart`:

```dart
import 'dart:async';

import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late int notifications;

  ReactionsController make({
    ReactionPolicy policy = const ReactionPolicy.single(),
    Future<void> Function(ReactionChange)? onChange,
  }) {
    notifications = 0;
    final c = ReactionsController(
      currentUserId: 'me',
      currentUserName: 'Me',
      policy: policy,
      onChange: onChange,
    )..addListener(() => notifications++);
    addTearDown(c.dispose);
    return c;
  }

  group('single policy', () {
    test('add, replace, remove via toggle', () async {
      final changes = <ReactionChange>[];
      final c = make(onChange: (change) async => changes.add(change));

      await c.toggle('m1', '👍');
      await c.toggle('m1', '❤️');
      await c.toggle('m1', '❤️');

      expect(changes, [
        const ReactionAdded(messageId: 'm1', emoji: '👍'),
        const ReactionReplaced(messageId: 'm1', emoji: '❤️', previousEmoji: '👍'),
        const ReactionRemoved(messageId: 'm1', emoji: '❤️'),
      ]);
      expect(c.summariesFor('m1'), isEmpty);
      expect(notifications, 3);
    });

    test('keeps other users reactions', () async {
      final c = make();
      c.setReactions('m1', const [Reaction(emoji: '👍', userId: 'u2')]);
      await c.toggle('m1', '👍');

      final summary = c.summariesFor('m1').single;
      expect(summary.count, 2);
      expect(summary.reactedByMe, isTrue);
      expect(summary.users.map((u) => u.name), contains('Me'));
    });

    test('add is a no-op when already reacted', () async {
      final c = make();
      await c.add('m1', '👍');
      final before = notifications;
      await c.add('m1', '👍');
      expect(notifications, before);
    });
  });

  group('multiple policy', () {
    test('toggles emojis independently', () async {
      final c = make(policy: const ReactionPolicy.multiple());
      await c.toggle('m1', '👍');
      await c.toggle('m1', '❤️');
      expect(c.summariesFor('m1').map((s) => s.emoji), ['👍', '❤️']);
      await c.toggle('m1', '👍');
      expect(c.summariesFor('m1').map((s) => s.emoji), ['❤️']);
    });

    test('respects max silently', () async {
      final changes = <ReactionChange>[];
      final c = make(
        policy: const ReactionPolicy.multiple(max: 1),
        onChange: (change) async => changes.add(change),
      );
      await c.add('m1', '👍');
      await c.add('m1', '❤️');
      expect(c.hasReacted('m1', '❤️'), isFalse);
      expect(changes, hasLength(1));
    });
  });

  group('optimistic updates', () {
    test('applies immediately, then rolls back and rethrows on failure', () async {
      final gate = Completer<void>();
      final c = make(onChange: (_) => gate.future);

      final pending = c.toggle('m1', '👍');
      expect(c.hasReacted('m1', '👍'), isTrue, reason: 'optimistic');

      gate.completeError(StateError('offline'));
      await expectLater(pending, throwsStateError);
      expect(c.hasReacted('m1', '👍'), isFalse, reason: 'rolled back');
    });

    test('does not roll back over a newer change', () async {
      final first = Completer<void>();
      var call = 0;
      final c = make(onChange: (_) => call++ == 0 ? first.future : Future.value());

      final pending = c.toggle('m1', '👍');
      await c.toggle('m1', '❤️');
      first.completeError(StateError('late failure'));
      await expectLater(pending, throwsStateError);
      expect(c.hasReacted('m1', '❤️'), isTrue);
    });
  });

  test('never exposes internal lists', () {
    final c = make();
    final source = [const Reaction(emoji: '👍', userId: 'u2')];
    c.setReactions('m1', source);
    source.clear();
    expect(c.reactionsFor('m1'), hasLength(1));
    expect(() => c.reactionsFor('m1').clear(), throwsUnsupportedError);
  });

  test('clear one message or all', () async {
    final c = make();
    await c.add('m1', '👍');
    await c.add('m2', '👍');
    c.clear('m1');
    expect(c.summariesFor('m1'), isEmpty);
    expect(c.summariesFor('m2'), hasLength(1));
    c.clear();
    expect(c.summariesFor('m2'), isEmpty);
  });

  test('bind returns current summaries and a toggling callback', () async {
    final c = make(onChange: (_) async => throw StateError('ignored by bind'));
    final binding = c.bind('m1');
    expect(binding.reactions, isEmpty);

    binding.onReactionSelected('👍');
    await Future<void>.delayed(Duration.zero);
    // onChange failed, so the optimistic add was rolled back; no uncaught error.
    expect(c.hasReacted('m1', '👍'), isFalse);
  });

  test('does not notify after dispose', () async {
    final c = ReactionsController(
      currentUserId: 'me',
      onChange: (_) => Future<void>.error(StateError('x')),
    );
    final pending = c.toggle('m1', '👍');
    c.dispose();
    await expectLater(pending, throwsStateError);
  });
}
```

- [ ] **Step 2: Run the tests to confirm they fail**

Run: `flutter test test/controller`
Expected: compilation error, `Undefined name 'ReactionsController'`.

- [ ] **Step 3: Implement**

`lib/src/controller/reaction_change.dart`:

```dart
/// A change the current user made, reported to `ReactionsController.onChange`
/// so the app can sync it to a backend.
sealed class ReactionChange {
  const ReactionChange({required this.messageId, required this.emoji});

  /// The message that changed.
  final String messageId;

  /// The emoji added, removed, or chosen as a replacement.
  final String emoji;

  @override
  bool operator ==(Object other) =>
      other.runtimeType == runtimeType &&
      other is ReactionChange &&
      other.messageId == messageId &&
      other.emoji == emoji;

  @override
  int get hashCode => Object.hash(runtimeType, messageId, emoji);
}

/// The current user added [emoji].
final class ReactionAdded extends ReactionChange {
  /// Creates an added change.
  const ReactionAdded({required super.messageId, required super.emoji});

  @override
  String toString() => 'ReactionAdded($messageId, $emoji)';
}

/// The current user removed [emoji].
final class ReactionRemoved extends ReactionChange {
  /// Creates a removed change.
  const ReactionRemoved({required super.messageId, required super.emoji});

  @override
  String toString() => 'ReactionRemoved($messageId, $emoji)';
}

/// The current user replaced [previousEmoji] with [emoji] (single policy).
final class ReactionReplaced extends ReactionChange {
  /// Creates a replaced change.
  const ReactionReplaced({
    required super.messageId,
    required super.emoji,
    required this.previousEmoji,
  });

  /// The emoji that was replaced.
  final String previousEmoji;

  @override
  bool operator ==(Object other) =>
      super == other &&
      other is ReactionReplaced &&
      other.previousEmoji == previousEmoji;

  @override
  int get hashCode => Object.hash(super.hashCode, previousEmoji);

  @override
  String toString() => 'ReactionReplaced($messageId, $previousEmoji → $emoji)';
}
```

`lib/src/controller/reactions_controller.dart`:

```dart
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/reaction.dart';
import '../models/reaction_policy.dart';
import '../models/reaction_summary.dart';
import 'reaction_change.dart';

/// Reactions and a selection callback for one message, ready to pass to
/// `ReactableMessage`. Produced by [ReactionsController.bind].
class ReactionBinding {
  /// Creates a binding.
  const ReactionBinding({
    required this.reactions,
    required this.onReactionSelected,
  });

  /// Current summaries for the message.
  final List<ReactionSummary> reactions;

  /// Toggles the tapped emoji for the current user.
  final ValueChanged<String> onReactionSelected;
}

/// An optional in-memory store of reactions, for apps without their own state
/// layer.
///
/// Changes are applied optimistically: listeners are notified immediately,
/// then [onChange] is awaited. If it throws, the message's previous state is
/// restored (unless a newer change has happened since) and the error is
/// rethrown.
class ReactionsController extends ChangeNotifier {
  /// Creates a controller for [currentUserId].
  ReactionsController({
    required this.currentUserId,
    this.currentUserName,
    this.policy = const ReactionPolicy.single(),
    this.onChange,
    this.sort = ReactionSort.countDesc,
  });

  /// The user whose reactions [add], [remove] and [toggle] modify.
  final String currentUserId;

  /// Display name stored on the current user's reactions.
  final String? currentUserName;

  /// How many reactions the current user may leave per message.
  final ReactionPolicy policy;

  /// Called after each local change; throw to roll the change back.
  final Future<void> Function(ReactionChange change)? onChange;

  /// Ordering used by [summariesFor].
  final ReactionSort sort;

  final Map<String, List<Reaction>> _reactions = {};
  bool _disposed = false;

  /// Raw reactions for [messageId] (unmodifiable).
  List<Reaction> reactionsFor(String messageId) =>
      List.unmodifiable(_reactions[messageId] ?? const <Reaction>[]);

  /// Aggregated reactions for [messageId] (unmodifiable).
  List<ReactionSummary> summariesFor(String messageId) =>
      (_reactions[messageId] ?? const <Reaction>[])
          .summarize(currentUserId: currentUserId, sort: sort);

  /// Whether the current user reacted to [messageId] with [emoji].
  bool hasReacted(String messageId, String emoji) =>
      _mine(messageId).contains(emoji);

  /// Replaces all reactions for [messageId], e.g. with data from a server.
  /// The iterable is copied.
  void setReactions(String messageId, Iterable<Reaction> reactions) {
    _reactions[messageId] = List.of(reactions);
    _notify();
  }

  /// Removes [emoji] if the current user reacted with it, otherwise adds it
  /// (subject to [policy]).
  Future<void> toggle(String messageId, String emoji) =>
      hasReacted(messageId, emoji)
          ? remove(messageId, emoji)
          : add(messageId, emoji);

  /// Adds [emoji] for the current user, subject to [policy].
  Future<void> add(String messageId, String emoji) async {
    final current = _reactions[messageId] ?? const <Reaction>[];
    final mine = _mine(messageId);
    if (mine.contains(emoji)) return;

    final reaction = Reaction(
      emoji: emoji,
      userId: currentUserId,
      userName: currentUserName,
      createdAt: DateTime.now(),
    );

    final List<Reaction> next;
    final ReactionChange change;
    switch (policy) {
      case SingleReactionPolicy():
        next = [
          ...current.where((r) => r.userId != currentUserId),
          reaction,
        ];
        change = mine.isEmpty
            ? ReactionAdded(messageId: messageId, emoji: emoji)
            : ReactionReplaced(
                messageId: messageId,
                emoji: emoji,
                previousEmoji: mine.first,
              );
      case MultipleReactionPolicy(:final max):
        if (max != null && mine.length >= max) return;
        next = [...current, reaction];
        change = ReactionAdded(messageId: messageId, emoji: emoji);
    }
    await _apply(messageId, next, change);
  }

  /// Removes the current user's [emoji] reaction, if present.
  Future<void> remove(String messageId, String emoji) async {
    if (!hasReacted(messageId, emoji)) return;
    final next = [
      for (final r in _reactions[messageId]!)
        if (!(r.userId == currentUserId && r.emoji == emoji)) r,
    ];
    await _apply(
      messageId,
      next,
      ReactionRemoved(messageId: messageId, emoji: emoji),
    );
  }

  /// Clears reactions for [messageId], or for every message when omitted.
  void clear([String? messageId]) {
    if (messageId == null) {
      _reactions.clear();
    } else {
      _reactions.remove(messageId);
    }
    _notify();
  }

  /// Returns the current summaries and a toggling callback for [messageId].
  ///
  /// Errors from [onChange] are swallowed here (the change is already rolled
  /// back); observe them in [onChange] itself.
  ReactionBinding bind(String messageId) => ReactionBinding(
        reactions: summariesFor(messageId),
        onReactionSelected: (emoji) => unawaited(
          toggle(messageId, emoji).catchError((Object _) {}),
        ),
      );

  List<String> _mine(String messageId) => [
        for (final r in _reactions[messageId] ?? const <Reaction>[])
          if (r.userId == currentUserId) r.emoji,
      ];

  Future<void> _apply(
    String messageId,
    List<Reaction> next,
    ReactionChange change,
  ) async {
    final hadEntry = _reactions.containsKey(messageId);
    final previous = _reactions[messageId];
    _reactions[messageId] = next;
    _notify();

    final callback = onChange;
    if (callback == null) return;
    try {
      await callback(change);
    } catch (_) {
      if (identical(_reactions[messageId], next)) {
        if (hadEntry) {
          _reactions[messageId] = previous!;
        } else {
          _reactions.remove(messageId);
        }
        _notify();
      }
      rethrow;
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
```

Append to the barrel, keeping the export block sorted:

```dart
export 'src/controller/reaction_change.dart';
export 'src/controller/reactions_controller.dart';
```

- [ ] **Step 4: Run the tests**

Run: `flutter test && flutter analyze --fatal-infos`
Expected: all tests pass and `No issues found!`.

- [ ] **Step 5: Commit**

```bash
git add lib test
git commit -m "feat!: Add ReactionsController with single/multiple policies and optimistic rollback

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Adaptive theme (`ChatReactionsTheme` + style classes)

**Files:**
- Create: `lib/src/theme/adaptive.dart`, `lib/src/theme/reaction_styles.dart`, `lib/src/theme/chat_reactions_theme.dart`
- Modify: barrel
- Test: `test/theme/chat_reactions_theme_test.dart`, `test/theme/reaction_styles_test.dart`

**Interfaces:**
- Produces:
  - `enum ReactionsVisualStyle { adaptive, material, cupertino }`, `enum ReactionHaptics { adaptive, none }`.
  - Internal helpers: `bool isCupertinoPlatform(TargetPlatform)`, `bool resolveCupertino(ReactionsVisualStyle, TargetPlatform)`, `void performReactionHaptic(ReactionHaptics, TargetPlatform)`.
  - Style classes, all fields nullable, each with `copyWith`, `merge(Other?)`, `static lerp(a, b, t)`, `==`:
    - `ReactionBarStyle{backgroundColor, highlightColor, shape, shadows, padding, emojiSize, itemSpacing}`
    - `ReactionMenuStyle{backgroundColor, shape, shadows, textStyle, iconColor, destructiveColor, dividerColor, minWidth, maxWidth, itemPadding}`
    - `ReactionChipStyle{backgroundColor, selectedBackgroundColor, border, selectedBorder, textStyle, selectedTextStyle, padding, borderRadius, emojiSize}`
    - `ReactionOverlayStyle{barrierColor, blurSigma, messageShadows, lift}`
  - `ChatReactionsTheme extends ThemeExtension<ChatReactionsTheme>`:
    - fields: `style`, `barStyle`, `menuStyle`, `chipStyle`, `overlayStyle`, `animationDuration`, `animationCurve`, `haptics`
    - factories: `fromColorScheme(ColorScheme, TextTheme, TargetPlatform, {style})`, `light({platform, style})`, `dark({platform, style})`
    - `merge`, `static ChatReactionsTheme of(BuildContext)`, which returns a fully resolved theme whose `style` is always `material` or `cupertino`
    - `bool get isCupertino`

- [ ] **Step 1: Write the failing tests**

`test/theme/chat_reactions_theme_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ChatReactionsTheme> resolve(
  WidgetTester tester, {
  TargetPlatform platform = TargetPlatform.android,
  Brightness brightness = Brightness.light,
  ChatReactionsTheme? extension,
  bool disableAnimations = false,
}) async {
  late ChatReactionsTheme resolved;
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Theme(
        data: ThemeData(
          platform: platform,
          brightness: brightness,
          extensions: [if (extension != null) extension],
        ),
        child: Builder(builder: (context) {
          resolved = ChatReactionsTheme.of(context);
          return const SizedBox();
        }),
      ),
    ),
  );
  return resolved;
}

void main() {
  testWidgets('adaptive: Cupertino on iOS and macOS, Material elsewhere', (tester) async {
    expect((await resolve(tester, platform: TargetPlatform.iOS)).isCupertino, isTrue);
    expect((await resolve(tester, platform: TargetPlatform.macOS)).isCupertino, isTrue);
    expect((await resolve(tester, platform: TargetPlatform.android)).isCupertino, isFalse);
    expect((await resolve(tester, platform: TargetPlatform.windows)).style, ReactionsVisualStyle.material);
  });

  testWidgets('style can be forced through the extension', (tester) async {
    final theme = await resolve(
      tester,
      platform: TargetPlatform.android,
      extension: const ChatReactionsTheme(style: ReactionsVisualStyle.cupertino),
    );
    expect(theme.isCupertino, isTrue);
  });

  testWidgets('Material defaults derive from the ColorScheme', (tester) async {
    final theme = await resolve(tester);
    final scheme = ThemeData().colorScheme;
    expect(theme.menuStyle.destructiveColor, scheme.error);
    expect(theme.chipStyle.selectedBackgroundColor, scheme.primaryContainer);
    expect(theme.animationDuration, const Duration(milliseconds: 220));
    expect(theme.animationCurve, Curves.easeOutCubic);
    expect(theme.haptics, ReactionHaptics.adaptive);
  });

  testWidgets('every style field is resolved (non-null)', (tester) async {
    for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
      for (final brightness in Brightness.values) {
        final t = await resolve(tester, platform: platform, brightness: brightness);
        final bar = t.barStyle;
        final menu = t.menuStyle;
        final chip = t.chipStyle;
        final overlay = t.overlayStyle;
        expect(
          [
            bar.backgroundColor, bar.highlightColor, bar.shape, bar.shadows,
            bar.padding, bar.emojiSize, bar.itemSpacing,
            menu.backgroundColor, menu.shape, menu.shadows, menu.textStyle,
            menu.iconColor, menu.destructiveColor, menu.dividerColor,
            menu.minWidth, menu.maxWidth, menu.itemPadding,
            chip.backgroundColor, chip.selectedBackgroundColor, chip.border,
            chip.selectedBorder, chip.textStyle, chip.selectedTextStyle,
            chip.padding, chip.borderRadius, chip.emojiSize,
            overlay.barrierColor, overlay.blurSigma, overlay.messageShadows,
            overlay.lift,
          ],
          everyElement(isNotNull),
          reason: '$platform $brightness',
        );
      }
    }
  });

  testWidgets('extension values override defaults field by field', (tester) async {
    final theme = await resolve(
      tester,
      extension: const ChatReactionsTheme(
        barStyle: ReactionBarStyle(emojiSize: 40),
        haptics: ReactionHaptics.none,
      ),
    );
    expect(theme.barStyle.emojiSize, 40);
    expect(theme.barStyle.backgroundColor, isNotNull, reason: 'kept default');
    expect(theme.haptics, ReactionHaptics.none);
  });

  testWidgets('disableAnimations zeroes the duration', (tester) async {
    final theme = await resolve(tester, disableAnimations: true);
    expect(theme.animationDuration, Duration.zero);
  });

  test('lerp interpolates numeric fields', () {
    const a = ChatReactionsTheme(barStyle: ReactionBarStyle(emojiSize: 20));
    const b = ChatReactionsTheme(barStyle: ReactionBarStyle(emojiSize: 40));
    expect(a.lerp(b, 0.5).barStyle.emojiSize, 30);
    expect(a.lerp(null, 0.5), same(a));
  });

  test('light() and dark() factories', () {
    expect(ChatReactionsTheme.light(platform: TargetPlatform.android).isCupertino, isFalse);
    final dark = ChatReactionsTheme.dark(platform: TargetPlatform.iOS);
    expect(dark.isCupertino, isTrue);
    expect(dark.barStyle.backgroundColor, const Color(0xFF2C2C2E));
  });
}
```

`test/theme/reaction_styles_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('merge: non-null fields of the argument win', () {
    const base = ReactionMenuStyle(minWidth: 200, maxWidth: 280, iconColor: Colors.red);
    final merged = base.merge(const ReactionMenuStyle(maxWidth: 300));
    expect(merged.minWidth, 200);
    expect(merged.maxWidth, 300);
    expect(merged.iconColor, Colors.red);
    expect(base.merge(null), same(base));
  });

  test('chip lerp handles null borders', () {
    const a = ReactionChipStyle(border: BorderSide(width: 2));
    const b = ReactionChipStyle();
    expect(ReactionChipStyle.lerp(a, b, 0.2)!.border, a.border);
    expect(ReactionChipStyle.lerp(a, b, 0.8)!.border, isNull);
  });

  test('overlay lerp', () {
    const a = ReactionOverlayStyle(blurSigma: 0, lift: 1);
    const b = ReactionOverlayStyle(blurSigma: 10, lift: 2);
    final mid = ReactionOverlayStyle.lerp(a, b, 0.5)!;
    expect(mid.blurSigma, 5);
    expect(mid.lift, 1.5);
  });

  test('bar equality', () {
    expect(const ReactionBarStyle(emojiSize: 1), const ReactionBarStyle(emojiSize: 1));
    expect(const ReactionBarStyle(emojiSize: 1) == const ReactionBarStyle(emojiSize: 2), isFalse);
  });
}
```

- [ ] **Step 2: Run the tests to confirm they fail**

Run: `flutter test test/theme`
Expected: compilation errors (`Undefined class 'ChatReactionsTheme'`).

- [ ] **Step 3: Implement `lib/src/theme/adaptive.dart`**

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Which visual language the package uses.
enum ReactionsVisualStyle {
  /// Cupertino on iOS and macOS, Material 3 elsewhere.
  adaptive,

  /// Material 3 everywhere.
  material,

  /// Cupertino everywhere.
  cupertino,
}

/// Haptic feedback on open and select.
enum ReactionHaptics {
  /// Selection click on iOS/macOS, light impact elsewhere.
  adaptive,

  /// No haptics.
  none,
}

/// Whether [platform] uses Apple conventions.
bool isCupertinoPlatform(TargetPlatform platform) =>
    platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;

/// Whether the Cupertino look applies for [style] on [platform].
bool resolveCupertino(ReactionsVisualStyle style, TargetPlatform platform) =>
    switch (style) {
      ReactionsVisualStyle.cupertino => true,
      ReactionsVisualStyle.material => false,
      ReactionsVisualStyle.adaptive => isCupertinoPlatform(platform),
    };

/// Whether [platform] is primarily touch-driven.
bool isTouchPlatform(TargetPlatform platform) =>
    platform == TargetPlatform.iOS ||
    platform == TargetPlatform.android ||
    platform == TargetPlatform.fuchsia;

/// Plays the haptic configured by [haptics] for [platform].
void performReactionHaptic(ReactionHaptics haptics, TargetPlatform platform) {
  if (haptics == ReactionHaptics.none) return;
  if (isCupertinoPlatform(platform)) {
    HapticFeedback.selectionClick();
  } else {
    HapticFeedback.lightImpact();
  }
}
```

- [ ] **Step 4: Implement `lib/src/theme/reaction_styles.dart`**

```dart
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

BorderSide? _lerpSide(BorderSide? a, BorderSide? b, double t) {
  if (a == null || b == null) return t < 0.5 ? a : b;
  return BorderSide.lerp(a, b, t);
}

/// Visual properties of `ReactionBar`.
@immutable
class ReactionBarStyle {
  /// Creates a bar style. Null fields fall back to the theme defaults.
  const ReactionBarStyle({
    this.backgroundColor,
    this.highlightColor,
    this.shape,
    this.shadows,
    this.padding,
    this.emojiSize,
    this.itemSpacing,
  });

  /// Bar fill color.
  final Color? backgroundColor;

  /// Circle behind emojis the current user already chose.
  final Color? highlightColor;

  /// Bar outline.
  final ShapeBorder? shape;

  /// Bar shadow.
  final List<BoxShadow>? shadows;

  /// Space between the bar edge and its items.
  final EdgeInsetsGeometry? padding;

  /// Emoji font size in logical pixels.
  final double? emojiSize;

  /// Horizontal gap between items.
  final double? itemSpacing;

  /// Returns a copy with the given fields replaced.
  ReactionBarStyle copyWith({
    Color? backgroundColor,
    Color? highlightColor,
    ShapeBorder? shape,
    List<BoxShadow>? shadows,
    EdgeInsetsGeometry? padding,
    double? emojiSize,
    double? itemSpacing,
  }) =>
      ReactionBarStyle(
        backgroundColor: backgroundColor ?? this.backgroundColor,
        highlightColor: highlightColor ?? this.highlightColor,
        shape: shape ?? this.shape,
        shadows: shadows ?? this.shadows,
        padding: padding ?? this.padding,
        emojiSize: emojiSize ?? this.emojiSize,
        itemSpacing: itemSpacing ?? this.itemSpacing,
      );

  /// Returns this style with [other]'s non-null fields applied on top.
  ReactionBarStyle merge(ReactionBarStyle? other) {
    if (other == null) return this;
    return copyWith(
      backgroundColor: other.backgroundColor,
      highlightColor: other.highlightColor,
      shape: other.shape,
      shadows: other.shadows,
      padding: other.padding,
      emojiSize: other.emojiSize,
      itemSpacing: other.itemSpacing,
    );
  }

  /// Linearly interpolates between two bar styles.
  static ReactionBarStyle? lerp(ReactionBarStyle? a, ReactionBarStyle? b, double t) {
    if (identical(a, b)) return a;
    return ReactionBarStyle(
      backgroundColor: Color.lerp(a?.backgroundColor, b?.backgroundColor, t),
      highlightColor: Color.lerp(a?.highlightColor, b?.highlightColor, t),
      shape: ShapeBorder.lerp(a?.shape, b?.shape, t),
      shadows: BoxShadow.lerpList(a?.shadows, b?.shadows, t),
      padding: EdgeInsetsGeometry.lerp(a?.padding, b?.padding, t),
      emojiSize: lerpDouble(a?.emojiSize, b?.emojiSize, t),
      itemSpacing: lerpDouble(a?.itemSpacing, b?.itemSpacing, t),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ReactionBarStyle &&
      other.backgroundColor == backgroundColor &&
      other.highlightColor == highlightColor &&
      other.shape == shape &&
      listEquals(other.shadows, shadows) &&
      other.padding == padding &&
      other.emojiSize == emojiSize &&
      other.itemSpacing == itemSpacing;

  @override
  int get hashCode => Object.hash(
        backgroundColor,
        highlightColor,
        shape,
        shadows == null ? null : Object.hashAll(shadows!),
        padding,
        emojiSize,
        itemSpacing,
      );
}

/// Visual properties of `ReactionActionMenu`.
@immutable
class ReactionMenuStyle {
  /// Creates a menu style. Null fields fall back to the theme defaults.
  const ReactionMenuStyle({
    this.backgroundColor,
    this.shape,
    this.shadows,
    this.textStyle,
    this.iconColor,
    this.destructiveColor,
    this.dividerColor,
    this.minWidth,
    this.maxWidth,
    this.itemPadding,
  });

  /// Menu fill color.
  final Color? backgroundColor;

  /// Menu outline.
  final ShapeBorder? shape;

  /// Menu shadow.
  final List<BoxShadow>? shadows;

  /// Label text style.
  final TextStyle? textStyle;

  /// Icon color for non-destructive actions.
  final Color? iconColor;

  /// Label and icon color for destructive actions.
  final Color? destructiveColor;

  /// Divider color between items (transparent hides dividers).
  final Color? dividerColor;

  /// Minimum menu width.
  final double? minWidth;

  /// Maximum menu width.
  final double? maxWidth;

  /// Padding inside each item.
  final EdgeInsetsGeometry? itemPadding;

  /// Returns a copy with the given fields replaced.
  ReactionMenuStyle copyWith({
    Color? backgroundColor,
    ShapeBorder? shape,
    List<BoxShadow>? shadows,
    TextStyle? textStyle,
    Color? iconColor,
    Color? destructiveColor,
    Color? dividerColor,
    double? minWidth,
    double? maxWidth,
    EdgeInsetsGeometry? itemPadding,
  }) =>
      ReactionMenuStyle(
        backgroundColor: backgroundColor ?? this.backgroundColor,
        shape: shape ?? this.shape,
        shadows: shadows ?? this.shadows,
        textStyle: textStyle ?? this.textStyle,
        iconColor: iconColor ?? this.iconColor,
        destructiveColor: destructiveColor ?? this.destructiveColor,
        dividerColor: dividerColor ?? this.dividerColor,
        minWidth: minWidth ?? this.minWidth,
        maxWidth: maxWidth ?? this.maxWidth,
        itemPadding: itemPadding ?? this.itemPadding,
      );

  /// Returns this style with [other]'s non-null fields applied on top.
  ReactionMenuStyle merge(ReactionMenuStyle? other) {
    if (other == null) return this;
    return copyWith(
      backgroundColor: other.backgroundColor,
      shape: other.shape,
      shadows: other.shadows,
      textStyle: textStyle?.merge(other.textStyle) ?? other.textStyle,
      iconColor: other.iconColor,
      destructiveColor: other.destructiveColor,
      dividerColor: other.dividerColor,
      minWidth: other.minWidth,
      maxWidth: other.maxWidth,
      itemPadding: other.itemPadding,
    );
  }

  /// Linearly interpolates between two menu styles.
  static ReactionMenuStyle? lerp(ReactionMenuStyle? a, ReactionMenuStyle? b, double t) {
    if (identical(a, b)) return a;
    return ReactionMenuStyle(
      backgroundColor: Color.lerp(a?.backgroundColor, b?.backgroundColor, t),
      shape: ShapeBorder.lerp(a?.shape, b?.shape, t),
      shadows: BoxShadow.lerpList(a?.shadows, b?.shadows, t),
      textStyle: TextStyle.lerp(a?.textStyle, b?.textStyle, t),
      iconColor: Color.lerp(a?.iconColor, b?.iconColor, t),
      destructiveColor: Color.lerp(a?.destructiveColor, b?.destructiveColor, t),
      dividerColor: Color.lerp(a?.dividerColor, b?.dividerColor, t),
      minWidth: lerpDouble(a?.minWidth, b?.minWidth, t),
      maxWidth: lerpDouble(a?.maxWidth, b?.maxWidth, t),
      itemPadding: EdgeInsetsGeometry.lerp(a?.itemPadding, b?.itemPadding, t),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ReactionMenuStyle &&
      other.backgroundColor == backgroundColor &&
      other.shape == shape &&
      listEquals(other.shadows, shadows) &&
      other.textStyle == textStyle &&
      other.iconColor == iconColor &&
      other.destructiveColor == destructiveColor &&
      other.dividerColor == dividerColor &&
      other.minWidth == minWidth &&
      other.maxWidth == maxWidth &&
      other.itemPadding == itemPadding;

  @override
  int get hashCode => Object.hash(
        backgroundColor,
        shape,
        shadows == null ? null : Object.hashAll(shadows!),
        textStyle,
        iconColor,
        destructiveColor,
        dividerColor,
        minWidth,
        maxWidth,
        itemPadding,
      );
}

/// Visual properties of the chips in `ReactionsSummaryView`.
@immutable
class ReactionChipStyle {
  /// Creates a chip style. Null fields fall back to the theme defaults.
  const ReactionChipStyle({
    this.backgroundColor,
    this.selectedBackgroundColor,
    this.border,
    this.selectedBorder,
    this.textStyle,
    this.selectedTextStyle,
    this.padding,
    this.borderRadius,
    this.emojiSize,
  });

  /// Chip fill color.
  final Color? backgroundColor;

  /// Chip fill color when the current user reacted.
  final Color? selectedBackgroundColor;

  /// Chip border.
  final BorderSide? border;

  /// Chip border when the current user reacted.
  final BorderSide? selectedBorder;

  /// Count text style.
  final TextStyle? textStyle;

  /// Count text style when the current user reacted.
  final TextStyle? selectedTextStyle;

  /// Padding inside a chip.
  final EdgeInsetsGeometry? padding;

  /// Chip corner radius.
  final BorderRadiusGeometry? borderRadius;

  /// Emoji size inside a chip.
  final double? emojiSize;

  /// Returns a copy with the given fields replaced.
  ReactionChipStyle copyWith({
    Color? backgroundColor,
    Color? selectedBackgroundColor,
    BorderSide? border,
    BorderSide? selectedBorder,
    TextStyle? textStyle,
    TextStyle? selectedTextStyle,
    EdgeInsetsGeometry? padding,
    BorderRadiusGeometry? borderRadius,
    double? emojiSize,
  }) =>
      ReactionChipStyle(
        backgroundColor: backgroundColor ?? this.backgroundColor,
        selectedBackgroundColor:
            selectedBackgroundColor ?? this.selectedBackgroundColor,
        border: border ?? this.border,
        selectedBorder: selectedBorder ?? this.selectedBorder,
        textStyle: textStyle ?? this.textStyle,
        selectedTextStyle: selectedTextStyle ?? this.selectedTextStyle,
        padding: padding ?? this.padding,
        borderRadius: borderRadius ?? this.borderRadius,
        emojiSize: emojiSize ?? this.emojiSize,
      );

  /// Returns this style with [other]'s non-null fields applied on top.
  ReactionChipStyle merge(ReactionChipStyle? other) {
    if (other == null) return this;
    return copyWith(
      backgroundColor: other.backgroundColor,
      selectedBackgroundColor: other.selectedBackgroundColor,
      border: other.border,
      selectedBorder: other.selectedBorder,
      textStyle: textStyle?.merge(other.textStyle) ?? other.textStyle,
      selectedTextStyle: selectedTextStyle?.merge(other.selectedTextStyle) ??
          other.selectedTextStyle,
      padding: other.padding,
      borderRadius: other.borderRadius,
      emojiSize: other.emojiSize,
    );
  }

  /// Linearly interpolates between two chip styles.
  static ReactionChipStyle? lerp(ReactionChipStyle? a, ReactionChipStyle? b, double t) {
    if (identical(a, b)) return a;
    return ReactionChipStyle(
      backgroundColor: Color.lerp(a?.backgroundColor, b?.backgroundColor, t),
      selectedBackgroundColor:
          Color.lerp(a?.selectedBackgroundColor, b?.selectedBackgroundColor, t),
      border: _lerpSide(a?.border, b?.border, t),
      selectedBorder: _lerpSide(a?.selectedBorder, b?.selectedBorder, t),
      textStyle: TextStyle.lerp(a?.textStyle, b?.textStyle, t),
      selectedTextStyle:
          TextStyle.lerp(a?.selectedTextStyle, b?.selectedTextStyle, t),
      padding: EdgeInsetsGeometry.lerp(a?.padding, b?.padding, t),
      borderRadius:
          BorderRadiusGeometry.lerp(a?.borderRadius, b?.borderRadius, t),
      emojiSize: lerpDouble(a?.emojiSize, b?.emojiSize, t),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ReactionChipStyle &&
      other.backgroundColor == backgroundColor &&
      other.selectedBackgroundColor == selectedBackgroundColor &&
      other.border == border &&
      other.selectedBorder == selectedBorder &&
      other.textStyle == textStyle &&
      other.selectedTextStyle == selectedTextStyle &&
      other.padding == padding &&
      other.borderRadius == borderRadius &&
      other.emojiSize == emojiSize;

  @override
  int get hashCode => Object.hash(
        backgroundColor,
        selectedBackgroundColor,
        border,
        selectedBorder,
        textStyle,
        selectedTextStyle,
        padding,
        borderRadius,
        emojiSize,
      );
}

/// Visual properties of the focused overlay (backdrop and lifted message).
@immutable
class ReactionOverlayStyle {
  /// Creates an overlay style. Null fields fall back to the theme defaults.
  const ReactionOverlayStyle({
    this.barrierColor,
    this.blurSigma,
    this.messageShadows,
    this.lift,
  });

  /// Tint painted over the page behind the menu.
  final Color? barrierColor;

  /// Backdrop blur strength (0 disables blur).
  final double? blurSigma;

  /// Shadow painted around the lifted message copy.
  final List<BoxShadow>? messageShadows;

  /// Scale applied to the lifted message copy.
  final double? lift;

  /// Returns a copy with the given fields replaced.
  ReactionOverlayStyle copyWith({
    Color? barrierColor,
    double? blurSigma,
    List<BoxShadow>? messageShadows,
    double? lift,
  }) =>
      ReactionOverlayStyle(
        barrierColor: barrierColor ?? this.barrierColor,
        blurSigma: blurSigma ?? this.blurSigma,
        messageShadows: messageShadows ?? this.messageShadows,
        lift: lift ?? this.lift,
      );

  /// Returns this style with [other]'s non-null fields applied on top.
  ReactionOverlayStyle merge(ReactionOverlayStyle? other) {
    if (other == null) return this;
    return copyWith(
      barrierColor: other.barrierColor,
      blurSigma: other.blurSigma,
      messageShadows: other.messageShadows,
      lift: other.lift,
    );
  }

  /// Linearly interpolates between two overlay styles.
  static ReactionOverlayStyle? lerp(
    ReactionOverlayStyle? a,
    ReactionOverlayStyle? b,
    double t,
  ) {
    if (identical(a, b)) return a;
    return ReactionOverlayStyle(
      barrierColor: Color.lerp(a?.barrierColor, b?.barrierColor, t),
      blurSigma: lerpDouble(a?.blurSigma, b?.blurSigma, t),
      messageShadows: BoxShadow.lerpList(a?.messageShadows, b?.messageShadows, t),
      lift: lerpDouble(a?.lift, b?.lift, t),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ReactionOverlayStyle &&
      other.barrierColor == barrierColor &&
      other.blurSigma == blurSigma &&
      listEquals(other.messageShadows, messageShadows) &&
      other.lift == lift;

  @override
  int get hashCode => Object.hash(
        barrierColor,
        blurSigma,
        messageShadows == null ? null : Object.hashAll(messageShadows!),
        lift,
      );
}
```

- [ ] **Step 5: Implement `lib/src/theme/chat_reactions_theme.dart`**

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'adaptive.dart';
import 'reaction_styles.dart';

/// Theme for every widget in this package, registered as a [ThemeExtension]:
///
/// ```dart
/// ThemeData(extensions: const [
///   ChatReactionsTheme(barStyle: ReactionBarStyle(emojiSize: 32)),
/// ])
/// ```
///
/// Unset fields fall back to adaptive defaults derived from the app's
/// [ColorScheme], [TextTheme] and platform. Read the resolved theme with
/// [ChatReactionsTheme.of].
class ChatReactionsTheme extends ThemeExtension<ChatReactionsTheme> {
  /// Creates a theme. Every field is optional.
  const ChatReactionsTheme({
    this.style,
    this.barStyle = const ReactionBarStyle(),
    this.menuStyle = const ReactionMenuStyle(),
    this.chipStyle = const ReactionChipStyle(),
    this.overlayStyle = const ReactionOverlayStyle(),
    this.animationDuration,
    this.animationCurve,
    this.haptics,
  });

  /// Fully populated defaults for [colorScheme], [textTheme] and [platform].
  factory ChatReactionsTheme.fromColorScheme(
    ColorScheme colorScheme,
    TextTheme textTheme,
    TargetPlatform platform, {
    ReactionsVisualStyle style = ReactionsVisualStyle.adaptive,
  }) =>
      resolveCupertino(style, platform)
          ? _cupertino(colorScheme)
          : _material(colorScheme, textTheme);

  /// Defaults for a light Material [ThemeData].
  factory ChatReactionsTheme.light({
    TargetPlatform? platform,
    ReactionsVisualStyle style = ReactionsVisualStyle.adaptive,
  }) {
    final data = ThemeData(brightness: Brightness.light);
    return ChatReactionsTheme.fromColorScheme(
      data.colorScheme,
      data.textTheme,
      platform ?? defaultTargetPlatform,
      style: style,
    );
  }

  /// Defaults for a dark Material [ThemeData].
  factory ChatReactionsTheme.dark({
    TargetPlatform? platform,
    ReactionsVisualStyle style = ReactionsVisualStyle.adaptive,
  }) {
    final data = ThemeData(brightness: Brightness.dark);
    return ChatReactionsTheme.fromColorScheme(
      data.colorScheme,
      data.textTheme,
      platform ?? defaultTargetPlatform,
      style: style,
    );
  }

  /// Visual language. Resolved themes are always `material` or `cupertino`.
  final ReactionsVisualStyle? style;

  /// Style of `ReactionBar`.
  final ReactionBarStyle barStyle;

  /// Style of `ReactionActionMenu`.
  final ReactionMenuStyle menuStyle;

  /// Style of `ReactionsSummaryView` chips.
  final ReactionChipStyle chipStyle;

  /// Style of the focused overlay.
  final ReactionOverlayStyle overlayStyle;

  /// Duration of open/close and chip animations.
  final Duration? animationDuration;

  /// Curve of open/close and chip animations.
  final Curve? animationCurve;

  /// Haptic feedback mode.
  final ReactionHaptics? haptics;

  /// Whether the resolved style is Cupertino.
  bool get isCupertino => style == ReactionsVisualStyle.cupertino;

  /// The fully resolved theme for [context]: adaptive defaults, overridden by
  /// any [ChatReactionsTheme] in [ThemeData.extensions]. Animation duration is
  /// zero when the platform requests reduced motion.
  static ChatReactionsTheme of(BuildContext context) {
    final theme = Theme.of(context);
    final extension = theme.extension<ChatReactionsTheme>();
    final base = ChatReactionsTheme.fromColorScheme(
      theme.colorScheme,
      theme.textTheme,
      theme.platform,
      style: extension?.style ?? ReactionsVisualStyle.adaptive,
    );
    var resolved =
        extension == null ? base : base.merge(extension).copyWith(style: base.style);
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      resolved = resolved.copyWith(animationDuration: Duration.zero);
    }
    return resolved;
  }

  /// Returns this theme with [other]'s non-null fields applied on top.
  ChatReactionsTheme merge(ChatReactionsTheme? other) {
    if (other == null) return this;
    return ChatReactionsTheme(
      style: other.style ?? style,
      barStyle: barStyle.merge(other.barStyle),
      menuStyle: menuStyle.merge(other.menuStyle),
      chipStyle: chipStyle.merge(other.chipStyle),
      overlayStyle: overlayStyle.merge(other.overlayStyle),
      animationDuration: other.animationDuration ?? animationDuration,
      animationCurve: other.animationCurve ?? animationCurve,
      haptics: other.haptics ?? haptics,
    );
  }

  @override
  ChatReactionsTheme copyWith({
    ReactionsVisualStyle? style,
    ReactionBarStyle? barStyle,
    ReactionMenuStyle? menuStyle,
    ReactionChipStyle? chipStyle,
    ReactionOverlayStyle? overlayStyle,
    Duration? animationDuration,
    Curve? animationCurve,
    ReactionHaptics? haptics,
  }) =>
      ChatReactionsTheme(
        style: style ?? this.style,
        barStyle: barStyle ?? this.barStyle,
        menuStyle: menuStyle ?? this.menuStyle,
        chipStyle: chipStyle ?? this.chipStyle,
        overlayStyle: overlayStyle ?? this.overlayStyle,
        animationDuration: animationDuration ?? this.animationDuration,
        animationCurve: animationCurve ?? this.animationCurve,
        haptics: haptics ?? this.haptics,
      );

  @override
  ChatReactionsTheme lerp(
    covariant ThemeExtension<ChatReactionsTheme>? other,
    double t,
  ) {
    if (other is! ChatReactionsTheme) return this;
    return ChatReactionsTheme(
      style: t < 0.5 ? style : other.style,
      barStyle: ReactionBarStyle.lerp(barStyle, other.barStyle, t)!,
      menuStyle: ReactionMenuStyle.lerp(menuStyle, other.menuStyle, t)!,
      chipStyle: ReactionChipStyle.lerp(chipStyle, other.chipStyle, t)!,
      overlayStyle:
          ReactionOverlayStyle.lerp(overlayStyle, other.overlayStyle, t)!,
      animationDuration: t < 0.5 ? animationDuration : other.animationDuration,
      animationCurve: t < 0.5 ? animationCurve : other.animationCurve,
      haptics: t < 0.5 ? haptics : other.haptics,
    );
  }

  static const Duration _duration = Duration(milliseconds: 220);

  static ChatReactionsTheme _material(ColorScheme cs, TextTheme tt) {
    return ChatReactionsTheme(
      style: ReactionsVisualStyle.material,
      barStyle: ReactionBarStyle(
        backgroundColor: cs.surfaceContainerHigh,
        highlightColor: cs.primaryContainer,
        shape: const StadiumBorder(),
        shadows: kElevationToShadow[3]!,
        padding: const EdgeInsets.all(6),
        emojiSize: 28,
        itemSpacing: 4,
      ),
      menuStyle: ReactionMenuStyle(
        backgroundColor: cs.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        shadows: kElevationToShadow[3]!,
        textStyle: (tt.bodyLarge ?? const TextStyle(fontSize: 16))
            .copyWith(color: cs.onSurface),
        iconColor: cs.onSurfaceVariant,
        destructiveColor: cs.error,
        dividerColor: Colors.transparent,
        minWidth: 200,
        maxWidth: 280,
        itemPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      chipStyle: ReactionChipStyle(
        backgroundColor: cs.surfaceContainerHighest,
        selectedBackgroundColor: cs.primaryContainer,
        border: BorderSide(color: cs.outlineVariant),
        selectedBorder: BorderSide(color: cs.primary),
        textStyle: (tt.labelMedium ?? const TextStyle(fontSize: 12)).copyWith(
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
        selectedTextStyle:
            (tt.labelMedium ?? const TextStyle(fontSize: 12)).copyWith(
          color: cs.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        borderRadius: BorderRadius.circular(999),
        emojiSize: 16,
      ),
      overlayStyle: ReactionOverlayStyle(
        barrierColor: cs.scrim.withValues(alpha: 0.32),
        blurSigma: 8,
        messageShadows: const [],
        lift: 1.03,
      ),
      animationDuration: _duration,
      animationCurve: Curves.easeOutCubic,
      haptics: ReactionHaptics.adaptive,
    );
  }

  static ChatReactionsTheme _cupertino(ColorScheme cs) {
    final dark = cs.brightness == Brightness.dark;
    final label = dark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    const shadow = [
      BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 4)),
    ];
    return ChatReactionsTheme(
      style: ReactionsVisualStyle.cupertino,
      barStyle: ReactionBarStyle(
        backgroundColor: dark ? const Color(0xFF2C2C2E) : const Color(0xFFFFFFFF),
        highlightColor: cs.primary.withValues(alpha: 0.18),
        shape: const StadiumBorder(),
        shadows: shadow,
        padding: const EdgeInsets.all(6),
        emojiSize: 30,
        itemSpacing: 2,
      ),
      menuStyle: ReactionMenuStyle(
        backgroundColor: dark ? const Color(0xFF2C2C2E) : const Color(0xFFF9F9F9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        shadows: shadow,
        textStyle: TextStyle(fontSize: 17, letterSpacing: -0.4, color: label),
        iconColor: label,
        destructiveColor: dark ? const Color(0xFFFF453A) : const Color(0xFFFF3B30),
        dividerColor: dark ? const Color(0x33FFFFFF) : const Color(0x1F000000),
        minWidth: 220,
        maxWidth: 280,
        itemPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      ),
      chipStyle: ReactionChipStyle(
        backgroundColor: dark ? const Color(0xFF3A3A3C) : const Color(0xFFE9E9EB),
        selectedBackgroundColor: cs.primary.withValues(alpha: 0.2),
        border: BorderSide.none,
        selectedBorder: BorderSide(color: cs.primary),
        textStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: dark ? const Color(0xFFEBEBF5) : const Color(0xFF3C3C43),
        ),
        selectedTextStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: cs.primary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        borderRadius: BorderRadius.circular(999),
        emojiSize: 16,
      ),
      overlayStyle: ReactionOverlayStyle(
        barrierColor: dark ? const Color(0x66000000) : const Color(0x33000000),
        blurSigma: 12,
        messageShadows: const [],
        lift: 1.04,
      ),
      animationDuration: _duration,
      animationCurve: Curves.easeOutCubic,
      haptics: ReactionHaptics.adaptive,
    );
  }
}
```

Append to the barrel:

```dart
export 'src/theme/adaptive.dart' show ReactionHaptics, ReactionsVisualStyle;
export 'src/theme/chat_reactions_theme.dart';
export 'src/theme/reaction_styles.dart';
```

- [ ] **Step 6: Run the tests**

Run: `flutter test && flutter analyze --fatal-infos`
Expected: all tests pass and `No issues found!`.

- [ ] **Step 7: Commit**

```bash
git add lib test/theme
git commit -m "feat!: Add adaptive ChatReactionsTheme ThemeExtension and style classes

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: Localizations

**Files:**
- Create: `lib/src/l10n/chat_reactions_localizations.dart`
- Modify: barrel
- Test: `test/l10n/chat_reactions_localizations_test.dart`

**Interfaces:**
- Produces:
  - `abstract class ChatReactionsLocalizations` with getters `openReactionsMenu`, `moreReactions`, `moreActions`, `dismissMenu`, `cancel`, `reactionsTitle`, `allReactions`, and methods `String reactionCount(int count)`, `String emojiLabel(String emoji)`.
  - `static const LocalizationsDelegate<ChatReactionsLocalizations> delegate` and `static ChatReactionsLocalizations of(BuildContext)`.
  - `class DefaultChatReactionsLocalizations` (English).
  - Task 13 changes `of` to check `ChatReactionsScope` first.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

class _German extends DefaultChatReactionsLocalizations {
  const _German();
  @override
  String get moreReactions => 'Weitere Reaktionen';
}

class _GermanDelegate extends LocalizationsDelegate<ChatReactionsLocalizations> {
  const _GermanDelegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<ChatReactionsLocalizations> load(Locale locale) async => const _German();
  @override
  bool shouldReload(_GermanDelegate old) => false;
}

void main() {
  const l10n = DefaultChatReactionsLocalizations();

  test('English defaults', () {
    expect(l10n.openReactionsMenu, 'Open reactions menu');
    expect(l10n.reactionCount(1), '1 reaction');
    expect(l10n.reactionCount(3), '3 reactions');
    expect(l10n.emojiLabel('👍'), 'thumbs up');
    expect(l10n.emojiLabel(':party:'), ':party:');
  });

  testWidgets('falls back to English without a delegate', (tester) async {
    late ChatReactionsLocalizations resolved;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
      resolved = ChatReactionsLocalizations.of(context);
      return const SizedBox();
    })));
    expect(resolved, isA<DefaultChatReactionsLocalizations>());
  });

  testWidgets('uses a registered delegate', (tester) async {
    late ChatReactionsLocalizations resolved;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        _GermanDelegate(),
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      home: Builder(builder: (context) {
        resolved = ChatReactionsLocalizations.of(context);
        return const SizedBox();
      }),
    ));
    expect(resolved.moreReactions, 'Weitere Reaktionen');
  });

  test('the package delegate loads English', () async {
    final loaded = await ChatReactionsLocalizations.delegate.load(const Locale('en'));
    expect(loaded.cancel, 'Cancel');
  });
}
```

Save as `test/l10n/chat_reactions_localizations_test.dart`.

- [ ] **Step 2: Run the test to confirm it fails**

Run: `flutter test test/l10n`
Expected: a compilation error.

- [ ] **Step 3: Implement `lib/src/l10n/chat_reactions_localizations.dart`**

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// User-facing strings used by this package.
///
/// Provide translations by subclassing [DefaultChatReactionsLocalizations] and
/// registering a [LocalizationsDelegate], or pass an instance to
/// `ChatReactionsScope.localizations`.
abstract class ChatReactionsLocalizations {
  /// Const constructor for subclasses.
  const ChatReactionsLocalizations();

  /// Semantics action that opens the reactions menu on a message.
  String get openReactionsMenu;

  /// Label of the "+" button that opens a full emoji picker.
  String get moreReactions;

  /// Label of the "⋯" button that reveals message actions.
  String get moreActions;

  /// Label of the barrier that dismisses the menu.
  String get dismissMenu;

  /// Cancel button in the Cupertino action sheet.
  String get cancel;

  /// Title of the reaction details sheet.
  String get reactionsTitle;

  /// "All" tab of the reaction details sheet.
  String get allReactions;

  /// Accessible description of a reaction count.
  String reactionCount(int count);

  /// Accessible name for [emoji]. Returns [emoji] itself when unknown.
  String emojiLabel(String emoji);

  /// English delegate. Register it in `MaterialApp.localizationsDelegates`
  /// (optional; English is used as a fallback anyway).
  static const LocalizationsDelegate<ChatReactionsLocalizations> delegate =
      _DefaultDelegate();

  /// The localizations for [context], falling back to English.
  static ChatReactionsLocalizations of(BuildContext context) =>
      Localizations.of<ChatReactionsLocalizations>(
        context,
        ChatReactionsLocalizations,
      ) ??
      const DefaultChatReactionsLocalizations();
}

/// English strings. Extend this to translate a subset of strings.
class DefaultChatReactionsLocalizations extends ChatReactionsLocalizations {
  /// Creates the English localizations.
  const DefaultChatReactionsLocalizations();

  static const Map<String, String> _names = {
    '👍': 'thumbs up',
    '👎': 'thumbs down',
    '❤️': 'red heart',
    '😂': 'face with tears of joy',
    '😮': 'face with open mouth',
    '😢': 'crying face',
    '😠': 'angry face',
    '🙏': 'folded hands',
    '🔥': 'fire',
    '🎉': 'party popper',
    '👏': 'clapping hands',
    '😍': 'smiling face with heart-eyes',
  };

  @override
  String get openReactionsMenu => 'Open reactions menu';

  @override
  String get moreReactions => 'More reactions';

  @override
  String get moreActions => 'More actions';

  @override
  String get dismissMenu => 'Dismiss';

  @override
  String get cancel => 'Cancel';

  @override
  String get reactionsTitle => 'Reactions';

  @override
  String get allReactions => 'All';

  @override
  String reactionCount(int count) =>
      count == 1 ? '1 reaction' : '$count reactions';

  @override
  String emojiLabel(String emoji) => _names[emoji] ?? emoji;
}

class _DefaultDelegate extends LocalizationsDelegate<ChatReactionsLocalizations> {
  const _DefaultDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<ChatReactionsLocalizations> load(Locale locale) =>
      SynchronousFuture(const DefaultChatReactionsLocalizations());

  @override
  bool shouldReload(_DefaultDelegate old) => false;
}
```

Append to the barrel: `export 'src/l10n/chat_reactions_localizations.dart';`

- [ ] **Step 4: Run and commit**

Run: `flutter test && flutter analyze --fatal-infos`
Expected: pass.

```bash
git add lib test/l10n
git commit -m "feat: Add ChatReactionsLocalizations with English defaults

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: `AnchoredLayout`

**Files:**
- Create: `lib/src/layout/reaction_alignment.dart`, `lib/src/layout/anchored_layout.dart`
- Modify: barrel
- Test: `test/layout/anchored_layout_test.dart`

**Interfaces:**
- Produces:
  - `enum ReactionAlignment { start, end }`.
  - `AnchoredLayout({Key? key, required Rect anchorRect, Widget? header, Widget? anchor, Widget? footer, ReactionAlignment alignment = ReactionAlignment.end, double spacing = 8, double margin = 12})`.
  - Behaviour when `anchor` is set:
    - The group (header, anchor, footer) starts with the header directly above `anchorRect.top`.
    - The group is translated vertically to fit the safe area.
    - The anchor gets a tight width of `anchorRect.width` and a maximum height of the remaining space, and scrolls when it is taller.
  - Behaviour when `anchor` is null:
    - The header goes above `anchorRect`, or flips below it.
    - The footer goes below `anchorRect.bottom`.
  - Horizontally, header and footer align to the anchor's end edge (the right edge in LTR) for `end`, or its start edge for `start`, and are clamped to the safe area.
  - `anchorRect` is in the coordinate space of the layout, which fills its parent (the overlay).

- [ ] **Step 1: Write the failing tests**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

const headerKey = Key('header');
const anchorKey = Key('anchor');
const footerKey = Key('footer');

Widget box(Key key, double w, double h) => SizedBox(key: key, width: w, height: h);

Future<void> pumpLayout(
  WidgetTester tester, {
  required Rect anchorRect,
  bool withAnchor = true,
  double anchorHeight = 60,
  ReactionAlignment alignment = ReactionAlignment.end,
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(size: Size(400, 800)),
      child: Directionality(
        textDirection: direction,
        child: AnchoredLayout(
          anchorRect: anchorRect,
          alignment: alignment,
          header: box(headerKey, 240, 48),
          anchor: withAnchor ? box(anchorKey, anchorRect.width, anchorHeight) : null,
          footer: box(footerKey, 220, 150),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('places header above and footer below a mid-screen anchor', (tester) async {
    const anchor = Rect.fromLTWH(150, 300, 200, 60);
    await pumpLayout(tester, anchorRect: anchor);

    final header = tester.getRect(find.byKey(headerKey));
    final message = tester.getRect(find.byKey(anchorKey));
    final footer = tester.getRect(find.byKey(footerKey));

    expect(message.topLeft, anchor.topLeft);
    expect(header.bottom, anchor.top - 8);
    expect(footer.top, anchor.bottom + 8);
    expect(header.right, anchor.right, reason: 'end-aligned in LTR');
    expect(footer.right, anchor.right);
  });

  testWidgets('shifts down when the anchor is near the top', (tester) async {
    await pumpLayout(tester, anchorRect: const Rect.fromLTWH(150, 10, 200, 60));
    expect(tester.getRect(find.byKey(headerKey)).top, 12);
    expect(tester.getRect(find.byKey(anchorKey)).top, 12 + 48 + 8);
  });

  testWidgets('shifts up when the anchor is near the bottom', (tester) async {
    await pumpLayout(tester, anchorRect: const Rect.fromLTWH(150, 740, 200, 60));
    expect(tester.getRect(find.byKey(footerKey)).bottom, 800 - 12);
  });

  testWidgets('limits and scrolls a very tall anchor', (tester) async {
    await pumpLayout(
      tester,
      anchorRect: const Rect.fromLTWH(150, 0, 200, 2000),
      anchorHeight: 2000,
    );
    final message = tester.getRect(find.byType(SingleChildScrollView));
    expect(message.height, 800 - 24 - 48 - 150 - 16);
  });

  testWidgets('start alignment uses the anchor start edge', (tester) async {
    const anchor = Rect.fromLTWH(20, 300, 200, 60);
    await pumpLayout(tester, anchorRect: anchor, alignment: ReactionAlignment.start);
    expect(tester.getRect(find.byKey(headerKey)).left, 20);
  });

  testWidgets('end alignment mirrors in RTL', (tester) async {
    const anchor = Rect.fromLTWH(20, 300, 200, 60);
    await pumpLayout(tester, anchorRect: anchor, direction: TextDirection.rtl);
    expect(tester.getRect(find.byKey(headerKey)).left, 20);
  });

  testWidgets('clamps horizontally inside the margin', (tester) async {
    await pumpLayout(
      tester,
      anchorRect: const Rect.fromLTWH(0, 300, 100, 60),
      alignment: ReactionAlignment.end,
    );
    expect(tester.getRect(find.byKey(headerKey)).left, 12);
  });

  testWidgets('without anchor: header flips below when there is no room above', (tester) async {
    const anchor = Rect.fromLTWH(150, 20, 200, 60);
    await pumpLayout(tester, anchorRect: anchor, withAnchor: false);
    expect(tester.getRect(find.byKey(headerKey)).top, anchor.bottom + 8);
    expect(find.byKey(anchorKey), findsNothing);
  });

  testWidgets('without anchor: header above when there is room', (tester) async {
    const anchor = Rect.fromLTWH(150, 300, 200, 60);
    await pumpLayout(tester, anchorRect: anchor, withAnchor: false);
    expect(tester.getRect(find.byKey(headerKey)).bottom, anchor.top - 8);
  });
}
```

Save as `test/layout/anchored_layout_test.dart`.

- [ ] **Step 2: Run the tests to confirm they fail**

Run: `flutter test test/layout`
Expected: compilation errors.

- [ ] **Step 3: Implement**

`lib/src/layout/reaction_alignment.dart`:

```dart
/// Which side of a message the reactions UI aligns to, relative to the
/// ambient text direction. Use [end] for the current user's messages and
/// [start] for others' in a typical chat.
enum ReactionAlignment {
  /// Leading edge (left in LTR, right in RTL).
  start,

  /// Trailing edge (right in LTR, left in RTL).
  end,
}
```

`lib/src/layout/anchored_layout.dart`:

```dart
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'reaction_alignment.dart';

enum _Slot { header, anchor, footer }

/// Lays out a [header] and [footer] around a rectangle (usually a message),
/// keeping everything inside the safe area.
///
/// With an [anchor], the group header→anchor→footer is placed at
/// [anchorRect] and translated vertically to fit; a too-tall anchor scrolls.
/// Without one, the header sits above [anchorRect] (or flips below) and the
/// footer below it.
///
/// [anchorRect] must be in this widget's coordinate space; the widget is
/// meant to fill an overlay.
class AnchoredLayout extends StatelessWidget {
  /// Creates an anchored layout.
  const AnchoredLayout({
    super.key,
    required this.anchorRect,
    this.header,
    this.anchor,
    this.footer,
    this.alignment = ReactionAlignment.end,
    this.spacing = 8,
    this.margin = 12,
  });

  /// The rectangle to anchor to.
  final Rect anchorRect;

  /// Widget placed above the anchor (e.g. the reaction bar).
  final Widget? header;

  /// Widget drawn at [anchorRect] (e.g. a copy of the message).
  final Widget? anchor;

  /// Widget placed below the anchor (e.g. the action menu).
  final Widget? footer;

  /// Horizontal alignment of [header] and [footer] relative to the anchor.
  final ReactionAlignment alignment;

  /// Vertical gap between the parts.
  final double spacing;

  /// Minimum distance from the safe-area edges.
  final double margin;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final insets = MediaQuery.viewInsetsOf(context);
    final safe = EdgeInsets.fromLTRB(
      padding.left + margin,
      padding.top + margin,
      padding.right + margin,
      math.max(padding.bottom, insets.bottom) + margin,
    );
    return CustomMultiChildLayout(
      delegate: _AnchoredLayoutDelegate(
        anchorRect: anchorRect,
        safe: safe,
        alignment: alignment,
        textDirection: Directionality.of(context),
        spacing: spacing,
      ),
      children: [
        if (header != null) LayoutId(id: _Slot.header, child: header!),
        if (anchor != null)
          LayoutId(
            id: _Slot.anchor,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: anchor,
            ),
          ),
        if (footer != null) LayoutId(id: _Slot.footer, child: footer!),
      ],
    );
  }
}

class _AnchoredLayoutDelegate extends MultiChildLayoutDelegate {
  _AnchoredLayoutDelegate({
    required this.anchorRect,
    required this.safe,
    required this.alignment,
    required this.textDirection,
    required this.spacing,
  });

  final Rect anchorRect;
  final EdgeInsets safe;
  final ReactionAlignment alignment;
  final TextDirection textDirection;
  final double spacing;

  @override
  void performLayout(Size size) {
    final area = safe.deflateRect(Offset.zero & size);
    final loose = BoxConstraints.loose(area.size);

    final hasHeader = hasChild(_Slot.header);
    final hasFooter = hasChild(_Slot.footer);
    final headerSize = hasHeader ? layoutChild(_Slot.header, loose) : Size.zero;
    final footerSize = hasFooter ? layoutChild(_Slot.footer, loose) : Size.zero;
    final headerGap = hasHeader ? spacing : 0.0;
    final footerGap = hasFooter ? spacing : 0.0;

    if (hasChild(_Slot.anchor)) {
      final maxAnchorHeight = math.max(
        0.0,
        area.height - headerSize.height - footerSize.height - headerGap - footerGap,
      );
      final width = math.min(anchorRect.width, area.width);
      final anchorSize = layoutChild(
        _Slot.anchor,
        BoxConstraints(minWidth: width, maxWidth: width, maxHeight: maxAnchorHeight),
      );
      final total = headerSize.height +
          headerGap +
          anchorSize.height +
          footerGap +
          footerSize.height;

      var y = (anchorRect.top - headerGap - headerSize.height)
          .clamp(area.top, math.max(area.top, area.bottom - total));
      if (hasHeader) {
        positionChild(_Slot.header, Offset(_x(headerSize.width, area), y));
        y += headerSize.height + headerGap;
      }
      final anchorX = anchorRect.left
          .clamp(area.left, math.max(area.left, area.right - anchorSize.width));
      positionChild(_Slot.anchor, Offset(anchorX, y));
      y += anchorSize.height + footerGap;
      if (hasFooter) {
        positionChild(_Slot.footer, Offset(_x(footerSize.width, area), y));
      }
      return;
    }

    if (hasHeader) {
      var y = anchorRect.top - spacing - headerSize.height;
      if (y < area.top) y = anchorRect.bottom + spacing;
      y = y.clamp(area.top, math.max(area.top, area.bottom - headerSize.height));
      positionChild(_Slot.header, Offset(_x(headerSize.width, area), y));
    }
    if (hasFooter) {
      final y = (anchorRect.bottom + spacing)
          .clamp(area.top, math.max(area.top, area.bottom - footerSize.height));
      positionChild(_Slot.footer, Offset(_x(footerSize.width, area), y));
    }
  }

  double _x(double width, Rect area) {
    final alignRight =
        (alignment == ReactionAlignment.end) == (textDirection == TextDirection.ltr);
    final x = alignRight ? anchorRect.right - width : anchorRect.left;
    return x.clamp(area.left, math.max(area.left, area.right - width));
  }

  @override
  bool shouldRelayout(_AnchoredLayoutDelegate old) =>
      old.anchorRect != anchorRect ||
      old.safe != safe ||
      old.alignment != alignment ||
      old.textDirection != textDirection ||
      old.spacing != spacing;
}
```

Append to the barrel:

```dart
export 'src/layout/anchored_layout.dart';
export 'src/layout/reaction_alignment.dart';
```

- [ ] **Step 4: Run and commit**

Run: `flutter test && flutter analyze --fatal-infos`
Expected: pass.

```bash
git add lib test/layout
git commit -m "feat: Add AnchoredLayout for safe-area-aware menu positioning

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 7: `ReactionBar` and `ReactionActionMenu` building blocks

**Files:**
- Create: `lib/src/widgets/emoji.dart`, `lib/src/widgets/reaction_bar.dart`, `lib/src/widgets/reaction_action_menu.dart`, `test/helpers.dart`
- Modify: barrel
- Test: `test/widgets/reaction_bar_test.dart`, `test/widgets/reaction_action_menu_test.dart`

**Interfaces:**
- Consumes: `ChatReactionsTheme.of`, `ReactionBarStyle`, `ReactionMenuStyle`, `ChatReactionsLocalizations.of`, `ReactionAction`.
- Produces:
  - `typedef EmojiBuilder = Widget Function(BuildContext context, String emoji, double size);` and `Widget defaultEmojiBuilder(BuildContext, String, double)`.
  - `ReactionBar({Key? key, required List<String> reactions, required ValueChanged<String> onSelected, Set<String> selected = const {}, VoidCallback? onMore, VoidCallback? onMoreActions, EmojiBuilder? emojiBuilder, ReactionBarStyle? style, bool animate = true})`.
  - `ReactionActionMenu({Key? key, required List<ReactionAction> actions, required ValueChanged<ReactionAction> onSelected, ReactionMenuStyle? style})`.
  - `test/helpers.dart`: `Widget harness(Widget child, {...})`.

- [ ] **Step 1: Create `test/helpers.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';

/// Wraps [child] in a MaterialApp with the given platform, brightness,
/// direction and accessibility settings.
Widget harness(
  Widget child, {
  TargetPlatform platform = TargetPlatform.android,
  Brightness brightness = Brightness.light,
  TextDirection textDirection = TextDirection.ltr,
  ChatReactionsTheme? reactionsTheme,
  double textScale = 1,
  bool disableAnimations = false,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: brightness,
      platform: platform,
      extensions: [if (reactionsTheme != null) reactionsTheme],
    ),
    builder: (context, app) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
        disableAnimations: disableAnimations,
      ),
      child: Directionality(textDirection: textDirection, child: app!),
    ),
    home: Scaffold(body: child),
  );
}
```

- [ ] **Step 2: Write the failing tests**

`test/widgets/reaction_bar_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  testWidgets('renders reactions and reports taps', (tester) async {
    String? tapped;
    await tester.pumpWidget(harness(Center(
      child: ReactionBar(
        reactions: const ['👍', '❤️'],
        onSelected: (e) => tapped = e,
      ),
    )));
    await tester.pumpAndSettle();

    expect(find.text('👍'), findsOneWidget);
    await tester.tap(find.text('❤️'));
    expect(tapped, '❤️');
  });

  testWidgets('more and more-actions buttons appear only with callbacks', (tester) async {
    var more = 0;
    var actions = 0;
    await tester.pumpWidget(harness(Center(
      child: ReactionBar(
        reactions: const ['👍'],
        onSelected: (_) {},
        onMore: () => more++,
        onMoreActions: () => actions++,
      ),
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('More reactions'));
    await tester.tap(find.bySemanticsLabel('More actions'));
    expect((more, actions), (1, 1));

    await tester.pumpWidget(harness(Center(
      child: ReactionBar(reactions: const ['👍'], onSelected: (_) {}),
    )));
    expect(find.bySemanticsLabel('More reactions'), findsNothing);
  });

  testWidgets('selected emojis are marked selected in semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(harness(Center(
      child: ReactionBar(
        reactions: const ['👍', '❤️'],
        selected: const {'👍'},
        onSelected: (_) {},
      ),
    )));
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.bySemanticsLabel('thumbs up')),
      containsSemantics(isButton: true, isSelected: true, hasTapAction: true),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('red heart')),
      containsSemantics(isSelected: false),
    );
    handle.dispose();
  });

  testWidgets('custom emojiBuilder is used', (tester) async {
    await tester.pumpWidget(harness(Center(
      child: ReactionBar(
        reactions: const [':party:'],
        onSelected: (_) {},
        emojiBuilder: (context, emoji, size) => Text('custom-$emoji'),
      ),
    )));
    await tester.pumpAndSettle();
    expect(find.text('custom-:party:'), findsOneWidget);
  });

  testWidgets('staggered entrance completes', (tester) async {
    await tester.pumpWidget(harness(Center(
      child: ReactionBar(reactions: const ['👍', '❤️', '😂'], onSelected: (_) {}),
    )));
    await tester.pump(const Duration(milliseconds: 10));
    final early = tester
        .widget<FadeTransition>(find.ancestor(of: find.text('😂'), matching: find.byType(FadeTransition)).first)
        .opacity
        .value;
    expect(early, lessThan(1));
    await tester.pumpAndSettle();
    final late = tester
        .widget<FadeTransition>(find.ancestor(of: find.text('😂'), matching: find.byType(FadeTransition)).first)
        .opacity
        .value;
    expect(late, 1);
  });
}
```

`test/widgets/reaction_action_menu_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

const actions = [
  ReactionAction<void>(id: 'reply', label: 'Reply', icon: Icons.reply),
  ReactionAction<void>(id: 'delete', label: 'Delete', icon: Icons.delete, isDestructive: true),
];

void main() {
  testWidgets('shows labels and icons, reports taps', (tester) async {
    ReactionAction? tapped;
    await tester.pumpWidget(harness(Center(
      child: ReactionActionMenu(actions: actions, onSelected: (a) => tapped = a),
    )));
    expect(find.text('Reply'), findsOneWidget);
    expect(find.byIcon(Icons.delete), findsOneWidget);
    await tester.tap(find.text('Delete'));
    expect(tapped?.id, 'delete');
  });

  testWidgets('destructive actions use the theme destructive color', (tester) async {
    await tester.pumpWidget(harness(Center(
      child: ReactionActionMenu(actions: actions, onSelected: (_) {}),
    )));
    final context = tester.element(find.text('Delete'));
    final expected = ChatReactionsTheme.of(context).menuStyle.destructiveColor;
    expect(tester.widget<Text>(find.text('Delete')).style?.color, expected);
    expect(tester.widget<Icon>(find.byIcon(Icons.delete)).color, expected);
  });

  testWidgets('width is clamped between min and max', (tester) async {
    await tester.pumpWidget(harness(Center(
      child: ReactionActionMenu(
        actions: const [ReactionAction<void>(id: 'a', label: 'A')],
        onSelected: (_) {},
      ),
    )));
    expect(tester.getSize(find.byType(ReactionActionMenu)).width, 200);

    await tester.pumpWidget(harness(Center(
      child: ReactionActionMenu(
        actions: [ReactionAction<void>(id: 'b', label: 'B' * 200)],
        onSelected: (_) {},
      ),
    )));
    expect(tester.getSize(find.byType(ReactionActionMenu)).width, 280);
  });

  testWidgets('Cupertino style draws dividers between items', (tester) async {
    await tester.pumpWidget(harness(
      Center(child: ReactionActionMenu(actions: actions, onSelected: (_) {})),
      platform: TargetPlatform.iOS,
    ));
    expect(find.byType(Divider), findsOneWidget);
  });
}
```

- [ ] **Step 3: Run the tests to confirm they fail**

Run: `flutter test test/widgets`
Expected: compilation errors.

- [ ] **Step 4: Implement `lib/src/widgets/emoji.dart`**

```dart
import 'package:flutter/widgets.dart';

/// Builds the visual for an emoji string at [size] logical pixels. Use it to
/// render custom emoji such as `:party:` as images.
typedef EmojiBuilder = Widget Function(
  BuildContext context,
  String emoji,
  double size,
);

/// Renders [emoji] as text at [size], ignoring the system text scale (the
/// containers scale instead).
Widget defaultEmojiBuilder(BuildContext context, String emoji, double size) =>
    Text(
      emoji,
      textScaler: TextScaler.noScaling,
      style: TextStyle(fontSize: size, height: 1.15),
    );
```

- [ ] **Step 5: Implement `lib/src/widgets/reaction_bar.dart`**

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/chat_reactions_localizations.dart';
import '../theme/chat_reactions_theme.dart';
import '../theme/reaction_styles.dart';
import 'emoji.dart';

/// A row of quick reactions with optional "+" (more reactions) and "⋯"
/// (more actions) buttons. Items enter with a staggered scale-and-fade.
class ReactionBar extends StatefulWidget {
  /// Creates a reaction bar.
  const ReactionBar({
    super.key,
    required this.reactions,
    required this.onSelected,
    this.selected = const {},
    this.onMore,
    this.onMoreActions,
    this.emojiBuilder,
    this.style,
    this.animate = true,
  });

  /// Emojis to show, in order.
  final List<String> reactions;

  /// Called with the tapped emoji.
  final ValueChanged<String> onSelected;

  /// Emojis the current user already chose (highlighted).
  final Set<String> selected;

  /// Shows a "+" button when non-null.
  final VoidCallback? onMore;

  /// Shows a "⋯" button when non-null.
  final VoidCallback? onMoreActions;

  /// Custom emoji rendering.
  final EmojiBuilder? emojiBuilder;

  /// Overrides for the themed bar style.
  final ReactionBarStyle? style;

  /// Whether to play the entrance animation.
  final bool animate;

  @override
  State<ReactionBar> createState() => _ReactionBarState();
}

class _ReactionBarState extends State<ReactionBar>
    with SingleTickerProviderStateMixin {
  static const Duration _stagger = Duration(milliseconds: 30);

  late final AnimationController _controller = AnimationController(vsync: this);
  Duration _itemDuration = Duration.zero;
  bool _initialized = false;

  int get _itemCount =>
      widget.reactions.length +
      (widget.onMore == null ? 0 : 1) +
      (widget.onMoreActions == null ? 0 : 1);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _itemDuration = ChatReactionsTheme.of(context).animationDuration!;
    if (!widget.animate || _itemDuration == Duration.zero) {
      _controller.value = 1;
      return;
    }
    _controller.duration = _itemDuration + _stagger * _itemCount;
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _animated(int index, Curve curve, Widget child) {
    final total = _controller.duration;
    if (total == null || total == Duration.zero) return child;
    final start = (_stagger * index).inMicroseconds / total.inMicroseconds;
    final end = math.min(
      1.0,
      start + _itemDuration.inMicroseconds / total.inMicroseconds,
    );
    final animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end, curve: curve),
    );
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.4, end: 1).animate(animation),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ChatReactionsTheme.of(context);
    final style = theme.barStyle.merge(widget.style);
    final l10n = ChatReactionsLocalizations.of(context);
    final emojiBuilder = widget.emojiBuilder ?? defaultEmojiBuilder;
    final size = style.emojiSize!;
    final iconColor = theme.menuStyle.iconColor;

    final items = <Widget>[
      for (final emoji in widget.reactions)
        _BarButton(
          label: l10n.emojiLabel(emoji),
          selected: widget.selected.contains(emoji),
          highlight: style.highlightColor!,
          size: size,
          onTap: () => widget.onSelected(emoji),
          child: emojiBuilder(context, emoji, size),
        ),
      if (widget.onMore != null)
        _BarButton(
          label: l10n.moreReactions,
          selected: false,
          highlight: style.highlightColor!,
          size: size,
          onTap: widget.onMore!,
          child: Icon(Icons.add_reaction_outlined, size: size * 0.8, color: iconColor),
        ),
      if (widget.onMoreActions != null)
        _BarButton(
          label: l10n.moreActions,
          selected: false,
          highlight: style.highlightColor!,
          size: size,
          onTap: widget.onMoreActions!,
          child: Icon(Icons.more_horiz, size: size * 0.8, color: iconColor),
        ),
    ];

    return FocusTraversalGroup(
      child: Material(
        type: MaterialType.transparency,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: style.backgroundColor,
            shape: style.shape!,
            shadows: style.shadows,
          ),
          child: Padding(
            padding: style.padding!,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) SizedBox(width: style.itemSpacing),
                    _animated(i, theme.animationCurve!, items[i]),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.label,
    required this.selected,
    required this.highlight,
    required this.size,
    required this.onTap,
    required this.child,
  });

  final String label;
  final bool selected;
  final Color highlight;
  final double size;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final extent = size * 1.5;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: extent / 2,
        excludeFromSemantics: true,
        child: Container(
          width: extent,
          height: extent,
          alignment: Alignment.center,
          decoration: selected
              ? BoxDecoration(color: highlight, shape: BoxShape.circle)
              : null,
          child: child,
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Implement `lib/src/widgets/reaction_action_menu.dart`**

```dart
import 'package:flutter/material.dart';

import '../models/reaction_action.dart';
import '../theme/chat_reactions_theme.dart';
import '../theme/reaction_styles.dart';

/// A vertical list of message actions (Reply, Copy, Delete, ...). Its width is
/// sized to the content, between the style's min and max width.
class ReactionActionMenu extends StatelessWidget {
  /// Creates an action menu.
  const ReactionActionMenu({
    super.key,
    required this.actions,
    required this.onSelected,
    this.style,
  });

  /// Actions to show, in order.
  final List<ReactionAction> actions;

  /// Called with the tapped action.
  final ValueChanged<ReactionAction> onSelected;

  /// Overrides for the themed menu style.
  final ReactionMenuStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ChatReactionsTheme.of(context);
    final style = theme.menuStyle.merge(this.style);
    final shape = style.shape!;

    final children = <Widget>[];
    for (var i = 0; i < actions.length; i++) {
      if (i > 0 && theme.isCupertino) {
        children.add(Divider(height: 0.5, thickness: 0.5, color: style.dividerColor));
      }
      children.add(_ActionItem(action: actions[i], style: style, onSelected: onSelected));
    }

    return FocusTraversalGroup(
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: style.minWidth!, maxWidth: style.maxWidth!),
        child: IntrinsicWidth(
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: style.backgroundColor,
              shape: shape,
              shadows: style.shadows,
            ),
            child: ClipPath(
              clipper: ShapeBorderClipper(
                shape: shape,
                textDirection: Directionality.of(context),
              ),
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({
    required this.action,
    required this.style,
    required this.onSelected,
  });

  final ReactionAction action;
  final ReactionMenuStyle style;
  final ValueChanged<ReactionAction> onSelected;

  @override
  Widget build(BuildContext context) {
    final color = action.isDestructive ? style.destructiveColor : null;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: () => onSelected(action),
        child: Padding(
          padding: style.itemPadding!,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  action.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: style.textStyle!.copyWith(color: color),
                ),
              ),
              if (action.icon != null) ...[
                const SizedBox(width: 16),
                Icon(action.icon, size: 20, color: color ?? style.iconColor),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
```

Append to the barrel:

```dart
export 'src/widgets/emoji.dart';
export 'src/widgets/reaction_action_menu.dart';
export 'src/widgets/reaction_bar.dart';
```

- [ ] **Step 7: Run and commit**

Run: `flutter test && flutter analyze --fatal-infos`
Expected: pass.

```bash
git add lib test
git commit -m "feat: Add ReactionBar and ReactionActionMenu building blocks

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 8: Presenter infrastructure — `ReactionsMenuContext`, `ReactionsPresenter`, menu route, `CustomPresenter`

**Files:**
- Create: `lib/src/trigger/reaction_trigger.dart`, `lib/src/presenters/reactions_menu_context.dart`, `lib/src/presenters/reactions_presenter.dart`, `lib/src/presenters/menu_route.dart`, `lib/src/presenters/custom_presenter.dart`
- Modify: barrel, `test/helpers.dart` (add `testMenu` and `PresenterLauncher`)
- Test: `test/presenters/custom_presenter_test.dart`, `test/presenters/reactions_menu_context_test.dart`

**Interfaces:**
- Consumes: `ReactionSummary`, `ReactionAction`, `ReactionAlignment`, `EmojiBuilder`, `ChatReactionsTheme`, `ChatReactionsLocalizations`.
- Produces:
  - `enum ReactionTrigger { longPress, doubleTap, secondaryTap, hover, keyboard }` and `Set<ReactionTrigger> defaultReactionTriggers(TargetPlatform)`.
  - `ReactionsMenuContext({required Rect anchorRect, required WidgetBuilder messageBuilder, required List<String> quickReactions, List<ReactionSummary> reactions = const [], List<ReactionAction> actions = const [], ReactionAlignment alignment = ReactionAlignment.end, TextDirection textDirection = TextDirection.ltr, ReactionTrigger trigger = ReactionTrigger.longPress, EmojiBuilder? emojiBuilder, ValueChanged<String>? onReactionSelected, ValueChanged<ReactionAction>? onActionSelected, Future<void> Function()? onMoreTap})`.
    - Getters: `hasMore`, `selectedReactions`, `isDismissed`.
    - Methods: `selectReaction(String)`, `selectAction(ReactionAction)`, `Future<void> openMore()`, `dismiss()`, `setDismissHandler(VoidCallback)`.
  - `abstract class ReactionsPresenter { const ReactionsPresenter(); Future<void> show(BuildContext context, ReactionsMenuContext menu); }`.
  - Internal: `class ReactionsMenuRoute extends PopupRoute<void>` and `Future<void> showReactionsMenuRoute(BuildContext, ReactionsMenuContext, ReactionsMenuRoute)`.
  - `CustomPresenter({required Widget Function(BuildContext, ReactionsMenuContext, Animation<double>) builder, Color? barrierColor, double blurSigma = 0, Duration? transitionDuration})`.

- [ ] **Step 1: Extend `test/helpers.dart`**

Append:

```dart
/// A menu context with sensible test defaults and recording callbacks.
ReactionsMenuContext testMenu({
  Rect anchorRect = const Rect.fromLTWH(300, 250, 200, 60),
  List<String> quickReactions = const ['👍', '❤️', '😂'],
  List<ReactionAction> actions = const [
    ReactionAction<void>(id: 'reply', label: 'Reply', icon: Icons.reply),
    ReactionAction<void>(id: 'delete', label: 'Delete', icon: Icons.delete, isDestructive: true),
  ],
  List<ReactionSummary> reactions = const [],
  ValueChanged<String>? onReactionSelected,
  ValueChanged<ReactionAction>? onActionSelected,
  Future<void> Function()? onMoreTap,
  ReactionTrigger trigger = ReactionTrigger.longPress,
  ReactionAlignment alignment = ReactionAlignment.end,
  TextDirection textDirection = TextDirection.ltr,
}) =>
    ReactionsMenuContext(
      anchorRect: anchorRect,
      messageBuilder: (_) => const ColoredBox(
        key: Key('message-copy'),
        color: Colors.blue,
        child: SizedBox(height: 60),
      ),
      quickReactions: quickReactions,
      actions: actions,
      reactions: reactions,
      onReactionSelected: onReactionSelected,
      onActionSelected: onActionSelected,
      onMoreTap: onMoreTap,
      trigger: trigger,
      alignment: alignment,
      textDirection: textDirection,
    );

/// A button that opens [presenter] with [menu] and records when it closes.
class PresenterLauncher extends StatelessWidget {
  const PresenterLauncher({
    super.key,
    required this.presenter,
    required this.menu,
    this.onClosed,
  });

  final ReactionsPresenter presenter;
  final ReactionsMenuContext menu;
  final VoidCallback? onClosed;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topLeft,
        child: TextButton(
          onPressed: () async {
            await presenter.show(context, menu);
            onClosed?.call();
          },
          child: const Text('open'),
        ),
      );
}
```

- [ ] **Step 2: Write the failing tests**

`test/presenters/reactions_menu_context_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  test('select dismisses first, then reports; dismiss runs the handler once', () {
    final log = <String>[];
    final menu = testMenu(
      onReactionSelected: (e) => log.add('select $e'),
      reactions: const [ReactionSummary(emoji: '👍', count: 1, reactedByMe: true)],
    )..setDismissHandler(() => log.add('dismiss'));

    expect(menu.selectedReactions, {'👍'});
    menu.selectReaction('❤️');
    menu.dismiss();
    expect(log, ['dismiss', 'select ❤️']);
    expect(menu.isDismissed, isTrue);
  });

  test('openMore dismisses then awaits the callback', () async {
    final log = <String>[];
    final menu = testMenu(onMoreTap: () async => log.add('more'))
      ..setDismissHandler(() => log.add('dismiss'));
    expect(menu.hasMore, isTrue);
    await menu.openMore();
    expect(log, ['dismiss', 'more']);
    expect(testMenu().hasMore, isFalse);
  });

  test('default triggers by platform', () {
    expect(defaultReactionTriggers(TargetPlatform.iOS),
        {ReactionTrigger.longPress, ReactionTrigger.keyboard});
    expect(defaultReactionTriggers(TargetPlatform.macOS),
        {ReactionTrigger.secondaryTap, ReactionTrigger.hover, ReactionTrigger.keyboard});
  });
}
```

`test/presenters/custom_presenter_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

CustomPresenter presenter() => CustomPresenter(
      barrierColor: Colors.black54,
      builder: (context, menu, animation) => Center(
        child: TextButton(
          onPressed: () => menu.selectReaction('🔥'),
          child: const Text('custom-ui'),
        ),
      ),
    );

void main() {
  testWidgets('builds custom UI and reports selection', (tester) async {
    String? selected;
    var closed = false;
    await tester.pumpWidget(harness(PresenterLauncher(
      presenter: presenter(),
      menu: testMenu(onReactionSelected: (e) => selected = e),
      onClosed: () => closed = true,
    )));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('custom-ui'), findsOneWidget);

    await tester.tap(find.text('custom-ui'));
    await tester.pumpAndSettle();
    expect(selected, '🔥');
    expect(closed, isTrue);
    expect(find.text('custom-ui'), findsNothing);
  });

  testWidgets('tap outside dismisses', (tester) async {
    await tester.pumpWidget(harness(PresenterLauncher(presenter: presenter(), menu: testMenu())));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 590));
    await tester.pumpAndSettle();
    expect(find.text('custom-ui'), findsNothing);
  });

  testWidgets('Escape dismisses', (tester) async {
    await tester.pumpWidget(harness(PresenterLauncher(presenter: presenter(), menu: testMenu())));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('custom-ui'), findsNothing);
  });

  testWidgets('system back dismisses the menu, not the page', (tester) async {
    await tester.pumpWidget(harness(PresenterLauncher(presenter: presenter(), menu: testMenu())));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('custom-ui'), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('screen resize dismisses', (tester) async {
    addTearDown(tester.view.reset);
    await tester.pumpWidget(harness(PresenterLauncher(presenter: presenter(), menu: testMenu())));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(1000, 1600);
    await tester.pumpAndSettle();
    expect(find.text('custom-ui'), findsNothing);
  });

  testWidgets('menu.dismiss() closes the route', (tester) async {
    final menu = testMenu();
    await tester.pumpWidget(harness(PresenterLauncher(presenter: presenter(), menu: menu)));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    menu.dismiss();
    await tester.pumpAndSettle();
    expect(find.text('custom-ui'), findsNothing);
  });
}
```

- [ ] **Step 3: Run the tests to confirm they fail**

Run: `flutter test test/presenters`
Expected: compilation errors.

- [ ] **Step 4: Implement `lib/src/trigger/reaction_trigger.dart`**

```dart
import 'package:flutter/foundation.dart';

import '../theme/adaptive.dart';

/// Gestures and inputs that open the reactions menu.
enum ReactionTrigger {
  /// Long press (touch).
  longPress,

  /// Double tap.
  doubleTap,

  /// Right-click or two-finger trackpad click.
  secondaryTap,

  /// Mouse hover; only used with `CompactBarPresenter`.
  hover,

  /// Enter, Shift+F10 or the context-menu key while the message has focus.
  keyboard,
}

/// Default triggers for [platform]: long press on touch platforms, right-click
/// and hover on desktop. Keyboard is always enabled.
Set<ReactionTrigger> defaultReactionTriggers(TargetPlatform platform) =>
    isTouchPlatform(platform)
        ? const {ReactionTrigger.longPress, ReactionTrigger.keyboard}
        : const {
            ReactionTrigger.secondaryTap,
            ReactionTrigger.hover,
            ReactionTrigger.keyboard,
          };
```

- [ ] **Step 5: Implement `lib/src/presenters/reactions_menu_context.dart`**

```dart
import 'package:flutter/widgets.dart';

import '../layout/reaction_alignment.dart';
import '../models/reaction_action.dart';
import '../models/reaction_summary.dart';
import '../trigger/reaction_trigger.dart';
import '../widgets/emoji.dart';

/// Everything a [ReactionsPresenter] needs to show a menu for one message.
///
/// `ReactableMessage` creates it; presenters read the data, call
/// [selectReaction], [selectAction], [openMore] or [dismiss], and register how
/// to close themselves with [setDismissHandler].
class ReactionsMenuContext {
  /// Creates a menu context. Presenters normally receive one; construct it
  /// directly only for tests or when calling a presenter yourself.
  ReactionsMenuContext({
    required this.anchorRect,
    required this.messageBuilder,
    required this.quickReactions,
    this.reactions = const [],
    this.actions = const [],
    this.alignment = ReactionAlignment.end,
    this.textDirection = TextDirection.ltr,
    this.trigger = ReactionTrigger.longPress,
    this.emojiBuilder,
    ValueChanged<String>? onReactionSelected,
    ValueChanged<ReactionAction>? onActionSelected,
    Future<void> Function()? onMoreTap,
  })  : _onReactionSelected = onReactionSelected,
        _onActionSelected = onActionSelected,
        _onMoreTap = onMoreTap;

  /// The message's bounds in the root overlay's coordinate space.
  final Rect anchorRect;

  /// Rebuilds the message for display inside the menu.
  final WidgetBuilder messageBuilder;

  /// Emojis offered in the reaction bar.
  final List<String> quickReactions;

  /// The message's current reactions.
  final List<ReactionSummary> reactions;

  /// Context-menu actions for this message.
  final List<ReactionAction> actions;

  /// Side the menu aligns to.
  final ReactionAlignment alignment;

  /// Text direction at the message.
  final TextDirection textDirection;

  /// What opened the menu.
  final ReactionTrigger trigger;

  /// Custom emoji rendering, if any.
  final EmojiBuilder? emojiBuilder;

  final ValueChanged<String>? _onReactionSelected;
  final ValueChanged<ReactionAction>? _onActionSelected;
  final Future<void> Function()? _onMoreTap;
  VoidCallback? _dismissHandler;
  bool _dismissed = false;

  /// Whether a "more reactions" callback exists (show a "+" button).
  bool get hasMore => _onMoreTap != null;

  /// Emojis the current user already reacted with.
  Set<String> get selectedReactions => {
        for (final r in reactions)
          if (r.reactedByMe) r.emoji,
      };

  /// Whether [dismiss] has been called.
  bool get isDismissed => _dismissed;

  /// Registers how the presenter closes itself. Presenters call this before
  /// showing.
  void setDismissHandler(VoidCallback handler) => _dismissHandler = handler;

  /// Closes the menu. Safe to call more than once.
  void dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    _dismissHandler?.call();
  }

  /// Closes the menu, then reports [emoji] as selected.
  void selectReaction(String emoji) {
    dismiss();
    _onReactionSelected?.call(emoji);
  }

  /// Closes the menu, then reports [action] as selected.
  void selectAction(ReactionAction action) {
    dismiss();
    _onActionSelected?.call(action);
  }

  /// Closes the menu, then runs the "more reactions" callback.
  Future<void> openMore() async {
    final callback = _onMoreTap;
    dismiss();
    if (callback != null) await callback();
  }
}
```

- [ ] **Step 6: Implement `lib/src/presenters/reactions_presenter.dart`**

```dart
import 'package:flutter/widgets.dart';

import 'reactions_menu_context.dart';

/// Shows the reactions UI for a message. Implement this for a fully custom
/// presentation (headless mode), or use `CustomPresenter`.
abstract class ReactionsPresenter {
  /// Const constructor for subclasses.
  const ReactionsPresenter();

  /// Shows the menu described by [menu]. The returned future completes after
  /// the menu has been dismissed. [context] belongs to the message.
  Future<void> show(BuildContext context, ReactionsMenuContext menu);
}
```

- [ ] **Step 7: Implement `lib/src/presenters/menu_route.dart` (internal)**

```dart
import 'dart:ui' show ImageFilter;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'reactions_menu_context.dart';

/// Transparent popup route used by the built-in presenters. Provides the
/// barrier (tap outside), Escape, system back and focus trapping via
/// [ModalRoute], plus an animated tint and blur.
class ReactionsMenuRoute extends PopupRoute<void> {
  /// Creates the route.
  ReactionsMenuRoute({
    required this.menu,
    required this.builder,
    required this.duration,
    required this.curve,
    required String barrierLabel,
    this.barrierTint,
    this.blurSigma = 0,
  }) : _barrierLabel = barrierLabel;

  /// The menu this route shows.
  final ReactionsMenuContext menu;

  /// Builds the content; the animation is already curved.
  final Widget Function(BuildContext context, Animation<double> animation) builder;

  /// Transition duration.
  final Duration duration;

  /// Transition curve.
  final Curve curve;

  /// Tint painted behind the content (animated).
  final Color? barrierTint;

  /// Backdrop blur (animated); 0 disables.
  final double blurSigma;

  final String _barrierLabel;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => _barrierLabel;

  @override
  Duration get transitionDuration => duration;

  @override
  Duration get reverseTransitionDuration => duration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: curve);
    final tint = barrierTint;
    return _DismissOnResize(
      onResize: menu.dismiss,
      child: Stack(
        children: [
          if (tint != null || blurSigma > 0)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: curved,
                  builder: (context, _) {
                    final t = curved.value;
                    Widget layer = ColoredBox(
                      color: (tint ?? const Color(0x00000000))
                          .withValues(alpha: (tint?.a ?? 0) * t),
                    );
                    if (blurSigma > 0) {
                      layer = BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: blurSigma * t,
                          sigmaY: blurSigma * t,
                        ),
                        child: layer,
                      );
                    }
                    return layer;
                  },
                ),
              ),
            ),
          Positioned.fill(child: builder(context, curved)),
        ],
      ),
    );
  }
}

/// Pushes [route] on the root navigator and wires [menu.dismiss] to close it.
Future<void> showReactionsMenuRoute(
  BuildContext context,
  ReactionsMenuContext menu,
  ReactionsMenuRoute route,
) {
  final navigator = Navigator.of(context, rootNavigator: true);
  menu.setDismissHandler(() => closeRouteSafely(navigator, route));
  return navigator.push(route);
}

/// Pops [route] if it is still active, deferring when the tree is locked
/// (e.g. when called from `dispose`).
void closeRouteSafely(NavigatorState navigator, Route<dynamic> route) {
  void close() {
    if (!route.isActive || !navigator.mounted) return;
    if (route.isCurrent) {
      navigator.pop();
    } else {
      navigator.removeRoute(route);
    }
  }

  final phase = SchedulerBinding.instance.schedulerPhase;
  if (phase == SchedulerPhase.persistentCallbacks ||
      phase == SchedulerPhase.midFrameMicrotasks) {
    SchedulerBinding.instance.addPostFrameCallback((_) => close());
  } else {
    close();
  }
}

class _DismissOnResize extends StatefulWidget {
  const _DismissOnResize({required this.onResize, required this.child});

  final VoidCallback onResize;
  final Widget child;

  @override
  State<_DismissOnResize> createState() => _DismissOnResizeState();
}

class _DismissOnResizeState extends State<_DismissOnResize> {
  Size? _initial;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final size = MediaQuery.sizeOf(context);
    final initial = _initial ??= size;
    if (size != initial) {
      SchedulerBinding.instance.addPostFrameCallback((_) => widget.onResize());
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
```

- [ ] **Step 8: Implement `lib/src/presenters/custom_presenter.dart`**

```dart
import 'package:flutter/widgets.dart';

import '../l10n/chat_reactions_localizations.dart';
import '../theme/chat_reactions_theme.dart';
import 'menu_route.dart';
import 'reactions_menu_context.dart';
import 'reactions_presenter.dart';

/// Headless presenter: the package handles the route, barrier, dismissal
/// (tap outside, Escape, back, resize) and focus trapping; [builder] draws
/// everything else. Position your UI using `menu.anchorRect`, e.g. with
/// `AnchoredLayout`.
class CustomPresenter extends ReactionsPresenter {
  /// Creates a custom presenter.
  const CustomPresenter({
    required this.builder,
    this.barrierColor,
    this.blurSigma = 0,
    this.transitionDuration,
  });

  /// Builds the menu. [animation] runs 0→1 on open and 1→0 on close.
  final Widget Function(
    BuildContext context,
    ReactionsMenuContext menu,
    Animation<double> animation,
  ) builder;

  /// Tint behind the menu; null for none.
  final Color? barrierColor;

  /// Backdrop blur; 0 for none.
  final double blurSigma;

  /// Open/close duration; defaults to the theme's animation duration.
  final Duration? transitionDuration;

  @override
  Future<void> show(BuildContext context, ReactionsMenuContext menu) {
    final theme = ChatReactionsTheme.of(context);
    final route = ReactionsMenuRoute(
      menu: menu,
      duration: transitionDuration ?? theme.animationDuration!,
      curve: theme.animationCurve!,
      barrierTint: barrierColor,
      blurSigma: blurSigma,
      barrierLabel: ChatReactionsLocalizations.of(context).dismissMenu,
      builder: (context, animation) => builder(context, menu, animation),
    );
    return showReactionsMenuRoute(context, menu, route);
  }
}
```

Append to the barrel:

```dart
export 'src/presenters/custom_presenter.dart';
export 'src/presenters/reactions_menu_context.dart';
export 'src/presenters/reactions_presenter.dart';
export 'src/trigger/reaction_trigger.dart';
```

- [ ] **Step 9: Run and commit**

Run: `flutter test && flutter analyze --fatal-infos`
Expected: pass. If the Escape test fails, check that the pushed route has focus: `ModalRoute` requests focus when `requestFocus` is true, which is the default for `navigator.push`.

```bash
git add lib test
git commit -m "feat: Add presenter infrastructure, menu route, and headless CustomPresenter

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 9: `ReactionsSummaryView` and reaction details

**Files:**
- Create: `lib/src/widgets/reactions_summary_view.dart`, `lib/src/widgets/reaction_details.dart`
- Modify: barrel
- Test: `test/widgets/reactions_summary_view_test.dart`, `test/widgets/reaction_details_test.dart`

**Interfaces:**
- Consumes: `ReactionSummary`, `ReactionUser`, `ChatReactionsTheme`, `ReactionChipStyle`, `ChatReactionsLocalizations`, `EmojiBuilder`, `defaultEmojiBuilder`, `ReactionAlignment`.
- Produces:
  - `enum ReactionSummaryLayout { chips, stacked, compact }`.
  - `ReactionsSummaryView({Key? key, required List<ReactionSummary> reactions, ReactionSummaryLayout layout = ReactionSummaryLayout.chips, int maxVisible = 5, ValueChanged<String>? onReactionTap, VoidCallback? onTap, ValueChanged<String>? onLongPress, Widget Function(BuildContext, ReactionSummary)? chipBuilder, EmojiBuilder? emojiBuilder, ReactionChipStyle? style})`.
  - `ReactionsSummaryView.overlay({Key? key, required Widget child, required List<ReactionSummary> reactions, ReactionSummaryLayout layout = ReactionSummaryLayout.stacked, ReactionAlignment alignment = ReactionAlignment.end, double overlap = 12, ...same optional args})`.
  - `ReactionDetailsList({Key? key, required List<ReactionSummary> reactions})`, `ReactionDetailsSheet({Key? key, required List<ReactionSummary> reactions})`, `Future<void> showReactionDetails(BuildContext context, List<ReactionSummary> reactions)`.

- [ ] **Step 1: Write the failing tests**

`test/widgets/reactions_summary_view_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

const three = [
  ReactionSummary(emoji: '👍', count: 3, reactedByMe: true),
  ReactionSummary(emoji: '❤️', count: 1),
  ReactionSummary(emoji: '😂', count: 2),
];

void main() {
  testWidgets('empty reactions render nothing', (tester) async {
    await tester.pumpWidget(harness(const ReactionsSummaryView(reactions: [])));
    expect(tester.getSize(find.byType(ReactionsSummaryView)), Size.zero);
  });

  testWidgets('chips show emoji and count, tap reports emoji', (tester) async {
    String? tapped;
    await tester.pumpWidget(harness(ReactionsSummaryView(
      reactions: three,
      onReactionTap: (e) => tapped = e,
    )));
    expect(find.text('👍'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    await tester.tap(find.text('😂'));
    expect(tapped, '😂');
  });

  testWidgets('selected chip uses selected style', (tester) async {
    await tester.pumpWidget(harness(const ReactionsSummaryView(reactions: three)));
    final context = tester.element(find.text('3'));
    final chip = ChatReactionsTheme.of(context).chipStyle;
    expect(tester.widget<Text>(find.text('3')).style?.color, chip.selectedTextStyle!.color);
    expect(tester.widget<Text>(find.text('1')).style?.color, chip.textStyle!.color);
  });

  testWidgets('maxVisible adds a +N chip', (tester) async {
    await tester.pumpWidget(harness(const ReactionsSummaryView(reactions: three, maxVisible: 2)));
    expect(find.text('+1'), findsOneWidget);
    expect(find.text('😂'), findsNothing);
  });

  testWidgets('stacked layout shows total count', (tester) async {
    await tester.pumpWidget(harness(const ReactionsSummaryView(
      reactions: three,
      layout: ReactionSummaryLayout.stacked,
    )));
    expect(find.text('6'), findsOneWidget);
    expect(find.text('👍'), findsOneWidget);
  });

  testWidgets('compact layout shows up to three emojis and total', (tester) async {
    await tester.pumpWidget(harness(const ReactionsSummaryView(
      reactions: [...three, ReactionSummary(emoji: '🔥', count: 1)],
      layout: ReactionSummaryLayout.compact,
    )));
    expect(find.text('🔥'), findsNothing);
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('onTap covers the whole view', (tester) async {
    var taps = 0;
    await tester.pumpWidget(harness(ReactionsSummaryView(
      reactions: three,
      layout: ReactionSummaryLayout.compact,
      onTap: () => taps++,
    )));
    await tester.tap(find.byType(ReactionsSummaryView));
    expect(taps, 1);
  });

  testWidgets('chipBuilder overrides chips', (tester) async {
    await tester.pumpWidget(harness(ReactionsSummaryView(
      reactions: three,
      chipBuilder: (context, s) => Text('chip ${s.emoji}'),
    )));
    expect(find.text('chip 👍'), findsOneWidget);
  });

  testWidgets('count changes animate', (tester) async {
    await tester.pumpWidget(harness(const ReactionsSummaryView(
      reactions: [ReactionSummary(emoji: '👍', count: 1)],
    )));
    await tester.pumpWidget(harness(const ReactionsSummaryView(
      reactions: [ReactionSummary(emoji: '👍', count: 2)],
    )));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('1'), findsOneWidget, reason: 'old count still fading out');
    await tester.pumpAndSettle();
    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('overlay places the summary over the bubble bottom edge', (tester) async {
    await tester.pumpWidget(harness(Align(
      alignment: Alignment.topLeft,
      child: ReactionsSummaryView.overlay(
        reactions: three,
        child: const SizedBox(key: Key('bubble'), width: 200, height: 80),
      ),
    )));
    final bubble = tester.getRect(find.byKey(const Key('bubble')));
    final summary = tester.getRect(find.text('👍'));
    expect(summary.top, lessThan(bubble.bottom));
    expect(summary.bottom, greaterThan(bubble.bottom));
  });

  testWidgets('chip semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(harness(ReactionsSummaryView(
      reactions: three,
      onReactionTap: (_) {},
    )));
    expect(
      tester.getSemantics(find.bySemanticsLabel('thumbs up, 3 reactions')),
      containsSemantics(isButton: true, isSelected: true, hasTapAction: true),
    );
    handle.dispose();
  });
}
```

`test/widgets/reaction_details_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

const reactions = [
  ReactionSummary(
    emoji: '👍',
    count: 2,
    users: [ReactionUser(id: 'u1', name: 'Ada'), ReactionUser(id: 'u2', name: 'Bo')],
  ),
  ReactionSummary(emoji: '❤️', count: 1, users: [ReactionUser(id: 'u3')]),
];

void main() {
  testWidgets('showReactionDetails lists users per tab', (tester) async {
    await tester.pumpWidget(harness(Builder(
      builder: (context) => TextButton(
        onPressed: () => showReactionDetails(context, reactions),
        child: const Text('details'),
      ),
    )));
    await tester.tap(find.text('details'));
    await tester.pumpAndSettle();

    expect(find.text('All 3'), findsOneWidget);
    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('u3'), findsOneWidget, reason: 'falls back to id');

    await tester.tap(find.text('❤️ 1'));
    await tester.pumpAndSettle();
    expect(find.text('Ada'), findsNothing);
    expect(find.text('u3'), findsOneWidget);
  });

  testWidgets('ReactionDetailsList shows a count when users are unknown', (tester) async {
    await tester.pumpWidget(harness(const ReactionDetailsList(
      reactions: [ReactionSummary(emoji: '🔥', count: 4)],
    )));
    expect(find.text('4 reactions'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the tests to confirm they fail**

Run: `flutter test test/widgets/reactions_summary_view_test.dart test/widgets/reaction_details_test.dart`
Expected: compilation errors.

- [ ] **Step 3: Implement `lib/src/widgets/reactions_summary_view.dart`**

```dart
import 'package:flutter/material.dart';

import '../l10n/chat_reactions_localizations.dart';
import '../layout/reaction_alignment.dart';
import '../models/reaction_summary.dart';
import '../theme/chat_reactions_theme.dart';
import '../theme/reaction_styles.dart';
import 'emoji.dart';

/// How [ReactionsSummaryView] arranges reactions.
enum ReactionSummaryLayout {
  /// One pill per emoji with its count, wrapping (Slack, Discord).
  chips,

  /// Overlapping emoji circles plus the total count (WhatsApp).
  stacked,

  /// A single pill with up to three emojis and the total count.
  compact,
}

/// Displays a message's reactions.
class ReactionsSummaryView extends StatelessWidget {
  /// Creates a summary view.
  const ReactionsSummaryView({
    super.key,
    required this.reactions,
    this.layout = ReactionSummaryLayout.chips,
    this.maxVisible = 5,
    this.onReactionTap,
    this.onTap,
    this.onLongPress,
    this.chipBuilder,
    this.emojiBuilder,
    this.style,
  })  : overlayChild = null,
        alignment = ReactionAlignment.end,
        overlap = 0;

  /// Places the summary over the bottom edge of [child] (e.g. a bubble),
  /// aligned to [alignment] and overlapping by [overlap] pixels.
  const ReactionsSummaryView.overlay({
    super.key,
    required Widget child,
    required this.reactions,
    this.layout = ReactionSummaryLayout.stacked,
    this.alignment = ReactionAlignment.end,
    this.overlap = 12,
    this.maxVisible = 5,
    this.onReactionTap,
    this.onTap,
    this.onLongPress,
    this.chipBuilder,
    this.emojiBuilder,
    this.style,
  }) : overlayChild = child;

  /// Reactions to display.
  final List<ReactionSummary> reactions;

  /// Arrangement.
  final ReactionSummaryLayout layout;

  /// Maximum emojis shown before a "+N" indicator.
  final int maxVisible;

  /// Called with the tapped chip's emoji (chips layout).
  final ValueChanged<String>? onReactionTap;

  /// Called when the whole view is tapped.
  final VoidCallback? onTap;

  /// Called with the long-pressed chip's emoji (chips layout).
  final ValueChanged<String>? onLongPress;

  /// Replaces the default chip (chips layout).
  final Widget Function(BuildContext context, ReactionSummary summary)? chipBuilder;

  /// Custom emoji rendering.
  final EmojiBuilder? emojiBuilder;

  /// Overrides for the themed chip style.
  final ReactionChipStyle? style;

  /// The bubble the summary overlaps ([ReactionsSummaryView.overlay] only).
  final Widget? overlayChild;

  /// Side of [overlayChild] the summary aligns to.
  final ReactionAlignment alignment;

  /// How far the summary overlaps [overlayChild]'s bottom edge.
  final double overlap;

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return overlayChild ?? const SizedBox.shrink();

    final theme = ChatReactionsTheme.of(context);
    final chip = theme.chipStyle.merge(style);
    final l10n = ChatReactionsLocalizations.of(context);
    final emoji = emojiBuilder ?? defaultEmojiBuilder;

    Widget content = switch (layout) {
      ReactionSummaryLayout.chips => _chips(context, chip, l10n, emoji, theme),
      ReactionSummaryLayout.stacked => _stacked(context, chip, l10n, emoji),
      ReactionSummaryLayout.compact => _compact(context, chip, l10n, emoji),
    };
    content = AnimatedSize(
      duration: theme.animationDuration!,
      curve: theme.animationCurve!,
      alignment: AlignmentDirectional.centerStart,
      child: content,
    );
    if (onTap != null) {
      content = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: content,
      );
    }

    final child = overlayChild;
    if (child == null) return content;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignment == ReactionAlignment.end
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        child,
        Transform.translate(
          offset: Offset(0, -overlap),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
            child: content,
          ),
        ),
      ],
    );
  }

  int get _total => reactions.fold(0, (sum, r) => sum + r.count);

  String _label(ChatReactionsLocalizations l10n) => reactions
      .map((r) => '${l10n.emojiLabel(r.emoji)}, ${l10n.reactionCount(r.count)}')
      .join('; ');

  Widget _chips(
    BuildContext context,
    ReactionChipStyle chip,
    ChatReactionsLocalizations l10n,
    EmojiBuilder emoji,
    ChatReactionsTheme theme,
  ) {
    final visible = reactions.take(maxVisible).toList();
    final remaining = reactions.length - visible.length;
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final summary in visible)
          chipBuilder?.call(context, summary) ??
              _ReactionChip(
                summary: summary,
                style: chip,
                emojiBuilder: emoji,
                duration: theme.animationDuration!,
                label:
                    '${l10n.emojiLabel(summary.emoji)}, ${l10n.reactionCount(summary.count)}',
                onTap: onReactionTap == null
                    ? null
                    : () => onReactionTap!(summary.emoji),
                onLongPress: onLongPress == null
                    ? null
                    : () => onLongPress!(summary.emoji),
              ),
        if (remaining > 0) _Pill(style: chip, child: Text('+$remaining', style: chip.textStyle)),
      ],
    );
  }

  Widget _stacked(
    BuildContext context,
    ReactionChipStyle chip,
    ChatReactionsLocalizations l10n,
    EmojiBuilder emoji,
  ) {
    final visible = reactions.take(maxVisible).toList();
    final size = chip.emojiSize!;
    final circle = size + 6;
    final step = circle * 0.6;
    final mine = reactions.any((r) => r.reactedByMe);
    return Semantics(
      label: _label(l10n),
      selected: mine,
      excludeSemantics: true,
      child: _Pill(
        style: chip,
        selected: mine,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: circle + step * (visible.length - 1),
              height: circle,
              child: Stack(
                children: [
                  for (var i = 0; i < visible.length; i++)
                    PositionedDirectional(
                      start: step * i,
                      child: Container(
                        width: circle,
                        height: circle,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: chip.backgroundColor,
                          shape: BoxShape.circle,
                        ),
                        child: emoji(context, visible[i].emoji, size * 0.8),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Text('$_total', style: mine ? chip.selectedTextStyle : chip.textStyle),
          ],
        ),
      ),
    );
  }

  Widget _compact(
    BuildContext context,
    ReactionChipStyle chip,
    ChatReactionsLocalizations l10n,
    EmojiBuilder emoji,
  ) {
    final mine = reactions.any((r) => r.reactedByMe);
    return Semantics(
      label: _label(l10n),
      selected: mine,
      excludeSemantics: true,
      child: _Pill(
        style: chip,
        selected: mine,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final r in reactions.take(3)) emoji(context, r.emoji, chip.emojiSize!),
            const SizedBox(width: 4),
            Text('$_total', style: mine ? chip.selectedTextStyle : chip.textStyle),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.style, required this.child, this.selected = false});

  final ReactionChipStyle style;
  final Widget child;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final side = (selected ? style.selectedBorder : style.border) ?? BorderSide.none;
    return Container(
      padding: style.padding,
      decoration: BoxDecoration(
        color: selected ? style.selectedBackgroundColor : style.backgroundColor,
        border: Border.fromBorderSide(side),
        borderRadius: style.borderRadius,
      ),
      child: child,
    );
  }
}

class _ReactionChip extends StatelessWidget {
  const _ReactionChip({
    required this.summary,
    required this.style,
    required this.emojiBuilder,
    required this.duration,
    required this.label,
    this.onTap,
    this.onLongPress,
  });

  final ReactionSummary summary;
  final ReactionChipStyle style;
  final EmojiBuilder emojiBuilder;
  final Duration duration;
  final String label;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final selected = summary.reactedByMe;
    final side = (selected ? style.selectedBorder : style.border) ?? BorderSide.none;
    final radius = style.borderRadius!.resolve(Directionality.of(context));
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: radius,
          excludeFromSemantics: true,
          child: AnimatedContainer(
            duration: duration,
            padding: style.padding,
            decoration: BoxDecoration(
              color: selected ? style.selectedBackgroundColor : style.backgroundColor,
              border: Border.fromBorderSide(side),
              borderRadius: radius,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                emojiBuilder(context, summary.emoji, style.emojiSize!),
                const SizedBox(width: 4),
                AnimatedSwitcher(
                  duration: duration,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  ),
                  child: Text(
                    '${summary.count}',
                    key: ValueKey(summary.count),
                    style: selected ? style.selectedTextStyle : style.textStyle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Implement `lib/src/widgets/reaction_details.dart`**

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/chat_reactions_localizations.dart';
import '../models/reaction_summary.dart';
import '../models/reaction_user.dart';

/// Lists who reacted with what. Shows a count when user details are unknown.
class ReactionDetailsList extends StatelessWidget {
  /// Creates a details list.
  const ReactionDetailsList({super.key, required this.reactions});

  /// Reactions to list.
  final List<ReactionSummary> reactions;

  @override
  Widget build(BuildContext context) {
    final l10n = ChatReactionsLocalizations.of(context);
    final rows = <Widget>[];
    for (final summary in reactions) {
      if (summary.users.isEmpty) {
        rows.add(ListTile(
          dense: true,
          leading: Text(summary.emoji, style: const TextStyle(fontSize: 22)),
          title: Text(l10n.reactionCount(summary.count)),
        ));
        continue;
      }
      for (final user in summary.users) {
        rows.add(_UserTile(user: user, emoji: summary.emoji));
      }
    }
    return ListView(shrinkWrap: true, children: rows);
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user, required this.emoji});

  final ReactionUser user;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    final name = user.name ?? user.id;
    final avatar = user.avatarUrl;
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        backgroundImage: avatar == null ? null : NetworkImage(avatar),
        child: avatar == null
            ? Text(name.isEmpty ? '?' : name.characters.first.toUpperCase())
            : null,
      ),
      title: Text(name),
      trailing: Text(emoji, style: const TextStyle(fontSize: 20)),
    );
  }
}

/// A tabbed sheet: "All" plus one tab per emoji, each listing users.
class ReactionDetailsSheet extends StatelessWidget {
  /// Creates a details sheet.
  const ReactionDetailsSheet({super.key, required this.reactions});

  /// Reactions to show.
  final List<ReactionSummary> reactions;

  @override
  Widget build(BuildContext context) {
    final l10n = ChatReactionsLocalizations.of(context);
    final total = reactions.fold(0, (sum, r) => sum + r.count);
    final height = math.min(400.0, MediaQuery.sizeOf(context).height * 0.5);
    return DefaultTabController(
      length: reactions.length + 1,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: '${l10n.allReactions} $total'),
              for (final r in reactions) Tab(text: '${r.emoji} ${r.count}'),
            ],
          ),
          SizedBox(
            height: height,
            child: TabBarView(
              children: [
                ReactionDetailsList(reactions: reactions),
                for (final r in reactions) ReactionDetailsList(reactions: [r]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows [ReactionDetailsSheet] in a modal bottom sheet.
Future<void> showReactionDetails(
  BuildContext context,
  List<ReactionSummary> reactions,
) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => SafeArea(child: ReactionDetailsSheet(reactions: reactions)),
    );
```

Append to the barrel:

```dart
export 'src/widgets/reaction_details.dart';
export 'src/widgets/reactions_summary_view.dart';
```

- [ ] **Step 5: Run and commit**

Run: `flutter test && flutter analyze --fatal-infos`
Expected: pass.

```bash
git add lib test/widgets
git commit -m "feat!: Add ReactionsSummaryView (chips/stacked/compact) and reaction details sheet

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 10: `BottomSheetPresenter`

**Files:**
- Create: `lib/src/presenters/bottom_sheet_presenter.dart`
- Modify: barrel
- Test: `test/presenters/bottom_sheet_presenter_test.dart`

**Interfaces:**
- Consumes: `ReactionsPresenter`, `ReactionsMenuContext`, `closeRouteSafely` (from `menu_route.dart`), `ReactionBar`, `ReactionDetailsList`, `ChatReactionsTheme`, `ChatReactionsLocalizations`.
- Produces: `BottomSheetPresenter({bool showReactionDetails = false})`. It is a Material modal sheet, or a `CupertinoActionSheet` when the resolved theme is Cupertino.

- [ ] **Step 1: Write the failing tests**

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  testWidgets('Material: shows bar and actions; action selection closes', (tester) async {
    ReactionAction? action;
    var closed = false;
    await tester.pumpWidget(harness(PresenterLauncher(
      presenter: const BottomSheetPresenter(),
      menu: testMenu(onActionSelected: (a) => action = a),
      onClosed: () => closed = true,
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(ReactionBar), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(action?.id, 'delete');
    expect(closed, isTrue);
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('reaction selection closes and reports', (tester) async {
    String? emoji;
    await tester.pumpWidget(harness(PresenterLauncher(
      presenter: const BottomSheetPresenter(),
      menu: testMenu(onReactionSelected: (e) => emoji = e),
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('❤️'));
    await tester.pumpAndSettle();
    expect(emoji, '❤️');
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('Cupertino: action sheet with cancel', (tester) async {
    await tester.pumpWidget(harness(
      PresenterLauncher(presenter: const BottomSheetPresenter(), menu: testMenu()),
      platform: TargetPlatform.iOS,
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoActionSheet), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoActionSheet), findsNothing);
  });

  testWidgets('showReactionDetails lists users', (tester) async {
    await tester.pumpWidget(harness(PresenterLauncher(
      presenter: const BottomSheetPresenter(showReactionDetails: true),
      menu: testMenu(reactions: const [
        ReactionSummary(emoji: '👍', count: 1, users: [ReactionUser(id: 'u1', name: 'Ada')]),
      ]),
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Ada'), findsOneWidget);
  });
}
```

Save as `test/presenters/bottom_sheet_presenter_test.dart`.

- [ ] **Step 2: Run the test to confirm it fails**

Run: `flutter test test/presenters/bottom_sheet_presenter_test.dart`
Expected: a compilation error.

- [ ] **Step 3: Implement `lib/src/presenters/bottom_sheet_presenter.dart`**

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../l10n/chat_reactions_localizations.dart';
import '../theme/chat_reactions_theme.dart';
import '../theme/reaction_styles.dart';
import '../widgets/reaction_bar.dart';
import '../widgets/reaction_details.dart';
import 'menu_route.dart';
import 'reactions_menu_context.dart';
import 'reactions_presenter.dart';

/// Shows reactions and actions in a modal bottom sheet (Material) or an
/// action sheet (Cupertino). The most robust choice for small screens and
/// large text; `FocusedOverlayPresenter` falls back to it automatically.
class BottomSheetPresenter extends ReactionsPresenter {
  /// Creates a bottom-sheet presenter.
  const BottomSheetPresenter({this.showReactionDetails = false});

  /// Whether to list who reacted with what below the reaction bar.
  final bool showReactionDetails;

  @override
  Future<void> show(BuildContext context, ReactionsMenuContext menu) async {
    final theme = ChatReactionsTheme.of(context);
    final navigator = Navigator.of(context, rootNavigator: true);
    Route<dynamic>? sheetRoute;
    menu.setDismissHandler(() {
      final route = sheetRoute;
      if (route != null) closeRouteSafely(navigator, route);
    });

    Widget capture(BuildContext sheetContext, Widget child) {
      sheetRoute = ModalRoute.of(sheetContext);
      return child;
    }

    if (theme.isCupertino) {
      await showCupertinoModalPopup<void>(
        context: context,
        useRootNavigator: true,
        builder: (sheetContext) => capture(sheetContext, _cupertinoSheet(sheetContext, menu)),
      );
    } else {
      await showModalBottomSheet<void>(
        context: context,
        useRootNavigator: true,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (sheetContext) => capture(sheetContext, _materialSheet(sheetContext, menu)),
      );
    }
  }

  Widget _bar(ReactionsMenuContext menu) => ReactionBar(
        reactions: menu.quickReactions,
        selected: menu.selectedReactions,
        onSelected: menu.selectReaction,
        onMore: menu.hasMore ? menu.openMore : null,
        emojiBuilder: menu.emojiBuilder,
        style: const ReactionBarStyle(shadows: []),
      );

  Widget _materialSheet(BuildContext context, ReactionsMenuContext menu) {
    final style = ChatReactionsTheme.of(context).menuStyle;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: _bar(menu)),
          if (showReactionDetails && menu.reactions.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ReactionDetailsList(reactions: menu.reactions),
            ),
          const SizedBox(height: 8),
          for (final action in menu.actions)
            ListTile(
              leading: action.icon == null ? null : Icon(action.icon),
              title: Text(action.label),
              iconColor: action.isDestructive ? style.destructiveColor : null,
              textColor: action.isDestructive ? style.destructiveColor : null,
              onTap: () => menu.selectAction(action),
            ),
        ],
      ),
    );
  }

  Widget _cupertinoSheet(BuildContext context, ReactionsMenuContext menu) {
    final l10n = ChatReactionsLocalizations.of(context);
    return CupertinoActionSheet(
      title: _bar(menu),
      message: showReactionDetails && menu.reactions.isNotEmpty
          ? Material(
              type: MaterialType.transparency,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ReactionDetailsList(reactions: menu.reactions),
              ),
            )
          : null,
      actions: [
        for (final action in menu.actions)
          CupertinoActionSheetAction(
            isDestructiveAction: action.isDestructive,
            onPressed: () => menu.selectAction(action),
            child: Text(action.label),
          ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: menu.dismiss,
        child: Text(l10n.cancel),
      ),
    );
  }
}
```

Append to the barrel: `export 'src/presenters/bottom_sheet_presenter.dart';`

- [ ] **Step 4: Run and commit**

Run: `flutter test && flutter analyze --fatal-infos`
Expected: pass.

```bash
git add lib test/presenters
git commit -m "feat: Add BottomSheetPresenter with Material sheet and Cupertino action sheet

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 11: `FocusedOverlayPresenter` (default)

**Files:**
- Create: `lib/src/presenters/focused_overlay_presenter.dart`
- Modify: barrel
- Test: `test/presenters/focused_overlay_presenter_test.dart`

**Interfaces:**
- Consumes: `ReactionsMenuRoute`, `showReactionsMenuRoute`, `AnchoredLayout`, `ReactionBar`, `ReactionActionMenu`, `BottomSheetPresenter`, `ChatReactionsTheme`.
- Produces: `FocusedOverlayPresenter({double? blurSigma, Color? barrierColor, bool showMessage = true, bool showActions = true, double? lift, double fallbackTextScale = 2.0, double fallbackMinHeight = 400, ReactionsPresenter fallback = const BottomSheetPresenter()})`.

- [ ] **Step 1: Write the failing tests**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  testWidgets('shows bar above, message copy at anchor, menu below', (tester) async {
    final menu = testMenu();
    await tester.pumpWidget(harness(PresenterLauncher(
      presenter: const FocusedOverlayPresenter(),
      menu: menu,
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final bar = tester.getRect(find.byType(ReactionBar));
    final message = tester.getRect(find.byKey(const Key('message-copy')));
    final actions = tester.getRect(find.byType(ReactionActionMenu));
    expect(bar.bottom, lessThanOrEqualTo(message.top));
    expect(actions.top, greaterThanOrEqualTo(message.bottom));
    expect(message.center.dx, closeTo(menu.anchorRect.center.dx, 4));
    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  testWidgets('selecting an emoji closes and reports', (tester) async {
    String? emoji;
    await tester.pumpWidget(harness(PresenterLauncher(
      presenter: const FocusedOverlayPresenter(),
      menu: testMenu(onReactionSelected: (e) => emoji = e),
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('😂'));
    await tester.pumpAndSettle();
    expect(emoji, '😂');
    expect(find.byType(ReactionBar), findsNothing);
  });

  testWidgets('selecting an action closes and reports', (tester) async {
    ReactionAction? action;
    await tester.pumpWidget(harness(PresenterLauncher(
      presenter: const FocusedOverlayPresenter(),
      menu: testMenu(onActionSelected: (a) => action = a),
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reply'));
    await tester.pumpAndSettle();
    expect(action?.id, 'reply');
  });

  testWidgets('tapping the message copy dismisses', (tester) async {
    await tester.pumpWidget(harness(PresenterLauncher(
      presenter: const FocusedOverlayPresenter(),
      menu: testMenu(),
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('message-copy')), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(ReactionBar), findsNothing);
  });

  testWidgets('stays inside the safe area near the top edge', (tester) async {
    await tester.pumpWidget(harness(PresenterLauncher(
      presenter: const FocusedOverlayPresenter(),
      menu: testMenu(anchorRect: const Rect.fromLTWH(300, 0, 200, 60)),
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byType(ReactionBar)).top, greaterThanOrEqualTo(12));
  });

  testWidgets('showActions: false hides the menu', (tester) async {
    await tester.pumpWidget(harness(PresenterLauncher(
      presenter: const FocusedOverlayPresenter(showActions: false),
      menu: testMenu(),
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(ReactionActionMenu), findsNothing);
  });

  testWidgets('falls back to the bottom sheet at large text scale', (tester) async {
    await tester.pumpWidget(harness(
      PresenterLauncher(presenter: const FocusedOverlayPresenter(), menu: testMenu()),
      textScale: 2,
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('"+" opens more reactions after dismissing', (tester) async {
    var more = 0;
    await tester.pumpWidget(harness(PresenterLauncher(
      presenter: const FocusedOverlayPresenter(),
      menu: testMenu(onMoreTap: () async => more++),
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('More reactions'));
    await tester.pumpAndSettle();
    expect(more, 1);
    expect(find.byType(ReactionBar), findsNothing);
  });
}
```

Save as `test/presenters/focused_overlay_presenter_test.dart`.

- [ ] **Step 2: Run the test to confirm it fails**

Run: `flutter test test/presenters/focused_overlay_presenter_test.dart`
Expected: a compilation error.

- [ ] **Step 3: Implement `lib/src/presenters/focused_overlay_presenter.dart`**

```dart
import 'package:flutter/material.dart';

import '../l10n/chat_reactions_localizations.dart';
import '../layout/anchored_layout.dart';
import '../layout/reaction_alignment.dart';
import '../theme/chat_reactions_theme.dart';
import '../widgets/reaction_action_menu.dart';
import '../widgets/reaction_bar.dart';
import 'bottom_sheet_presenter.dart';
import 'menu_route.dart';
import 'reactions_menu_context.dart';
import 'reactions_presenter.dart';

/// The default presenter (iMessage/WhatsApp style): the page blurs and dims,
/// the message lifts in place, the reaction bar appears above it and the
/// action menu below, all kept inside the safe area.
///
/// Falls back to [fallback] when the text scale is at least
/// [fallbackTextScale] or the screen is shorter than [fallbackMinHeight].
class FocusedOverlayPresenter extends ReactionsPresenter {
  /// Creates a focused-overlay presenter.
  const FocusedOverlayPresenter({
    this.blurSigma,
    this.barrierColor,
    this.showMessage = true,
    this.showActions = true,
    this.lift,
    this.fallbackTextScale = 2.0,
    this.fallbackMinHeight = 400,
    this.fallback = const BottomSheetPresenter(),
  });

  /// Backdrop blur; defaults to the theme's overlay blur.
  final double? blurSigma;

  /// Backdrop tint; defaults to the theme's overlay barrier color.
  final Color? barrierColor;

  /// Whether to draw the lifted message copy.
  final bool showMessage;

  /// Whether to show the action menu.
  final bool showActions;

  /// Scale of the lifted message; defaults to the theme's overlay lift.
  final double? lift;

  /// Text scale at or above which [fallback] is used.
  final double fallbackTextScale;

  /// Screen height below which [fallback] is used.
  final double fallbackMinHeight;

  /// Presenter used when the overlay would not fit.
  final ReactionsPresenter fallback;

  @override
  Future<void> show(BuildContext context, ReactionsMenuContext menu) {
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    if (textScale >= fallbackTextScale ||
        MediaQuery.sizeOf(context).height < fallbackMinHeight) {
      return fallback.show(context, menu);
    }
    final theme = ChatReactionsTheme.of(context);
    final overlay = theme.overlayStyle;
    final route = ReactionsMenuRoute(
      menu: menu,
      duration: theme.animationDuration!,
      curve: theme.animationCurve!,
      barrierTint: barrierColor ?? overlay.barrierColor,
      blurSigma: blurSigma ?? overlay.blurSigma!,
      barrierLabel: ChatReactionsLocalizations.of(context).dismissMenu,
      builder: (context, animation) => _FocusedMenu(
        menu: menu,
        animation: animation,
        showMessage: showMessage,
        showActions: showActions,
        lift: lift ?? overlay.lift!,
        shadows: overlay.messageShadows!,
      ),
    );
    return showReactionsMenuRoute(context, menu, route);
  }
}

class _FocusedMenu extends StatelessWidget {
  const _FocusedMenu({
    required this.menu,
    required this.animation,
    required this.showMessage,
    required this.showActions,
    required this.lift,
    required this.shadows,
  });

  final ReactionsMenuContext menu;
  final Animation<double> animation;
  final bool showMessage;
  final bool showActions;
  final double lift;
  final List<BoxShadow> shadows;

  @override
  Widget build(BuildContext context) {
    final alignRight = (menu.alignment == ReactionAlignment.end) ==
        (menu.textDirection == TextDirection.ltr);
    final origin = alignRight ? Alignment.bottomRight : Alignment.bottomLeft;

    final bar = FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        alignment: origin,
        scale: Tween<double>(begin: 0.8, end: 1).animate(animation),
        child: ReactionBar(
          reactions: menu.quickReactions,
          selected: menu.selectedReactions,
          onSelected: menu.selectReaction,
          onMore: menu.hasMore ? menu.openMore : null,
          emojiBuilder: menu.emojiBuilder,
        ),
      ),
    );

    final message = showMessage
        ? IgnorePointer(
            child: ScaleTransition(
              scale: Tween<double>(begin: 1, end: lift).animate(animation),
              child: DecoratedBox(
                decoration: BoxDecoration(boxShadow: shadows),
                child: menu.messageBuilder(context),
              ),
            ),
          )
        : null;

    final actions = showActions && menu.actions.isNotEmpty
        ? FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              alignment: alignRight ? Alignment.topRight : Alignment.topLeft,
              scale: Tween<double>(begin: 0.9, end: 1).animate(animation),
              child: ReactionActionMenu(
                actions: menu.actions,
                onSelected: menu.selectAction,
              ),
            ),
          )
        : null;

    return Directionality(
      textDirection: menu.textDirection,
      child: AnchoredLayout(
        anchorRect: menu.anchorRect,
        alignment: menu.alignment,
        header: bar,
        anchor: message,
        footer: actions,
      ),
    );
  }
}
```

Append to the barrel: `export 'src/presenters/focused_overlay_presenter.dart';`

- [ ] **Step 4: Run and commit**

Run: `flutter test && flutter analyze --fatal-infos`
Expected: pass.

```bash
git add lib test/presenters
git commit -m "feat: Add FocusedOverlayPresenter with safe-area layout and sheet fallback

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 12: `CompactBarPresenter`

**Files:**
- Create: `lib/src/presenters/compact_bar_presenter.dart`
- Modify: barrel
- Test: `test/presenters/compact_bar_presenter_test.dart`

**Interfaces:**
- Consumes: `ReactionsMenuRoute`, `showReactionsMenuRoute`, `AnchoredLayout`, `ReactionBar`, `ReactionActionMenu`, `ReactionTrigger`.
- Produces: `CompactBarPresenter({Duration hoverDelay = const Duration(milliseconds: 300), Duration hoverExitDelay = const Duration(milliseconds: 200), bool actionsOverflow = true})`. `ReactableMessage` reads `hoverDelay` in Task 13.

- [ ] **Step 1: Write the failing tests**

```dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  testWidgets('shows only the bar, no blur and no message copy', (tester) async {
    await tester.pumpWidget(harness(PresenterLauncher(
      presenter: const CompactBarPresenter(),
      menu: testMenu(),
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(ReactionBar), findsOneWidget);
    expect(find.byType(BackdropFilter), findsNothing);
    expect(find.byKey(const Key('message-copy')), findsNothing);
    expect(find.byType(ReactionActionMenu), findsNothing);
  });

  testWidgets('"⋯" toggles the action menu', (tester) async {
    ReactionAction? action;
    await tester.pumpWidget(harness(PresenterLauncher(
      presenter: const CompactBarPresenter(),
      menu: testMenu(onActionSelected: (a) => action = a),
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('More actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reply'));
    await tester.pumpAndSettle();
    expect(action?.id, 'reply');
    expect(find.byType(ReactionBar), findsNothing);
  });

  testWidgets('actionsOverflow: false hides "⋯"', (tester) async {
    await tester.pumpWidget(harness(PresenterLauncher(
      presenter: const CompactBarPresenter(actionsOverflow: false),
      menu: testMenu(),
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('More actions'), findsNothing);
  });

  testWidgets('hover-opened bar closes after the pointer leaves both areas', (tester) async {
    final menu = testMenu(trigger: ReactionTrigger.hover);
    await tester.pumpWidget(harness(
      PresenterLauncher(presenter: const CompactBarPresenter(), menu: menu),
      platform: TargetPlatform.macOS,
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: menu.anchorRect.center);
    await tester.pump();

    // Move onto the bar: stays open.
    await mouse.moveTo(tester.getCenter(find.byType(ReactionBar)));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(ReactionBar), findsOneWidget);

    // Leave everything: closes after the exit delay.
    await mouse.moveTo(const Offset(5, 590));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();
    expect(find.byType(ReactionBar), findsNothing);
  });

  testWidgets('long-press-opened bar ignores hover exit', (tester) async {
    final menu = testMenu();
    await tester.pumpWidget(harness(PresenterLauncher(presenter: const CompactBarPresenter(), menu: menu)));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: const Offset(5, 590));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(ReactionBar), findsOneWidget);
  });
}
```

Save as `test/presenters/compact_bar_presenter_test.dart`.

- [ ] **Step 2: Run the test to confirm it fails**

Run: `flutter test test/presenters/compact_bar_presenter_test.dart`
Expected: a compilation error.

- [ ] **Step 3: Implement `lib/src/presenters/compact_bar_presenter.dart`**

```dart
import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/chat_reactions_localizations.dart';
import '../layout/anchored_layout.dart';
import '../theme/chat_reactions_theme.dart';
import '../trigger/reaction_trigger.dart';
import '../widgets/reaction_action_menu.dart';
import '../widgets/reaction_bar.dart';
import 'menu_route.dart';
import 'reactions_menu_context.dart';
import 'reactions_presenter.dart';

/// A small floating reaction bar attached to the message (Slack/Discord
/// style). No blur. On desktop it can open on hover and stays open while the
/// pointer is over the message or the bar.
class CompactBarPresenter extends ReactionsPresenter {
  /// Creates a compact-bar presenter.
  const CompactBarPresenter({
    this.hoverDelay = const Duration(milliseconds: 300),
    this.hoverExitDelay = const Duration(milliseconds: 200),
    this.actionsOverflow = true,
  });

  /// How long the pointer must rest on a message before the bar opens.
  final Duration hoverDelay;

  /// How long after the pointer leaves the message and bar before closing.
  final Duration hoverExitDelay;

  /// Whether to add a "⋯" button that reveals the message actions.
  final bool actionsOverflow;

  @override
  Future<void> show(BuildContext context, ReactionsMenuContext menu) {
    final theme = ChatReactionsTheme.of(context);
    final route = ReactionsMenuRoute(
      menu: menu,
      duration: theme.animationDuration!,
      curve: theme.animationCurve!,
      barrierLabel: ChatReactionsLocalizations.of(context).dismissMenu,
      builder: (context, animation) => _CompactMenu(
        menu: menu,
        animation: animation,
        presenter: this,
      ),
    );
    return showReactionsMenuRoute(context, menu, route);
  }
}

class _CompactMenu extends StatefulWidget {
  const _CompactMenu({
    required this.menu,
    required this.animation,
    required this.presenter,
  });

  final ReactionsMenuContext menu;
  final Animation<double> animation;
  final CompactBarPresenter presenter;

  @override
  State<_CompactMenu> createState() => _CompactMenuState();
}

class _CompactMenuState extends State<_CompactMenu> {
  bool _overAnchor = true;
  bool _overBar = false;
  bool _showActions = false;
  Timer? _exitTimer;

  bool get _hoverMode => widget.menu.trigger == ReactionTrigger.hover;

  void _update() {
    _exitTimer?.cancel();
    if (!_hoverMode || _overAnchor || _overBar) return;
    _exitTimer = Timer(widget.presenter.hoverExitDelay, widget.menu.dismiss);
  }

  @override
  void dispose() {
    _exitTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final menu = widget.menu;
    final animation = widget.animation;
    final canShowActions = widget.presenter.actionsOverflow && menu.actions.isNotEmpty;

    final bar = MouseRegion(
      onEnter: (_) {
        _overBar = true;
        _update();
      },
      onExit: (_) {
        _overBar = false;
        _update();
      },
      child: FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1).animate(animation),
          child: ReactionBar(
            reactions: menu.quickReactions,
            selected: menu.selectedReactions,
            onSelected: menu.selectReaction,
            onMore: menu.hasMore ? menu.openMore : null,
            onMoreActions: canShowActions
                ? () => setState(() => _showActions = !_showActions)
                : null,
            emojiBuilder: menu.emojiBuilder,
          ),
        ),
      ),
    );

    return Directionality(
      textDirection: menu.textDirection,
      child: Stack(
        children: [
          Positioned.fromRect(
            rect: menu.anchorRect,
            child: MouseRegion(
              opaque: false,
              onEnter: (_) {
                _overAnchor = true;
                _update();
              },
              onExit: (_) {
                _overAnchor = false;
                _update();
              },
              child: const SizedBox.expand(),
            ),
          ),
          Positioned.fill(
            child: AnchoredLayout(
              anchorRect: menu.anchorRect,
              alignment: menu.alignment,
              header: bar,
              footer: _showActions
                  ? ReactionActionMenu(
                      actions: menu.actions,
                      onSelected: menu.selectAction,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
```

Append to the barrel: `export 'src/presenters/compact_bar_presenter.dart';`

- [ ] **Step 4: Run and commit**

Run: `flutter test && flutter analyze --fatal-infos`
Expected: pass. If the hover test fails because the anchor `MouseRegion` never gets `onExit`, the pointer was added after the route was built. `_overAnchor` starts as `true`, and the move to the bar then the move away still triggers exit, so check the order of the `moveTo` calls before changing any code.

```bash
git add lib test/presenters
git commit -m "feat: Add CompactBarPresenter with hover persistence and actions overflow

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 13: `ReactableMessage` and `ChatReactionsScope`

**Files:**
- Create: `lib/src/trigger/chat_reactions_scope.dart`, `lib/src/trigger/reactable_message.dart`
- Modify: `lib/src/l10n/chat_reactions_localizations.dart` (`of` checks the scope first), barrel
- Test: `test/trigger/reactable_message_test.dart`, `test/trigger/chat_reactions_scope_test.dart`

**Interfaces:**
- Consumes: everything above.
- Produces:
  - `typedef ReactionActionsBuilder = List<ReactionAction> Function(BuildContext context);`
  - `typedef MoreReactionsCallback = Future<void> Function(BuildContext context);`
  - `const List<String> kDefaultQuickReactions`.
  - `ChatReactionsScope({Key? key, required Widget child, ReactionsPresenter? presenter, List<String>? quickReactions, Set<ReactionTrigger>? triggers, ReactionActionsBuilder? actionsBuilder, MoreReactionsCallback? onMoreTap, EmojiBuilder? emojiBuilder, ChatReactionsLocalizations? localizations})` with `static ChatReactionsScope? maybeOf(BuildContext)`.
  - `ReactableMessage({Key? key, required Widget child, List<ReactionSummary> reactions = const [], List<String>? quickReactions, ReactionActionsBuilder? actionsBuilder, ValueChanged<String>? onReactionSelected, ValueChanged<ReactionAction>? onActionSelected, MoreReactionsCallback? onMoreTap, ReactionsPresenter? presenter, Set<ReactionTrigger>? triggers, ReactionAlignment alignment = ReactionAlignment.end, bool enabled = true, EmojiBuilder? emojiBuilder, String? semanticLabel})`.

- [ ] **Step 1: Write the failing tests**

`test/trigger/reactable_message_test.dart`:

```dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

const bubbleKey = Key('bubble');

class RecordingPresenter extends ReactionsPresenter {
  RecordingPresenter();
  final List<ReactionsMenuContext> shown = [];

  @override
  Future<void> show(BuildContext context, ReactionsMenuContext menu) async {
    shown.add(menu);
  }
}

Widget message({
  ReactionsPresenter? presenter,
  Set<ReactionTrigger>? triggers,
  ValueChanged<String>? onReactionSelected,
  MoreReactionsCallback? onMoreTap,
  ReactionActionsBuilder? actionsBuilder,
  bool enabled = true,
}) =>
    Center(
      child: ReactableMessage(
        presenter: presenter,
        triggers: triggers,
        onReactionSelected: onReactionSelected,
        onMoreTap: onMoreTap,
        actionsBuilder: actionsBuilder,
        enabled: enabled,
        reactions: const [ReactionSummary(emoji: '👍', count: 1, reactedByMe: true)],
        child: const SizedBox(
          key: bubbleKey,
          width: 180,
          height: 50,
          child: ColoredBox(color: Colors.green),
        ),
      ),
    );

void main() {
  testWidgets('long press opens the default focused overlay', (tester) async {
    String? emoji;
    await tester.pumpWidget(harness(message(onReactionSelected: (e) => emoji = e)));
    await tester.longPress(find.byKey(bubbleKey));
    await tester.pumpAndSettle();

    expect(find.byType(ReactionBar), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);
    await tester.tap(find.text('❤️'));
    await tester.pumpAndSettle();
    expect(emoji, '❤️');
  });

  testWidgets('menu context carries the anchor rect and data', (tester) async {
    final presenter = RecordingPresenter();
    await tester.pumpWidget(harness(message(
      presenter: presenter,
      actionsBuilder: (_) => const [ReactionAction<void>(id: 'copy', label: 'Copy')],
    )));
    await tester.longPress(find.byKey(bubbleKey));
    final menu = presenter.shown.single;
    expect(menu.anchorRect, tester.getRect(find.byKey(bubbleKey)));
    expect(menu.quickReactions, kDefaultQuickReactions);
    expect(menu.actions.single.id, 'copy');
    expect(menu.selectedReactions, {'👍'});
    expect(menu.hasMore, isFalse);
  });

  testWidgets('desktop defaults: right-click opens, long press does not', (tester) async {
    final presenter = RecordingPresenter();
    await tester.pumpWidget(harness(message(presenter: presenter), platform: TargetPlatform.windows));
    await tester.longPress(find.byKey(bubbleKey));
    expect(presenter.shown, isEmpty);
    await tester.tap(find.byKey(bubbleKey), buttons: kSecondaryButton);
    expect(presenter.shown.single.trigger, ReactionTrigger.secondaryTap);
  });

  testWidgets('double tap trigger', (tester) async {
    final presenter = RecordingPresenter();
    await tester.pumpWidget(harness(message(
      presenter: presenter,
      triggers: {ReactionTrigger.doubleTap},
    )));
    await tester.tap(find.byKey(bubbleKey));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byKey(bubbleKey));
    await tester.pumpAndSettle();
    expect(presenter.shown.single.trigger, ReactionTrigger.doubleTap);
  });

  testWidgets('keyboard: Enter on the focused message opens', (tester) async {
    final presenter = RecordingPresenter();
    await tester.pumpWidget(harness(message(presenter: presenter)));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(presenter.shown.single.trigger, ReactionTrigger.keyboard);
  });

  testWidgets('hover opens CompactBarPresenter after the delay', (tester) async {
    await tester.pumpWidget(harness(
      ChatReactionsScope(
        presenter: const CompactBarPresenter(),
        child: Center(
          child: ReactableMessage(
            onReactionSelected: (_) {},
            child: const SizedBox(key: bubbleKey, width: 180, height: 50),
          ),
        ),
      ),
      platform: TargetPlatform.macOS,
    ));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.byKey(bubbleKey)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(ReactionBar), findsNothing);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();
    expect(find.byType(ReactionBar), findsOneWidget);
  });

  testWidgets('semantics action opens the menu', (tester) async {
    final presenter = RecordingPresenter();
    await tester.pumpWidget(harness(message(presenter: presenter)));
    final semantics = tester.widget<Semantics>(find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.customSemanticsActions != null,
    ));
    final actions = semantics.properties.customSemanticsActions!;
    expect(actions.keys.single.label, 'Open reactions menu');
    actions.values.single();
    await tester.pump();
    expect(presenter.shown, hasLength(1));
  });

  testWidgets('disabled messages do not open', (tester) async {
    final presenter = RecordingPresenter();
    await tester.pumpWidget(harness(message(presenter: presenter, enabled: false)));
    await tester.longPress(find.byKey(bubbleKey));
    expect(presenter.shown, isEmpty);
  });

  testWidgets('onMoreTap receives the message context', (tester) async {
    BuildContext? moreContext;
    await tester.pumpWidget(harness(message(onMoreTap: (context) async => moreContext = context)));
    await tester.longPress(find.byKey(bubbleKey));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('More reactions'));
    await tester.pumpAndSettle();
    expect(moreContext, isNotNull);
    expect(moreContext!.mounted, isTrue);
  });

  testWidgets('removing the message while open closes the menu', (tester) async {
    var show = true;
    late StateSetter setOuter;
    await tester.pumpWidget(harness(StatefulBuilder(builder: (context, setState) {
      setOuter = setState;
      return show ? message() : const SizedBox();
    })));
    await tester.longPress(find.byKey(bubbleKey));
    await tester.pumpAndSettle();
    expect(find.byType(ReactionBar), findsOneWidget);
    setOuter(() => show = false);
    await tester.pumpAndSettle();
    expect(find.byType(ReactionBar), findsNothing);
  });

  testWidgets('does not open twice while open', (tester) async {
    final presenter = CustomPresenter(builder: (_, __, ___) => const SizedBox());
    await tester.pumpWidget(harness(message(presenter: presenter)));
    await tester.longPress(find.byKey(bubbleKey));
    await tester.pumpAndSettle();
    final routes = find.byType(SizedBox).evaluate().length;
    await tester.longPress(find.byKey(bubbleKey), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(SizedBox).evaluate().length, routes);
  });
}
```

`test/trigger/chat_reactions_scope_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

class _Recording extends ReactionsPresenter {
  ReactionsMenuContext? last;
  @override
  Future<void> show(BuildContext context, ReactionsMenuContext menu) async => last = menu;
}

void main() {
  testWidgets('scope supplies defaults; widget arguments win', (tester) async {
    final scoped = _Recording();
    await tester.pumpWidget(harness(ChatReactionsScope(
      presenter: scoped,
      quickReactions: const ['🔥'],
      actionsBuilder: (_) => const [ReactionAction<void>(id: 'pin', label: 'Pin')],
      child: Column(children: [
        ReactableMessage(child: const SizedBox(key: Key('a'), width: 50, height: 50)),
        ReactableMessage(
          quickReactions: const ['✅'],
          child: const SizedBox(key: Key('b'), width: 50, height: 50),
        ),
      ]),
    )));

    await tester.longPress(find.byKey(const Key('a')));
    expect(scoped.last!.quickReactions, ['🔥']);
    expect(scoped.last!.actions.single.id, 'pin');

    await tester.longPress(find.byKey(const Key('b')));
    expect(scoped.last!.quickReactions, ['✅']);
  });

  testWidgets('scope localizations override the delegate', (tester) async {
    late ChatReactionsLocalizations l10n;
    await tester.pumpWidget(harness(ChatReactionsScope(
      localizations: const _Custom(),
      child: Builder(builder: (context) {
        l10n = ChatReactionsLocalizations.of(context);
        return const SizedBox();
      }),
    )));
    expect(l10n.cancel, 'Abbrechen');
  });
}

class _Custom extends DefaultChatReactionsLocalizations {
  const _Custom();
  @override
  String get cancel => 'Abbrechen';
}
```

- [ ] **Step 2: Run the tests to confirm they fail**

Run: `flutter test test/trigger`
Expected: compilation errors.

- [ ] **Step 3: Implement `lib/src/trigger/chat_reactions_scope.dart`**

```dart
import 'package:flutter/widgets.dart';

import '../l10n/chat_reactions_localizations.dart';
import '../models/reaction_action.dart';
import '../presenters/reactions_presenter.dart';
import '../widgets/emoji.dart';
import 'reaction_trigger.dart';

/// Builds the context-menu actions for one message.
typedef ReactionActionsBuilder = List<ReactionAction> Function(
  BuildContext context,
);

/// Opens a full emoji picker. [context] belongs to the message and is still
/// mounted when this is called.
typedef MoreReactionsCallback = Future<void> Function(BuildContext context);

/// Quick reactions used when neither the message nor a scope sets any.
const List<String> kDefaultQuickReactions = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

/// Provides defaults for every `ReactableMessage` below it. A message's own
/// arguments take precedence.
class ChatReactionsScope extends InheritedWidget {
  /// Creates a scope.
  const ChatReactionsScope({
    super.key,
    required super.child,
    this.presenter,
    this.quickReactions,
    this.triggers,
    this.actionsBuilder,
    this.onMoreTap,
    this.emojiBuilder,
    this.localizations,
  });

  /// Default presenter.
  final ReactionsPresenter? presenter;

  /// Default quick reactions.
  final List<String>? quickReactions;

  /// Default triggers.
  final Set<ReactionTrigger>? triggers;

  /// Default actions builder.
  final ReactionActionsBuilder? actionsBuilder;

  /// Default "more reactions" callback.
  final MoreReactionsCallback? onMoreTap;

  /// Default emoji rendering.
  final EmojiBuilder? emojiBuilder;

  /// Strings override, taking precedence over localization delegates.
  final ChatReactionsLocalizations? localizations;

  /// The nearest scope, or null.
  static ChatReactionsScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ChatReactionsScope>();

  @override
  bool updateShouldNotify(ChatReactionsScope oldWidget) =>
      presenter != oldWidget.presenter ||
      quickReactions != oldWidget.quickReactions ||
      triggers != oldWidget.triggers ||
      actionsBuilder != oldWidget.actionsBuilder ||
      onMoreTap != oldWidget.onMoreTap ||
      emojiBuilder != oldWidget.emojiBuilder ||
      localizations != oldWidget.localizations;
}
```

In `lib/src/l10n/chat_reactions_localizations.dart`, add `import '../trigger/chat_reactions_scope.dart';` and change `of` to:

```dart
  static ChatReactionsLocalizations of(BuildContext context) =>
      ChatReactionsScope.maybeOf(context)?.localizations ??
      Localizations.of<ChatReactionsLocalizations>(
        context,
        ChatReactionsLocalizations,
      ) ??
      const DefaultChatReactionsLocalizations();
```

Update the doc comment above `of` to mention `ChatReactionsScope.localizations` first.

- [ ] **Step 4: Implement `lib/src/trigger/reactable_message.dart`**

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../l10n/chat_reactions_localizations.dart';
import '../layout/reaction_alignment.dart';
import '../models/reaction_action.dart';
import '../models/reaction_summary.dart';
import '../presenters/compact_bar_presenter.dart';
import '../presenters/focused_overlay_presenter.dart';
import '../presenters/reactions_menu_context.dart';
import '../presenters/reactions_presenter.dart';
import '../theme/adaptive.dart';
import '../theme/chat_reactions_theme.dart';
import '../widgets/emoji.dart';
import 'chat_reactions_scope.dart';
import 'reaction_trigger.dart';

/// Makes [child] (a chat message) open a reactions menu on long press,
/// right-click, hover, keyboard or an accessibility action.
///
/// Reaction data is owned by your app: pass the message's [reactions] and
/// handle [onReactionSelected]. Unset options fall back to the nearest
/// [ChatReactionsScope], then to built-in defaults.
///
/// The menu rebuilds [child] inside the root overlay, so [child] must not
/// depend on inherited widgets that exist only below the chat screen, and
/// must not contain a `GlobalKey`.
class ReactableMessage extends StatefulWidget {
  /// Creates a reactable message.
  const ReactableMessage({
    super.key,
    required this.child,
    this.reactions = const [],
    this.quickReactions,
    this.actionsBuilder,
    this.onReactionSelected,
    this.onActionSelected,
    this.onMoreTap,
    this.presenter,
    this.triggers,
    this.alignment = ReactionAlignment.end,
    this.enabled = true,
    this.emojiBuilder,
    this.semanticLabel,
  });

  /// The message widget.
  final Widget child;

  /// The message's current reactions (used to highlight the user's choices).
  final List<ReactionSummary> reactions;

  /// Emojis in the reaction bar.
  final List<String>? quickReactions;

  /// Builds this message's context-menu actions.
  final ReactionActionsBuilder? actionsBuilder;

  /// Called with the emoji the user tapped.
  final ValueChanged<String>? onReactionSelected;

  /// Called with the action the user tapped.
  final ValueChanged<ReactionAction>? onActionSelected;

  /// Opens a full emoji picker; the "+" button is hidden when null.
  final MoreReactionsCallback? onMoreTap;

  /// How the menu is shown.
  final ReactionsPresenter? presenter;

  /// Which inputs open the menu.
  final Set<ReactionTrigger>? triggers;

  /// Side of the message the menu aligns to.
  final ReactionAlignment alignment;

  /// Whether the menu can be opened.
  final bool enabled;

  /// Custom emoji rendering.
  final EmojiBuilder? emojiBuilder;

  /// Accessible label for the message.
  final String? semanticLabel;

  @override
  State<ReactableMessage> createState() => _ReactableMessageState();
}

class _ReactableMessageState extends State<ReactableMessage> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'ReactableMessage');
  ReactionsMenuContext? _menu;
  Timer? _hoverTimer;

  ChatReactionsScope? get _scope => ChatReactionsScope.maybeOf(context);

  ReactionsPresenter get _presenter =>
      widget.presenter ?? _scope?.presenter ?? const FocusedOverlayPresenter();

  Set<ReactionTrigger> get _triggers =>
      widget.triggers ??
      _scope?.triggers ??
      defaultReactionTriggers(Theme.of(context).platform);

  Future<void> _open(ReactionTrigger trigger) async {
    if (_menu != null || !widget.enabled || !mounted) return;
    final scope = _scope;
    final platform = Theme.of(context).platform;
    final theme = ChatReactionsTheme.of(context);
    final box = context.findRenderObject()! as RenderBox;
    final overlayBox = Navigator.of(context, rootNavigator: true)
        .overlay!
        .context
        .findRenderObject()! as RenderBox;
    final rect = box.localToGlobal(Offset.zero, ancestor: overlayBox) & box.size;
    final actionsBuilder = widget.actionsBuilder ?? scope?.actionsBuilder;
    final onMore = widget.onMoreTap ?? scope?.onMoreTap;

    performReactionHaptic(theme.haptics!, platform);
    final menu = ReactionsMenuContext(
      anchorRect: rect,
      messageBuilder: (_) => widget.child,
      quickReactions:
          widget.quickReactions ?? scope?.quickReactions ?? kDefaultQuickReactions,
      reactions: widget.reactions,
      actions: actionsBuilder?.call(context) ?? const [],
      alignment: widget.alignment,
      textDirection: Directionality.of(context),
      trigger: trigger,
      emojiBuilder: widget.emojiBuilder ?? scope?.emojiBuilder,
      onReactionSelected: (emoji) {
        performReactionHaptic(theme.haptics!, platform);
        widget.onReactionSelected?.call(emoji);
      },
      onActionSelected: widget.onActionSelected,
      onMoreTap: onMore == null ? null : () => onMore(context),
    );

    _menu = menu;
    try {
      await _presenter.show(context, menu);
    } finally {
      _menu = null;
      if (mounted && trigger == ReactionTrigger.keyboard) {
        _focusNode.requestFocus();
      }
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final shift = HardwareKeyboard.instance.isShiftPressed;
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.contextMenu ||
        (shift && key == LogicalKeyboardKey.f10)) {
      unawaited(_open(ReactionTrigger.keyboard));
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    _hoverTimer?.cancel();
    _menu?.dismiss();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final triggers = _triggers;
    final enabled = widget.enabled;
    final presenter = _presenter;
    Widget result = widget.child;

    if (enabled) {
      result = GestureDetector(
        onLongPress: triggers.contains(ReactionTrigger.longPress)
            ? () => _open(ReactionTrigger.longPress)
            : null,
        onDoubleTap: triggers.contains(ReactionTrigger.doubleTap)
            ? () => _open(ReactionTrigger.doubleTap)
            : null,
        onSecondaryTap: triggers.contains(ReactionTrigger.secondaryTap)
            ? () => _open(ReactionTrigger.secondaryTap)
            : null,
        child: result,
      );
      if (triggers.contains(ReactionTrigger.hover) &&
          presenter is CompactBarPresenter) {
        result = MouseRegion(
          onEnter: (_) {
            _hoverTimer?.cancel();
            _hoverTimer = Timer(
              presenter.hoverDelay,
              () => _open(ReactionTrigger.hover),
            );
          },
          onExit: (_) => _hoverTimer?.cancel(),
          child: result,
        );
      }
    }

    final keyboard = enabled && triggers.contains(ReactionTrigger.keyboard);
    result = Focus(
      focusNode: _focusNode,
      canRequestFocus: keyboard,
      skipTraversal: !keyboard,
      onKeyEvent: keyboard ? _onKey : null,
      child: result,
    );

    return Semantics(
      container: true,
      label: widget.semanticLabel,
      customSemanticsActions: enabled
          ? {
              CustomSemanticsAction(
                label: ChatReactionsLocalizations.of(context).openReactionsMenu,
              ): () => _open(ReactionTrigger.keyboard),
            }
          : null,
      child: result,
    );
  }
}
```

Append to the barrel:

```dart
export 'src/trigger/chat_reactions_scope.dart';
export 'src/trigger/reactable_message.dart';
```

- [ ] **Step 5: Run and commit**

Run: `flutter test && flutter analyze --fatal-infos`
Expected: pass. If the semantics-action test cannot find the node through `find.byKey(bubbleKey)`, use `find.byType(ReactableMessage)` instead; `getSemantics` returns the nearest node that has semantics.

```bash
git add lib test/trigger
git commit -m "feat!: Add ReactableMessage and ChatReactionsScope

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 14: Cross-cutting accessibility checks (RTL, keyboard traversal, reduced motion)

**Files:**
- Test: `test/a11y/accessibility_test.dart`
- Modify: any `lib/` file only if a test exposes a gap

**Interfaces:**
- Consumes: the public API.
- Produces: regression tests for spec §9.

- [ ] **Step 1: Write the tests**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  testWidgets('RTL: end alignment anchors the bar to the message left edge', (tester) async {
    final menu = testMenu(
      anchorRect: const Rect.fromLTWH(40, 250, 200, 60),
      textDirection: TextDirection.rtl,
    );
    await tester.pumpWidget(harness(
      PresenterLauncher(presenter: const FocusedOverlayPresenter(), menu: menu),
      textDirection: TextDirection.rtl,
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byType(ReactionBar)).left, 40);
  });

  testWidgets('keyboard: Tab reaches the first emoji, Enter selects it', (tester) async {
    String? emoji;
    await tester.pumpWidget(harness(PresenterLauncher(
      presenter: const FocusedOverlayPresenter(),
      menu: testMenu(onReactionSelected: (e) => emoji = e),
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(emoji, '👍');
  });

  testWidgets('reduced motion: menu is fully visible after one frame', (tester) async {
    await tester.pumpWidget(harness(
      PresenterLauncher(presenter: const FocusedOverlayPresenter(), menu: testMenu()),
      disableAnimations: true,
    ));
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump();
    final fades = tester.widgetList<FadeTransition>(
      find.ancestor(of: find.text('😂'), matching: find.byType(FadeTransition)),
    );
    expect(fades.every((f) => f.opacity.value == 1), isTrue);
  });

  testWidgets('bar buttons expose names and selection', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(harness(PresenterLauncher(
      presenter: const FocusedOverlayPresenter(),
      menu: testMenu(reactions: const [ReactionSummary(emoji: '❤️', count: 2, reactedByMe: true)]),
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.bySemanticsLabel('red heart')),
      containsSemantics(isButton: true, isSelected: true),
    );
    handle.dispose();
  });

  testWidgets('focus returns to the message after keyboard-opened menu closes', (tester) async {
    await tester.pumpWidget(harness(Center(
      child: ReactableMessage(
        onReactionSelected: (_) {},
        child: const SizedBox(width: 100, height: 40),
      ),
    )));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final messageFocus = FocusManager.instance.primaryFocus;
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus, messageFocus);
  });
}
```

- [ ] **Step 2: Run the tests and fix any gaps**

Run: `flutter test test/a11y`
Expected: pass. If a test fails, debug it with superpowers:systematic-debugging and fix `lib/` code, not the test, unless the test itself is wrong. Likely gaps:
- The reduced-motion test needs `ChatReactionsTheme.of` to see `disableAnimations`. The harness sets it through `MaterialApp.builder`, which sits above the routes, so it should.

- [ ] **Step 3: Commit**

```bash
git add test/a11y lib
git commit -m "test: Add accessibility regression tests for RTL, keyboard, and reduced motion

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 15: Golden tests (Linux-generated) and the golden update workflow

**Files:**
- Create: `dart_test.yaml`, `test/goldens/goldens_test.dart`, `.github/workflows/update-goldens.yml`
- Modify: `.github/workflows/ci.yml` (exclude goldens on the `3.32.x` leg)
- Generated (by CI): `test/goldens/*.png`

**Interfaces:**
- Consumes: `ReactionBar`, `ReactionActionMenu`, `ReactionsSummaryView`, `FocusedOverlayPresenter`, `harness`, `testMenu`, `PresenterLauncher`.
- Produces: 16 golden images, from 4 components × light/dark × material/cupertino. Goldens only run on Linux, and are generated by the `update-goldens` workflow.

- [ ] **Step 1: Tag configuration**

`dart_test.yaml`:

```yaml
tags:
  golden:
    description: Pixel comparisons; generated and verified on Linux only.
```

- [ ] **Step 2: Write the golden tests**

`test/goldens/goldens_test.dart`:

```dart
@Tags(['golden'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

final bool _skip = !Platform.isLinux;

const _actions = [
  ReactionAction<void>(id: 'reply', label: 'Reply', icon: Icons.reply),
  ReactionAction<void>(id: 'copy', label: 'Copy', icon: Icons.copy),
  ReactionAction<void>(id: 'delete', label: 'Delete', icon: Icons.delete, isDestructive: true),
];

const _summaries = [
  ReactionSummary(emoji: '👍', count: 3, reactedByMe: true),
  ReactionSummary(emoji: '❤️', count: 1),
];

void main() {
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    for (final brightness in Brightness.values) {
      final variant = '${platform == TargetPlatform.iOS ? 'cupertino' : 'material'}_${brightness.name}';

      Widget wrap(Widget child) => harness(
            RepaintBoundary(
              key: const Key('golden'),
              child: Padding(padding: const EdgeInsets.all(16), child: child),
            ),
            platform: platform,
            brightness: brightness,
          );

      testWidgets('bar $variant', (tester) async {
        await tester.pumpWidget(wrap(ReactionBar(
          reactions: kDefaultQuickReactions,
          selected: const {'❤️'},
          onSelected: (_) {},
          onMore: () {},
        )));
        await tester.pumpAndSettle();
        await expectLater(find.byKey(const Key('golden')), matchesGoldenFile('bar_$variant.png'));
      }, skip: _skip);

      testWidgets('menu $variant', (tester) async {
        await tester.pumpWidget(wrap(ReactionActionMenu(actions: _actions, onSelected: (_) {})));
        await expectLater(find.byKey(const Key('golden')), matchesGoldenFile('menu_$variant.png'));
      }, skip: _skip);

      testWidgets('chips $variant', (tester) async {
        await tester.pumpWidget(wrap(const ReactionsSummaryView(reactions: _summaries)));
        await tester.pumpAndSettle();
        await expectLater(find.byKey(const Key('golden')), matchesGoldenFile('chips_$variant.png'));
      }, skip: _skip);

      testWidgets('focused overlay $variant', (tester) async {
        await tester.pumpWidget(harness(
          PresenterLauncher(presenter: const FocusedOverlayPresenter(), menu: testMenu()),
          platform: platform,
          brightness: brightness,
        ));
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        await expectLater(find.byType(MaterialApp), matchesGoldenFile('overlay_$variant.png'));
      }, skip: _skip);
    }
  }
}
```

- [ ] **Step 3: Golden update workflow**

`.github/workflows/update-goldens.yml`:

```yaml
name: Update goldens

on:
  workflow_dispatch:

permissions:
  contents: write

jobs:
  update:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true
      - run: flutter pub get
      - run: flutter test --tags golden --update-goldens
      - name: Commit goldens
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
          git add test/goldens/*.png
          git diff --cached --quiet || git commit -m "test: Update golden images"
          git push
```

- [ ] **Step 4: Exclude goldens on the older Flutter leg in `ci.yml`**

Replace the `Test with coverage` step with:

```yaml
      - name: Test with coverage
        run: |
          if [ "${{ matrix.flutter }}" = "stable" ]; then
            flutter test --coverage
          else
            flutter test --coverage --exclude-tags golden
          fi
```

- [ ] **Step 5: Verify locally that the goldens are skipped on non-Linux machines**

Run: `flutter test test/goldens`
Expected: 16 tests reported as skipped on Windows and macOS.

- [ ] **Step 6: Commit, push, generate the goldens in CI, and pull**

```bash
git add dart_test.yaml test/goldens/goldens_test.dart .github/workflows/update-goldens.yml .github/workflows/ci.yml
git commit -m "test: Add Linux golden tests and a workflow to regenerate them

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
git push
gh workflow run update-goldens.yml --ref feat/v1-modernization
```

Wait for the run with `gh run watch` on the id from `gh run list --workflow update-goldens.yml --limit 1`. Then:

Run: `git pull && ls test/goldens/*.png | wc -l`
Expected: `16`. Open 2 or 3 of the PNGs with the Read tool and check that they look right. Emoji render as boxes in the test font; that is expected.

---

### Task 16: Minimal example, full API docs, and tightened CI gates

**Files:**
- Modify: `example/lib/main.dart`, `.github/workflows/ci.yml` (`MIN_COVERAGE: 90`, `PANA_MAX_MISSING_POINTS: 10`), `CHANGELOG.md`
- Create: `example/test/example_test.dart`

**Interfaces:**
- Consumes: the whole public API.
- Produces: a runnable single-screen example (Plan 3 replaces it with the gallery), coverage ≥ 90%, and a pana score ≥ 150.

- [ ] **Step 1: Replace `example/lib/main.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';

void main() => runApp(const ExampleApp());

/// Minimal chat showing ReactableMessage, ReactionsSummaryView and the
/// optional ReactionsController.
class ExampleApp extends StatelessWidget {
  /// Creates the example app.
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter_chat_reactions',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(colorSchemeSeed: Colors.indigo, brightness: Brightness.dark),
      home: const ChatScreen(),
    );
  }
}

/// A single chat screen.
class ChatScreen extends StatefulWidget {
  /// Creates the chat screen.
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = ReactionsController(currentUserId: 'me', currentUserName: 'Me');
  final _messages = const [
    ('m1', 'them', 'Hey! Did you see the new release?'),
    ('m2', 'me', 'Yes — reactions finally work everywhere 🎉'),
    ('m3', 'them', 'Long-press (or right-click) a message to react.'),
  ];

  @override
  void initState() {
    super.initState();
    _controller.setReactions('m1', const [Reaction(emoji: '👍', userId: 'them', userName: 'Sam')]);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onAction(BuildContext context, ReactionAction action) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('${action.label} tapped')));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: ChatReactionsScope(
        actionsBuilder: (_) => const [
          ReactionAction<void>(id: 'reply', label: 'Reply', icon: Icons.reply),
          ReactionAction<void>(id: 'copy', label: 'Copy', icon: Icons.copy),
        ],
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final (id, author, text) in _messages)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Align(
                    alignment: author == 'me'
                        ? AlignmentDirectional.centerEnd
                        : AlignmentDirectional.centerStart,
                    child: ReactableMessage(
                      alignment: author == 'me' ? ReactionAlignment.end : ReactionAlignment.start,
                      reactions: _controller.summariesFor(id),
                      onReactionSelected: _controller.bind(id).onReactionSelected,
                      onActionSelected: (action) => _onAction(context, action),
                      child: ReactionsSummaryView.overlay(
                        reactions: _controller.summariesFor(id),
                        alignment: author == 'me' ? ReactionAlignment.end : ReactionAlignment.start,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 280),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: author == 'me' ? scheme.primary : scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            text,
                            style: TextStyle(
                              color: author == 'me' ? scheme.onPrimary : scheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Add an example smoke test**

`example/test/example_test.dart`:

```dart
import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('long-press a message and react', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.longPress(find.text('Long-press (or right-click) a message to react.'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('😂'));
    await tester.pumpAndSettle();
    expect(find.byType(ReactionsSummaryView), findsWidgets);
    expect(find.text('😂'), findsOneWidget);
  });
}
```

Run: `cd example && flutter test && cd ..`
Expected: pass.

- [ ] **Step 3: Measure coverage and add tests for gaps until it is at least 90%**

Run: `flutter test --coverage && dart run tool/check_coverage.dart 90`
Expected: `Line coverage: ≥ 90%`. If it is lower, list the uncovered lines per file:

```bash
python - <<'EOF'
import re
f=None
for line in open('coverage/lcov.info'):
    if line.startswith('SF:'): f=line[3:].strip()
    elif line.startswith('DA:'):
        n,h=line[3:].split(',')[:2]
        if h.strip()=='0': print(f, n)
EOF
```

For each uncovered branch, write a focused test in the matching `test/<area>/` file. Examples: `ReactionsSummaryView` long press, `ChatReactionsTheme.merge(null)`, `ReactionMenuStyle.lerp`. Repeat until the check passes.

- [ ] **Step 4: Tighten the CI gates**

In `.github/workflows/ci.yml` set `MIN_COVERAGE: 90` and `PANA_MAX_MISSING_POINTS: 10`, and delete the two "Raised/Lowered … at the end of Plan 2" comments.

Run: `dart pub global run pana --no-warning --exit-code-threshold 10 .`
Expected: exit code 0 and `Points: ≥150/160`. Fix every item pana reports; typical ones are missing doc comments and an outdated `CHANGELOG.md` format.

- [ ] **Step 5: Changelog entry**

Prepend to `CHANGELOG.md`. Release Please owns this file from Plan 4 onward; this entry documents the unreleased breaking change for reviewers.

```markdown
## Unreleased (1.0.0)

* **Breaking:** New layered API. `ReactableMessage` replaces `ChatMessageWrapper`, `ReactionsSummaryView` replaces `StackedReactions`, `ChatReactionsTheme` + presenters replace `ChatReactionsConfig`, `ReactionAction` replaces `MenuItem`.
* App-owned data: pass `List<ReactionSummary>`; `ReactionsController` is optional and supports single/multiple policies with optimistic rollback.
* Four presenters: focused overlay (default), compact bar, bottom sheet, headless `CustomPresenter`.
* Adaptive Cupertino/Material theming via `ThemeExtension`; RTL, keyboard, screen-reader and reduced-motion support.
* No third-party dependencies (emoji picker is pluggable via `onMoreTap`).
```

- [ ] **Step 6: Full verification**

Run:
```bash
dart format --output=none --set-exit-if-changed . && flutter analyze --fatal-infos && flutter test --coverage && dart run tool/check_coverage.dart 90 && dart pub publish --dry-run && (cd example && flutter test && flutter build web)
```
Expected: every command exits 0.

- [ ] **Step 7: Commit and push**

```bash
git add example lib test .github/workflows/ci.yml CHANGELOG.md
git commit -m "feat!: Add minimal 1.0 example, reach 90% coverage, tighten CI gates

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
git push
```

Confirm on the draft PR that all CI jobs are green (ccd_pr tools). Do not poll by hand.
