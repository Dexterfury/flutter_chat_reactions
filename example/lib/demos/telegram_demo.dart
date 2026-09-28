import 'package:example/app/demo_id.dart';
import 'package:example/data/sample_chat.dart';
import 'package:example/widgets/bubble_row.dart';
import 'package:example/widgets/demo_chat_model.dart';
import 'package:example/widgets/message_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';

/// Telegram style: a bottom sheet with the reaction row, who reacted, and
/// full-width actions (including Pin).
class TelegramDemo extends StatefulWidget {
  /// Creates the demo.
  const TelegramDemo({super.key});

  @override
  State<TelegramDemo> createState() => _TelegramDemoState();
}

class _TelegramDemoState extends State<TelegramDemo> {
  final _chat = DemoChatModel();

  @override
  void dispose() {
    _chat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(DemoId.telegram.title)),
      body: ChatReactionsScope(
        presenter: const BottomSheetPresenter(showReactionDetails: true),
        child: ListenableBuilder(
          listenable: _chat,
          builder: (context, _) {
            final pinned = _chat.pinned;
            return Column(
              children: [
                if (pinned != null) _PinnedBanner(message: pinned),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      for (final message in _chat.messages)
                        BubbleRow(
                          message: message,
                          chat: _chat,
                          actionsFor: (m) => actionsFor(m, pin: true),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PinnedBanner extends StatelessWidget {
  const _PinnedBanner({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      key: const ValueKey('pinned-banner'),
      color: scheme.secondaryContainer,
      child: ListTile(
        dense: true,
        leading: Icon(Icons.push_pin, color: scheme.onSecondaryContainer),
        title: const Text('Pinned message'),
        subtitle: Text(
          message.text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
