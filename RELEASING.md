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
