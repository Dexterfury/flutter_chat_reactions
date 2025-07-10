import 'package:flutter/material.dart';

class ReactionsTheme {
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final Color textColor;
  final Color destructiveColor;
  final TextStyle reactionTextStyle;
  final TextStyle menuItemTextStyle;
  final BoxDecoration reactionContainerDecoration;
  final BoxDecoration menuContainerDecoration;
  final BorderRadius borderRadius;

  const ReactionsTheme({
    this.primaryColor = Colors.blue,
    this.secondaryColor = Colors.grey,
    this.backgroundColor = Colors.white,
    this.textColor = Colors.black,
    this.destructiveColor = Colors.red,
    this.reactionTextStyle = const TextStyle(fontSize: 20),
    this.menuItemTextStyle = const TextStyle(fontSize: 16),
    this.reactionContainerDecoration = const BoxDecoration(
      borderRadius: BorderRadius.all(Radius.circular(20)),
    ),
    this.menuContainerDecoration = const BoxDecoration(
      borderRadius: BorderRadius.all(Radius.circular(10)),
    ),
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
  });

  static ReactionsTheme of(BuildContext context) {
    return ReactionsTheme(
      primaryColor: Theme.of(context).primaryColor,
      secondaryColor: Theme.of(context).colorScheme.secondary,
      backgroundColor: Theme.of(context).cardColor,
      textColor: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black,
      destructiveColor: Colors.red,
    );
  }
}
