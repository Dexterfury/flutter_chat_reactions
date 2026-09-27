import 'package:flutter/widgets.dart';

/// An item in a message's context menu (Reply, Copy, Delete, ...).
///
/// Actions are identified by [id]; two actions with the same id are equal
/// regardless of label, so localized labels never break matching.
@immutable
class ReactionAction<T> {
  /// Creates a context-menu action.
  const ReactionAction({
    required this.id,
    required this.label,
    this.icon,
    this.isDestructive = false,
    this.value,
  });

  /// Stable identifier used for matching in `onActionSelected`.
  final String id;

  /// Text shown in the menu.
  final String label;

  /// Optional icon shown next to [label].
  final IconData? icon;

  /// Whether the action is destructive (rendered in the theme's destructive color).
  final bool isDestructive;

  /// Optional app-specific payload.
  final T? value;

  /// Returns a copy with the given fields replaced.
  ReactionAction<T> copyWith({
    String? id,
    String? label,
    IconData? icon,
    bool? isDestructive,
    T? value,
  }) => ReactionAction<T>(
    id: id ?? this.id,
    label: label ?? this.label,
    icon: icon ?? this.icon,
    isDestructive: isDestructive ?? this.isDestructive,
    value: value ?? this.value,
  );

  @override
  bool operator ==(Object other) => other is ReactionAction && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ReactionAction($id)';
}
