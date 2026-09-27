import 'package:example/app/demo_id.dart';
import 'package:example/widgets/bubble_row.dart';
import 'package:example/widgets/demo_chat_model.dart';
import 'package:example/widgets/radial_reaction_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';

Widget _buildRadial(
  BuildContext context,
  ReactionsMenuContext menu,
  Animation<double> animation,
) => RadialReactionMenu(menu: menu, animation: animation);

/// Headless mode: CustomPresenter handles the route, barrier and dismissal;
/// the UI is a radial ring drawn by this app.
class CustomDemo extends StatefulWidget {
  /// Creates the demo.
  const CustomDemo({super.key});

  @override
  State<CustomDemo> createState() => _CustomDemoState();
}

class _CustomDemoState extends State<CustomDemo> {
  final _chat = DemoChatModel();

  @override
  void dispose() {
    _chat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(DemoId.custom.title)),
      body: ChatReactionsScope(
        presenter: const CustomPresenter(
          builder: _buildRadial,
          barrierColor: Color(0x99000000),
          blurSigma: 6,
        ),
        child: ListenableBuilder(
          listenable: _chat,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.all(12),
            children: [
              for (final message in _chat.messages)
                BubbleRow(
                  message: message,
                  chat: _chat,
                  summaryLayout: ReactionSummaryLayout.compact,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
