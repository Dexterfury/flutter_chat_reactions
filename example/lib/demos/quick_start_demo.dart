import 'package:example/app/demo_id.dart';
import 'package:example/data/sample_chat.dart';
import 'package:example/widgets/chat_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';

/// The smallest useful integration: a controller, ReactableMessage around
/// each bubble, and a ReactionsSummaryView below it.
class QuickStartDemo extends StatefulWidget {
  /// Creates the demo.
  const QuickStartDemo({super.key});

  @override
  State<QuickStartDemo> createState() => _QuickStartDemoState();
}

class _QuickStartDemoState extends State<QuickStartDemo> {
  final _controller = ReactionsController(
    currentUserId: kMe.id,
    currentUserName: kMe.name,
  );
  final _messages = sampleConversation();

  @override
  void initState() {
    super.initState();
    for (final entry in sampleReactions().entries) {
      _controller.setReactions(entry.key, entry.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(DemoId.quickStart.title)),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final message in _messages)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Align(
                  alignment: message.isMine
                      ? AlignmentDirectional.centerEnd
                      : AlignmentDirectional.centerStart,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: message.isMine
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      ReactableMessage(
                        key: ValueKey('reactable-${message.id}'),
                        alignment: message.isMine
                            ? ReactionAlignment.end
                            : ReactionAlignment.start,
                        reactions: _controller.summariesFor(message.id),
                        onReactionSelected: _controller
                            .bind(message.id)
                            .onReactionSelected,
                        child: ChatBubble(message: message),
                      ),
                      const SizedBox(height: 4),
                      ReactionsSummaryView(
                        key: ValueKey('summary-${message.id}'),
                        reactions: _controller.summariesFor(message.id),
                        onReactionTap: _controller
                            .bind(message.id)
                            .onReactionSelected,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
