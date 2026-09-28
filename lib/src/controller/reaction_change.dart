/// A change the current user made, reported to `ReactionsController.onChange`
/// so the app can sync it to a backend.
sealed class ReactionChange {
  const ReactionChange({required this.messageId, required this.emoji});

  /// The message that changed.
  final String messageId;

  /// The emoji added, removed, or chosen as a replacement.
  final String emoji;

  @override
  bool operator ==(Object other) =>
      other.runtimeType == runtimeType &&
      other is ReactionChange &&
      other.messageId == messageId &&
      other.emoji == emoji;

  @override
  int get hashCode => Object.hash(runtimeType, messageId, emoji);
}

/// The current user added [emoji].
final class ReactionAdded extends ReactionChange {
  /// Creates an added change.
  const ReactionAdded({required super.messageId, required super.emoji});

  @override
  String toString() => 'ReactionAdded($messageId, $emoji)';
}

/// The current user removed [emoji].
final class ReactionRemoved extends ReactionChange {
  /// Creates a removed change.
  const ReactionRemoved({required super.messageId, required super.emoji});

  @override
  String toString() => 'ReactionRemoved($messageId, $emoji)';
}

/// The current user replaced [previousEmoji] with [emoji] (single policy).
final class ReactionReplaced extends ReactionChange {
  /// Creates a replaced change.
  const ReactionReplaced({
    required super.messageId,
    required super.emoji,
    required this.previousEmoji,
  });

  /// The emoji that was replaced.
  final String previousEmoji;

  @override
  bool operator ==(Object other) =>
      super == other &&
      other is ReactionReplaced &&
      other.previousEmoji == previousEmoji;

  @override
  int get hashCode => Object.hash(super.hashCode, previousEmoji);

  @override
  String toString() => 'ReactionReplaced($messageId, $previousEmoji → $emoji)';
}
