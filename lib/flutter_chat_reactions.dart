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

  Align buildMenuItems(BuildContext context) {
    return Align(
      alignment: widget.widgetAlignment,
      child: // contextMenu for reply, copy, delete
          Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * widget.menuItemsWidth,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade500,
                spreadRadius: 1,
                blurRadius: 2,
                offset: const Offset(0, 1), // changes position of shadow
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var item in widget.menuItems)
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
                      child: InkWell(
                        onTap: () {
                          // set the clicked index for animation
                          setState(() {
                            clickedContextMenuIndex =
                                widget.menuItems.indexOf(item);
                          });

                          // delay for 200 milliseconds to allow the animation to complete
                          Future.delayed(const Duration(milliseconds: 500))
                              .whenComplete(() {
                            // pop the dialog
                            Navigator.of(context).pop();
                            widget.onContextMenuTap(item);
                          });
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item.label,
                              style: TextStyle(
                                color: item.isDestuctive
                                    ? Colors.red
                                    : Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .color,
                              ),
                            ),
                            Pulse(
                              infinite: false,
                              duration: const Duration(milliseconds: 500),
                              animate: clickedContextMenuIndex ==
                                  widget.menuItems.indexOf(item),
                              child: Icon(
                                item.icon,
                                color: item.isDestuctive
                                    ? Colors.red
                                    : Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .color,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    if (widget.menuItems.last != item)
                      Divider(
                        color: Colors.grey.shade300,
                        thickness: 1,
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Align buildMessage() {
    return Align(
      alignment: widget.widgetAlignment,
      child: Hero(
        tag: widget.id,
        child: widget.messageWidget,
      ),
    );
  }

  Align buildReactions(BuildContext context) {
    return Align(
      alignment: widget.widgetAlignment,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade500,
                spreadRadius: 1,
                blurRadius: 2,
                offset: const Offset(0, 1), // changes position of shadow
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var reaction in widget.reactions)
                FadeInLeft(
                  from: // first index should be from 0, second from 20, third from 40 and so on
                      0 + (widget.reactions.indexOf(reaction) * 20).toDouble(),
                  duration: const Duration(milliseconds: 500),
                  delay: const Duration(milliseconds: 200),
                  child: InkWell(
                      onTap: () {
                        setState(() {
                          reactionClicked = true;
                          clickedReactionIndex =
                              widget.reactions.indexOf(reaction);
                        });
                        // delay for 200 milliseconds to allow the animation to complete
                        Future.delayed(const Duration(milliseconds: 500))
                            .whenComplete(() {
                          // pop the dialog
                          Navigator.of(context).pop();
                          widget.onReactionTap(reaction);
                        });
                      },
                      child: Pulse(
                        infinite: false,
                        duration: const Duration(milliseconds: 500),
                        animate: reactionClicked &&
                            clickedReactionIndex ==
                                widget.reactions.indexOf(reaction),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(4.0, 2.0, 4.0, 2),
                          child: Text(
                            reaction,
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      )),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
