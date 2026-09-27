/// Reactions and context menus for chat messages.
///
/// Wrap a message in [ReactableMessage] to let users react to it, and show the
/// result with [ReactionsSummaryView]. Reaction data is owned by your app; the
/// optional [ReactionsController] covers apps without their own state layer.
library;

export 'src/controller/reaction_change.dart';
export 'src/controller/reactions_controller.dart';
export 'src/l10n/chat_reactions_localizations.dart';
export 'src/layout/anchored_layout.dart';
export 'src/layout/reaction_alignment.dart';
export 'src/models/reaction.dart';
export 'src/models/reaction_action.dart';
export 'src/models/reaction_policy.dart';
export 'src/models/reaction_summary.dart';
export 'src/models/reaction_user.dart';
export 'src/presenters/bottom_sheet_presenter.dart';
export 'src/presenters/compact_bar_presenter.dart';
export 'src/presenters/custom_presenter.dart';
export 'src/presenters/focused_overlay_presenter.dart';
export 'src/presenters/reactions_menu_context.dart';
export 'src/presenters/reactions_presenter.dart';
export 'src/theme/adaptive.dart' show ReactionHaptics, ReactionsVisualStyle;
export 'src/theme/chat_reactions_theme.dart';
export 'src/theme/reaction_styles.dart';
export 'src/trigger/reaction_trigger.dart';
export 'src/widgets/emoji.dart';
export 'src/widgets/reaction_action_menu.dart';
export 'src/widgets/reaction_bar.dart';
export 'src/widgets/reaction_details.dart';
export 'src/widgets/reactions_summary_view.dart';
