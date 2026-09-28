# Plan 1 of 4 — CI Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Put quality gates (format, analysis, tests, coverage, pana, publish dry-run, example builds) on every PR and replace the tag-triggered publish workflow with the official pub.dev OIDC reusable workflow, without changing the package's public API.

**Architecture:** Two GitHub Actions workflows (`ci.yml`, `publish.yml`) plus a small Dart script, `tool/check_coverage.dart`, that enforces a line-coverage floor from `coverage/lcov.info`. The coverage floor and the pana threshold are workflow `env` values, so Plan 2 can tighten them in one line each.

**Tech Stack:** Flutter 3.32+/stable, GitHub Actions (`actions/checkout@v5`, `subosito/flutter-action@v2`, `actions/setup-java@v5`, `actions/upload-artifact@v4`, `dart-lang/setup-dart/.github/workflows/publish.yml@v1`), `pana`.

**Spec:** `docs/superpowers/specs/2026-09-26-v1-modernization-design.md` (§10, §14.1, §14.3, §15 phase 1)

## Global Constraints

- SDK floor: `sdk: ^3.8.0`, `flutter: ">=3.32.0"`. This deviates from the spec's `^3.6.0`/`>=3.27.0` because `flutter_lints` 6.0.0 requires Dart `^3.8.0`. Task 1 records the change in the spec.
- Runtime dependencies are unchanged in this plan: `animate_do` and `emoji_picker_flutter` stay until Plan 2.
- Dev dependency: `flutter_lints: ^6.0.0`.
- CI matrix: Flutter `3.32.x` and `stable`.
- Commit messages use Conventional Commits and end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Do NOT commit the pre-existing modifications to `example/**/generated_plugin*`, `example/macos/Flutter/GeneratedPluginRegistrant.swift` or `example/pubspec.lock` unless a step explicitly says so.

---

### Task 1: Package metadata, SDK floor, lint upgrade, packaging hygiene

**Files:**
- Modify: `pubspec.yaml` (whole file)
- Modify: `lib/flutter_chat_reactions.dart:1` (remove the `library` directive)
- Modify: `example/pubspec.yaml` (environment and flutter_lints)
- Modify: `example/lib/main.dart:66-96` (remove the unused `_customMenuItemBuilder`) and `example/lib/main.dart:124` (add `const`)
- Create: `.pubignore`
- Modify: `.gitignore`
- Modify: `docs/superpowers/specs/2026-09-26-v1-modernization-design.md` (§10 and §14.1 SDK floor)

**Interfaces:**
- Consumes: nothing.
- Produces: a package that resolves on Flutter ≥ 3.32, analyzes clean with `--fatal-infos`, and whose `dart pub publish --dry-run` archive excludes GIFs, `docs/`, `tool/` and `coverage/`.

- [ ] **Step 1: Record the baseline archive size**

Run: `dart pub publish --dry-run 2>&1 | grep -i "total compressed archive size"`
Expected: about 11 MB (the root GIFs are included). Write the number down for Step 9.

- [ ] **Step 2: Replace `pubspec.yaml`**

```yaml
name: flutter_chat_reactions
description: "Add reactions and a context menu to chat messages in Flutter, with adaptive iOS and Material styling."
version: 0.2.7
homepage: https://github.com/Dexterfury/flutter_chat_reactions
repository: https://github.com/Dexterfury/flutter_chat_reactions
issue_tracker: https://github.com/Dexterfury/flutter_chat_reactions/issues
topics:
  - chat
  - reactions
  - emoji
  - context-menu
  - messaging

environment:
  sdk: ^3.8.0
  flutter: ">=3.32.0"

dependencies:
  flutter:
    sdk: flutter
  animate_do: ^4.2.0
  emoji_picker_flutter: ^4.3.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0

flutter:
  uses-material-design: true
```

- [ ] **Step 3: Remove the `library` directive**

In `lib/flutter_chat_reactions.dart`, delete line 1 (`library flutter_chat_reactions;`) and the blank line after it. The file then starts with `export 'src/models/reaction.dart';`.

- [ ] **Step 4: Update `example/pubspec.yaml`**

Replace the `environment` block and the `flutter_lints` line:

```yaml
environment:
  sdk: ^3.8.0
```

```yaml
  flutter_lints: ^6.0.0
```

- [ ] **Step 5: Fix the two existing example analyzer issues**

In `example/lib/main.dart`:
1. Delete the whole unused method `Widget _customMenuItemBuilder(MenuItem item, VoidCallback onTap) { ... }` (lines 66–96) and the commented-out `//customMenuItemBuilder: _customMenuItemBuilder,` line inside `build`.
2. Change `final config = ChatReactionsConfig(` (line 124) to `const config = ChatReactionsConfig(`.

- [ ] **Step 6: Create `.pubignore`**

A `.pubignore` replaces `.gitignore` for publishing, so it has to repeat the relevant ignore rules.

```gitignore
# Build and tool output
.dart_tool/
build/
coverage/
/pubspec.lock
.flutter-plugins
.flutter-plugins-dependencies

# Repository-only content (README images load from GitHub)
/*.gif
doc/gifs/
docs/
tool/
.github/
.qodo

# Example build output
example/build/
example/.dart_tool/

# Editor / OS
.idea/
*.iml
.DS_Store
```

- [ ] **Step 7: Stop tracking generated plugin files**

Append to `.gitignore`:

```gitignore
# Flutter tool generated
.flutter-plugins
.flutter-plugins-dependencies
coverage/
```

Run: `git rm --cached .flutter-plugins-dependencies`
Expected: `rm '.flutter-plugins-dependencies'`

- [ ] **Step 8: Record the SDK floor change in the spec**

In `docs/superpowers/specs/2026-09-26-v1-modernization-design.md`, change:

- in §10, `` `sdk: ^3.6.0`, `flutter: ">=3.27.0"` `` → `` `sdk: ^3.8.0`, `flutter: ">=3.32.0"` (raised from 3.6/3.27 because `flutter_lints` 6 requires Dart 3.8) ``
- in §14.1, `matrix of Flutter \`3.27.x\` and \`stable\`` → `matrix of Flutter \`3.32.x\` and \`stable\``

- [ ] **Step 9: Verify**

Run:
```bash
flutter pub get && (cd example && flutter pub get) && dart format --output=none --set-exit-if-changed . && flutter analyze --fatal-infos && dart pub publish --dry-run 2>&1 | tail -20
```
Expected:
- format: `0 changed`
- analyze: `No issues found!`
- the dry-run file listing contains no `.gif`, no `docs/`, no `tool/`
- `Total compressed archive size` is under 100 KB
- `Package has 0 warnings.`

If `flutter analyze` reports new `flutter_lints` 6 infos in `lib/` or `example/lib/`, fix each one exactly as the lint message suggests. These are small mechanical fixes only; no API changes.

- [ ] **Step 10: Commit**

```bash
git add pubspec.yaml lib/flutter_chat_reactions.dart example/pubspec.yaml example/lib/main.dart .pubignore .gitignore docs/superpowers/specs/2026-09-26-v1-modernization-design.md
git commit -m "build: Raise SDK floor to Flutter 3.32, upgrade lints, exclude GIFs from package

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
(`git rm --cached` already staged the removal of `.flutter-plugins-dependencies`.)

---

### Task 2: Characterization tests for the current controller

The CI gate needs real tests. These pin down the 0.2.7 `ReactionsController` behaviour, and Plan 2 Task 3 replaces them.

**Files:**
- Create: `test/legacy_reactions_controller_test.dart`
- Delete: `test/flutter_chat_reactions_test.dart` (an empty placeholder)

**Interfaces:**
- Consumes: `ReactionsController({required String currentUserId})`, `toggleReaction(String messageId, String emoji, {String? userName})`, `getReactions`, `getReactionCounts`, `hasUserReacted`, `clearReactions` from `package:flutter_chat_reactions/flutter_chat_reactions.dart`.
- Produces: a green `flutter test` run, so CI has something meaningful to execute.

- [ ] **Step 1: Write the tests**

```dart
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReactionsController (0.2.x behaviour)', () {
    late ReactionsController controller;
    var notifications = 0;

    setUp(() {
      controller = ReactionsController(currentUserId: 'me');
      notifications = 0;
      controller.addListener(() => notifications++);
    });

    test('toggle adds a reaction for the current user', () {
      controller.toggleReaction('m1', '👍');

      expect(controller.hasUserReacted('m1', '👍'), isTrue);
      expect(controller.getReactionCounts('m1'), {'👍': 1});
      expect(notifications, greaterThan(0));
    });

    test('toggling the same emoji twice removes it', () {
      controller.toggleReaction('m1', '👍');
      controller.toggleReaction('m1', '👍');

      expect(controller.hasUserReacted('m1', '👍'), isFalse);
      expect(controller.getReactions('m1'), isEmpty);
    });

    test('a different emoji replaces the previous one (single policy)', () {
      controller.toggleReaction('m1', '👍');
      controller.toggleReaction('m1', '❤️');

      expect(controller.getReactionCounts('m1'), {'❤️': 1});
    });

    test('clearReactions empties one message only', () {
      controller.toggleReaction('m1', '👍');
      controller.toggleReaction('m2', '😂');
      controller.clearReactions('m1');

      expect(controller.getReactions('m1'), isEmpty);
      expect(controller.getReactionCounts('m2'), {'😂': 1});
    });
  });
}
```

- [ ] **Step 2: Delete the placeholder and run the tests**

Run: `git rm test/flutter_chat_reactions_test.dart && flutter test`
Expected: `All tests passed!`. The tests describe existing behaviour, so they pass immediately. If one fails, the test has misread the current behaviour; fix the test, not `lib/`.

- [ ] **Step 3: Commit**

```bash
git add test/legacy_reactions_controller_test.dart
git commit -m "test: Add characterization tests for the 0.2.x ReactionsController

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Coverage gate script and the CI workflow

**Files:**
- Create: `tool/check_coverage.dart`
- Create: `.github/workflows/ci.yml`

**Interfaces:**
- Consumes: `coverage/lcov.info`, produced by `flutter test --coverage`.
- Produces: `dart run tool/check_coverage.dart <minPercent> [lcovPath]`, which exits 1 when coverage is below the minimum. The workflow reads `env.MIN_COVERAGE` and `env.PANA_MAX_MISSING_POINTS`, and Plan 2's final task changes them to `90` and `10`.

- [ ] **Step 1: Write `tool/check_coverage.dart`**

```dart
import 'dart:io';

/// Fails (exit code 1) when line coverage in an lcov file is below a minimum.
///
/// Usage: dart run tool/check_coverage.dart <minPercent> [path/to/lcov.info]
void main(List<String> args) {
  final minimum = args.isEmpty ? 0.0 : double.parse(args[0]);
  final file = File(args.length > 1 ? args[1] : 'coverage/lcov.info');
  if (!file.existsSync()) {
    stderr.writeln('Coverage file not found: ${file.path}');
    exit(1);
  }

  var found = 0;
  var hit = 0;
  for (final line in file.readAsLinesSync()) {
    if (line.startsWith('LF:')) {
      found += int.parse(line.substring(3));
    } else if (line.startsWith('LH:')) {
      hit += int.parse(line.substring(3));
    }
  }

  final percent = found == 0 ? 100.0 : hit * 100 / found;
  stdout.writeln(
    'Line coverage: ${percent.toStringAsFixed(1)}% ($hit/$found lines), '
    'minimum ${minimum.toStringAsFixed(1)}%',
  );
  if (percent < minimum) {
    stderr.writeln('Coverage is below the minimum.');
    exit(1);
  }
}
```

- [ ] **Step 2: Check the script both ways**

Run: `flutter test --coverage && dart run tool/check_coverage.dart 0 && dart run tool/check_coverage.dart 101; echo "exit=$?"`
Expected: two `Line coverage: …` lines. The second command prints `Coverage is below the minimum.` and `exit=1`.

- [ ] **Step 3: Measure the current pana score**

Run: `dart pub global activate pana && dart pub global run pana --no-warning . 2>&1 | tail -5`
Expected: a `Points: X/160` line. Set `PANA_MAX_MISSING_POINTS` in Step 4 to `160 - X + 5`, rounded up to a multiple of 5, so today's code passes. Plan 2 tightens it to `10`.

- [ ] **Step 4: Write `.github/workflows/ci.yml`**

```yaml
name: CI

on:
  pull_request:
  push:
    branches: [main]

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

env:
  # Raised to 90 at the end of Plan 2.
  MIN_COVERAGE: 0
  # Lowered to 10 (score >= 150/160) at the end of Plan 2.
  PANA_MAX_MISSING_POINTS: 40

jobs:
  checks:
    name: Checks (Flutter ${{ matrix.flutter }})
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        flutter: ['3.32.x', 'stable']
    steps:
      - uses: actions/checkout@v5

      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          # Empty for 'stable' (latest stable release), pinned otherwise.
          flutter-version: ${{ matrix.flutter != 'stable' && matrix.flutter || '' }}
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Verify formatting
        if: matrix.flutter == 'stable'
        run: dart format --output=none --set-exit-if-changed .

      - name: Analyze
        run: flutter analyze --fatal-infos

      - name: Test with coverage
        run: flutter test --coverage

      - name: Enforce coverage floor
        if: matrix.flutter == 'stable'
        run: dart run tool/check_coverage.dart "$MIN_COVERAGE"

      - name: Upload coverage
        if: matrix.flutter == 'stable'
        uses: actions/upload-artifact@v4
        with:
          name: lcov
          path: coverage/lcov.info

      - name: Publish dry run
        if: matrix.flutter == 'stable'
        run: dart pub publish --dry-run

  pana:
    name: Package score (pana)
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true
      - name: Run pana
        run: |
          dart pub global activate pana
          dart pub global run pana --no-warning --exit-code-threshold "$PANA_MAX_MISSING_POINTS" .

  example:
    name: Build example (${{ matrix.target }})
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        target: [apk, web]
    defaults:
      run:
        working-directory: example
    steps:
      - uses: actions/checkout@v5
      - uses: actions/setup-java@v5
        if: matrix.target == 'apk'
        with:
          distribution: temurin
          java-version: '17'
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true
      - run: flutter pub get
      - name: Build APK
        if: matrix.target == 'apk'
        run: flutter build apk --debug
      - name: Build web
        if: matrix.target == 'web'
        run: flutter build web
```

- [ ] **Step 5: Replace the placeholder pana threshold**

Change `PANA_MAX_MISSING_POINTS: 40` to the value calculated in Step 3.

- [ ] **Step 6: Run the workflow's commands locally**

Run:
```bash
dart format --output=none --set-exit-if-changed . && flutter analyze --fatal-infos && flutter test --coverage && dart run tool/check_coverage.dart 0 && dart pub publish --dry-run && (cd example && flutter build web)
```
Expected: every command exits 0. (The APK build is checked in CI; it needs the Android SDK and Java 17 locally.)

- [ ] **Step 7: Commit**

```bash
git add tool/check_coverage.dart .github/workflows/ci.yml
git commit -m "ci: Add PR checks for format, analysis, tests, coverage, pana, and example builds

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Replace the publish workflow with the official OIDC reusable workflow

**Files:**
- Modify: `.github/workflows/publish.yml` (replace the whole file)

**Interfaces:**
- Consumes: a pushed tag matching `[0-9]+.[0-9]+.[0-9]+*`, a GitHub environment named `pub.dev`, and pub.dev automated publishing configured for this repository (maintainer setup, spec §14.5).
- Produces: a publish job that Plan 4's Release Please tags trigger. GitHub releases are no longer created here; Release Please creates them in Plan 4.

- [ ] **Step 1: Replace `.github/workflows/publish.yml`**

```yaml
# Publishes to pub.dev when a version tag (e.g. 1.0.0 or 1.1.0-beta.1) is pushed.
# Authentication uses GitHub OIDC; no pub.dev secrets are stored in the repo.
# One-time setup (maintainer): see docs/superpowers/specs/2026-09-26-v1-modernization-design.md §14.5.
name: Publish to pub.dev

on:
  push:
    tags:
      - '[0-9]+.[0-9]+.[0-9]+*'

jobs:
  publish:
    permissions:
      id-token: write
    uses: dart-lang/setup-dart/.github/workflows/publish.yml@v1
    with:
      environment: pub.dev
```

- [ ] **Step 2: Validate the YAML**

Run: `python -c "import yaml,sys;[yaml.safe_load(open(f)) for f in sys.argv[1:]];print('ok')" .github/workflows/publish.yml .github/workflows/ci.yml`
Expected: `ok`. If PyYAML is missing, run `pip install pyyaml` first.

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/publish.yml
git commit -m "ci: Publish via the official dart-lang OIDC reusable workflow

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

- [ ] **Step 4: Push and confirm CI is green**

Run: `git push -u origin feat/v1-modernization`, open a draft PR with `gh pr create --draft --title "feat!: flutter_chat_reactions 1.0.0 modernization" --body-file -`, and watch the checks with the ccd_pr tools. Do not poll by hand.
Expected: the `Checks (3.32.x)`, `Checks (stable)`, `Package score (pana)`, `Build example (apk)` and `Build example (web)` jobs all pass. If a job fails, use superpowers:systematic-debugging before changing anything.

The PR body must end with:

```
🤖 Generated with [Claude Code](https://claude.com/claude-code)
```
