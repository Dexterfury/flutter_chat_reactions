# Changelog

## [1.0.0] (2026-09-28)

A redesign for any chat app — see [MIGRATION.md](https://github.com/Dexterfury/flutter_chat_reactions/blob/main/MIGRATION.md) for upgrading from 0.2.x.

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

## [0.2.7]

* Fixed a bug where customMenuItemBuilder was not being used.

## [0.2.6]

* Fixed an issue where a user could add multiple reactions to a single message. Now, a user can only have one reaction per message. If a user selects a new reaction, it replaces the old one. If they select the same reaction, it is removed.

## [0.2.5]

* **Breaking Change:** Refactored the entire package to use a `ReactionsController` and `ChatMessageWrapper` for a more robust and flexible API.
* Added a `ChatReactionsConfig` to allow for extensive customization of the reactions dialog and its components.
* Integrated `emoji_picker_flutter` to provide a default emoji picker, which can be replaced with a custom implementation.
* Made the context menu optional and customizable.
* Added comprehensive documentation and comments to all public APIs.
* Improved the example app to showcase the new API and features.

## [0.1.1]

* Extracted components into separate widgets
* Added comprehensive documentation
* Improved null safety handling
* Added proper mounted checks in async operations
* Added complete widget documentation
* Improved component organization
* Extracted reusable sub-widgets
* Improved overall package structure and organization 

## [0.1.0]

* Updated the read me file
* Code refactoring

## [0.0.9]

* Updated example App
* Added a StackedReactions widget for displaying reactions
* Updated dependencies
* Updated the read me file

## [0.0.8]

* Minor fixes

## [0.0.7]

* Updated demo gifs

## [0.0.6]

* Added dark theme mode support

## [0.0.5]

* Updated the demo gif

## [0.0.4]

* Updated the read me file
* Code refactoring
