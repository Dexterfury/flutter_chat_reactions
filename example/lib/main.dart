import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';

void main() => runApp(const ExampleApp());

/// Minimal chat showing ReactableMessage, ReactionsSummaryView and the
/// optional ReactionsController.
class ExampleApp extends StatelessWidget {
  /// Creates the example app.
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter_chat_reactions',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      home: const ChatScreen(),
    );
  }
}

/// A single chat screen.
class ChatScreen extends StatefulWidget {
  /// Creates the chat screen.
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = ReactionsController(
    currentUserId: 'me',
    currentUserName: 'Me',
  );
  final _messages = const [
    ('m1', 'them', 'Hey! Did you see the new release?'),
    ('m2', 'me', 'Yes — reactions finally work everywhere 🎉'),
    ('m3', 'them', 'Long-press (or right-click) a message to react.'),
  ];

  @override
  void initState() {
    super.initState();
    _controller.setReactions('m1', const [
      Reaction(emoji: '👍', userId: 'them', userName: 'Sam'),
    ]);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onAction(BuildContext context, ReactionAction<dynamic> action) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${action.label} tapped')));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: ChatReactionsScope(
        actionsBuilder: (_) => const [
          ReactionAction<void>(id: 'reply', label: 'Reply', icon: Icons.reply),
          ReactionAction<void>(id: 'copy', label: 'Copy', icon: Icons.copy),
        ],
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final (id, author, text) in _messages)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Align(
                    alignment: author == 'me'
                        ? AlignmentDirectional.centerEnd
                        : AlignmentDirectional.centerStart,
                    child: ReactableMessage(
                      alignment: author == 'me'
                          ? ReactionAlignment.end
                          : ReactionAlignment.start,
                      reactions: _controller.summariesFor(id),
                      onReactionSelected: _controller
                          .bind(id)
                          .onReactionSelected,
                      onActionSelected: (action) => _onAction(context, action),
                      child: ReactionsSummaryView.overlay(
                        reactions: _controller.summariesFor(id),
                        alignment: author == 'me'
                            ? ReactionAlignment.end
                            : ReactionAlignment.start,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 280),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: author == 'me'
                                ? scheme.primary
                                : scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            text,
                            style: TextStyle(
                              color: author == 'me'
                                  ? scheme.onPrimary
                                  : scheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
