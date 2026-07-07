import 'package:flutter/material.dart';
import 'package:wtf_shared/wtf_shared.dart';

import '../main.dart';
import 'call_launcher.dart';

/// Trainer chat list (spec §3B): conversations with unread badge, last
/// message preview and "5m ago" timestamp. With one seeded member (DK)
/// this is a single live row driven by the chat summary stream.
class ChatListScreen extends StatelessWidget {
  final AppUser me;
  final ChatService chatService;
  final AuthService authService;

  const ChatListScreen({
    super.key,
    required this.me,
    required this.chatService,
    required this.authService,
  });

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.chats)),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.trainerPrimary,
        foregroundColor: AppColors.white,
        onPressed: () => _openDkChat(context),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<AppUser?>(
        future: _dk(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final dk = snap.data;
          if (dk == null) {
            return const EmptyState(
              icon: Icons.chat_bubble_outline,
              title: AppStrings.emptyChat,
            );
          }
          final chatId = SeedIds.chatId(dk.id, me.id);
          return StreamBuilder<ChatSummary>(
            stream: chatService.watchChat(chatId, me.id),
            builder: (context, chatSnap) {
              final summary = chatSnap.data ?? const ChatSummary();
              final last = summary.lastMessage;
              return ListView(
                padding: const EdgeInsets.all(Gap.s16),
                children: [
                  Card(
                    child: ListTile(
                      onTap: () => _openDkChat(context, dk: dk),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.guruPrimary,
                        foregroundColor: AppColors.white,
                        child: Text(dk.name.substring(0, 1)),
                      ),
                      title: Text(dk.name, style: AppTextStyles.body),
                      subtitle: Text(
                        summary.typingUserId == dk.id
                            ? AppStrings.typing
                            : (last?.text ?? AppStrings.emptyChat),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall,
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (last != null)
                            Text(_ago(last.createdAt),
                                style: AppTextStyles.caption),
                          if (summary.unreadCount > 0) ...[
                            const SizedBox(height: Gap.s4),
                            CircleAvatar(
                              radius: 10,
                              backgroundColor: AppColors.trainerPrimary,
                              child: Text(
                                '${summary.unreadCount}',
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.white),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<AppUser?> _dk() async {
    // The only member in this assessment is DK; look him up via the
    // members list (assignedTrainerId == me).
    final members = await authService.membersOf(me.id);
    return members.isEmpty ? null : members.first;
  }

  Future<void> _openDkChat(BuildContext context, {AppUser? dk}) async {
    final peer = dk ?? await _dk();
    if (peer == null || !context.mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (screenContext) => ConversationScreen(
        me: me,
        peer: peer,
        myBubbleColor: AppColors.trainerPrimary,
        chatService: chatService,
        toolbarAction: ChatCallAction(
          approvedStream: scheduleService.watchApproved('trainerId', me.id),
          onJoin: (request) => launchCall(screenContext, me, request),
        ),
      ),
    ));
  }
}
