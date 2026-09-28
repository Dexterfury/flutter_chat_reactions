import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/reaction.dart';
import '../models/reaction_policy.dart';
import '../models/reaction_summary.dart';
import 'reaction_change.dart';

/// Reactions and a selection callback for one message, ready to pass to
/// `ReactableMessage`. Produced by [ReactionsController.bind].
class ReactionBinding {
  /// Creates a binding.
  const ReactionBinding({
    required this.reactions,
    required this.onReactionSelected,
  });

  /// Current summaries for the message.
  final List<ReactionSummary> reactions;

  /// Toggles the tapped emoji for the current user.
  final ValueChanged<String> onReactionSelected;
}

/// An optional in-memory store of reactions, for apps without their own state
/// layer.
///
/// Changes are applied optimistically: listeners are notified immediately,
/// then [onChange] is awaited. If it throws, the message's previous state is
/// restored (unless a newer change has happened since) and the error is
/// rethrown.
class ReactionsController extends ChangeNotifier {
  /// Creates a controller for [currentUserId].
  ReactionsController({
    required this.currentUserId,
    this.currentUserName,
    this.policy = const ReactionPolicy.single(),
    this.onChange,
    this.sort = ReactionSort.countDesc,
  });

  /// The user whose reactions [add], [remove] and [toggle] modify.
  final String currentUserId;

  /// Display name stored on the current user's reactions.
  final String? currentUserName;

  /// How many reactions the current user may leave per message.
  final ReactionPolicy policy;

  /// Called after each local change; throw to roll the change back.
  final Future<void> Function(ReactionChange change)? onChange;

  /// Ordering used by [summariesFor].
  final ReactionSort sort;

  final Map<String, List<Reaction>> _reactions = {};
  bool _disposed = false;

  /// Raw reactions for [messageId] (unmodifiable).
  List<Reaction> reactionsFor(String messageId) =>
      List.unmodifiable(_reactions[messageId] ?? const <Reaction>[]);

  /// Aggregated reactions for [messageId] (unmodifiable).
  List<ReactionSummary> summariesFor(String messageId) =>
      (_reactions[messageId] ?? const <Reaction>[]).summarize(
        currentUserId: currentUserId,
        sort: sort,
      );

  /// Whether the current user reacted to [messageId] with [emoji].
  bool hasReacted(String messageId, String emoji) =>
      _mine(messageId).contains(emoji);

  /// Replaces all reactions for [messageId], e.g. with data from a server.
  /// The iterable is copied.
  void setReactions(String messageId, Iterable<Reaction> reactions) {
    _reactions[messageId] = List.of(reactions);
    _notify();
  }

  /// Removes [emoji] if the current user reacted with it, otherwise adds it
  /// (subject to [policy]).
  Future<void> toggle(String messageId, String emoji) =>
      hasReacted(messageId, emoji)
      ? remove(messageId, emoji)
      : add(messageId, emoji);

  /// Adds [emoji] for the current user, subject to [policy].
  Future<void> add(String messageId, String emoji) async {
    final current = _reactions[messageId] ?? const <Reaction>[];
    final mine = _mine(messageId);
    if (mine.contains(emoji)) return;

    final reaction = Reaction(
      emoji: emoji,
      userId: currentUserId,
      userName: currentUserName,
      createdAt: DateTime.now(),
    );

    final List<Reaction> next;
    final ReactionChange change;
    switch (policy) {
      case SingleReactionPolicy():
        next = [...current.where((r) => r.userId != currentUserId), reaction];
        change = mine.isEmpty
            ? ReactionAdded(messageId: messageId, emoji: emoji)
            : ReactionReplaced(
                messageId: messageId,
                emoji: emoji,
                previousEmoji: mine.first,
              );
      case MultipleReactionPolicy(:final max):
        if (max != null && mine.length >= max) return;
        next = [...current, reaction];
        change = ReactionAdded(messageId: messageId, emoji: emoji);
    }
    await _apply(messageId, next, change);
  }

  /// Removes the current user's [emoji] reaction, if present.
  Future<void> remove(String messageId, String emoji) async {
    if (!hasReacted(messageId, emoji)) return;
    final next = [
      for (final r in _reactions[messageId]!)
        if (!(r.userId == currentUserId && r.emoji == emoji)) r,
    ];
    await _apply(
      messageId,
      next,
      ReactionRemoved(messageId: messageId, emoji: emoji),
    );
  }

  /// Clears reactions for [messageId], or for every message when omitted.
  void clear([String? messageId]) {
    if (messageId == null) {
      _reactions.clear();
    } else {
      _reactions.remove(messageId);
    }
    _notify();
  }

  /// Returns the current summaries and a toggling callback for [messageId].
  ///
  /// Errors from [onChange] are swallowed here (the change is already rolled
  /// back); observe them in [onChange] itself.
  ReactionBinding bind(String messageId) => ReactionBinding(
    reactions: summariesFor(messageId),
    onReactionSelected: (emoji) =>
        unawaited(toggle(messageId, emoji).catchError((Object _) {})),
  );

  List<String> _mine(String messageId) => [
    for (final r in _reactions[messageId] ?? const <Reaction>[])
      if (r.userId == currentUserId) r.emoji,
  ];

  Future<void> _apply(
    String messageId,
    List<Reaction> next,
    ReactionChange change,
  ) async {
    final hadEntry = _reactions.containsKey(messageId);
    final previous = _reactions[messageId];
    _reactions[messageId] = next;
    _notify();

    final callback = onChange;
    if (callback == null) return;
    try {
      await callback(change);
    } catch (_) {
      if (identical(_reactions[messageId], next)) {
        if (hadEntry) {
          _reactions[messageId] = previous!;
        } else {
          _reactions.remove(messageId);
        }
        _notify();
      }
      rethrow;
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
