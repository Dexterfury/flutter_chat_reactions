import 'package:flutter_chat_reactions/src/utilities/reactions_constants.dart';

class Reaction {
  final String emoji;
  final String userId;
  final DateTime timestamp;
  final String? userName;

  const Reaction({
    required this.emoji,
    required this.userId,
    required this.timestamp,
    this.userName,
  });

  Map<String, dynamic> toJson() => {
        ReactionsConstants.emoji: emoji,
        ReactionsConstants.userId: userId,
        ReactionsConstants.timestamp: timestamp.toIso8601String(),
        ReactionsConstants.userName: userName,
      };

  factory Reaction.fromJson(Map<String, dynamic> json) => Reaction(
        emoji: json[ReactionsConstants.emoji],
        userId: json[ReactionsConstants.userId],
        timestamp: DateTime.parse(json[ReactionsConstants.timestamp]),
        userName: json[ReactionsConstants.userName],
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Reaction &&
          runtimeType == other.runtimeType &&
          emoji == other.emoji &&
          userId == other.userId;

  @override
  int get hashCode => emoji.hashCode ^ userId.hashCode;
}
