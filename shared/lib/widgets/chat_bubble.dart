import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/message.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

/// Chat bubble (spec §3B): own messages right-aligned in the sender's role
/// color, peer messages left in grey; ✓ sent / ✓✓ read ticks on own
/// messages; system messages render as a centered grey pill.
class ChatBubble extends StatelessWidget {
  final Message message;
  final bool isMine;
  final Color roleColor;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.roleColor,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isSystem) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: Gap.s8),
          padding: const EdgeInsets.symmetric(
              horizontal: Gap.s16, vertical: Gap.s4),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(message.text, style: AppTextStyles.caption),
        ),
      );
    }

    final time = DateFormat('h:mm a').format(message.createdAt);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 12, end: 0),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      builder: (context, dy, child) =>
          Transform.translate(offset: Offset(0, dy), child: child),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.75),
          margin: const EdgeInsets.symmetric(vertical: Gap.s4),
          padding: const EdgeInsets.symmetric(
              horizontal: Gap.s16, vertical: Gap.s8),
          decoration: BoxDecoration(
            color: isMine ? roleColor : AppColors.grey100,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMine ? 16 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.text,
                style: AppTextStyles.body.copyWith(
                    color: isMine ? AppColors.white : AppColors.grey900),
              ),
              const SizedBox(height: Gap.s4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    time,
                    style: AppTextStyles.caption.copyWith(
                        color: isMine
                            ? AppColors.white.withValues(alpha: 0.8)
                            : AppColors.grey500),
                  ),
                  if (isMine) ...[
                    const SizedBox(width: Gap.s4),
                    Icon(
                      message.status == MessageStatus.read
                          ? Icons.done_all
                          : Icons.done,
                      size: 14,
                      color: AppColors.white.withValues(alpha: 0.9),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
