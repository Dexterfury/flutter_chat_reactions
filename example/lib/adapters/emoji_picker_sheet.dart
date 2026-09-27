import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as picker;
import 'package:flutter/material.dart';

/// Opens a full emoji picker and returns a user-picked emoji, or null.
typedef EmojiPickerLauncher = Future<String?> Function(BuildContext context);

/// [EmojiPickerLauncher] backed by `emoji_picker_flutter` in a bottom sheet.
///
/// This is the adapter the README documents: the package ships no picker of
/// its own; wire any picker into `ReactableMessage.onMoreTap` like this.
Future<String?> showEmojiPickerSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (sheetContext) => SizedBox(
      height: 340,
      child: picker.EmojiPicker(
        onEmojiSelected: (_, emoji) =>
            Navigator.of(sheetContext).pop(emoji.emoji),
        config: picker.Config(
          height: 320,
          checkPlatformCompatibility: true,
          emojiViewConfig: picker.EmojiViewConfig(
            backgroundColor: Theme.of(sheetContext).colorScheme.surface,
          ),
        ),
      ),
    ),
  );
}
