import 'package:example/models/message.dart';
import 'package:example/widgets/contact_message.dart';
import 'package:example/widgets/my_message.dart';
import 'package:flutter/material.dart';

class MessageWidget extends StatelessWidget {
  const MessageWidget({
    super.key,
    required this.message,
  });

  final Message message;

  @override
  Widget build(BuildContext context) {
    return message.isMe
        ? MyMessage(message: message)
        : ContactMessage(message: message);
  }
}
