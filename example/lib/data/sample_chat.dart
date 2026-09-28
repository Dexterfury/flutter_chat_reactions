import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';

/// A chat participant in the demos.
@immutable
class ChatUser {
  /// Creates a user.
  const ChatUser({required this.id, required this.name, required this.color});

  /// Stable id, used as the reaction user id.
  final String id;

  /// Display name.
  final String name;

  /// Avatar / name colour.
  final Color color;
}

/// The current user.
const ChatUser kMe = ChatUser(id: 'me', name: 'You', color: Colors.indigo);

/// Other participants.
const ChatUser kSam = ChatUser(id: 'sam', name: 'Sam', color: Colors.teal);
const ChatUser kAlex = ChatUser(
  id: 'alex',
  name: 'Alex',
  color: Colors.deepOrange,
);
const ChatUser kPriya = ChatUser(
  id: 'priya',
  name: 'Priya',
  color: Colors.purple,
);

/// All users by id.
const Map<String, ChatUser> kUsers = {
  'me': kMe,
  'sam': kSam,
  'alex': kAlex,
  'priya': kPriya,
};

/// A chat message in the demos.
@immutable
class ChatMessage {
  /// Creates a message.
  const ChatMessage({
    required this.id,
    required this.authorId,
    required this.text,
  });

  /// Stable id; also the reactions key.
  final String id;

  /// Author's user id.
  final String authorId;

  /// Message text. Must not contain default quick-reaction emojis.
  final String text;

  /// The author.
  ChatUser get author => kUsers[authorId]!;

  /// Whether the current user wrote this message.
  bool get isMine => authorId == kMe.id;

  /// Returns a copy of this message with [text] substituted; id and author
  /// stay the same, so keys (`msg-<id>`, `summary-<id>`, `reactable-<id>`)
  /// and reactions are unaffected.
  ChatMessage withText(String text) =>
      ChatMessage(id: id, authorId: authorId, text: text);
}

/// Arabic translations of [sampleConversation]'s messages, keyed by message
/// id. Used by the theming demo's RTL mode so the sample text reads
/// naturally right-to-left (the English text is valid but visually odd in
/// RTL layout, since bidi rules keep line-end punctuation at the start).
const Map<String, String> kRtlSampleTexts = {
  'm1': 'صباح الخير! هل وصل الإصدار الجديد؟',
  'm2': 'نعم، التفاعلات تعمل في كل مكان الآن.',
  'm3': 'اضغط مطولًا على أي رسالة للتفاعل.',
  'm4': 'على سطح المكتب يمكنك النقر بزر الفأرة الأيمن أو التمرير فوق الرسالة.',
  'm5': 'سنطلقه بعد الغداء.',
};

/// The conversation every demo starts from (ids m1–m5).
List<ChatMessage> sampleConversation() => const [
  ChatMessage(
    id: 'm1',
    authorId: 'sam',
    text: 'Morning! Did the new build land?',
  ),
  ChatMessage(
    id: 'm2',
    authorId: 'me',
    text: 'Yes, reactions work everywhere now.',
  ),
  ChatMessage(
    id: 'm3',
    authorId: 'priya',
    text: 'Long-press any message to react.',
  ),
  ChatMessage(
    id: 'm4',
    authorId: 'alex',
    text: 'On desktop you can right-click or hover instead.',
  ),
  ChatMessage(id: 'm5', authorId: 'me', text: 'Shipping it after lunch.'),
];

/// Reactions every demo starts from, keyed by message id.
Map<String, List<Reaction>> sampleReactions() => const {
  'm2': [
    Reaction(emoji: '👍', userId: 'sam', userName: 'Sam'),
    Reaction(emoji: '👍', userId: 'alex', userName: 'Alex'),
    Reaction(emoji: '❤️', userId: 'priya', userName: 'Priya'),
  ],
  'm3': [Reaction(emoji: '❤️', userId: 'me', userName: 'You')],
  'm4': [Reaction(emoji: '😂', userId: 'sam', userName: 'Sam')],
};
