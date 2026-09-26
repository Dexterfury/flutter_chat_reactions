/// Which side of a message the reactions UI aligns to, relative to the
/// ambient text direction. Use [end] for the current user's messages and
/// [start] for others' in a typical chat.
enum ReactionAlignment {
  /// Leading edge (left in LTR, right in RTL).
  start,

  /// Trailing edge (right in LTR, left in RTL).
  end,
}
