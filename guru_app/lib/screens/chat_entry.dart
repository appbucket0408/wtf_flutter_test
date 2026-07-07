import 'package:flutter/material.dart';
import 'package:wtf_shared/wtf_shared.dart';

import '../main.dart';
import 'call_launcher.dart';

/// Guru "Chat with Trainer" entry: resolves the assigned trainer then
/// opens the single DK ↔ Aarav conversation.
class ChatEntry extends StatelessWidget {
  final AppUser me;
  final AuthService authService;
  final ChatService chatService;

  const ChatEntry({
    super.key,
    required this.me,
    required this.authService,
    required this.chatService,
  });

  Future<AppUser?> _trainer() async {
    final trainers = await authService.seededTrainers();
    for (final t in trainers) {
      if (t.id == me.assignedTrainerId) return t;
    }
    return trainers.isEmpty ? null : trainers.first;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: _trainer(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.chatWithTrainer)),
            body: EmptyState(
              icon: Icons.error_outline,
              title: AppStrings.genericError,
              ctaLabel: AppStrings.retry,
              onCta: () => (context as Element).markNeedsBuild(),
            ),
          );
        }
        if (!snap.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        return ConversationScreen(
          me: me,
          peer: snap.data!,
          myBubbleColor: AppColors.guruPrimary,
          chatService: chatService,
          toolbarAction: ChatCallAction(
            approvedStream: scheduleService.watchApproved('memberId', me.id),
            onJoin: (request) => launchCall(context, me, request),
          ),
        );
      },
    );
  }
}
