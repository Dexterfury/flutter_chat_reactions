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
    builder: (sheetContext) {
      final scheme = Theme.of(sheetContext).colorScheme;
      return picker.EmojiPicker(
        onEmojiSelected: (_, emoji) =>
            Navigator.of(sheetContext).pop(emoji.emoji),
        config: picker.Config(
          height: 320,
          checkPlatformCompatibility: true,
          emojiViewConfig: picker.EmojiViewConfig(
            backgroundColor: scheme.surface,
          ),
          categoryViewConfig: picker.CategoryViewConfig(
            backgroundColor: scheme.surface,
            indicatorColor: scheme.primary,
            iconColor: scheme.onSurfaceVariant,
            iconColorSelected: scheme.primary,
            backspaceColor: scheme.primary,
            dividerColor: scheme.outlineVariant,
          ),
          searchViewConfig: picker.SearchViewConfig(
            backgroundColor: scheme.surface,
            buttonIconColor: scheme.onSurfaceVariant,
          ),
          // No text field to edit, so no backspace / search action bar.
          bottomActionBarConfig: const picker.BottomActionBarConfig(
            enabled: false,
          ),
        ),
      );
    },
  );
}
