import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/chat_reactions_localizations.dart';
import '../models/reaction_summary.dart';
import '../models/reaction_user.dart';

/// Lists who reacted with what. Shows a count when user details are unknown.
class ReactionDetailsList extends StatelessWidget {
  /// Creates a details list.
  const ReactionDetailsList({super.key, required this.reactions});

  /// Reactions to list.
  final List<ReactionSummary> reactions;

  @override
  Widget build(BuildContext context) {
    final l10n = ChatReactionsLocalizations.of(context);
    final rows = <Widget>[];
    for (final summary in reactions) {
      if (summary.users.isEmpty) {
        rows.add(
          ListTile(
            dense: true,
            leading: Text(summary.emoji, style: const TextStyle(fontSize: 22)),
            title: Text(l10n.reactionCount(summary.count)),
          ),
        );
        continue;
      }
      for (final user in summary.users) {
        rows.add(_UserTile(user: user, emoji: summary.emoji));
      }
    }
    return ListView(shrinkWrap: true, children: rows);
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user, required this.emoji});

  final ReactionUser user;
  final String emoji;

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
      trailing: Text(emoji, style: const TextStyle(fontSize: 20)),
    );
  }
}

/// A tabbed sheet: "All" plus one tab per emoji, each listing users.
class ReactionDetailsSheet extends StatelessWidget {
  /// Creates a details sheet.
  const ReactionDetailsSheet({super.key, required this.reactions});

  /// Reactions to show.
  final List<ReactionSummary> reactions;

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
              for (final r in reactions) Tab(text: '${r.emoji} ${r.count}'),
            ],
          ),
          SizedBox(
            height: height,
            child: TabBarView(
              children: [
                ReactionDetailsList(reactions: reactions),
                for (final r in reactions) ReactionDetailsList(reactions: [r]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows [ReactionDetailsSheet] in a modal bottom sheet.
Future<void> showReactionDetails(
  BuildContext context,
  List<ReactionSummary> reactions,
) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => SafeArea(child: ReactionDetailsSheet(reactions: reactions)),
);
