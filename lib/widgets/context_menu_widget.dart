import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/model/menu_item.dart';
import 'package:flutter_chat_reactions/widgets/menu_item_widget.dart';

/// Widget that displays the context menu options
class ContextMenuWidget extends StatelessWidget {
  /// Creates a context menu widget.
  const ContextMenuWidget({
    super.key,
    required this.menuItems,
    required this.alignment,
    required this.menuWidth,
    required this.clickedIndex,
    required this.onMenuItemTap,
  });

  final List<MenuItem> menuItems;
  final Alignment alignment;
  final double menuWidth;
  final int? clickedIndex;
  final Function(MenuItem, int) onMenuItemTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * menuWidth,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade500,
                spreadRadius: 1,
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < menuItems.length; i++) ...[
                MenuItemWidget(
                  item: menuItems[i],
                  index: i,
                  isClicked: clickedIndex == i,
                  onTap: onMenuItemTap,
                ),
                if (i != menuItems.length - 1)
                  Divider(
                    color: Colors.grey.shade300,
                    thickness: 1,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
