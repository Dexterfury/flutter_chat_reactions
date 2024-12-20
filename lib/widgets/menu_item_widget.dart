import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/model/menu_item.dart';

/// Single menu item widget with animation
class MenuItemWidget extends StatelessWidget {
  /// Creates a menu item widget.
  const MenuItemWidget({
    super.key,
    required this.item,
    required this.index,
    required this.isClicked,
    required this.onTap,
  });

  final MenuItem item;
  final int index;
  final bool isClicked;
  final Function(MenuItem, int) onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = item.isDestuctive
        ? Colors.red
        : Theme.of(context).textTheme.bodyMedium!.color;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
      child: InkWell(
        onTap: () => onTap(item, index),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              item.label,
              style: TextStyle(color: textColor),
            ),
            Pulse(
              infinite: false,
              duration: const Duration(milliseconds: 500),
              animate: isClicked,
              child: Icon(
                item.icon,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
