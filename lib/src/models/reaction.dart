import 'equality.dart';
import 'reaction_summary.dart';
import 'reaction_user.dart';

/// A single user's reaction to a message, for apps that store reactions
/// individually. Convert a list of these to display data with `summarize`.
class Reaction {
  /// Creates a reaction.
  const Reaction({
    required this.emoji,
    required this.userId,
    this.userName,
    this.createdAt,
    this.extra = const {},
  });

  /// Creates a [Reaction] from JSON produced by [toJson].
  ///
  /// Also accepts the 0.2.x `timestamp` key in place of `createdAt`.
  factory Reaction.fromJson(Map<String, Object?> json) {
    final created = json['createdAt'] ?? json['timestamp'];
    return Reaction(
      emoji: json['emoji']! as String,
      userId: json['userId']! as String,
      userName: json['userName'] as String?,
      createdAt: created == null ? null : DateTime.parse(created as String),
      extra: json['extra'] as Map<String, Object?>? ?? const {},
    );
  }

  /// The emoji (see [ReactionSummary.emoji]).
  final String emoji;

  /// Id of the user who reacted.
  final String userId;

  /// Display name of the user who reacted, if known.
  final String? userName;

  /// When the reaction was made, if known.
  final DateTime? createdAt;

  /// App-specific payload carried alongside the reaction.
  final Map<String, Object?> extra;

  /// Returns a copy with the given fields replaced.
  Reaction copyWith({
    String? emoji,
    String? userId,
    String? userName,
    DateTime? createdAt,
    Map<String, Object?>? extra,
  }) => Reaction(
    emoji: emoji ?? this.emoji,
    userId: userId ?? this.userId,
    userName: userName ?? this.userName,
    createdAt: createdAt ?? this.createdAt,
    extra: extra ?? this.extra,
  );

  /// Converts to JSON. Null and empty fields are omitted.
  Map<String, Object?> toJson() => {
    'emoji': emoji,
    'userId': userId,
    if (userName != null) 'userName': userName,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (extra.isNotEmpty) 'extra': extra,
  };

  @override
  bool operator ==(Object other) =>
      other is Reaction &&
      other.emoji == emoji &&
      other.userId == userId &&
      other.userName == userName &&
      other.createdAt == createdAt &&
      equalMaps(other.extra, extra);

  @override
  int get hashCode =>
      Object.hash(emoji, userId, userName, createdAt, hashMap(extra));

  @override
  String toString() => 'Reaction($emoji by $userId)';
}

/// Ordering for [ReactionListX.summarize].
enum ReactionSort {
  /// Most reactions first; ties keep first-appearance order.
  countDesc,

  /// Earliest `createdAt` first; reactions without a date go last.
  firstReacted,

  /// First-appearance order.
  none,
}

/// Aggregation helpers for raw reactions.
extension ReactionListX on Iterable<Reaction> {
  /// Aggregates raw reactions into one [ReactionSummary] per emoji.
  ///
  /// Duplicate reactions (same user, same emoji) count once. The returned
  /// list is unmodifiable.
  List<ReactionSummary> summarize({
    required String currentUserId,
    ReactionSort sort = ReactionSort.countDesc,
  }) {
    final order = <String>[];
    final users = <String, List<ReactionUser>>{};
    final firstAt = <String, DateTime>{};
    final mine = <String>{};

    for (final reaction in this) {
      final list = users.putIfAbsent(reaction.emoji, () {
        order.add(reaction.emoji);
        return <ReactionUser>[];
      });
      if (list.any((u) => u.id == reaction.userId)) continue;
      list.add(ReactionUser(id: reaction.userId, name: reaction.userName));
      if (reaction.userId == currentUserId) mine.add(reaction.emoji);
      final at = reaction.createdAt;
      if (at != null) {
        final previous = firstAt[reaction.emoji];
        if (previous == null || at.isBefore(previous)) {
          firstAt[reaction.emoji] = at;
        }
      }
    }

    final indexed = <(int, ReactionSummary)>[
      for (var i = 0; i < order.length; i++)
        (
          i,
          ReactionSummary(
            emoji: order[i],
            count: users[order[i]]!.length,
            reactedByMe: mine.contains(order[i]),
            users: List.unmodifiable(users[order[i]]!),
          ),
        ),
    ];

    int byIndex((int, ReactionSummary) a, (int, ReactionSummary) b) =>
        a.$1.compareTo(b.$1);

    switch (sort) {
      case ReactionSort.countDesc:
        indexed.sort((a, b) {
          final byCount = b.$2.count.compareTo(a.$2.count);
          return byCount != 0 ? byCount : byIndex(a, b);
        });
      case ReactionSort.firstReacted:
        indexed.sort((a, b) {
          final ta = firstAt[a.$2.emoji];
          final tb = firstAt[b.$2.emoji];
          if (ta != null && tb != null) {
            final byTime = ta.compareTo(tb);
            if (byTime != 0) return byTime;
          } else if (ta != null) {
            return -1;
          } else if (tb != null) {
            return 1;
          }
          return byIndex(a, b);
        });
      case ReactionSort.none:
        break;
    }

    return List.unmodifiable([for (final entry in indexed) entry.$2]);
  }
}
