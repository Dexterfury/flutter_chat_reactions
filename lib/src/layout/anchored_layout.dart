import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'reaction_alignment.dart';

enum _Slot { header, anchor, footer }

/// Lays out a [header] and [footer] around a rectangle (usually a message),
/// keeping everything inside the safe area.
///
/// With an [anchor], the group header→anchor→footer is placed at
/// [anchorRect] and translated vertically to fit; a too-tall anchor scrolls.
/// Without one, the header sits above [anchorRect] (or flips below) and the
/// footer below it.
///
/// [anchorRect] must be in this widget's coordinate space; the widget is
/// meant to fill an overlay.
class AnchoredLayout extends StatelessWidget {
  /// Creates an anchored layout.
  const AnchoredLayout({
    super.key,
    required this.anchorRect,
    this.header,
    this.anchor,
    this.footer,
    this.alignment = ReactionAlignment.end,
    this.spacing = 8,
    this.margin = 12,
  });

  /// The rectangle to anchor to.
  final Rect anchorRect;

  /// Widget placed above the anchor (e.g. the reaction bar).
  final Widget? header;

  /// Widget drawn at [anchorRect] (e.g. a copy of the message).
  final Widget? anchor;

  /// Widget placed below the anchor (e.g. the action menu).
  final Widget? footer;

  /// Horizontal alignment of [header] and [footer] relative to the anchor.
  final ReactionAlignment alignment;

  /// Vertical gap between the parts.
  final double spacing;

  /// Minimum distance from the safe-area edges.
  final double margin;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final insets = MediaQuery.viewInsetsOf(context);
    final safe = EdgeInsets.fromLTRB(
      padding.left + margin,
      padding.top + margin,
      padding.right + margin,
      math.max(padding.bottom, insets.bottom) + margin,
    );
    return CustomMultiChildLayout(
      delegate: _AnchoredLayoutDelegate(
        anchorRect: anchorRect,
        safe: safe,
        alignment: alignment,
        textDirection: Directionality.of(context),
        spacing: spacing,
      ),
      children: [
        if (header != null) LayoutId(id: _Slot.header, child: header!),
        if (anchor != null)
          LayoutId(
            id: _Slot.anchor,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: anchor,
            ),
          ),
        if (footer != null) LayoutId(id: _Slot.footer, child: footer!),
      ],
    );
  }
}

class _AnchoredLayoutDelegate extends MultiChildLayoutDelegate {
  _AnchoredLayoutDelegate({
    required this.anchorRect,
    required this.safe,
    required this.alignment,
    required this.textDirection,
    required this.spacing,
  });

  final Rect anchorRect;
  final EdgeInsets safe;
  final ReactionAlignment alignment;
  final TextDirection textDirection;
  final double spacing;

  @override
  void performLayout(Size size) {
    final area = safe.deflateRect(Offset.zero & size);
    final loose = BoxConstraints.loose(area.size);

    final hasHeader = hasChild(_Slot.header);
    final hasFooter = hasChild(_Slot.footer);
    final headerSize = hasHeader ? layoutChild(_Slot.header, loose) : Size.zero;
    final footerSize = hasFooter ? layoutChild(_Slot.footer, loose) : Size.zero;
    final headerGap = hasHeader ? spacing : 0.0;
    final footerGap = hasFooter ? spacing : 0.0;

    if (hasChild(_Slot.anchor)) {
      final maxAnchorHeight = math.max(
        0.0,
        area.height -
            headerSize.height -
            footerSize.height -
            headerGap -
            footerGap,
      );
      final width = math.min(anchorRect.width, area.width);
      final anchorSize = layoutChild(
        _Slot.anchor,
        BoxConstraints(
          minWidth: width,
          maxWidth: width,
          maxHeight: maxAnchorHeight,
        ),
      );
      final total =
          headerSize.height +
          headerGap +
          anchorSize.height +
          footerGap +
          footerSize.height;

      var y = (anchorRect.top - headerGap - headerSize.height)
          .clamp(area.top, math.max(area.top, area.bottom - total))
          .toDouble();
      if (hasHeader) {
        positionChild(_Slot.header, Offset(_x(headerSize.width, area), y));
        y += headerSize.height + headerGap;
      }
      final anchorX = anchorRect.left
          .clamp(area.left, math.max(area.left, area.right - anchorSize.width))
          .toDouble();
      positionChild(_Slot.anchor, Offset(anchorX, y));
      y += anchorSize.height + footerGap;
      if (hasFooter) {
        positionChild(_Slot.footer, Offset(_x(footerSize.width, area), y));
      }
      return;
    }

    if (hasHeader) {
      var y = anchorRect.top - spacing - headerSize.height;
      if (y < area.top) y = anchorRect.bottom + spacing;
      y = y
          .clamp(area.top, math.max(area.top, area.bottom - headerSize.height))
          .toDouble();
      positionChild(_Slot.header, Offset(_x(headerSize.width, area), y));
    }
    if (hasFooter) {
      final y = (anchorRect.bottom + spacing)
          .clamp(area.top, math.max(area.top, area.bottom - footerSize.height))
          .toDouble();
      positionChild(_Slot.footer, Offset(_x(footerSize.width, area), y));
    }
  }

  double _x(double width, Rect area) {
    final alignRight =
        (alignment == ReactionAlignment.end) ==
        (textDirection == TextDirection.ltr);
    final x = alignRight ? anchorRect.right - width : anchorRect.left;
    return x
        .clamp(area.left, math.max(area.left, area.right - width))
        .toDouble();
  }

  @override
  bool shouldRelayout(_AnchoredLayoutDelegate old) =>
      old.anchorRect != anchorRect ||
      old.safe != safe ||
      old.alignment != alignment ||
      old.textDirection != textDirection ||
      old.spacing != spacing;
}
