enum MessageStatus { sending, sent, read }

/// Attachment kind — images and documents only (no video/audio).
enum AttachmentType { none, image, document }

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime createdAt;
  final MessageStatus status;

  final AttachmentType attachmentType;
  final String? attachmentName;

  /// Base64-encoded file bytes. Present only on the message doc itself —
  /// stripped from the chat's lastMessage preview to stay under Firestore's
  /// 1 MB doc limit.
  final String? attachmentData;

  const Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.createdAt,
    required this.status,
    this.attachmentType = AttachmentType.none,
    this.attachmentName,
    this.attachmentData,
  });

  /// Sender id used for system messages (call approvals etc).
  static const systemSenderId = 'system';

  bool get isSystem => senderId == systemSenderId;
  bool get hasAttachment => attachmentType != AttachmentType.none;

  /// Chat-list preview text — never leaks the base64 blob.
  String get preview {
    if (text.isNotEmpty) return text;
    return switch (attachmentType) {
      AttachmentType.image => '📷 Photo',
      AttachmentType.document => '📄 ${attachmentName ?? 'Document'}',
      AttachmentType.none => '',
    };
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'chatId': chatId,
        'senderId': senderId,
        'receiverId': receiverId,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'status': status.name,
        'attachmentType': attachmentType.name,
        'attachmentName': attachmentName,
        'attachmentData': attachmentData,
      };

  factory Message.fromMap(Map<String, dynamic> map) => Message(
        id: map['id'] as String,
        chatId: map['chatId'] as String,
        senderId: map['senderId'] as String,
        receiverId: map['receiverId'] as String,
        text: map['text'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
        status: MessageStatus.values.byName(map['status'] as String),
        attachmentType: AttachmentType.values
            .byName((map['attachmentType'] as String?) ?? 'none'),
        attachmentName: map['attachmentName'] as String?,
        attachmentData: map['attachmentData'] as String?,
      );

  Message copyWith({String? text, MessageStatus? status}) => Message(
        id: id,
        chatId: chatId,
        senderId: senderId,
        receiverId: receiverId,
        text: text ?? this.text,
        createdAt: createdAt,
        status: status ?? this.status,
        attachmentType: attachmentType,
        attachmentName: attachmentName,
        attachmentData: attachmentData,
      );

  /// Lightweight copy for the chat-list `lastMessage` field — drops the
  /// base64 payload so the chat doc stays small.
  Message toPreview() => Message(
        id: id,
        chatId: chatId,
        senderId: senderId,
        receiverId: receiverId,
        text: text,
        createdAt: createdAt,
        status: status,
        attachmentType: attachmentType,
        attachmentName: attachmentName,
      );
}
