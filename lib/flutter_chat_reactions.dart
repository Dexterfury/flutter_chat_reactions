library flutter_chat_reactions;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/model/menu_item.dart';
import 'package:flutter_chat_reactions/utilities/default_data.dart';
import 'package:flutter_chat_reactions/widgets/context_menu_widget.dart';
import 'package:flutter_chat_reactions/widgets/message_bubble.dart';
import 'package:flutter_chat_reactions/widgets/rections_row.dart';

/// A dialog widget that displays reactions and context menu options for a message.
///
/// This widget creates a modal dialog with three main sections:
/// - A row of reaction emojis that can be tapped
/// - The original message (displayed using a Hero animation)
/// - A context menu with customizable options
///
/// Example usage:
/// ```dart
/// ReactionsDialogWidget(
///   id: 'message_123',
///   messageWidget: Text('Hello World'),
///   onReactionTap: (reaction) => print('Selected reaction: $reaction'),
///   onContextMenuTap: (menuItem) => print('Selected menu item: ${menuItem.label}'),
/// )
/// ```
class ReactionsDialogWidget extends StatefulWidget {
  /// Creates a reactions dialog widget.
  ///
  /// The [id], [messageWidget], [onReactionTap], and [onContextMenuTap] must not be null.
  const ReactionsDialogWidget({
    super.key,
    required this.id,
    required this.messageWidget,
    required this.onReactionTap,
    required this.onContextMenuTap,
    this.menuItems = DefaultData.menuItems,
    this.reactions = DefaultData.reactions,
    this.widgetAlignment = Alignment.centerRight,
    this.menuItemsWidth = 0.45,
  });

  /// Unique identifier for the hero animation.
  final String id;

  /// The widget displaying the message content.
  final Widget messageWidget;

  /// Callback triggered when a reaction is selected.
  ///
  /// The selected reaction string is passed as an argument.
  final Function(String) onReactionTap;

  /// Callback triggered when a context menu item is selected.
  ///
  /// The selected [MenuItem] is passed as an argument.
  final Function(MenuItem) onContextMenuTap;

  /// List of menu items to display in the context menu.
  ///
  /// Defaults to [DefaultData.menuItems].
  final List<MenuItem> menuItems;

  /// List of reaction emojis/strings to display.
  ///
  /// Defaults to [DefaultData.reactions].
  final List<String> reactions;

  /// Alignment of the dialog components.
  ///
  /// Defaults to [Alignment.centerRight].
  final Alignment widgetAlignment;

  /// Width of the context menu as a fraction of screen width.
  ///
  /// Defaults to 0.45 (45% of screen width).
  final double menuItemsWidth;

  @override
  State<ReactionsDialogWidget> createState() => _ReactionsDialogWidgetState();
}

class _ReactionsDialogWidgetState extends State<ReactionsDialogWidget> {
  /// Tracks whether a reaction has been selected
  bool _reactionClicked = false;

  /// Index of the currently selected reaction
  int? _clickedReactionIndex;

  /// Index of the currently selected context menu item
  int? _clickedContextMenuIndex;

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ReactionsRow(
                reactions: widget.reactions,
                alignment: widget.widgetAlignment,
                onReactionTap: _handleReactionTap,
                clickedIndex: _clickedReactionIndex,
                reactionClicked: _reactionClicked,
              ),
              const SizedBox(height: 10),
              MessageBubble(
                id: widget.id,
                messageWidget: widget.messageWidget,
                alignment: widget.widgetAlignment,
              ),
              const SizedBox(height: 10),
              ContextMenuWidget(
                menuItems: widget.menuItems,
                alignment: widget.widgetAlignment,
                menuWidth: widget.menuItemsWidth,
                clickedIndex: _clickedContextMenuIndex,
                onMenuItemTap: _handleContextMenuTap,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Handles the reaction tap event and triggers the animation
  void _handleReactionTap(String reaction, int index) {
    setState(() {
      _reactionClicked = true;
      _clickedReactionIndex = index;
    });

    // Delay to allow animation completion
    Future.delayed(const Duration(milliseconds: 500)).whenComplete(() {
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onReactionTap(reaction);
    });
  }

  /// Handles the context menu item tap event and triggers the animation
  void _handleContextMenuTap(MenuItem item, int index) {
    setState(() {
      _clickedContextMenuIndex = index;
    });

    // Delay to allow animation completion
    Future.delayed(const Duration(milliseconds: 500)).whenComplete(() {
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onContextMenuTap(item);
    });
  }
}
