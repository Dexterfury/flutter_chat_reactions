# Plan 4 of 4 — Demo GIFs, Docs, and Release Automation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship everything around the 1.0.0 code:
- iOS-simulator demo GIFs recorded by CI from the Plan 3 demo scripts;
- a rewritten README, a `MIGRATION.md` and a maintainer `RELEASING.md`;
- Release Please, which opens the release PR, bumps the version, writes the changelog and tags;
- the pub.dev screenshot;
- removal of the old root GIFs.

**Architecture:**
- **Recording:** `tool/record_gifs.sh` does it all. It picks and boots an iPhone Pro simulator, runs `example/integration_test/demo_script_test.dart` per demo and theme, starts and stops `simctl recordVideo` on `DEMO_SCRIPT_START`/`DEMO_SCRIPT_END` markers printed by the runner, then converts each video with ffmpeg and gifsicle into `doc/gifs/<slug>_<theme>.gif`.
- **CI recording:** `.github/workflows/demo-gifs.yml` runs that script on `macos-latest` and pushes a `demo-gifs/<run>` branch. It opens a PR with the maintainer's `RELEASE_PLEASE_TOKEN` when that secret exists.
- **Releases:** Release Please (`release-type: dart`, tags without a `v`, bootstrapped at the 0.2.7 commit) turns conventional commits on `main` into a release PR. Merging it tags `1.0.0`, and the existing `publish.yml` then publishes.

**Tech Stack:** Bash, Xcode `simctl`, ffmpeg, gifsicle, GitHub Actions (`subosito/flutter-action@v2`, `actions/upload-artifact@v4`, `googleapis/release-please-action@v5`), Markdown.

**Spec:** `docs/superpowers/specs/2026-09-26-v1-modernization-design.md` §10, §14.2, §14.4 and §14.5.

## Global Constraints

- The package's `lib/` and `test/` do not change in this plan (documentation and automation only).
- GIF names are exactly `doc/gifs/<slug>_<theme>.gif`, with slugs `quickstart messenger team telegram custom theming` and themes `light dark`: 12 files. They are 320 px wide at 20 fps, with a target of ≤ 1.5 MB each; bigger files produce a warning, not a failure.
- The README embeds GIFs with absolute URLs of the form `https://raw.githubusercontent.com/Dexterfury/flutter_chat_reactions/main/doc/gifs/<file>`. pub.dev renders these, and they don't bloat the package.
- Release tags have no `v` prefix (for example `1.0.0`), so they match `publish.yml`'s `[0-9]+.[0-9]+.[0-9]+*` and pub.dev's `{{version}}` pattern. The first release is exactly `1.0.0`.
- This repo does not let GitHub Actions create PRs (`can_approve_pull_request_reviews: false`, confirmed on 2026-09-27). Workflows must never depend on `GITHUB_TOKEN` creating PRs. Use the `RELEASE_PLEASE_TOKEN` secret, and do nothing if it is absent.
- API names in the docs must match the 1.0 code exactly. Notable examples: `ReactionsSummaryView.onReactionLongPress`, `CustomPresenter(dismissible:)`, `ReactionAction.copyWith`, `ReactionDetailsList(emojiBuilder:)`, and `ReactionAction<dynamic>` in type positions. Before writing any API name, check it against `lib/`.
- The minimum SDK is Flutter ≥ 3.32 and Dart ^3.8. The example pins `emoji_picker_flutter >=4.4.0 <4.5.0`.
- The "Buy me a coffee" link from the current README stays (`https://www.buymeacoffee.com/raphaelsqu7`).
- Commits use Conventional Commits and end with `Co-Authored-By: <committing model> <noreply@anthropic.com>`. Stage explicit paths only. Run `dart format .` before committing when Dart files change.

---

## File Map

```
example/integration_test/demo_script_test.dart   + DEMO_SCRIPT_START / DEMO_SCRIPT_END markers
tool/record_gifs.sh                               simulator recording + GIF conversion (macOS)
.github/workflows/demo-gifs.yml                   runs the script on macos-latest, pushes branch / opens PR
README.md                                         rewritten for 1.0
MIGRATION.md                                      0.2.x → 1.0 guide
RELEASING.md                                      maintainer setup + release/recording/golden procedures
CHANGELOG.md                                      drop the hand-written "Unreleased (1.0.0)" block
docs/superpowers/specs/...design.md               sync §6 (onReactionLongPress) + §16 additions
release-please-config.json, .release-please-manifest.json, .github/workflows/release-please.yml
pubspec.yaml (screenshots), .pubignore (ship one GIF), root *.gif deleted     [Task 5, after GIFs exist]
```

Execution order: Task 1 comes first. Then the controller triggers a recording (a commit containing `[record-gifs]`) and merges the resulting GIF PR into the feature branch. Tasks 2–4 can run while the recording is in progress. Task 5 needs the GIFs.

---

### Task 1: GIF recording pipeline (markers, script, workflow)

**Files:**
- Modify: `example/integration_test/demo_script_test.dart`
- Create: `tool/record_gifs.sh` (executable), `.github/workflows/demo-gifs.yml`

**Interfaces:**
- Consumes: the Plan 3 real-time runner (`flutter test integration_test/demo_script_test.dart -d <device> --dart-define=DEMO=<slug> --dart-define=THEME=<light|dark>`), which already uses `LiveTestWidgetsFlutterBindingFramePolicy.fullyLive`.
- Produces:
  - `tool/record_gifs.sh [slug...]`, with the environment variables `THEMES` (default `"light dark"`) and `SIMULATOR_UDID` (optional). It writes `doc/gifs/<slug>_<theme>.gif`.
  - The workflow triggers: `workflow_dispatch` (input `demos`), `release: published`, and `push` to any non-`main` branch whose head commit message contains `[record-gifs]`.

- [ ] **Step 1: Add the start/end markers to the real-time runner**

In `example/integration_test/demo_script_test.dart`, add `import 'package:flutter/foundation.dart';` (for `debugPrint`). Then, inside the `testWidgets` body, wrap the `runDemoScript(...)` call like this:

```dart
    // tool/record_gifs.sh starts the simulator recording when it sees
    // DEMO_SCRIPT_START and stops it at DEMO_SCRIPT_END.
    debugPrint('DEMO_SCRIPT_START');
    await Future<void>.delayed(const Duration(seconds: 1));
    await runDemoScript(
      tester,
      demo,
      pace: (duration) async {
        await Future<void>.delayed(duration);
        await tester.pumpAndSettle();
      },
    );
    debugPrint('DEMO_SCRIPT_END');
```

Keep everything else in the file as it is: the binding setup, the frame policy, and the doc comment.

- [ ] **Step 2: Verify the markers on a local device**

Run: `cd example && flutter test integration_test/demo_script_test.dart -d windows --dart-define=DEMO=quickstart 2>&1 | tee /tmp/run.log | tail -5 && grep -c "DEMO_SCRIPT_START\|DEMO_SCRIPT_END" /tmp/run.log`
Expected: `All tests passed!` and a count of `2`. If `debugPrint` output doesn't reach the `flutter test` console on this device, use `print` with `// ignore: avoid_print` on the line above instead, and record that in the report.

- [ ] **Step 3: Create `tool/record_gifs.sh`**

```bash
#!/usr/bin/env bash
# Records the example gallery's demo scripts on an iOS simulator and converts
# them to GIFs in doc/gifs/. macOS only. Needs Xcode, Flutter, ffmpeg, gifsicle.
#
#   tool/record_gifs.sh                  # every demo, light + dark
#   tool/record_gifs.sh messenger team   # selected demos
#   THEMES=light tool/record_gifs.sh     # light only
#   SIMULATOR_UDID=<udid> tool/record_gifs.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/doc/gifs"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
ALL_DEMOS=(quickstart messenger team telegram custom theming)
if [ "$#" -gt 0 ]; then DEMOS=("$@"); else DEMOS=("${ALL_DEMOS[@]}"); fi
read -r -a THEME_LIST <<< "${THEMES:-light dark}"
MAX_BYTES=$((1500 * 1024))

for tool in xcrun flutter ffmpeg gifsicle python3; do
  command -v "$tool" >/dev/null || { echo "error: $tool not found" >&2; exit 1; }
done

# Newest available "iPhone <n> Pro" simulator on the newest iOS runtime.
pick_simulator() {
  xcrun simctl list devices available --json | python3 -c '
import json, re, sys
best = None
for runtime, devices in json.load(sys.stdin)["devices"].items():
    m = re.search(r"iOS-(\d+)-(\d+)", runtime)
    if not m:
        continue
    version = (int(m.group(1)), int(m.group(2)))
    for d in devices:
        name = d["name"]
        if name.startswith("iPhone") and name.endswith(" Pro"):
            key = (version, name)
            if best is None or key > best[0]:
                best = (key, d["udid"])
if best is None:
    sys.exit("no available iPhone Pro simulator")
print(best[1])
'
}

UDID="${SIMULATOR_UDID:-$(pick_simulator)}"
echo "Using simulator $UDID"
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b
xcrun simctl status_bar "$UDID" override --time 9:41 --dataNetwork wifi \
  --wifiBars 3 --cellularBars 4 --batteryState charged --batteryLevel 100

mkdir -p "$OUT"
cd "$ROOT/example"
flutter pub get >/dev/null

record() {
  local demo="$1" theme="$2"
  local log="$WORK/$demo-$theme.log"
  local video="$WORK/$demo-$theme.mp4"
  local gif="$OUT/${demo}_${theme}.gif"
  local rec_pid="" test_pid size
  echo "==> $demo ($theme)"
  xcrun simctl ui "$UDID" appearance "$theme"
  flutter test integration_test/demo_script_test.dart -d "$UDID" \
    --dart-define=DEMO="$demo" --dart-define=THEME="$theme" >"$log" 2>&1 &
  test_pid=$!
  # Start recording at DEMO_SCRIPT_START, stop at DEMO_SCRIPT_END.
  while kill -0 "$test_pid" 2>/dev/null; do
    if [ -z "$rec_pid" ] && grep -q DEMO_SCRIPT_START "$log"; then
      xcrun simctl io "$UDID" recordVideo --codec=h264 --force "$video" &
      rec_pid=$!
    fi
    if [ -n "$rec_pid" ] && grep -q DEMO_SCRIPT_END "$log"; then
      break
    fi
    sleep 0.2
  done
  if [ -n "$rec_pid" ]; then
    kill -INT "$rec_pid"
    wait "$rec_pid" || true
  fi
  if ! wait "$test_pid"; then
    cat "$log"
    echo "error: demo script failed: $demo ($theme)" >&2
    return 1
  fi
  if [ -z "$rec_pid" ]; then
    cat "$log"
    echo "error: DEMO_SCRIPT_START marker not seen for $demo ($theme)" >&2
    return 1
  fi
  ffmpeg -loglevel error -y -i "$video" -vf \
    "fps=20,scale=320:-1:flags=lanczos,split[a][b];[a]palettegen=stats_mode=diff[p];[b][p]paletteuse=dither=bayer:bayer_scale=5" \
    "$WORK/raw.gif"
  gifsicle -O3 --lossy=40 -o "$gif" "$WORK/raw.gif"
  size=$(wc -c <"$gif")
  echo "    $(basename "$gif"): $((size / 1024)) KB"
  if [ "$size" -gt "$MAX_BYTES" ]; then
    echo "warning: $(basename "$gif") is larger than 1.5 MB" >&2
  fi
}

for demo in "${DEMOS[@]}"; do
  for theme in "${THEME_LIST[@]}"; do
    record "$demo" "$theme"
  done
done

xcrun simctl status_bar "$UDID" clear
echo "GIFs written to $OUT"
```

Make it executable in git, which is needed on Windows checkouts:

Run: `git add tool/record_gifs.sh && git update-index --chmod=+x tool/record_gifs.sh && bash -n tool/record_gifs.sh && echo syntax-ok`
Expected: `syntax-ok`. If `shellcheck` is available, also run `shellcheck tool/record_gifs.sh` and fix any warnings.

- [ ] **Step 4: Create `.github/workflows/demo-gifs.yml`**

```yaml
# Records iOS-simulator GIFs of the example gallery (tool/record_gifs.sh) and
# pushes them on a branch. A PR is opened when the RELEASE_PLEASE_TOKEN secret
# exists (GitHub Actions may not create PRs in this repo otherwise).
#
# Triggers: manual dispatch, a published release, or a push to a non-main
# branch whose head commit message contains [record-gifs].
name: Record demo GIFs

on:
  workflow_dispatch:
    inputs:
      demos:
        description: Space-separated demo slugs (empty = all)
        required: false
        default: ''
  release:
    types: [published]
  push:
    branches-ignore: [main]
    tags-ignore: ['**']

permissions:
  contents: write

jobs:
  record:
    if: github.event_name != 'push' || contains(github.event.head_commit.message, '[record-gifs]')
    runs-on: macos-latest
    timeout-minutes: 90
    steps:
      - uses: actions/checkout@v5

      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true

      - name: Install ffmpeg and gifsicle
        run: brew install ffmpeg gifsicle

      - name: Record GIFs
        env:
          DEMOS: ${{ inputs.demos }}
        # $DEMOS is intentionally unquoted: it is a space-separated list.
        run: tool/record_gifs.sh $DEMOS

      - name: Upload GIFs
        uses: actions/upload-artifact@v4
        with:
          name: demo-gifs
          path: doc/gifs/*.gif

      - name: Push branch and open PR
        env:
          GH_TOKEN: ${{ secrets.RELEASE_PLEASE_TOKEN }}
          BASE: ${{ github.event_name == 'release' && github.event.repository.default_branch || github.ref_name }}
          RUN_ID: ${{ github.run_id }}
        run: |
          branch="demo-gifs/$RUN_ID"
          git config user.name "github-actions[bot]"
          git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
          git switch -c "$branch"
          git add doc/gifs/*.gif
          if git diff --cached --quiet; then
            echo "No GIF changes."
            exit 0
          fi
          git commit -m "docs: Update demo GIFs"
          git push origin "$branch"
          if [ -n "$GH_TOKEN" ]; then
            gh pr create --base "$BASE" --head "$branch" \
              --title "docs: Update demo GIFs" \
              --body "Recorded on the iOS simulator by workflow run $RUN_ID."
          else
            echo "::notice::Pushed $branch — open a PR into $BASE (no RELEASE_PLEASE_TOKEN secret)."
          fi
```

Run: `python -c "import yaml;yaml.safe_load(open('.github/workflows/demo-gifs.yml'));print('ok')"`
Expected: `ok`.

- [ ] **Step 5: Verify and commit**

Run: `dart format . && cd example && flutter analyze --fatal-infos && flutter test`
Expected: `No issues found!` and all example tests pass. The fake-time tests don't use the runner, but analysis covers it.

```bash
git add example/integration_test/demo_script_test.dart tool/record_gifs.sh .github/workflows/demo-gifs.yml
git commit -m "ci: Record demo GIFs on the iOS simulator

Co-Authored-By: <committing model> <noreply@anthropic.com>"
```

Do NOT push. The controller pushes and triggers the first recording with a `[record-gifs]` commit.

---

### Task 2: README rewrite for 1.0

**Files:**
- Modify: `README.md` (replace the whole file)

**Interfaces:**
- Consumes: the 1.0 public API (check every name against `lib/`), the GIF file names from Task 1 (absolute raw URLs), `example/README.md`'s Quick start snippet (reuse it verbatim so there is one source of truth), and `example/lib/adapters/emoji_picker_sheet.dart`.
- Produces: the README with a Release Please version marker on the install line. Task 4's config relies on that marker.

- [ ] **Step 1: Replace `README.md` with the following**

Before writing, confirm every identifier used below against `lib/` (grep for it). If a name differs, use the real name and list the correction in the report. For the `## Quick start` code block, copy the Quick start snippet from `example/README.md` verbatim instead of the placeholder comment shown here.

````markdown
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
// (paste the Quick start snippet from example/README.md here, verbatim)
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

Contributions are welcome. CI runs formatting, analysis, tests (≥ 90% coverage), the pub.dev score,
golden tests and the example on Flutter 3.32 and stable. See [RELEASING.md](RELEASING.md) for how
releases, golden images and the demo GIFs are produced.

## Support

Liked some of my work? Buy me a coffee. Thanks for your support :heart:

<a href="https://www.buymeacoffee.com/raphaelsqu7" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-blue.png" alt="Buy Me A Coffee" height=64></a>

## License

See [LICENSE](LICENSE).
````

- [ ] **Step 2: Verify the snippets compile**

Create a scratch file, `example/lib/_readme_check.dart`, that imports `package:flutter/material.dart` and `package:flutter_chat_reactions/flutter_chat_reactions.dart`. Add small stand-ins for the app-specific names the snippets use: an `api` object with `Future<void>` methods `toggleReaction/add/remove/replace`, a `me` with `id`, a `message` with `id` and `reactions`, and `MessageBubble`/`ChatList` widgets. Then paste every Dart snippet from the new README into functions in that file.

Run: `cd example && flutter analyze --fatal-infos lib/_readme_check.dart`
Expected: `No issues found!`. Fix the README, not the stand-ins, for any real API mismatch. Then delete `example/lib/_readme_check.dart`; it must not be committed.

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: Rewrite README for the 1.0 API

Co-Authored-By: <committing model> <noreply@anthropic.com>"
```

---

### Task 3: MIGRATION.md, CHANGELOG cleanup, spec sync

**Files:**
- Create: `MIGRATION.md`
- Modify: `CHANGELOG.md` (remove the `## Unreleased (1.0.0)` block only), `docs/superpowers/specs/2026-09-26-v1-modernization-design.md` (§6 rename, §16 additions)

**Interfaces:**
- Consumes: the 0.2.x API at commit `f00b0c4`, which you can view with `git show f00b0c4:lib/src/widgets/chat_message_wrapper.dart`, `git show f00b0c4:lib/src/models/chat_reactions_config.dart` and so on, plus the 1.0 API in `lib/`.
- Produces: `MIGRATION.md`, which is linked from the README and from the Release Please changelog.

- [ ] **Step 1: Create `MIGRATION.md`**

Check each "1.0" name against `lib/` and each "0.2.x" name against `f00b0c4` before writing.

````markdown
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
````

- [ ] **Step 2: Remove the hand-written changelog block**

In `CHANGELOG.md`, delete the `## Unreleased (1.0.0)` heading and its five bullet lines, plus the blank line after them. The file must start with `## [0.2.7]`. Release Please writes the 1.0.0 entry.

- [ ] **Step 3: Sync the spec with what shipped**

In `docs/superpowers/specs/2026-09-26-v1-modernization-design.md`:
- In §6, change `ValueChanged<String>? onLongPress,` to `ValueChanged<String>? onReactionLongPress,`.
- Append these items to §16 "Implementation deviations (Plan 2)":
  6. `ReactionsSummaryView.onLongPress` was renamed to `onReactionLongPress`, to match `onReactionTap`.
  7. Additive API from the final review: `CustomPresenter(dismissible:)`, `ReactionAction.copyWith`, `emojiBuilder` on `ReactionDetailsList`/`ReactionDetailsSheet`/`showReactionDetails`, `ReactionDetailsList(scrollable:)`, and `ChatReactionsTheme` value equality.
  8. Presenters capture the message's inherited themes (`InheritedTheme.capture`), and `ChatReactionsScope` is an `InheritedTheme`, so local themes, scopes and localizations reach the menus.
  9. The minimum is Flutter 3.32 / Dart 3.8 (not 3.27/3.6), because `flutter_lints` 6 requires it.

- [ ] **Step 4: Commit**

```bash
git add MIGRATION.md CHANGELOG.md docs/superpowers/specs/2026-09-26-v1-modernization-design.md
git commit -m "docs: Add 0.2.x to 1.0 migration guide and sync the design spec

Co-Authored-By: <committing model> <noreply@anthropic.com>"
```

---

### Task 4: Release Please and RELEASING.md

**Files:**
- Create: `release-please-config.json`, `.release-please-manifest.json`, `.github/workflows/release-please.yml`, `RELEASING.md`

**Interfaces:**
- Consumes: the README install line with `# x-release-please-version` (Task 2), and `publish.yml` (tag trigger `[0-9]+.[0-9]+.[0-9]+*`).
- Produces: on pushes to `main`, a release PR that sets `pubspec.yaml` `version: 1.0.0`, adds the CHANGELOG entry and updates the README marker line. Merging that PR creates the tag `1.0.0` and a GitHub release.

- [ ] **Step 1: `release-please-config.json`**

```json
{
  "$schema": "https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json",
  "bootstrap-sha": "f00b0c4cf45ff3925a28a2e1831093b40449001d",
  "include-v-in-tag": false,
  "include-component-in-tag": false,
  "packages": {
    ".": {
      "release-type": "dart",
      "package-name": "flutter_chat_reactions",
      "release-as": "1.0.0",
      "changelog-path": "CHANGELOG.md",
      "exclude-paths": ["example", "docs", "doc", "tool", ".github"],
      "extra-files": [{ "type": "generic", "path": "README.md" }],
      "changelog-sections": [
        { "type": "feat", "section": "Features" },
        { "type": "fix", "section": "Bug Fixes" },
        { "type": "perf", "section": "Performance" },
        { "type": "refactor", "section": "Code Refactoring" },
        { "type": "docs", "section": "Documentation", "hidden": true },
        { "type": "test", "section": "Tests", "hidden": true },
        { "type": "ci", "section": "Continuous Integration", "hidden": true },
        { "type": "build", "section": "Build System", "hidden": true },
        { "type": "chore", "section": "Miscellaneous", "hidden": true }
      ]
    }
  }
}
```

`f00b0c4` is the untagged 0.2.7 commit on `main`. Confirm it with `git merge-base main HEAD`. If it differs, use the actual merge-base SHA and note that in the report.

- [ ] **Step 2: `.release-please-manifest.json`**

```json
{
  ".": "0.2.7"
}
```

- [ ] **Step 3: `.github/workflows/release-please.yml`**

```yaml
# Opens / updates the release PR from conventional commits on main. Merging the
# release PR tags the version (e.g. 1.0.0), which triggers publish.yml.
# Needs the RELEASE_PLEASE_TOKEN secret (see RELEASING.md): tags created with
# GITHUB_TOKEN would not trigger publish.yml, and this repo does not allow
# GitHub Actions to open PRs.
name: Release Please

on:
  push:
    branches: [main]

permissions:
  contents: write
  pull-requests: write

jobs:
  release-please:
    runs-on: ubuntu-latest
    steps:
      - uses: googleapis/release-please-action@v5
        with:
          token: ${{ secrets.RELEASE_PLEASE_TOKEN }}
          config-file: release-please-config.json
          manifest-file: .release-please-manifest.json
```

- [ ] **Step 4: `RELEASING.md`**

````markdown
# Releasing flutter_chat_reactions

Releases are automated: conventional commits on `main` → a Release Please PR → merge it → tag →
pub.dev. This page covers the one-time setup and the maintenance chores.

## One-time setup (maintainer)

1. **pub.dev automated publishing** — on https://pub.dev/packages/flutter_chat_reactions/admin →
   *Automated publishing*: enable publishing from GitHub Actions, repository
   `Dexterfury/flutter_chat_reactions`, tag pattern `{{version}}`, and require the GitHub
   environment `pub.dev`.
2. **GitHub environment** — repository *Settings → Environments → New environment* named
   `pub.dev`. Optionally add yourself as a required reviewer so every publish waits for approval.
3. **Release token** — create a fine-grained personal access token limited to this repository with
   *Contents: Read and write* and *Pull requests: Read and write*, then add it as the repository
   secret `RELEASE_PLEASE_TOKEN` (*Settings → Secrets and variables → Actions*). Release Please and
   the GIF workflow use it to open PRs; tags it creates can trigger the publish workflow.
   (Alternatively enable *Settings → Actions → General → Allow GitHub Actions to create and approve
   pull requests* — Release Please still needs the token for tags to trigger publishing.)

## Shipping 1.0.0

1. Merge the modernization PR into `main` with **Create a merge commit** (not squash), so Release
   Please sees the individual conventional commits for the changelog.
2. Release Please opens *"chore(main): release 1.0.0"*. Review the version, CHANGELOG and README
   install line, then merge it.
3. The tag `1.0.0` triggers **Publish to pub.dev**; approve the `pub.dev` environment if required.
   Publishing the GitHub release also re-records the demo GIFs.
4. After 1.0.0 is out, remove `"release-as": "1.0.0"` from `release-please-config.json` so later
   releases follow semver from the commit types.

## Everyday releases

`fix:` → patch, `feat:` → minor, `feat!:` / `BREAKING CHANGE:` → major. Commits that only touch
`example/`, `docs/`, `doc/`, `tool/` or `.github/` stay out of the changelog.

## Demo GIFs (`doc/gifs/`)

Recorded on an iOS simulator from the example's demo scripts by **Record demo GIFs**
(`.github/workflows/demo-gifs.yml`):

- on every published release,
- manually from the Actions tab (optionally listing demo slugs), or
- by pushing a commit whose message contains `[record-gifs]` to any branch except `main`.

The workflow pushes a `demo-gifs/<run>` branch and opens a PR when `RELEASE_PLEASE_TOKEN` exists.
On a Mac you can run it locally: `tool/record_gifs.sh [slug…]` (needs Xcode, Flutter, ffmpeg and
gifsicle; `THEMES=light` records one theme).

## Golden images (`test/goldens/`)

Goldens are generated on Linux only. After an intentional visual change, push a commit whose message
contains `[update-goldens]` to your branch; **Update goldens** regenerates and commits them.
````

- [ ] **Step 5: Validate and commit**

Run: `python -c "import json,yaml;json.load(open('release-please-config.json'));json.load(open('.release-please-manifest.json'));yaml.safe_load(open('.github/workflows/release-please.yml'));print('ok')" && grep -n "x-release-please-version" README.md`
Expected: `ok`, and exactly one README line containing `x-release-please-version`.

```bash
git add release-please-config.json .release-please-manifest.json .github/workflows/release-please.yml RELEASING.md
git commit -m "ci: Automate releases with Release Please

Co-Authored-By: <committing model> <noreply@anthropic.com>"
```

---

### Task 5: pub.dev screenshot, ship one GIF, remove the old root GIFs

**Precondition:** `doc/gifs/` contains all 12 recorded GIFs; the controller merged the recording PR into this branch.

**Files:**
- Modify: `pubspec.yaml` (add `screenshots:`), `.pubignore`
- Delete: `demo_light.gif`, `demo_dark.gif`, `flutter_chat_reactions_iphone_demo2.gif`

**Interfaces:**
- Consumes: `doc/gifs/messenger_light.gif`.
- Produces: a pub.dev screenshot entry, where that GIF is the only one in the published archive.

- [ ] **Step 1: Check the GIF exists and its size**

Run: `ls -la doc/gifs/ && wc -c doc/gifs/messenger_light.gif`
Expected: 12 GIFs, and `messenger_light.gif` under 4 MB (pub.dev's screenshot limit). If it's bigger, stop and report it.

- [ ] **Step 2: Add the screenshot to `pubspec.yaml`**

Insert after the `topics:` list:

```yaml
screenshots:
  - description: 'Messenger-style focused overlay: blurred backdrop, reaction bar above the message and actions below.'
    path: doc/gifs/messenger_light.gif
```

- [ ] **Step 3: Ship only that GIF in the archive**

In `.pubignore`, replace the line `doc/gifs/` with:

```gitignore
doc/gifs/*
!doc/gifs/messenger_light.gif
```

(Keep `/*.gif`.)

- [ ] **Step 4: Delete the old root GIFs**

Run: `git rm -q demo_light.gif demo_dark.gif flutter_chat_reactions_iphone_demo2.gif && grep -rn "demo_light.gif\|demo_dark.gif\|iphone_demo2" --include=*.md --include=*.yaml . | grep -v docs/superpowers || echo "no references"`
Expected: `no references`.

- [ ] **Step 5: Verify the package archive**

Run: `dart pub publish --dry-run 2>&1 | grep -E "gif|Total compressed|warning" `
Expected: `doc/gifs/messenger_light.gif` is the only `.gif` in the listing; the archive size is well under 2 MB; and `Package has 0 warnings.` (on a clean tree).

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml .pubignore
git commit -m "docs: Add pub.dev screenshot and remove the old demo GIFs

Co-Authored-By: <committing model> <noreply@anthropic.com>"
```
(The `git rm` in Step 4 already staged the deletions.)
