import 'package:example/models/message.dart';
import 'package:example/widgets/stacked_reactions.dart';
import 'package:flutter/material.dart';

class MyMessage extends StatelessWidget {
  const MyMessage({super.key, required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    final padding = message.reactions.isNotEmpty
        ? const EdgeInsets.only(left: 30.0, bottom: 25.0)
        : const EdgeInsets.only(bottom: 0.0);
    return Align(
      alignment: Alignment.centerRight,
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
                    bottomLeft: Radius.circular(15),
                  ),
                ),
                color: Theme.of(context).colorScheme.primary,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          message.message,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              message.timeSent,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Icon(
                              Icons.done_all,
                              color: Colors.blue,
                              size: 20,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // show reactions
            if (message.reactions.isNotEmpty)
              Positioned(
                bottom: 4,
                right: 20,
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
