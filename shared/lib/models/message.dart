enum MessageStatus { sending, sent, read }

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime createdAt;
  final MessageStatus status;

  const Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.createdAt,
    required this.status,
  });

  /// Sender id used for system messages (call approvals etc).
  static const systemSenderId = 'system';

  bool get isSystem => senderId == systemSenderId;

  Map<String, dynamic> toMap() => {
        'id': id,
        'chatId': chatId,
        'senderId': senderId,
        'receiverId': receiverId,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'status': status.name,
      };

  factory Message.fromMap(Map<String, dynamic> map) => Message(
        id: map['id'] as String,
        chatId: map['chatId'] as String,
        senderId: map['senderId'] as String,
        receiverId: map['receiverId'] as String,
        text: map['text'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
        status: MessageStatus.values.byName(map['status'] as String),
      );

  Message copyWith({String? text, MessageStatus? status}) => Message(
        id: id,
        chatId: chatId,
        senderId: senderId,
        receiverId: receiverId,
        text: text ?? this.text,
        createdAt: createdAt,
        status: status ?? this.status,
      );
}
