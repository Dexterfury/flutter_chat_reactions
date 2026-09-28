# Contributing to flutter_chat_reactions

Thanks for helping to improve the package. Bug reports, fixes, docs and new ideas are all welcome.

## How changes get in

- `main` is protected. Every change goes through a pull request from a fork or a branch, and is
  reviewed and merged by the maintainer ([@Dexterfury](https://github.com/Dexterfury)).
- All CI checks must pass before a pull request can be merged.
- Releases to pub.dev are automated; contributors never publish. See [RELEASING.md](RELEASING.md).

## Before you start

For anything bigger than a small fix, please open an issue first so we can agree on the approach.
That avoids work on changes that don't fit the package's design.

## Development setup

The package supports Flutter 3.32 and later (Dart 3.8).

```bash
flutter pub get
flutter test --exclude-tags golden
```

The example gallery lives in `example/`:

```bash
cd example
flutter run
```

## Checks CI runs

Run these before pushing; CI runs the same checks on Flutter 3.32 and stable.

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test --coverage --exclude-tags golden
```

- Coverage must stay at or above 90%.
- Golden images are generated on Linux in CI. If your change alters them, the maintainer
  regenerates them; don't commit goldens produced on macOS or Windows.
- The demo GIFs are recorded by CI on an iOS simulator; you don't need to update them.

## Commit messages and pull request titles

This project uses [Conventional Commits](https://www.conventionalcommits.org). The pull request
title becomes the changelog entry, so make it clear:

- `fix: Keep the reaction bar on screen near the top edge`
- `feat: Add a haptic feedback option`
- `docs: Clarify the theming example`

Add `!` for breaking changes, for example `feat!: Rename ReactionBar.onTap`.

## Code style

- Follow the existing structure in `lib/src/` and the lints in `analysis_options.yaml`.
- Public APIs need dartdoc comments.
- The package has no third-party runtime dependencies; please keep it that way.

## Code of conduct

By taking part you agree to follow the [code of conduct](CODE_OF_CONDUCT.md).

## License

By contributing, you agree that your contributions are licensed under the project's
[GPL-3.0 license](LICENSE).
