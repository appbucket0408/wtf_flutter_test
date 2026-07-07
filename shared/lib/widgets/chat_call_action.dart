import 'package:flutter/material.dart';

import '../models/call_request.dart';
import '../utils/app_colors.dart';
import 'upcoming_call_banner.dart';

/// Chat toolbar camera icon (spec §3D): shows a badge while a call is
/// joinable and launches it on tap. Used by both apps.
class ChatCallAction extends StatelessWidget {
  final Stream<List<CallRequest>> approvedStream;
  final void Function(CallRequest request) onJoin;

  const ChatCallAction({
    super.key,
    required this.approvedStream,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CallRequest>>(
      stream: approvedStream,
      builder: (context, snap) {
        final now = DateTime.now();
        final joinable =
            (snap.data ?? []).where((r) => isJoinable(r, now)).toList()
              ..sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
        if (joinable.isEmpty) return const SizedBox.shrink();
        return IconButton(
          onPressed: () => onJoin(joinable.first),
          icon: Badge(
            backgroundColor: AppColors.success,
            smallSize: 10,
            child: const Icon(Icons.videocam),
          ),
        );
      },
    );
  }
}
