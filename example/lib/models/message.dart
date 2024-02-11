class Message {
  String id;
  String message;
  String timeSent;
  List<String> reactions;
  bool isMe;

  Message({
    required this.id,
    required this.message,
    required this.timeSent,
    required this.reactions,
    required this.isMe,
  });

  // list of messages
  static List<Message> messages = [
    Message(
      id: '1',
      message: 'Hello',
      timeSent: '10:00 AM',
      reactions: ['😍'],
      isMe: false,
    ),
    Message(
      id: '2',
      message: 'Hi',
      timeSent: '10:01 AM',
      reactions: ['😂'],
      isMe: true,
    ),
    Message(
      id: '3',
      message: 'How are you?',
      timeSent: '10:02 AM',
      reactions: [],
      isMe: false,
    ),
    Message(
      id: '4',
      message: 'I am fine, thank you',
      timeSent: '10:03 AM',
      reactions: [],
      isMe: true,
    ),
    Message(
      id: '5',
      message: 'What about you?',
      timeSent: '10:04 AM',
      reactions: [],
      isMe: false,
    ),
    Message(
      id: '6',
      message: 'I am also fine',
      timeSent: '10:05 AM',
      reactions: ['👍', '❤️', '😂'],
      isMe: true,
    ),
    Message(
      id: '7',
      message: 'Good to hear that',
      timeSent: '10:06 AM',
      reactions: ['👍'],
      isMe: false,
    ),
    Message(
      id: '8',
      message: 'Yes',
      timeSent: '10:07 AM',
      reactions: ['❤️'],
      isMe: true,
    ),
    Message(
      id: '9',
      message: 'Bye',
      timeSent: '10:08 AM',
      reactions: ['👍', '💗', '😂'],
      isMe: false,
    ),
    Message(
      id: '10',
      message: 'Goodbye',
      timeSent: '10:09 AM',
      reactions: [
        '👍',
      ],
      isMe: true,
    ),
  ];
}
