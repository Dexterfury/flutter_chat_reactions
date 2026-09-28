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
   *Contents: Read and write*, *Pull requests: Read and write* and *Issues: Read and write* (release
   please applies and reads `autorelease: pending`/`autorelease: tagged` labels to find and tag the
   release PR), then add it as the repository secret `RELEASE_PLEASE_TOKEN` (*Settings → Secrets and
   variables → Actions*). Release Please and the GIF workflow use it to open PRs; tags it creates can
   trigger the publish workflow.
   (Enabling *Settings → Actions → General → Allow GitHub Actions to create and approve pull
   requests* lets the GIF workflow open PRs without the token; Release Please still needs the token
   so its tags trigger publishing.)

## Shipping 1.0.0

1. Mark the PR ready for review first (it is a draft). Merge the modernization PR into `main` with
   **Create a merge commit** (not squash), so Release Please sees the individual conventional
   commits for the changelog.
2. Release Please opens *"chore(main): release 1.0.0"*. Its generated CHANGELOG entry and PR
   description are a raw dump of every `feat`/`fix`/`refactor` commit, including fixes to code that
   was never released, a misleading breaking-change note about `onLongPress` → `onReactionLongPress`
   (that rename never shipped), an internal aside ("See MIGRATION.md (Plan 4).") from a commit
   footer, and a CHANGELOG compare link (`compare/0.2.7...1.0.0`) that is broken because `0.2.7` was
   never tagged. Before merging, replace the generated `## [1.0.0]` entry in both `CHANGELOG.md` and
   the release PR description (release-please builds the GitHub release from the PR body) with the
   curated notes below, keeping the `## [1.0.0]` heading line format but without the compare link.
   Do not fix the broken link by pushing a `0.2.7` tag; that would trigger **Publish to pub.dev**.

   ```markdown
   ## 1.0.0 (<date>)

   A redesign for any chat app — see [MIGRATION.md](MIGRATION.md) for upgrading from 0.2.x.

   ### Breaking changes

   * New layered API: `ReactableMessage` replaces `ChatMessageWrapper`; `ReactionsSummaryView`
     replaces `StackedReactions`; `ChatReactionsTheme` (ThemeExtension), `ChatReactionsScope` and
     presenters replace `ChatReactionsConfig`; `ReactionAction` replaces `MenuItem`;
     `ReactionsController` methods renamed.
   * Requires Flutter 3.32+ / Dart 3.8+. No third-party dependencies (emoji picker is pluggable via
     `onMoreTap`).

   ### Features

   * App-owned data (`ReactionSummary`, `summarize`); optional `ReactionsController` with
     single/multiple policies and optimistic rollback.
   * Four presenters: focused overlay (default), compact bar, bottom sheet, headless
     `CustomPresenter`.
   * Adaptive Cupertino/Material theming; long-press, double-tap, right-click, hover, keyboard and
     screen-reader triggers; RTL, keyboard navigation, reduced motion, localization.
   * `ReactionsSummaryView` chips / stacked / compact layouts and a who-reacted details sheet.
   * Example gallery with six demos.
   ```
3. The tag `1.0.0` triggers **Publish to pub.dev**; approve the `pub.dev` environment if required.
   Publishing the GitHub release also re-records the demo GIFs.
4. Immediately after `1.0.0` is tagged — before merging any other `feat:`/`fix:` commit to `main` —
   remove `"release-as": "1.0.0"` from `release-please-config.json` and commit it as `chore:` (a
   hidden changelog type, so it does not itself trigger a release PR). Skipping this, or merging
   another change first, causes Release Please to open a second "release 1.0.0" PR.

## Everyday releases

`fix:` → patch, `feat:` → minor, `feat!:` / `BREAKING CHANGE:` → major. Commits that only touch
`example/`, `docs/`, `doc/`, `tool/` or `.github/` stay out of the changelog.

## Demo GIFs (`doc/gifs/`)

Recorded on an iOS simulator from the example's demo scripts by **Record demo GIFs**
(`.github/workflows/demo-gifs.yml`):

- on every published release,
- manually from the Actions tab (optionally listing demo slugs and themes), or
- by pushing a commit whose message contains `[record-gifs]` to any branch except `main`; lines
  such as `record-demos: quickstart` and `record-themes: light` in that message narrow the run.

The workflow pushes a `demo-gifs/<run>` branch and opens a PR when `RELEASE_PLEASE_TOKEN` exists.
On a Mac you can run it locally: `tool/record_gifs.sh [slug…]` (needs Xcode, Flutter, ffmpeg and
gifsicle; `THEMES=light` records one theme).

## Golden images (`test/goldens/`)

Goldens are generated on Linux only. After an intentional visual change, push a commit whose message
contains `[update-goldens]` to your branch; **Update goldens** regenerates and commits them.
