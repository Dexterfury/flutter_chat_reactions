import 'equality.dart';
import 'reaction_user.dart';

/// One aggregated reaction on a message: an emoji, how many users chose it,
/// and whether the current user is one of them.
///
/// This is the primary display input. Servers usually send aggregates, so
/// build these directly, or derive them from raw [Reaction]s with
/// `summarize`.
class ReactionSummary {
  /// Creates a reaction summary. [count] must be at least 1.
  const ReactionSummary({
    required this.emoji,
    required this.count,
    this.reactedByMe = false,
    this.users = const [],
  }) : assert(count >= 1, 'count must be at least 1');

  /// Creates a [ReactionSummary] from JSON produced by [toJson].
  factory ReactionSummary.fromJson(Map<String, Object?> json) =>
      ReactionSummary(
        emoji: json['emoji']! as String,
        count: (json['count']! as num).toInt(),
        reactedByMe: json['reactedByMe'] as bool? ?? false,
        users: [
          for (final user in json['users'] as List<Object?>? ?? const [])
            ReactionUser.fromJson(user! as Map<String, Object?>),
        ],
      );

  /// The emoji. Any string: a unicode emoji or an app-specific id such as
  /// `:party:` rendered through an `EmojiBuilder`.
  final String emoji;

  /// Number of users who reacted with [emoji].
  final int count;

  /// Whether the current user reacted with [emoji].
  final bool reactedByMe;

  /// Users who reacted. May be empty or partial (fewer than [count]).
  final List<ReactionUser> users;

  /// Returns a copy with the given fields replaced.
  ReactionSummary copyWith({
    String? emoji,
    int? count,
    bool? reactedByMe,
    List<ReactionUser>? users,
  }) => ReactionSummary(
    emoji: emoji ?? this.emoji,
    count: count ?? this.count,
    reactedByMe: reactedByMe ?? this.reactedByMe,
    users: users ?? this.users,
  );

  /// Converts to JSON. `users` is omitted when empty.
  Map<String, Object?> toJson() => {
    'emoji': emoji,
    'count': count,
    'reactedByMe': reactedByMe,
    if (users.isNotEmpty) 'users': [for (final u in users) u.toJson()],
  };

  @override
  bool operator ==(Object other) =>
      other is ReactionSummary &&
      other.emoji == emoji &&
      other.count == count &&
      other.reactedByMe == reactedByMe &&
      equalLists(other.users, users);

  @override
  int get hashCode =>
      Object.hash(emoji, count, reactedByMe, Object.hashAll(users));

  @override
  String toString() => 'ReactionSummary($emoji × $count, mine: $reactedByMe)';
}
