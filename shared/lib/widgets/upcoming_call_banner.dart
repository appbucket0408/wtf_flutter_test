import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/call_request.dart';
import '../utils/app_strings.dart';
import '../utils/app_text_styles.dart';

/// Join window opens 10 minutes before the scheduled time (spec §3D)
/// and stays open for 30 minutes after.
bool isJoinable(CallRequest r, DateTime now) =>
    r.status == CallStatus.approved &&
    now.isAfter(r.scheduledFor.subtract(const Duration(minutes: 10))) &&
    now.isBefore(r.scheduledFor.add(const Duration(minutes: 30)));

/// Upcoming Calls banner: shows approved calls; the Join Call CTA
/// activates inside the join window. Re-evaluates every 30s.
class UpcomingCallBanner extends StatefulWidget {
  final Stream<List<CallRequest>> approvedStream;
  final Color roleColor;
  final void Function(CallRequest request) onJoin;

  const UpcomingCallBanner({
    super.key,
    required this.approvedStream,
    required this.roleColor,
    required this.onJoin,
  });

  @override
  State<UpcomingCallBanner> createState() => _UpcomingCallBannerState();
}

class _UpcomingCallBannerState extends State<UpcomingCallBanner> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Re-check the join window periodically so the button appears
    // without a manual refresh.
    _ticker = Timer.periodic(
        const Duration(seconds: 30), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CallRequest>>(
      stream: widget.approvedStream,
      builder: (context, snap) {
        final now = DateTime.now();
        final upcoming = (snap.data ?? [])
            .where((r) =>
                r.status == CallStatus.approved &&
                r.scheduledFor
                    .isAfter(now.subtract(const Duration(minutes: 30))))
            .toList()
          ..sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
        if (upcoming.isEmpty) return const SizedBox.shrink();

        final next = upcoming.first;
        final joinable = isJoinable(next, now);
        return Card(
          color: widget.roleColor.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.all(Gap.s16),
            child: Row(
              children: [
                Icon(Icons.videocam, color: widget.roleColor),
                const SizedBox(width: Gap.s8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppStrings.upcomingCalls,
                          style: AppTextStyles.caption),
                      Text(
                        DateFormat('EEE d MMM • h:mm a')
                            .format(next.scheduledFor),
                        style: AppTextStyles.body,
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  style:
                      FilledButton.styleFrom(backgroundColor: widget.roleColor),
                  onPressed: joinable ? () => widget.onJoin(next) : null,
                  icon: const Icon(Icons.videocam, size: 18),
                  label: Text(joinable
                      ? AppStrings.joinCall
                      : DateFormat('h:mm a').format(next.scheduledFor)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
