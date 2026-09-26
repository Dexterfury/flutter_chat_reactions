/// A user who reacted to a message.
class ReactionUser {
  /// Creates a reaction user.
  const ReactionUser({required this.id, this.name, this.avatarUrl});

  /// Creates a [ReactionUser] from JSON produced by [toJson].
  factory ReactionUser.fromJson(Map<String, Object?> json) => ReactionUser(
    id: json['id']! as String,
    name: json['name'] as String?,
    avatarUrl: json['avatarUrl'] as String?,
  );

  /// Stable user identifier.
  final String id;

  /// Display name, if known.
  final String? name;

  /// Avatar image URL, if known.
  final String? avatarUrl;

  /// Returns a copy with the given fields replaced.
  ReactionUser copyWith({String? id, String? name, String? avatarUrl}) =>
      ReactionUser(
        id: id ?? this.id,
        name: name ?? this.name,
        avatarUrl: avatarUrl ?? this.avatarUrl,
      );

  /// Converts to JSON. Null fields are omitted.
  Map<String, Object?> toJson() => {
    'id': id,
    if (name != null) 'name': name,
    if (avatarUrl != null) 'avatarUrl': avatarUrl,
  };

  @override
  bool operator ==(Object other) =>
      other is ReactionUser &&
      other.id == id &&
      other.name == name &&
      other.avatarUrl == avatarUrl;

  @override
  int get hashCode => Object.hash(id, name, avatarUrl);

  @override
  String toString() => 'ReactionUser($id, $name)';
}
