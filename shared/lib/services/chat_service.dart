import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/message.dart';
import '../utils/app_exception.dart';
import '../utils/app_strings.dart';
import '../utils/wtf_logger.dart';

/// Live chat-list metadata for one conversation.
class ChatSummary {
  final Message? lastMessage;
  final int unreadCount;
  final String? typingUserId;

  const ChatSummary({
    this.lastMessage,
    this.unreadCount = 0,
    this.typingUserId,
  });
}

abstract class ChatService {
  Stream<ChatSummary> watchChat(String chatId, String viewerId);
  Stream<List<Message>> watchMessages(String chatId, {int limit = 50});
  Future<void> send(Message m);
  Future<void> markRead(String chatId, String readerId);
  Future<void> setTyping(String chatId, String? userId);
  Future<void> sendSystem(String chatId, String text);
}

class FirebaseChatService implements ChatService {
  final FirebaseFirestore _db;
  final Random _random = Random();
  FirebaseChatService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _chat(String chatId) =>
      _db.collection('chats').doc(chatId);

  CollectionReference<Map<String, dynamic>> _messages(String chatId) =>
      _chat(chatId).collection('messages');

  @override
  Stream<ChatSummary> watchChat(String chatId, String viewerId) =>
      _chat(chatId).snapshots().map((doc) {
        final data = doc.data();
        if (data == null) return const ChatSummary();
        return ChatSummary(
          lastMessage: data['lastMessage'] == null
              ? null
              : Message.fromMap(
                  Map<String, dynamic>.from(data['lastMessage'] as Map)),
          unreadCount: (data['unread_$viewerId'] as int?) ?? 0,
          typingUserId: data['typingUserId'] as String?,
        );
      });

  @override
  Stream<List<Message>> watchMessages(String chatId, {int limit = 50}) =>
      _messages(chatId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((snap) =>
              snap.docs.map((d) => Message.fromMap(d.data())).toList());

  @override
  Future<void> send(Message m) async {
    try {
      final sent = m.copyWith(status: MessageStatus.sent);
      final batch = _db.batch();
      // Full message (may carry base64 attachment) in the subcollection…
      batch.set(_messages(m.chatId).doc(m.id), sent.toMap());
      // …but the chat-list preview strips the blob to stay under 1 MB.
      batch.set(
        _chat(m.chatId),
        {
          'lastMessage': sent.toPreview().toMap(),
          'unread_${m.receiverId}': FieldValue.increment(1),
        },
        SetOptions(merge: true),
      );
      await batch.commit();
      WtfLog.d(LogTag.chat, 'sent ${m.id} → ${m.receiverId}');

      // Simulated typing indicator on the receiving side (spec §3B:
      // 400–800ms delay after a send).
      Future<void>.delayed(
        Duration(milliseconds: 400 + _random.nextInt(400)),
        () async {
          await setTyping(m.chatId, m.receiverId);
          await Future<void>.delayed(const Duration(milliseconds: 1200));
          await setTyping(m.chatId, null);
        },
      );
    } catch (e) {
      throw AppException(AppStrings.chatSendFailed, e);
    }
  }

  @override
  Future<void> markRead(String chatId, String readerId) async {
    try {
      final unread = await _messages(chatId)
          .where('receiverId', isEqualTo: readerId)
          .where('status', isEqualTo: MessageStatus.sent.name)
          .get();
      if (unread.docs.isEmpty) return;
      final batch = _db.batch();
      for (final doc in unread.docs) {
        batch.update(doc.reference, {'status': MessageStatus.read.name});
      }
      // Also flip the lastMessage tick when the reader received it.
      final chatDoc = await _chat(chatId).get();
      final last = chatDoc.data()?['lastMessage'] as Map?;
      if (last != null && last['receiverId'] == readerId) {
        batch.set(
            _chat(chatId),
            {
              'lastMessage': {...Map<String, dynamic>.from(last), 'status': MessageStatus.read.name},
            },
            SetOptions(merge: true));
      }
      batch.set(_chat(chatId), {'unread_$readerId': 0}, SetOptions(merge: true));
      await batch.commit();
      WtfLog.d(LogTag.chat, 'markRead $chatId by $readerId (${unread.docs.length})');
    } catch (e) {
      throw AppException(AppStrings.genericError, e);
    }
  }

  @override
  Future<void> setTyping(String chatId, String? userId) =>
      _chat(chatId).set({'typingUserId': userId}, SetOptions(merge: true));

  @override
  Future<void> sendSystem(String chatId, String text) async {
    final parts = chatId.split('_trainer_');
    final m = Message(
      id: _db.collection('chats').doc().id,
      chatId: chatId,
      senderId: Message.systemSenderId,
      receiverId: parts.first,
      text: text,
      createdAt: DateTime.now(),
      status: MessageStatus.sent,
    );
    await _messages(chatId).doc(m.id).set(m.toMap());
    await _chat(chatId).set({'lastMessage': m.toMap()}, SetOptions(merge: true));
    WtfLog.d(LogTag.chat, 'system message in $chatId: $text');
  }
}
