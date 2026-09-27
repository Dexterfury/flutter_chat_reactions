import 'package:example/app/demo_id.dart';
import 'package:example/data/sample_chat.dart';
import 'package:example/widgets/demo_chat_model.dart';
import 'package:example/widgets/message_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';

/// Quick reactions for the team channel, including custom shortcodes.
const List<String> kTeamReactions = [
  '👍',
  '🎉',
  '👀',
  ':party:',
  ':ship_it:',
  ':lgtm:',
];

@immutable
class _Shortcode {
  const _Shortcode(this.icon, this.colors);
  final IconData icon;
  final List<Color> colors;
}

const Map<String, _Shortcode> _shortcodes = {
  ':party:': _Shortcode(Icons.celebration, [
    Color(0xFFFF6B6B),
    Color(0xFFFFB347),
  ]),
  ':ship_it:': _Shortcode(Icons.rocket_launch, [
    Color(0xFF4D96FF),
    Color(0xFF6BCB77),
  ]),
  ':lgtm:': _Shortcode(Icons.check_circle, [
    Color(0xFF2E7D32),
    Color(0xFF1DE9B6),
  ]),
};

/// Draws `:shortcode:` emoji as gradient badges; unicode emoji as text.
///
/// In a real app, give custom `:shortcode:` emoji accessible names via a
/// `ChatReactionsLocalizations` subclass that overrides `emojiLabel`.
Widget teamEmojiBuilder(BuildContext context, String emoji, double size) {
  final spec = _shortcodes[emoji];
  if (spec == null) return defaultEmojiBuilder(context, emoji, size);
  return Container(
    key: ValueKey('emoji-$emoji'),
    width: size * 1.15,
    height: size * 1.15,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(size * 0.3),
      gradient: LinearGradient(colors: spec.colors),
    ),
    child: Icon(spec.icon, size: size * 0.75, color: Colors.white),
  );
}

/// Sample reactions plus some shortcode reactions.
Map<String, List<Reaction>> teamReactions() => {
  ...sampleReactions(),
  'm4': const [
    Reaction(emoji: ':ship_it:', userId: 'sam', userName: 'Sam'),
    Reaction(emoji: ':ship_it:', userId: 'priya', userName: 'Priya'),
    Reaction(emoji: '👀', userId: 'me', userName: 'You'),
  ],
};

/// Slack / Discord style: compact bar, chips, many reactions per user.
class TeamDemo extends StatefulWidget {
  /// Creates the demo.
  const TeamDemo({super.key});

  @override
  State<TeamDemo> createState() => _TeamDemoState();
}

class _TeamDemoState extends State<TeamDemo> {
  final _chat = DemoChatModel(
    policy: const ReactionPolicy.multiple(),
    reactions: teamReactions(),
  );

  @override
  void dispose() {
    _chat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(DemoId.team.title)),
      body: ChatReactionsScope(
        presenter: const CompactBarPresenter(),
        quickReactions: kTeamReactions,
        emojiBuilder: teamEmojiBuilder,
        child: ListenableBuilder(
          listenable: _chat,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              for (final message in _chat.messages)
                _TeamRow(message: message, chat: _chat),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamRow extends StatelessWidget {
  const _TeamRow({required this.message, required this.chat});

  final ChatMessage message;
  final DemoChatModel chat;

  @override
  Widget build(BuildContext context) {
    final id = message.id;
    final reactions = chat.reactionsFor(id);
    final select = chat.onReactionSelected(id);
    final author = message.author;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: author.color,
            child: Text(
              author.name.characters.first,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReactableMessage(
                  key: ValueKey('reactable-$id'),
                  alignment: ReactionAlignment.start,
                  reactions: reactions,
                  onReactionSelected: select,
                  actionsBuilder: (_) => actionsFor(message),
                  onActionSelected: (action) =>
                      chat.handleAction(context, message, action),
                  child: Container(
                    key: ValueKey('msg-$id'),
                    width: double.infinity,
                    color: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          author.name,
                          style: text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(message.text, style: text.bodyLarge),
                      ],
                    ),
                  ),
                ),
                if (reactions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: ReactionsSummaryView(
                      key: ValueKey('summary-$id'),
                      reactions: reactions,
                      emojiBuilder: teamEmojiBuilder,
                      onReactionTap: select,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
