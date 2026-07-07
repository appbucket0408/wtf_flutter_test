import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/conversation_bloc.dart';
import '../models/app_user.dart';
import '../services/chat_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_strings.dart';
import '../utils/app_text_styles.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/empty_state.dart';
import '../widgets/typing_dots.dart';

/// One conversation, shared by both apps (spec §3B). The opener passes
/// who they are, who they're chatting with, and their role color.
class ConversationScreen extends StatelessWidget {
  final AppUser me;
  final AppUser peer;
  final Color myBubbleColor;
  final ChatService chatService;

  /// Optional trailing appbar action (e.g. join-call camera icon, Task 10).
  final Widget? toolbarAction;

  const ConversationScreen({
    super.key,
    required this.me,
    required this.peer,
    required this.myBubbleColor,
    required this.chatService,
    this.toolbarAction,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ConversationBloc(
        chat: chatService,
        me: me,
        peer: peer,
        chatId: SeedChatId.of(me, peer),
      )..add(const ConversationOpened()),
      child: _ConversationView(
        me: me,
        peer: peer,
        myBubbleColor: myBubbleColor,
        toolbarAction: toolbarAction,
      ),
    );
  }
}

/// Deterministic chat id regardless of which side opens the screen.
abstract final class SeedChatId {
  static String of(AppUser a, AppUser b) {
    final member = a.role == UserRole.member ? a : b;
    final trainer = a.role == UserRole.trainer ? a : b;
    return '${member.id}_${trainer.id}';
  }
}

class _ConversationView extends StatefulWidget {
  final AppUser me;
  final AppUser peer;
  final Color myBubbleColor;
  final Widget? toolbarAction;

  const _ConversationView({
    required this.me,
    required this.peer,
    required this.myBubbleColor,
    this.toolbarAction,
  });

  @override
  State<_ConversationView> createState() => _ConversationViewState();
}

class _ConversationViewState extends State<_ConversationView> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send(BuildContext context, String text) {
    context.read<ConversationBloc>().add(TextSent(text));
    _inputController.clear();
    // Reversed list: bottom == offset 0.
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0,
          duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: widget.myBubbleColor,
              foregroundColor: AppColors.white,
              child: Text(widget.peer.name.substring(0, 1)),
            ),
            const SizedBox(width: Gap.s8),
            Expanded(
              child: BlocBuilder<ConversationBloc, ConversationState>(
                buildWhen: (a, b) => a.peerTyping != b.peerTyping,
                builder: (context, state) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.peer.name,
                        style: AppTextStyles.h2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    if (state.peerTyping)
                      Text(AppStrings.typing,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.success)),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [if (widget.toolbarAction != null) widget.toolbarAction!],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<ConversationBloc, ConversationState>(
              builder: (context, state) {
                if (state.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.messages.isEmpty && !state.peerTyping) {
                  return EmptyState(
                    icon: Icons.chat_bubble_outline,
                    title: AppStrings.emptyChat,
                    ctaLabel: AppStrings.sayHi,
                    onCta: () => _send(context, 'Hi ${widget.peer.name} 👋'),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => context
                      .read<ConversationBloc>()
                      .add(const LoadOlderRequested()),
                  child: ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(Gap.s16),
                    itemCount:
                        state.messages.length + (state.peerTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (state.peerTyping && index == 0) {
                        return const TypingDots();
                      }
                      final m = state
                          .messages[state.peerTyping ? index - 1 : index];
                      return ChatBubble(
                        message: m,
                        isMine: m.senderId == widget.me.id,
                        roleColor: widget.myBubbleColor,
                      );
                    },
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding:
                        const EdgeInsets.symmetric(horizontal: Gap.s16),
                    children: [
                      for (final reply in const [
                        AppStrings.quickReply1,
                        AppStrings.quickReply2,
                        AppStrings.quickReply3,
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: Gap.s8),
                          child: ActionChip(
                            label: Text(reply),
                            onPressed: () => _send(context, reply),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(Gap.s8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inputController,
                          maxLines: 4,
                          minLines: 1,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                              hintText: AppStrings.typeMessage),
                          onSubmitted: (t) => _send(context, t),
                        ),
                      ),
                      const SizedBox(width: Gap.s8),
                      IconButton.filled(
                        style: IconButton.styleFrom(
                            backgroundColor: widget.myBubbleColor,
                            foregroundColor: AppColors.white),
                        icon: const Icon(Icons.send),
                        onPressed: () =>
                            _send(context, _inputController.text),
                      ),
                    ],
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
