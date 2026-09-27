import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/chat_reactions_localizations.dart';
import '../models/reaction_summary.dart';
import '../models/reaction_user.dart';
import 'emoji.dart';

/// Lists who reacted with what. Shows a count when user details are unknown.
class ReactionDetailsList extends StatelessWidget {
  /// Creates a details list.
  const ReactionDetailsList({
    super.key,
    required this.reactions,
    this.scrollable = true,
    this.emojiBuilder,
  });

  /// Reactions to list.
  final List<ReactionSummary> reactions;

  /// Custom emoji rendering (e.g. images for `:shortcode:` ids); emojis are
  /// shown as text when null.
  final EmojiBuilder? emojiBuilder;

  /// Whether rows are laid out in a scrolling, shrink-wrapped [ListView]
  /// (the default). When false, rows are laid out in a plain, non-lazy
  /// [Column] instead — useful when a caller needs an intrinsic-height-aware
  /// ancestor (e.g. a [SingleChildScrollView] capped by a [ConstrainedBox]),
  /// which a [ListView] cannot provide.
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final l10n = ChatReactionsLocalizations.of(context);
    final rows = <Widget>[];
    for (final summary in reactions) {
      if (summary.users.isEmpty) {
        rows.add(
          ListTile(
            dense: true,
            leading: _emoji(context, emojiBuilder, summary.emoji, 22),
            title: Text(l10n.reactionCount(summary.count)),
          ),
        );
        continue;
      }
      for (final user in summary.users) {
        rows.add(
          _UserTile(
            user: user,
            emoji: summary.emoji,
            emojiBuilder: emojiBuilder,
          ),
        );
      }
    }
    if (!scrollable) {
      return Column(mainAxisSize: MainAxisSize.min, children: rows);
    }
    return ListView(shrinkWrap: true, children: rows);
  }
}

Widget _emoji(
  BuildContext context,
  EmojiBuilder? builder,
  String emoji,
  double size,
) => builder == null
    ? Text(emoji, style: TextStyle(fontSize: size))
    : builder(context, emoji, size);

class _UserTile extends StatelessWidget {
  const _UserTile({
    required this.user,
    required this.emoji,
    required this.emojiBuilder,
  });

  final ReactionUser user;
  final String emoji;
  final EmojiBuilder? emojiBuilder;

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
      trailing: _emoji(context, emojiBuilder, emoji, 20),
    );
  }
}

/// A tabbed sheet: "All" plus one tab per emoji, each listing users.
class ReactionDetailsSheet extends StatelessWidget {
  /// Creates a details sheet.
  const ReactionDetailsSheet({
    super.key,
    required this.reactions,
    this.emojiBuilder,
  });

  /// Reactions to show.
  final List<ReactionSummary> reactions;

  /// Custom emoji rendering for the tabs and rows; emojis are shown as text
  /// when null.
  final EmojiBuilder? emojiBuilder;

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
              for (final r in reactions)
                emojiBuilder == null
                    ? Tab(text: '${r.emoji} ${r.count}')
                    : Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            emojiBuilder!(context, r.emoji, 16),
                            Text(' ${r.count}'),
                          ],
                        ),
                      ),
            ],
          ),
          SizedBox(
            height: height,
            child: TabBarView(
              children: [
                ReactionDetailsList(
                  reactions: reactions,
                  emojiBuilder: emojiBuilder,
                ),
                for (final r in reactions)
                  ReactionDetailsList(
                    reactions: [r],
                    emojiBuilder: emojiBuilder,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows [ReactionDetailsSheet] in a modal bottom sheet. [emojiBuilder]
/// renders custom emoji; emojis are shown as text when null.
Future<void> showReactionDetails(
  BuildContext context,
  List<ReactionSummary> reactions, {
  EmojiBuilder? emojiBuilder,
}) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => SafeArea(
    child: ReactionDetailsSheet(
      reactions: reactions,
      emojiBuilder: emojiBuilder,
    ),
  ),
);
