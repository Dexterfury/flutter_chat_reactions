import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/src/models/menu_item.dart';

class ChatReactionsConfig {
  final List<String> availableReactions;
  final List<MenuItem> menuItems;
  final Duration animationDuration;
  final Duration dialogTransitionDuration;
  final bool showAddReactionButton;
  final bool enableHapticFeedback;
  final bool enableLongPress;
  final bool enableDoubleTap;
  final int maxReactionsToShow;
  final double reactionSize;
  final double stackedValue;
  final EdgeInsets dialogPadding;
  final BorderRadius? dialogBorderRadius;
  final Color? dialogBackgroundColor;
  final double dialogBlurSigma;
  final bool dismissOnTapOutside;
  final bool showContextMenu;
  final Widget Function(BuildContext, Function(String) onEmojiSelected)?
      emojiPickerBuilder;
  final Widget Function(String, bool)? customReactionBuilder;
  final Widget Function(MenuItem, VoidCallback)? customMenuItemBuilder;

  const ChatReactionsConfig({
    this.availableReactions = const ['👍', '❤️', '😂', '😮', '😢', '😠', '➕'],
    this.menuItems = const [
      MenuItem(label: 'Reply', icon: Icons.reply),
      MenuItem(label: 'Copy', icon: Icons.copy),
      MenuItem(
          label: 'Delete', icon: Icons.delete_forever, isDestructive: true),
    ],
    this.animationDuration = const Duration(milliseconds: 300),
    this.dialogTransitionDuration = const Duration(milliseconds: 300),
    this.showAddReactionButton = true,
    this.enableHapticFeedback = true,
    this.enableLongPress = true,
    this.enableDoubleTap = false,
    this.maxReactionsToShow = 5,
    this.reactionSize = 25.0,
    this.stackedValue = 4.0,
    this.dialogPadding = const EdgeInsets.all(20.0),
    this.dialogBorderRadius,
    this.dialogBackgroundColor,
    this.dialogBlurSigma = 5.0,
    this.dismissOnTapOutside = true,
    this.showContextMenu = true,
    this.emojiPickerBuilder = _defaultEmojiPickerBuilder,
    this.customReactionBuilder,
    this.customMenuItemBuilder,
  });

  ChatReactionsConfig copyWith({
    List<String>? availableReactions,
    List<MenuItem>? menuItems,
    Duration? animationDuration,
    Duration? dialogTransitionDuration,
    bool? showAddReactionButton,
    bool? enableHapticFeedback,
    bool? enableLongPress,
    bool? enableDoubleTap,
    int? maxReactionsToShow,
    double? reactionSize,
    double? stackedValue,
    EdgeInsets? dialogPadding,
    BorderRadius? dialogBorderRadius,
    Color? dialogBackgroundColor,
    Color? reactionBackgroundColor,
    double? dialogBlurSigma,
    bool? dismissOnTapOutside,
    bool? showContextMenu,
    Widget Function(BuildContext, Function(String) onEmojiSelected)?
        emojiPickerBuilder,
    Widget Function(String, bool)? customReactionBuilder,
    Widget Function(MenuItem, VoidCallback)? customMenuItemBuilder,
  }) {
    return ChatReactionsConfig(
      availableReactions: availableReactions ?? this.availableReactions,
      menuItems: menuItems ?? this.menuItems,
      animationDuration: animationDuration ?? this.animationDuration,
      dialogTransitionDuration:
          dialogTransitionDuration ?? this.dialogTransitionDuration,
      showAddReactionButton:
          showAddReactionButton ?? this.showAddReactionButton,
      enableHapticFeedback: enableHapticFeedback ?? this.enableHapticFeedback,
      enableLongPress: enableLongPress ?? this.enableLongPress,
      enableDoubleTap: enableDoubleTap ?? this.enableDoubleTap,
      maxReactionsToShow: maxReactionsToShow ?? this.maxReactionsToShow,
      reactionSize: reactionSize ?? this.reactionSize,
      stackedValue: stackedValue ?? this.stackedValue,
      dialogPadding: dialogPadding ?? this.dialogPadding,
      dialogBorderRadius: dialogBorderRadius ?? this.dialogBorderRadius,
      dialogBackgroundColor:
          dialogBackgroundColor ?? this.dialogBackgroundColor,
      dialogBlurSigma: dialogBlurSigma ?? this.dialogBlurSigma,
      dismissOnTapOutside: dismissOnTapOutside ?? this.dismissOnTapOutside,
      showContextMenu: showContextMenu ?? this.showContextMenu,
      emojiPickerBuilder: emojiPickerBuilder ?? this.emojiPickerBuilder,
      customReactionBuilder:
          customReactionBuilder ?? this.customReactionBuilder,
      customMenuItemBuilder:
          customMenuItemBuilder ?? this.customMenuItemBuilder,
    );
  }
}

Widget _defaultEmojiPickerBuilder(
    BuildContext context, Function(String) onEmojiSelected) {
  return EmojiPicker(
    onEmojiSelected: (category, emoji) {
      onEmojiSelected(emoji.emoji);
    },
  );
}
