import 'package:example/models/message.dart';
import 'package:flutter/material.dart';

class StackedReactions extends StatelessWidget {
  const StackedReactions({
    super.key,
    required this.message,
    required this.size,
    required this.stackedValue,
    this.direction = TextDirection.ltr,
  });
  final Message message;
  final double size;
  final double stackedValue;
  final TextDirection direction;

  @override
  Widget build(BuildContext context) {
    // if reactions are greater than 5, get the first 5 reactions
    final reactionsToShow = message.reactions.length > 5
        ? message.reactions.sublist(0, 5)
        : message.reactions;
    // remaining reactions
    final remaing = message.reactions.length - reactionsToShow.length;
    final allItems = reactionsToShow
        .asMap()
        .map((index, reaction) {
          final left = size - stackedValue;
          final value = Container(
            margin: EdgeInsets.only(left: left * index),
            padding: const EdgeInsets.all(2.0),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(25)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  offset: Offset(0.0, 1.0), //(x,y)
                  blurRadius: 6.0,
                ),
              ],
            ),
            child: ClipOval(
              child: Text(
                reaction,
                style: TextStyle(fontSize: size),
              ),
            ),
          );
          return MapEntry(index, value);
        })
        .values
        .toList();

    return Row(
      children: [
        Stack(
          children: direction == TextDirection.ltr
              ? allItems.reversed.toList()
              : allItems,
        ),
        // show this only if there are more than 5 reactions
        if (remaing > 0)
          Container(
            padding: const EdgeInsets.all(2.0),
            margin: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(25)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  offset: Offset(0.0, 1.0), //(x,y)
                  blurRadius: 6.0,
                ),
              ],
            ),
            child: ClipOval(
              child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: Text(
                  '+$remaing',
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          )
      ],
    );
  }
}
