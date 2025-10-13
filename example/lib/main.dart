import 'package:example/models/message.dart';
import 'package:example/widgets/bottom_chat_field.dart';
import 'package:example/widgets/contact_info.dart';
import 'package:example/widgets/message_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Chat Reactions Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = ReactionsController(currentUserId: 'user123');

  @override
  void initState() {
    super.initState();
    for (final message in Message.messages) {
      for (final reaction in message.reactions) {
        _controller.addReaction(message.id, reaction);
      }
    }
  }

  // add reaction to message
  void _addReactionToMessage({
    required Message message,
    required String reaction,
  }) {
    _controller.addReaction(message.id, reaction);
    setState(() {});
  }

  void _removeReactionFromMessage({
    required Message message,
    required String reaction,
  }) {
    _controller.removeReaction(message.id, reaction);
    setState(() {});
  }

  Widget _customMenuItemBuilder(MenuItem item, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: item.isDestructive
              ? Colors.red.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              item.label,
              style: TextStyle(
                color: item.isDestructive ? Colors.red : Colors.black,
                fontSize: 16,
              ),
            ),
            Icon(
              item.icon,
              color: item.isDestructive ? Colors.red : Colors.black,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {},
        ),
        title: const ContactInfo(),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            left: 8.0,
            right: 8.0,
          ),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: Message.messages.length,
                  itemBuilder: (BuildContext context, int index) {
                    final message = Message.messages[index];

                    final config = ChatReactionsConfig(
                      enableHapticFeedback: true,
                      maxReactionsToShow: 3,
                      enableDoubleTap: true,
                      //customMenuItemBuilder: _customMenuItemBuilder,
                    );
                    return ChatMessageWrapper(
                      messageId: message.id,
                      controller: _controller,
                      config: config,
                      onReactionAdded: (reaction) {
                        _addReactionToMessage(
                          message: message,
                          reaction: reaction,
                        );
                      },
                      onReactionRemoved: (reaction) {
                        _removeReactionFromMessage(
                          message: message,
                          reaction: reaction,
                        );
                      },
                      onMenuItemTapped: (item) {
                        print('menu item: ${item.label}');
                      },
                      alignment: message.isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: MessageWidget(
                        message: message,
                        controller: _controller,
                      ),
                    );
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
                child: BottomChatField(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
