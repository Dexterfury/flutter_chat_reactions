import 'package:example/models/message.dart';
import 'package:example/widgets/stacked_reactions.dart';
import 'package:flutter/material.dart';

class ContactMessage extends StatelessWidget {
  const ContactMessage({
    super.key,
    required this.message,
  });

  final Message message;

  @override
  Widget build(BuildContext context) {
    final padding = message.reactions.isNotEmpty
        ? const EdgeInsets.only(right: 30.0, bottom: 25.0)
        : const EdgeInsets.only(bottom: 0.0);
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
          minWidth: MediaQuery.of(context).size.width * 0.3,
        ),
        child: Stack(
          children: [
            Padding(
              padding: padding,
              child: Card(
                elevation: 5,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                ),
                color: Colors.black54,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.message,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSecondary,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        message.timeSent,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 4,
              left: 0,
              child: StackedReactions(
                message: message,
                size: 20,
                stackedValue: 4.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
