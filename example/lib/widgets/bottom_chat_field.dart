import 'package:date_format/date_format.dart';
import 'package:example/models/message.dart';
import 'package:flutter/material.dart';

class BottomChatField extends StatefulWidget {
  const BottomChatField({
    super.key,
  });

  @override
  State<BottomChatField> createState() => _BottomChatFieldState();
}

class _BottomChatFieldState extends State<BottomChatField> {
  // textEditingController
  final TextEditingController _textEditingController = TextEditingController();

  // add message
  void addMessage() {
    // add message to the list
    if (_textEditingController.text.isNotEmpty) {
      final timeSent = DateTime.now().millisecondsSinceEpoch;
      // format the time like 10:00 AM or 10:00 PM using package [date_format]
      final time = formatDate(DateTime.fromMillisecondsSinceEpoch(timeSent),
          [hh, ':', nn, ' ', am]);
      // message id
      final id = Message.messages.length + 1;
      // add message to the list
      Message.messages.add(
        Message(
          id: id.toString(),
          message: _textEditingController.text,
          timeSent: time,
          isMe: true,
          reactions: [],
        ),
      );

      // clear the text field
      _textEditingController.clear();
      // update UI
      setState(() {});
    }
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(30),
          border:
              Border.all(color: Theme.of(context).textTheme.titleLarge!.color!),
        ),
        //padding: const EdgeInsets.all(4.0),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 6.0),
                child: TextField(
                  controller: _textEditingController,
                  textInputAction: TextInputAction.send,
                  style: const TextStyle(fontSize: 18),
                  decoration: InputDecoration.collapsed(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    hintText: 'Type a message...',
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: addMessage,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Theme.of(context).primaryColor,
                ),
                margin: const EdgeInsets.all(6.0),
                child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                    )),
              ),
            ),
          ],
        ));
  }
}
