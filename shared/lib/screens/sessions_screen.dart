import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/app_user.dart';
import '../models/session_log.dart';
import '../services/log_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_strings.dart';
import '../utils/app_text_styles.dart';
import '../widgets/empty_state.dart';

enum SessionFilter { all, last7, month }

/// Session logs list (spec §3E): filter chips, latest first,
/// row = date/duration/rating, tap → detail modal with both notes.
class SessionsScreen extends StatefulWidget {
  final AppUser me;
  final LogService logService;
  final Color roleColor;
  final VoidCallback? onScheduleFirst;

  const SessionsScreen({
    super.key,
    required this.me,
    required this.logService,
    required this.roleColor,
    this.onScheduleFirst,
  });

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  SessionFilter _filter = SessionFilter.all;

  List<SessionLog> _applyFilter(List<SessionLog> logs) {
    final now = DateTime.now();
    return switch (_filter) {
      SessionFilter.all => logs,
      SessionFilter.last7 => logs
          .where((l) =>
              l.startedAt.isAfter(now.subtract(const Duration(days: 7))))
          .toList(),
      SessionFilter.month => logs
          .where((l) =>
              l.startedAt.year == now.year && l.startedAt.month == now.month)
          .toList(),
    };
  }

  String _duration(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _showDetail(SessionLog log) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(Gap.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat('EEE d MMM • h:mm a').format(log.startedAt),
                style: AppTextStyles.h2),
            const SizedBox(height: Gap.s8),
            Row(
              children: [
                const Icon(Icons.timer_outlined,
                    size: 16, color: AppColors.grey500),
                const SizedBox(width: Gap.s4),
                Text(_duration(log.durationSec),
                    style: AppTextStyles.bodySmall),
                const SizedBox(width: Gap.s16),
                if (log.rating != null) ...[
                  const Icon(Icons.star, size: 16, color: AppColors.warning),
                  const SizedBox(width: Gap.s4),
                  Text('${log.rating}/5', style: AppTextStyles.bodySmall),
                ],
              ],
            ),
            const SizedBox(height: Gap.s16),
            if (log.memberNotes?.isNotEmpty ?? false) ...[
              Text('${AppStrings.memberBadge}:',
                  style: AppTextStyles.caption),
              Text(log.memberNotes!, style: AppTextStyles.body),
              const SizedBox(height: Gap.s8),
            ],
            if (log.trainerNotes?.isNotEmpty ?? false) ...[
              Text('${AppStrings.trainerBadge}:',
                  style: AppTextStyles.caption),
              Text(log.trainerNotes!, style: AppTextStyles.body),
            ],
            const SizedBox(height: Gap.s16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final field =
        widget.me.role == UserRole.member ? 'memberId' : 'trainerId';
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.sessions)),
      body: StreamBuilder<List<SessionLog>>(
        stream: widget.logService.watch(field, widget.me.id),
        builder: (context, snap) {
          if (snap.hasError) {
            return EmptyState(
              icon: Icons.error_outline,
              title: AppStrings.genericError,
              ctaLabel: AppStrings.retry,
              onCta: () => setState(() {}),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final logs = _applyFilter(snap.data!);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(Gap.s16),
                child: Row(
                  children: [
                    for (final (f, label) in const [
                      (SessionFilter.all, AppStrings.filterAll),
                      (SessionFilter.last7, AppStrings.filterLast7),
                      (SessionFilter.month, AppStrings.filterMonth),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: Gap.s8),
                        child: ChoiceChip(
                          label: Text(label),
                          selected: _filter == f,
                          onSelected: (_) => setState(() => _filter = f),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: logs.isEmpty
                    ? EmptyState(
                        icon: Icons.history,
                        title: AppStrings.emptySessions,
                        ctaLabel: widget.onScheduleFirst != null
                            ? AppStrings.scheduleFirstCall
                            : null,
                        onCta: widget.onScheduleFirst,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: Gap.s16),
                        itemCount: logs.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: Gap.s8),
                        itemBuilder: (context, i) {
                          final log = logs[i];
                          return Card(
                            child: ListTile(
                              onTap: () => _showDetail(log),
                              leading: CircleAvatar(
                                backgroundColor: widget.roleColor
                                    .withValues(alpha: 0.1),
                                child: Icon(Icons.videocam,
                                    color: widget.roleColor),
                              ),
                              title: Text(
                                DateFormat('EEE d MMM • h:mm a')
                                    .format(log.startedAt),
                                style: AppTextStyles.body,
                              ),
                              subtitle: Text(
                                  _duration(log.durationSec),
                                  style: AppTextStyles.caption),
                              trailing: log.rating != null
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.star,
                                            size: 16,
                                            color: AppColors.warning),
                                        Text(' ${log.rating}',
                                            style:
                                                AppTextStyles.bodySmall),
                                      ],
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
