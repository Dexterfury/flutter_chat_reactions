import 'dart:async';

import 'package:example/data/sample_chat.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';

/// Messages + reactions + action handling shared by the demos.
class DemoChatModel extends ChangeNotifier {
  /// Creates a model seeded with [sampleConversation] and [reactions]
  /// (defaults to [sampleReactions]).
  DemoChatModel({
    ReactionPolicy policy = const ReactionPolicy.single(),
    Map<String, List<Reaction>>? reactions,
  }) : controller = ReactionsController(
         currentUserId: kMe.id,
         currentUserName: kMe.name,
         policy: policy,
       ) {
    for (final entry in (reactions ?? sampleReactions()).entries) {
      controller.setReactions(entry.key, entry.value);
    }
    controller.addListener(notifyListeners);
  }

  /// The reactions store.
  final ReactionsController controller;

  /// Current messages (deletable).
  final List<ChatMessage> messages = List.of(sampleConversation());

  String? _pinnedId;

  /// The pinned message, if any.
  ChatMessage? get pinned {
    for (final m in messages) {
      if (m.id == _pinnedId) return m;
    }
    return null;
  }

  /// Summaries for message [id].
  List<ReactionSummary> reactionsFor(String id) => controller.summariesFor(id);

  /// Toggle callback for message [id].
  ValueChanged<String> onReactionSelected(String id) =>
      controller.bind(id).onReactionSelected;

  /// Runs [action] on [message]; feedback is shown via [context]'s
  /// ScaffoldMessenger.
  void handleAction(
    BuildContext context,
    ChatMessage message,
    ReactionAction<dynamic> action,
  ) {
    final messenger = ScaffoldMessenger.of(context);
    switch (action.id) {
      case 'delete':
        messages.removeWhere((m) => m.id == message.id);
        if (_pinnedId == message.id) _pinnedId = null;
        controller.clear(message.id);
        notifyListeners();
        messenger.showSnackBar(
          const SnackBar(content: Text('Message deleted')),
        );
      case 'pin':
        _pinnedId = message.id;
        notifyListeners();
      case 'copy':
        unawaited(
          Clipboard.setData(
            ClipboardData(text: message.text),
          ).catchError((Object _) {}),
        );
        messenger.showSnackBar(
          const SnackBar(content: Text('Copied to clipboard')),
        );
      case 'reply':
        messenger.showSnackBar(
          SnackBar(content: Text('Replying to ${message.author.name}')),
        );
    }
  }

  @override
  void dispose() {
    controller.removeListener(notifyListeners);
    controller.dispose();
    super.dispose();
  }
}
