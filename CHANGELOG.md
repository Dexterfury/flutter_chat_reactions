# Changelog

## [1.0.0](https://github.com/Dexterfury/flutter_chat_reactions/compare/0.2.7...1.0.0) (2026-09-28)


### ⚠ BREAKING CHANGES

* ReactionsSummaryView.onLongPress is now onReactionLongPress (ValueChanged<String>).
* Add minimal 1.0 example, reach 90% coverage, tighten CI gates
* Add ReactableMessage and ChatReactionsScope
* Add ReactionsSummaryView (chips/stacked/compact) and reaction details sheet
* Add adaptive ChatReactionsTheme ThemeExtension and style classes
* Add ReactionsController with single/multiple policies and optimistic rollback
* Add immutable reaction data models and summarize()
* ChatMessageWrapper, StackedReactions, ChatReactionsConfig, MenuItem and the old ReactionsController are removed. See MIGRATION.md (Plan 4).

### Features

* Add adaptive ChatReactionsTheme ThemeExtension and style classes ([4c6ca48](https://github.com/Dexterfury/flutter_chat_reactions/commit/4c6ca48b8a6c9745b203230742148f14ce6f2c55))
* Add AnchoredLayout for safe-area-aware menu positioning ([6fbd9dd](https://github.com/Dexterfury/flutter_chat_reactions/commit/6fbd9dd41c0d31c4be6d1b61765a0eaffe489e6a))
* Add BottomSheetPresenter with Material sheet and Cupertino action sheet ([f9b3109](https://github.com/Dexterfury/flutter_chat_reactions/commit/f9b3109a52de52facd114eb23141a8c50b039912))
* Add ChatReactionsLocalizations with English defaults ([10f1d7f](https://github.com/Dexterfury/flutter_chat_reactions/commit/10f1d7f75198aada115b4b50a1b2d7401391741b))
* Add CompactBarPresenter with hover persistence and actions overflow ([511ffe3](https://github.com/Dexterfury/flutter_chat_reactions/commit/511ffe3d560e93ff8bb8d54aa5ebd4d0117a8d35))
* Add CustomPresenter.dismissible ([526df10](https://github.com/Dexterfury/flutter_chat_reactions/commit/526df10982043ae10d73c0b8e7ad5ea4e7e6596e))
* Add emojiBuilder to reaction details and ReactionAction.copyWith ([7b07a81](https://github.com/Dexterfury/flutter_chat_reactions/commit/7b07a8171b6b3fc33634be1c925f144f2fdaa60f))
* Add FocusedOverlayPresenter with safe-area layout and sheet fallback ([79ebf32](https://github.com/Dexterfury/flutter_chat_reactions/commit/79ebf32225db1d756d18612ee4c5c4a9ad15efae))
* Add immutable reaction data models and summarize() ([0761055](https://github.com/Dexterfury/flutter_chat_reactions/commit/076105580183d18b8def13f184891fcd78f4a6ac))
* Add minimal 1.0 example, reach 90% coverage, tighten CI gates ([2c938fe](https://github.com/Dexterfury/flutter_chat_reactions/commit/2c938feca31e3f0daa5d7a5efa99d2734fbb4d5c))
* Add presenter infrastructure, menu route, and headless CustomPresenter ([997a1ad](https://github.com/Dexterfury/flutter_chat_reactions/commit/997a1adab9e1f25d39366b514a9ce65ff335ad49))
* Add ReactableMessage and ChatReactionsScope ([bfdeaba](https://github.com/Dexterfury/flutter_chat_reactions/commit/bfdeaba6d52165a8bf9f3890a0ce6775aca00b4b))
* Add ReactionBar and ReactionActionMenu building blocks ([ccf867d](https://github.com/Dexterfury/flutter_chat_reactions/commit/ccf867db9c79dc14353211b78e4229984d94cfad))
* Add ReactionsController with single/multiple policies and optimistic rollback ([ae9be0f](https://github.com/Dexterfury/flutter_chat_reactions/commit/ae9be0ff8c81107536a18e7fe7042e2fac6ff9f8))
* Add ReactionsSummaryView (chips/stacked/compact) and reaction details sheet ([9aeae1c](https://github.com/Dexterfury/flutter_chat_reactions/commit/9aeae1c2177284a7e922a1632c86692c9983ffe2))


### Bug Fixes

* Arm hover-open from onHover so synthetic enters never reopen the bar ([8280337](https://github.com/Dexterfury/flutter_chat_reactions/commit/8280337ad63a2d94e8805c765740853ac502cecd))
* Avoid intrinsic-height crash in BottomSheetPresenter's Cupertino details view ([0a8eb07](https://github.com/Dexterfury/flutter_chat_reactions/commit/0a8eb07b802b80ba4d4a5c5dc85506fab8513d54))
* Carry the message's inherited themes and scope into menus ([afc5372](https://github.com/Dexterfury/flutter_chat_reactions/commit/afc53722b170d7818ce41576b42c1a8c5588f96b))
* Close bottom sheet when dismissed before it finishes building ([48f5d90](https://github.com/Dexterfury/flutter_chat_reactions/commit/48f5d90747c0f622c092ce5e87be5d77b8b168ac))
* Dismiss state, animation leaks and stale hover after updates ([95c51bb](https://github.com/Dexterfury/flutter_chat_reactions/commit/95c51bb0890537d372fec40211676769d4920390))
* Give ChatReactionsTheme value equality ([9e9112a](https://github.com/Dexterfury/flutter_chat_reactions/commit/9e9112a4f51640acbcd11e848662dcd2a0278aa8))
* Guard AnchoredLayout against tiny safe areas and header/footer overlap ([4a3f4f4](https://github.com/Dexterfury/flutter_chat_reactions/commit/4a3f4f45ba92882472f849238ebeac7770ac7ece))
* Guard ReactionsSummaryView against negative maxVisible ([a57ac0a](https://github.com/Dexterfury/flutter_chat_reactions/commit/a57ac0aed5dd51af898fe4a57778b97f4e9cf9cb))
* Honour reduced motion in CustomPresenter and freeze model collections ([0e0bb4c](https://github.com/Dexterfury/flutter_chat_reactions/commit/0e0bb4cb5878bf6de5c2ad9f6300910200b2143b))
* Shrink-wrap Cupertino reaction details up to 240px ([decce44](https://github.com/Dexterfury/flutter_chat_reactions/commit/decce44853a9e2cdf2c3b01867eaf43e04071275))
* Stop hover-opened reaction bar from reopening after Escape ([7618a3a](https://github.com/Dexterfury/flutter_chat_reactions/commit/7618a3aa892e1f81e884268f2c401b1797be1b03))


### Code Refactoring

* Remove 0.2.x API and third-party dependencies ahead of 1.0.0 ([f80a3be](https://github.com/Dexterfury/flutter_chat_reactions/commit/f80a3be1fca80f099cc13a5321e8103e6d1024a1))
* Rename ReactionsSummaryView.onLongPress to onReactionLongPress ([0723573](https://github.com/Dexterfury/flutter_chat_reactions/commit/072357329db4900bba37a8cd89d63983f1db9c7e))

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
