/// How many reactions one user may leave on a message. Used by
/// `ReactionsController`; the widgets only report what was tapped.
sealed class ReactionPolicy {
  const ReactionPolicy();

  /// One reaction per user; choosing another emoji replaces the previous one,
  /// choosing the same emoji removes it (WhatsApp, iMessage).
  const factory ReactionPolicy.single() = SingleReactionPolicy;

  /// Any number of distinct reactions per user, optionally capped by [max]
  /// (Slack, Discord).
  const factory ReactionPolicy.multiple({int? max}) = MultipleReactionPolicy;
}

/// See [ReactionPolicy.single].
final class SingleReactionPolicy extends ReactionPolicy {
  /// Creates the single-reaction policy.
  const SingleReactionPolicy();

  @override
  bool operator ==(Object other) => other is SingleReactionPolicy;

  @override
  int get hashCode => (SingleReactionPolicy).hashCode;
}

/// See [ReactionPolicy.multiple].
final class MultipleReactionPolicy extends ReactionPolicy {
  /// Creates the multiple-reaction policy. [max], when given, must be > 0.
  const MultipleReactionPolicy({this.max})
    : assert(max == null || max > 0, 'max must be positive');

  /// Maximum distinct reactions per user, or null for unlimited.
  final int? max;

  @override
  bool operator ==(Object other) =>
      other is MultipleReactionPolicy && other.max == max;

  @override
  int get hashCode => Object.hash(MultipleReactionPolicy, max);
}
