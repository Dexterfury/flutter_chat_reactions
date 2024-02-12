import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:example/models/message.dart';
import 'package:example/widgets/bottom_chat_field.dart';
import 'package:example/widgets/contact_info.dart';
import 'package:example/widgets/contact_message.dart';
import 'package:example/widgets/message_widget.dart';
import 'package:example/widgets/my_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_chat_reactions/utilities/hero_dialog_route.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
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
  // show emoji picker bottom sheet
  void showEmojiBottomSheet({
    required Message message,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 310,
          child: EmojiPicker(
            onEmojiSelected: ((category, emoji) {
              // pop the bottom sheet
              Navigator.pop(context);
              addReactionToMessage(
                message: message,
                reaction: emoji.emoji,
              );
            }),
          ),
        );
      },
    );
  }

  // add reaction to message
  void addReactionToMessage({
    required Message message,
    required String reaction,
  }) {
    message.reactions.add(reaction);
    // update UI
    setState(() {});
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
                child: // list view builder for example messages
                    ListView.builder(
                  itemCount: Message.messages.length,
                  itemBuilder: (BuildContext context, int index) {
                    // get message
                    final message = Message.messages[index];
                    return GestureDetector(
                      // wrap your message widget with a [GestureDectector] or [InkWell]
                      onLongPress: () {
                        // navigate with a custom [HeroDialogRoute] to [ReactionsDialogWidget]
                        Navigator.of(context).push(
                          HeroDialogRoute(
                            builder: (context) {
                              return ReactionsDialogWidget(
                                id: message.id, // unique id for message
                                messageWidget: message.isMe
                                    ? MyMessage(message: message)
                                    : ContactMessage(
                                        message: message), // message widget
                                onReactionTap: (reaction) {
                                  print('reaction: $reaction');

                                  if (reaction == '➕') {
                                    // show emoji picker container
                                    showEmojiBottomSheet(
                                      message: message,
                                    );
                                  } else {
                                    // add reaction to message
                                    addReactionToMessage(
                                      message: message,
                                      reaction: reaction,
                                    );
                                  }
                                },
                                onContextMenuTap: (menuItem) {
                                  print('menu item: $menuItem');
                                  // handle context menu item
                                },
                                // align widget to the right for my message and to the left for contact message
                                // default is [Alignment.centerRight]
                                widgetAlignment: message.isMe
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                              );
                            },
                          ),
                        );
                      },
                      // wrap message with [Hero] widget
                      child: Hero(
                        tag: message.id,
                        child: MessageWidget(message: message),
                      ),
                    );
                  },
                ),
              ),
              // bottom chat input
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
