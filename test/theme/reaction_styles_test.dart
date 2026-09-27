import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('merge: non-null fields of the argument win', () {
    const base = ReactionMenuStyle(
      minWidth: 200,
      maxWidth: 280,
      iconColor: Colors.red,
    );
    final merged = base.merge(const ReactionMenuStyle(maxWidth: 300));
    expect(merged.minWidth, 200);
    expect(merged.maxWidth, 300);
    expect(merged.iconColor, Colors.red);
    expect(base.merge(null), same(base));
  });

  test('chip lerp handles null borders', () {
    const a = ReactionChipStyle(border: BorderSide(width: 2));
    const b = ReactionChipStyle();
    expect(ReactionChipStyle.lerp(a, b, 0.2)!.border, a.border);
    expect(ReactionChipStyle.lerp(a, b, 0.8)!.border, isNull);
  });

  test('overlay lerp', () {
    const a = ReactionOverlayStyle(blurSigma: 0, lift: 1);
    const b = ReactionOverlayStyle(blurSigma: 10, lift: 2);
    final mid = ReactionOverlayStyle.lerp(a, b, 0.5)!;
    expect(mid.blurSigma, 5);
    expect(mid.lift, 1.5);
  });

  test('bar equality and hashCode', () {
    expect(
      const ReactionBarStyle(emojiSize: 1),
      const ReactionBarStyle(emojiSize: 1),
    );
    expect(
      const ReactionBarStyle(emojiSize: 1) ==
          const ReactionBarStyle(emojiSize: 2),
      isFalse,
    );
    expect(
      const ReactionBarStyle(emojiSize: 1).hashCode,
      const ReactionBarStyle(emojiSize: 1).hashCode,
    );
  });

  test('bar lerp interpolates fields', () {
    const a = ReactionBarStyle(emojiSize: 10, itemSpacing: 2);
    const b = ReactionBarStyle(emojiSize: 20, itemSpacing: 4);
    final mid = ReactionBarStyle.lerp(a, b, 0.5)!;
    expect(mid.emojiSize, 15);
    expect(mid.itemSpacing, 3);
    expect(ReactionBarStyle.lerp(a, a, 0.5), same(a));
  });

  test('menu equality, hashCode and lerp', () {
    const a = ReactionMenuStyle(minWidth: 200, iconColor: Colors.red);
    const b = ReactionMenuStyle(minWidth: 200, iconColor: Colors.red);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a == const ReactionMenuStyle(minWidth: 100), isFalse);

    const c = ReactionMenuStyle(minWidth: 100, maxWidth: 200);
    const d = ReactionMenuStyle(minWidth: 300, maxWidth: 400);
    final mid = ReactionMenuStyle.lerp(c, d, 0.5)!;
    expect(mid.minWidth, 200);
    expect(mid.maxWidth, 300);
    expect(ReactionMenuStyle.lerp(c, c, 0.5), same(c));
  });

  test('chip equality and hashCode', () {
    const a = ReactionChipStyle(emojiSize: 16);
    const b = ReactionChipStyle(emojiSize: 16);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a == const ReactionChipStyle(emojiSize: 20), isFalse);
  });

  test('overlay equality and hashCode', () {
    const a = ReactionOverlayStyle(blurSigma: 4, lift: 1.1);
    const b = ReactionOverlayStyle(blurSigma: 4, lift: 1.1);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a == const ReactionOverlayStyle(blurSigma: 5), isFalse);
  });
}
