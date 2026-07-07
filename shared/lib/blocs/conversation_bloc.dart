import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/app_user.dart';
import '../models/message.dart';
import '../services/chat_service.dart';
import '../utils/app_exception.dart';
import '../utils/app_toast.dart';

sealed class ConversationEvent {
  const ConversationEvent();
}

class ConversationOpened extends ConversationEvent {
  const ConversationOpened();
}

class TextSent extends ConversationEvent {
  final String text;
  const TextSent(this.text);
}

class LoadOlderRequested extends ConversationEvent {
  const LoadOlderRequested();
}

class _MessagesChanged extends ConversationEvent {
  final List<Message> messages;
  const _MessagesChanged(this.messages);
}

class _SummaryChanged extends ConversationEvent {
  final ChatSummary summary;
  const _SummaryChanged(this.summary);
}

class ConversationState {
  final List<Message> messages; // newest first (reversed ListView)
  final bool peerTyping;
  final bool loading;

  const ConversationState({
    this.messages = const [],
    this.peerTyping = false,
    this.loading = true,
  });

  ConversationState copyWith(
          {List<Message>? messages, bool? peerTyping, bool? loading}) =>
      ConversationState(
        messages: messages ?? this.messages,
        peerTyping: peerTyping ?? this.peerTyping,
        loading: loading ?? this.loading,
      );
}

/// Drives one conversation for whichever role opens it: streams messages,
/// sends texts, marks incoming messages read while the screen is open and
/// surfaces the peer's (simulated) typing state.
class ConversationBloc extends Bloc<ConversationEvent, ConversationState> {
  final ChatService _chat;
  final AppUser me;
  final AppUser peer;
  final String chatId;

  StreamSubscription<List<Message>>? _messagesSub;
  StreamSubscription<ChatSummary>? _summarySub;
  int _limit = 50;

  ConversationBloc({
    required ChatService chat,
    required this.me,
    required this.peer,
    required this.chatId,
  })  : _chat = chat,
        super(const ConversationState()) {
    on<ConversationOpened>(_onOpened);
    on<TextSent>(_onTextSent);
    on<LoadOlderRequested>(_onLoadOlder);
    on<_MessagesChanged>(_onMessagesChanged);
    on<_SummaryChanged>((event, emit) =>
        emit(state.copyWith(peerTyping: event.summary.typingUserId == peer.id)));
  }

  void _subscribe() {
    _messagesSub?.cancel();
    _messagesSub = _chat
        .watchMessages(chatId, limit: _limit)
        .listen((m) => add(_MessagesChanged(m)));
  }

  Future<void> _onOpened(
      ConversationOpened event, Emitter<ConversationState> emit) async {
    _subscribe();
    _summarySub =
        _chat.watchChat(chatId, me.id).listen((s) => add(_SummaryChanged(s)));
    await _chat.markRead(chatId, me.id);
  }

  Future<void> _onMessagesChanged(
      _MessagesChanged event, Emitter<ConversationState> emit) async {
    emit(state.copyWith(messages: event.messages, loading: false));
    // New incoming message while the screen is open → mark read immediately.
    final hasUnread = event.messages.any(
        (m) => m.receiverId == me.id && m.status == MessageStatus.sent);
    if (hasUnread) await _chat.markRead(chatId, me.id);
  }

  Future<void> _onTextSent(
      TextSent event, Emitter<ConversationState> emit) async {
    final text = event.text.trim();
    if (text.isEmpty) return;
    try {
      await _chat.send(Message(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        chatId: chatId,
        senderId: me.id,
        receiverId: peer.id,
        text: text,
        createdAt: DateTime.now(),
        status: MessageStatus.sending,
      ));
    } on AppException catch (e) {
      AppToast.error(e.userMessage);
    }
  }

  void _onLoadOlder(
      LoadOlderRequested event, Emitter<ConversationState> emit) {
    _limit += 50;
    _subscribe();
  }

  @override
  Future<void> close() async {
    await _messagesSub?.cancel();
    await _summarySub?.cancel();
    return super.close();
  }
}
