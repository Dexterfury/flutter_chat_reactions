import 'package:example/data/sample_chat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';

/// Reply to a message.
const ReactionAction<void> kReplyAction = ReactionAction<void>(
  id: 'reply',
  label: 'Reply',
  icon: Icons.reply,
);

/// Copy a message's text.
const ReactionAction<void> kCopyAction = ReactionAction<void>(
  id: 'copy',
  label: 'Copy',
  icon: Icons.copy_outlined,
);

/// Pin a message to the top of the chat.
const ReactionAction<void> kPinAction = ReactionAction<void>(
  id: 'pin',
  label: 'Pin',
  icon: Icons.push_pin_outlined,
);

/// Delete one of your own messages.
const ReactionAction<void> kDeleteAction = ReactionAction<void>(
  id: 'delete',
  label: 'Delete',
  icon: Icons.delete_outline,
  isDestructive: true,
);

/// Actions offered for [message]: delete only on your own messages.
List<ReactionAction<dynamic>> actionsFor(
  ChatMessage message, {
  bool pin = false,
}) => [
  kReplyAction,
  kCopyAction,
  if (pin) kPinAction,
  if (message.isMine) kDeleteAction,
];
