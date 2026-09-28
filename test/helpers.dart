import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';

/// Wraps [child] in a MaterialApp with the given platform, brightness,
/// direction and accessibility settings.
Widget harness(
  Widget child, {
  TargetPlatform platform = TargetPlatform.android,
  Brightness brightness = Brightness.light,
  TextDirection textDirection = TextDirection.ltr,
  ChatReactionsTheme? reactionsTheme,
  double textScale = 1,
  bool disableAnimations = false,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: brightness,
      platform: platform,
      extensions: [?reactionsTheme],
    ),
    builder: (context, app) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
        disableAnimations: disableAnimations,
      ),
      child: Directionality(textDirection: textDirection, child: app!),
    ),
    home: Scaffold(body: child),
  );
}

/// A menu context with sensible test defaults and recording callbacks.
ReactionsMenuContext testMenu({
  Rect anchorRect = const Rect.fromLTWH(300, 250, 200, 60),
  List<String> quickReactions = const ['👍', '❤️', '😂'],
  List<ReactionAction<dynamic>> actions = const [
    ReactionAction<void>(id: 'reply', label: 'Reply', icon: Icons.reply),
    ReactionAction<void>(
      id: 'delete',
      label: 'Delete',
      icon: Icons.delete,
      isDestructive: true,
    ),
  ],
  List<ReactionSummary> reactions = const [],
  ValueChanged<String>? onReactionSelected,
  ValueChanged<ReactionAction<dynamic>>? onActionSelected,
  Future<void> Function()? onMoreTap,
  ReactionTrigger trigger = ReactionTrigger.longPress,
  ReactionAlignment alignment = ReactionAlignment.end,
  TextDirection textDirection = TextDirection.ltr,
}) => ReactionsMenuContext(
  anchorRect: anchorRect,
  messageBuilder: (_) => const ColoredBox(
    key: Key('message-copy'),
    color: Colors.blue,
    child: SizedBox(height: 60),
  ),
  quickReactions: quickReactions,
  actions: actions,
  reactions: reactions,
  onReactionSelected: onReactionSelected,
  onActionSelected: onActionSelected,
  onMoreTap: onMoreTap,
  trigger: trigger,
  alignment: alignment,
  textDirection: textDirection,
);

/// A button that opens [presenter] with [menu] and records when it closes.
class PresenterLauncher extends StatelessWidget {
  /// Creates the launcher button.
  const PresenterLauncher({
    super.key,
    required this.presenter,
    required this.menu,
    this.onClosed,
  });

  /// The presenter to open.
  final ReactionsPresenter presenter;

  /// The menu context passed to [presenter].
  final ReactionsMenuContext menu;

  /// Called after the presenter's future completes.
  final VoidCallback? onClosed;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topLeft,
    child: TextButton(
      onPressed: () async {
        await presenter.show(context, menu);
        onClosed?.call();
      },
      child: const Text('open'),
    ),
  );
}
