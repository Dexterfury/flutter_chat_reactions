# flutter_chat_reactions 1.0.0 — Modernization Design

- **Date:** 2026-09-26
- **Status:** Approved in brainstorming, pending written-spec review
- **Branch:** `feat/v1-modernization`

## 1. Goals

1. Make the package work with any chat app, whatever its backend or state management (Firebase, Stream, Supabase, custom servers, Riverpod, Bloc, `setState`).
2. Make every visual and behavioural part customizable, with good adaptive defaults.
3. Fix every known 0.2.x defect (see §11).
4. Ship with no third-party runtime dependencies.
5. Automate quality checks, versioning, pub.dev publishing and demo-GIF generation (the GIFs stay iOS).

### Non-goals
- A built-in emoji picker. The README documents a copy-paste adapter for `emoji_picker_flutter` instead.
- Backward compatibility with 0.2.x. 1.0.0 is a clean break, with `MIGRATION.md`.
- Networking or persistence. The app owns its data.

## 2. Decisions log

| # | Decision | Choice |
|---|----------|--------|
| 1 | Breaking change tolerance | Clean 1.0.0, with a migration guide |
| 2 | Data ownership | App-owned data; widgets display it; optional in-memory `ReactionsController` |
| 3 | Presentation modes | Focused overlay (default), compact bar, bottom sheet, headless |
| 4 | Theming | `ThemeExtension`, adaptive Cupertino/Material defaults, can be forced |
| 5 | Dependencies | None; picker supplied through `onMoreTap` |
| 6 | Release automation | Release Please, then tag, then pub.dev OIDC publish |
| 7 | Example and GIFs | Showcase gallery; GIFs recorded on the iOS simulator in CI |
| 8 | Architecture | Layered: trigger widget + swappable presenters + shared building blocks |

## 3. Data model (`lib/src/models/`)

All models are immutable, have value `==`/`hashCode`, `copyWith`, and `toJson`/`fromJson`, and are pure Dart (no Flutter imports) except `ReactionAction`, which uses `IconData`.

```dart
class ReactionUser {
  final String id;
  final String? name;
  final String? avatarUrl;
}

/// Primary display input: one aggregated entry per emoji.
class ReactionSummary {
  final String emoji;             // any string: unicode or custom id like ':party:'
  final int count;                // >= 1
  final bool reactedByMe;
  final List<ReactionUser> users; // may be empty or partial
}

/// Raw per-user record for apps that store individual reactions.
class Reaction {
  final String emoji;
  final String userId;
  final String? userName;
  final DateTime? createdAt;
  final Map<String, Object?> extra;
}

enum ReactionSort { countDesc, firstReacted, none }

extension ReactionListX on Iterable<Reaction> {
  List<ReactionSummary> summarize({
    required String currentUserId,
    ReactionSort sort = ReactionSort.countDesc, // ties broken by first appearance
  });
}

class ReactionAction<T> {
  final String id;          // identity; equality is by id
  final String label;
  final IconData? icon;
  final bool isDestructive;
  final T? value;
}

sealed class ReactionPolicy {
  const factory ReactionPolicy.single() = SingleReactionPolicy;
  const factory ReactionPolicy.multiple({int? max}) = MultipleReactionPolicy;
}
```

Rules:
- Emoji are opaque strings. How they are drawn can be overridden with `emojiBuilder`.
- The "more" button is a separate slot, not a member of `quickReactions`.
- The actions for each message come from `actionsBuilder(BuildContext) => List<ReactionAction>`.

## 4. Trigger layer (`lib/src/trigger/`)

### 4.1 `ReactableMessage`

```dart
ReactableMessage({
  required Widget child,
  List<ReactionSummary> reactions = const [],
  List<String>? quickReactions,             // falls back to scope, then default set
  List<ReactionAction> Function(BuildContext)? actionsBuilder,
  ValueChanged<String>? onReactionSelected,
  ValueChanged<ReactionAction>? onActionSelected,
  Future<void> Function(BuildContext)? onMoreTap, // null => no "+" button
  ReactionsPresenter? presenter,
  Set<ReactionTrigger>? triggers,
  ReactionAlignment alignment = ReactionAlignment.end,
  bool enabled = true,
  String? semanticLabel,
})
```

- `ReactionTrigger` is one of `longPress`, `doubleTap`, `secondaryTap`, `hover`, `keyboard`.
- Default triggers: touch platforms (iOS, Android, Fuchsia) get `{longPress, keyboard}`. Desktop and web get `{secondaryTap, hover, keyboard}`, and `hover` only takes effect with `CompactBarPresenter`.
- The keyboard triggers are Enter and Shift+F10 while the message has focus.
- On trigger, the widget:
  1. measures the child's global `Rect` through its `RenderBox`;
  2. builds a `ReactionsMenuContext`;
  3. calls `presenter.show(context, menu)`, ignoring re-triggers while a menu is open.
- The child is shown in the overlay by rebuilding the same widget inside the presenter. No Hero and no route push are used.
- The menu closes when the scroll position of the nearest `Scrollable` changes, when the screen metrics change (for example rotation), and when the widget is disposed.
- Haptics come from `ChatReactionsTheme.haptics`. Adaptive means `selectionClick` on iOS/macOS and `lightImpact` elsewhere, fired on open and on select.

### 4.2 `ChatReactionsScope`

An `InheritedWidget` that provides defaults to every `ReactableMessage` below it: `presenter`, `quickReactions`, `triggers`, `actionsBuilder`, `onMoreTap`.

Values are resolved in this order: the widget's own argument, then the nearest scope, then the built-in default.

### 4.3 `ReactionsMenuContext`

```dart
class ReactionsMenuContext {
  final Rect anchorRect;
  final WidgetBuilder messageBuilder;
  final List<ReactionSummary> reactions;
  final List<String> quickReactions;
  final List<ReactionAction> actions;
  final ReactionAlignment alignment;
  final TextDirection textDirection;
  final bool hasMore;
  void selectReaction(String emoji);    // dismisses, then calls onReactionSelected
  void selectAction(ReactionAction a);  // dismisses, then calls onActionSelected
  Future<void> openMore();              // dismisses, then calls onMoreTap
  void dismiss();
}
```

Callbacks run after the dismiss animation has started, so apps can navigate or show sheets safely.

## 5. Presenters (`lib/src/presenters/`)

```dart
abstract class ReactionsPresenter {
  const ReactionsPresenter();
  Future<void> show(BuildContext context, ReactionsMenuContext menu); // completes on dismiss
}
```

The built-in presenters host their content in the root `Overlay` (via `OverlayEntry`/`OverlayPortal`) inside a modal barrier. The barrier handles tap-outside, Escape and Android back through `PopScope`/`BackButtonListener`, and adds a focus trap.

### 5.1 Shared building blocks (public)

- **`ReactionBar`**
  - Quick reactions plus an optional "+" button.
  - Entrance animation: staggered scale and fade, 30 ms per item.
  - The selected emoji is highlighted.
  - Scrolls horizontally when it overflows.
- **`ReactionActionMenu`**
  - Width is sized to the content and clamped to 200–280 logical px.
  - Destructive actions use the theme's error color.
  - Grouped Cupertino style or Material 3 style, chosen by the resolved theme.
- **`AnchoredLayout`**: a `CustomMultiChildLayout` delegate that positions a header, the anchor and a footer around a `Rect` inside the safe area.
  - Preferred order: header above, footer below.
  - When that doesn't fit, the anchor is translated to fit, and if it still doesn't fit the anchor becomes scrollable (tall messages).
  - The horizontal position follows `alignment` and the text direction, clamped to the screen with a 12 px margin.

### 5.2 `FocusedOverlayPresenter` (default)

- Parameters: `blurSigma = 8`, `barrierColor` (from the theme), `showMessage = true`, `showActions = true`, `lift = 1.03`, `fallbackTextScale = 2.0`, `fallbackMinHeight = 400`.
- It blurs the backdrop, lifts the message copy from `anchorRect` with a scale-and-shadow animation, puts `ReactionBar` above and `ReactionActionMenu` below, and lays them out with `AnchoredLayout`.
- It falls back to `BottomSheetPresenter` when the text scale is at least `fallbackTextScale` or the screen height is below `fallbackMinHeight`.

### 5.3 `CompactBarPresenter`

- Parameters: `hoverDelay = 300ms`, `actionsOverflow = true`.
- Only a `ReactionBar`, attached to the top edge of the anchor and flipped below it when there is no room. It has no blur and a transparent barrier.
- On hover it stays open while the pointer is over the anchor, the bar, or the gap between them. It closes 200 ms after the pointer leaves.
- With `actionsOverflow`, a "⋯" button opens the actions in a small anchored menu.

### 5.4 `BottomSheetPresenter`

- Parameter: `showReactionDetails = false`.
- It uses `showModalBottomSheet` (Material) or `showCupertinoModalPopup` with an action-sheet look (Cupertino).
- Contents: a scrollable `ReactionBar`, an optional who-reacted section, and the actions as full-width tiles.

### 5.5 Headless

- Subclass `ReactionsPresenter` for full control.
- Or use `CustomPresenter(builder: (BuildContext, ReactionsMenuContext) => Widget, barrierColor, dismissible)`, which provides the overlay, barrier, dismissal, focus trap and reduced-motion handling while the builder draws everything.

## 6. `ReactionsSummaryView` (`lib/src/widgets/`)

```dart
ReactionsSummaryView({
  required List<ReactionSummary> reactions,
  ReactionSummaryLayout layout = ReactionSummaryLayout.chips, // chips | stacked | compact
  int maxVisible = 5,                                        // overflow shown as "+N"
  ValueChanged<String>? onReactionTap,
  VoidCallback? onTap,
  ValueChanged<String>? onLongPress,
  Widget Function(BuildContext, ReactionSummary)? chipBuilder,
  Widget Function(BuildContext, String emoji, double size)? emojiBuilder,
})
ReactionsSummaryView.overlay(...) // positions over the bubble's bottom edge (WhatsApp style)
```

Layouts:
- **`chips`**: a `Wrap` of pills showing emoji and count. `reactedByMe` pills use the highlight style.
- **`stacked`**: overlapping emoji circles plus a total count.
- **`compact`**: a single pill with up to 3 emoji and the total, such as "👍❤️😂 12".

Behaviour:
- Count changes animate with `AnimatedSwitcher`, and chips enter and leave with `AnimatedSize`.
- Renders `SizedBox.shrink()` when `reactions` is empty.
- `showReactionDetails(BuildContext, List<ReactionSummary>)` opens a sheet with an "All" tab plus one tab per emoji, listing `ReactionUser`s with an avatar or initials.

## 7. Theming (`lib/src/theme/`)

`ChatReactionsTheme extends ThemeExtension<ChatReactionsTheme>` with:
- `style`: `ReactionsVisualStyle.adaptive | material | cupertino`
- `barStyle`: `ReactionBarStyle` (background, shape, shadow, padding, emojiSize, itemSpacing, highlightColor)
- `menuStyle`: `ReactionMenuStyle` (background, shape, textStyle, iconColor, destructiveColor, dividerColor, min/max width, itemPadding)
- `chipStyle`: `ReactionChipStyle` (background, selectedBackground, border, selectedBorder, textStyle, selectedTextStyle, padding, shape, emojiSize)
- `overlayStyle`: `ReactionOverlayStyle` (barrierColor, blurSigma, messageShadow, lift)
- `animationDuration` (default 220 ms) and `animationCurve` (default `Curves.easeOutCubic`)
- `haptics`: `ReactionHaptics.adaptive | none`

Rules:
- Factories: `ChatReactionsTheme.light()` and `.dark()`, plus `fromColorScheme(ColorScheme, TextTheme, TargetPlatform)`.
- Every style class implements `copyWith`, `merge` and `lerp`.
- Resolution order: widget argument, then `Theme.of(context).extension<ChatReactionsTheme>()`, then `fromColorScheme(...)`.
- Adaptive means the Cupertino look on `iOS`/`macOS` and Material 3 on every other platform.
- Reduced motion: when `MediaQuery.disableAnimations` is true, durations become zero or a 100 ms fade.

## 8. Optional `ReactionsController` (`lib/src/controller/`)

```dart
class ReactionsController extends ChangeNotifier {
  ReactionsController({
    required String currentUserId,
    String? currentUserName,
    ReactionPolicy policy = const ReactionPolicy.single(),
    Future<void> Function(ReactionChange change)? onChange,
  });
  List<ReactionSummary> summariesFor(String messageId);   // unmodifiable
  List<Reaction> reactionsFor(String messageId);          // unmodifiable
  void setReactions(String messageId, Iterable<Reaction> reactions);
  Future<void> toggle(String messageId, String emoji);
  Future<void> add(String messageId, String emoji);
  Future<void> remove(String messageId, String emoji);
  void clear([String? messageId]);
  ReactionBinding bind(String messageId); // (reactions, onReactionSelected)
}

sealed class ReactionChange { String get messageId; String get emoji; }
// ReactionAdded, ReactionRemoved, ReactionReplaced(previousEmoji)
```

Policies:
- `single`: a user has at most one reaction per message. Choosing a different emoji replaces the old one, which is a `ReactionReplaced` change. Choosing the same emoji removes it.
- `multiple(max)`: toggles each emoji independently. Adding past `max` is ignored, and nothing is reported.

Optimistic updates:
- The controller applies the change locally, notifies listeners, then awaits `onChange`.
- If `onChange` throws, it restores the previous state for that message, notifies listeners again, and rethrows.

Internal lists are never exposed, and the collections passed to `setReactions` are copied.

## 9. Accessibility and internationalization

- **Semantics on each message:** `ReactableMessage` adds a `CustomSemanticsAction(label: l10n.openReactionsMenu)`.
- **Reaction bar semantics:**
  - `ReactionBar` items are `Semantics(button: true, selected: …)`.
  - Their label comes from `l10n.emojiLabel(emoji)`, which uses a small built-in name table for the default quick reactions and falls back to the emoji itself.
- **Chip semantics:** chips announce "<name>, <count> reactions, selected".
- **Keyboard focus:**
  - Focus traversal groups are used for the bar and the menu.
  - Arrow keys move within a group, Tab moves between groups.
  - Focus returns to the message when the menu closes.
- **Right-to-left:** all padding uses `EdgeInsetsDirectional`, and `ReactionAlignment.start/end` follow `Directionality`.
- **Strings:** `ChatReactionsLocalizations` is an abstract class with an English default, provided through `ChatReactionsLocalizations.delegate` or an override on `ChatReactionsScope`.

## 10. Packaging and tooling

- `pubspec.yaml`:
  - `sdk: ^3.6.0`, `flutter: ">=3.27.0"`
  - no runtime dependencies besides `flutter`
  - dev dependencies: `flutter_test` and `flutter_lints: ^6.0.0`
  - `topics: [chat, reactions, emoji, context-menu, messaging]`
  - `screenshots:` pointing at one small GIF
  - `repository:` and `issue_tracker:` URLs
- `analysis_options.yaml`: `flutter_lints` plus `public_member_api_docs`, `prefer_const_constructors`, `always_declare_return_types`, `unawaited_futures`, `directives_ordering`, and `strict-casts`/`strict-inference`.
- The `library` directive and the misspelled file `rections_row.dart` are removed.
- `.pubignore` excludes `doc/gifs/`, `tool/`, `docs/`, `example/build/` and `coverage/`.
- `MIGRATION.md` maps the old API to the new one:
  - `ChatMessageWrapper` → `ReactableMessage`
  - `StackedReactions` → `ReactionsSummaryView(layout: stacked)`
  - `ChatReactionsConfig` → theme, scope and presenter parameters
  - `MenuItem` → `ReactionAction`
  - the `'➕'` sentinel → `onMoreTap`
  - `ReactionsController` API changes
  - the `emoji_picker_flutter` adapter snippet

## 11. 0.2.x defects fixed by this design

| Defect | Resolution |
|--------|------------|
| Nine `ChatReactionsConfig` fields unused | Config removed; every remaining option is wired up and tested |
| `copyWith` drops `reactionBackgroundColor` | Replaced by the theme, whose `copyWith` is tested |
| `customReactionBuilder` signature mismatch | A single `chipBuilder(BuildContext, ReactionSummary)` |
| Count text the same color as the chip background | Theme-derived contrast; golden tests |
| `ReactionsTheme` unused and unexported | Replaced by `ChatReactionsTheme` |
| `'➕'` sentinel | `onMoreTap` slot |
| Hero tag collisions | No Hero; the overlay rebuilds the message |
| Dialog centered, overflows on tall messages | `AnchoredLayout` with flip and scroll |
| Menu fixed at 45% of screen width | Width sized to content and clamped |
| Controller exposes mutable internal lists | Copies and unmodifiable views |
| `flutter: >=1.17.0` while using `withValues` | `>=3.27.0` |
| No tests; publish workflow works around it | TDD with a 90% coverage gate |
| About 11 MB of GIFs shipped to pub.dev | Moved to `doc/gifs/` and excluded by `.pubignore` |

## 12. Example app: showcase gallery (`example/`)

The home screen lists these demos:
1. **Messenger**: iMessage/WhatsApp style, `FocusedOverlayPresenter`, the `stacked` summary overlaid on the bubble, `ReactionPolicy.single`, and an `emoji_picker_flutter` adapter for "+". The example may depend on it; the package does not.
2. **Team channel**: Slack/Discord style, `CompactBarPresenter`, the `chips` summary, `ReactionPolicy.multiple()`, and custom `:shortcode:` emoji drawn with `emojiBuilder`.
3. **Telegram-like**: `BottomSheetPresenter` with reaction details.
4. **Custom (headless)**: `CustomPresenter` with a radial emoji picker drawn around the message.
5. **Theming playground**: live toggles for light/dark, adaptive/Material/Cupertino, the seed color, text scale and right-to-left layout.

Every demo is selectable through `--dart-define=DEMO=<messenger|team|telegram|custom|theming>` and `--dart-define=THEME=<light|dark>`, which lets the GIF pipeline and tests open it directly.

`example/integration_test/demo_script_test.dart` holds a paced interaction script for each demo (open the menu, react, change the reaction, run an action). It serves as an end-to-end test in CI and as the recording script.

## 13. Testing strategy

- **TDD** for every unit of `lib/`.
- **Unit tests:** models (JSON round trips, equality), `summarize` (sorting, `reactedByMe`), both controller policies, optimistic rollback, and `bind`.
- **Widget tests:**
  - each trigger on each platform, overridden with `debugDefaultTargetPlatformOverride`
  - each presenter: open, select, act, dismiss by tap outside, Escape, back and scroll, flipping at the top and bottom edges, the fallback to the bottom sheet, and hover persistence
  - summary layouts, overflow "+N", theme resolution and lerp
  - right-to-left mirroring, semantics tree assertions, keyboard traversal, and reduced motion
- **Golden tests:** bar, menu, chips and focused overlay × light/dark × material/cupertino. They run on Linux CI only, using a bundled test font and an emoji-free fallback so results are deterministic; emoji glyphs are covered by the text tests.
- **Coverage gate:** at least 90% of lines in `lib/`.

## 14. CI/CD (`.github/workflows/`)

### 14.1 `ci.yml`
Runs on pull requests and on pushes to `main`. It uses a matrix of Flutter `3.27.x` and `stable`, and the steps are:
1. `dart format --set-exit-if-changed .`
2. `flutter analyze --fatal-infos`
3. `flutter test --coverage` with a coverage threshold check; the lcov file is uploaded as an artifact
4. golden tests (`stable` on Linux only)
5. `pana --exit-code-threshold 10` (a score of at least 150 of 160)
6. `dart pub publish --dry-run`
7. build the example for `apk --debug` and `web`
8. run the example's integration tests on `flutter-tester` where possible

### 14.2 `release-please.yml`
- Runs on pushes to `main`, using `googleapis/release-please-action@v4` with `release-type: dart`.
- The version in the README is kept up to date through `<!-- x-release-please-version -->` markers.
- It uses the secret `RELEASE_PLEASE_TOKEN`, a fine-grained PAT scoped to this repository with Contents: RW and Pull requests: RW. The token is needed because a tag created with `GITHUB_TOKEN` does not trigger other workflows.
- `release-please-config.json` and `.release-please-manifest.json` are seeded at `0.2.7`, with `release-as: 1.0.0` for the first run.

### 14.3 `publish.yml`
- Runs when a tag matching `[0-9]+.[0-9]+.[0-9]+*` is pushed.
- It uses `dart-lang/setup-dart/.github/workflows/publish.yml@v1` with `environment: pub.dev`.
- Required permissions: `id-token: write`.

### 14.4 `demo-gifs.yml`
Runs on `workflow_dispatch` and on `release: published`, on `macos-latest`:
1. Boot the latest available iPhone Pro simulator.
2. Run `xcrun simctl status_bar booted override --time 9:41 --batteryLevel 100 --cellularBars 4 --wifiBars 3`.
3. For each demo × theme: start `xcrun simctl io booted recordVideo`, run `flutter test integration_test/demo_script_test.dart -d <sim> --dart-define=DEMO=… --dart-define=THEME=…`, then stop recording with SIGINT.
4. Convert each video with `ffmpeg` (trim, `fps=20`, `scale=320:-1`, palettegen/paletteuse), then `gifsicle -O3 --lossy=40`. Target size is 1.5 MB or less.
5. Open a PR with `peter-evans/create-pull-request` updating `doc/gifs/<demo>_<theme>.gif`.

`tool/record_gifs.sh` repeats the same steps for recording locally on a Mac.

### 14.5 Manual setup required from the maintainer
1. pub.dev → package Admin → Automated publishing: enable GitHub Actions, set the repository to `Dexterfury/flutter_chat_reactions` and the tag pattern to `{{version}}`, and require the environment `pub.dev`.
2. GitHub → Settings → Environments: create `pub.dev`, optionally with required reviewers.
3. Create a fine-grained PAT, then add it as the repository secret `RELEASE_PLEASE_TOKEN`.

## 15. Delivery phases

Each phase ends green in CI.

1. **CI foundation:** `ci.yml` checking the current code; publish workflow replaced; `.pubignore`; lints upgraded. The existing code gets only the fixes needed to pass.
2. **Core redesign (TDD, in order):**
   1. models
   2. controller
   3. theme
   4. `AnchoredLayout`
   5. `ReactionBar` and `ReactionActionMenu`
   6. `ReactableMessage` and `ChatReactionsScope`
   7. presenters: focused, compact, sheet, custom
   8. `ReactionsSummaryView` and the details sheet
   9. accessibility and localization
   10. goldens

   The old API is removed.
3. **Example gallery and `demo_script_test.dart`.**
4. **Docs and release:** `demo-gifs.yml`, `tool/record_gifs.sh`, README rewrite, `MIGRATION.md`, Release Please wiring. The first release PR is 1.0.0. The root GIFs are deleted once the recorded GIFs merge.
